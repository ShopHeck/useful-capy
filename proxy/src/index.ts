/**
 * InterfaceForge API Proxy — Cloudflare Worker
 *
 * Sits between the iOS app and OpenAI. Pro subscribers authenticate with
 * their App Store transaction ID; the worker validates the receipt, enforces
 * a daily rate limit, and forwards the chat completion request using the
 * org's server-side API key.
 *
 * Secrets (set via `wrangler secret put`):
 *   OPENAI_API_KEY      — OpenAI org key
 *   APPLE_SHARED_SECRET — App Store Connect shared secret
 *
 * KV namespace:
 *   RATE_LIMIT — stores daily counters keyed by device/transaction ID
 */

export interface Env {
  OPENAI_API_KEY: string;
  APPLE_SHARED_SECRET: string;
  RATE_LIMIT: KVNamespace;
  DEFAULT_MODEL: string;
  DAILY_RATE_LIMIT: string;
  APP_BUNDLE_ID: string;
}

// ─── Types ───────────────────────────────────────────────────────────────

interface ChatRequest {
  model?: string;
  messages: Array<{ role: string; content: string }>;
  temperature?: number;
  response_format?: { type: string };
}

interface AppleReceiptResponse {
  status: number;
  latest_receipt_info?: Array<{
    product_id: string;
    expires_date_ms: string;
    original_transaction_id: string;
  }>;
}

// ─── Helpers ─────────────────────────────────────────────────────────────

function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function corsHeaders(origin: string | null): HeadersInit {
  return {
    "Access-Control-Allow-Origin": origin || "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Access-Control-Max-Age": "86400",
  };
}

/** Returns today's date as YYYY-MM-DD for rate-limit keying. */
function todayKey(): string {
  return new Date().toISOString().slice(0, 10);
}

// ─── Receipt Validation ──────────────────────────────────────────────────

/**
 * Validates an App Store receipt/transaction.
 *
 * In production, use Apple's App Store Server API v2 (JWT-based).
 * This implementation uses the legacy /verifyReceipt endpoint as a
 * working starting point — swap to v2 before scale.
 */
async function validateReceipt(
  receiptData: string,
  sharedSecret: string
): Promise<{ valid: boolean; transactionId?: string }> {
  // Try production first, fall back to sandbox
  const endpoints = [
    "https://buy.itunes.apple.com/verifyReceipt",
    "https://sandbox.itunes.apple.com/verifyReceipt",
  ];

  for (const endpoint of endpoints) {
    const res = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        "receipt-data": receiptData,
        password: sharedSecret,
        "exclude-old-transactions": true,
      }),
    });

    const data = (await res.json()) as AppleReceiptResponse;

    // Status 21007 = sandbox receipt sent to production → retry sandbox
    if (data.status === 21007) continue;

    if (data.status === 0 && data.latest_receipt_info?.length) {
      const active = data.latest_receipt_info.find(
        (txn) => parseInt(txn.expires_date_ms) > Date.now()
      );
      if (active) {
        return { valid: true, transactionId: active.original_transaction_id };
      }
    }

    return { valid: false };
  }

  return { valid: false };
}

// ─── Rate Limiting ───────────────────────────────────────────────────────

async function checkRateLimit(
  kv: KVNamespace,
  identifier: string,
  dailyLimit: number
): Promise<{ allowed: boolean; remaining: number }> {
  const key = `rl:${identifier}:${todayKey()}`;
  const current = parseInt((await kv.get(key)) || "0");

  if (current >= dailyLimit) {
    return { allowed: false, remaining: 0 };
  }

  // Increment with TTL of 48h (covers timezone edge cases)
  await kv.put(key, String(current + 1), { expirationTtl: 172800 });
  return { allowed: true, remaining: dailyLimit - current - 1 };
}

// ─── OpenAI Relay ────────────────────────────────────────────────────────

async function relayToOpenAI(
  apiKey: string,
  body: ChatRequest,
  defaultModel: string
): Promise<Response> {
  const payload = {
    ...body,
    model: body.model || defaultModel,
  };

  const upstream = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(payload),
  });

  // Stream the response back to the client
  return new Response(upstream.body, {
    status: upstream.status,
    headers: {
      "Content-Type": upstream.headers.get("Content-Type") || "application/json",
    },
  });
}

// ─── Main Handler ────────────────────────────────────────────────────────

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const origin = request.headers.get("Origin");
    const cors = corsHeaders(origin);

    // Handle CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors });
    }

    // Health check
    const url = new URL(request.url);
    if (url.pathname === "/health") {
      return new Response(
        JSON.stringify({ status: "ok", service: "interfaceforge-proxy" }),
        { status: 200, headers: { ...cors, "Content-Type": "application/json" } }
      );
    }

    // Only accept POST to /v1/chat/completions
    if (request.method !== "POST" || url.pathname !== "/v1/chat/completions") {
      return jsonError("Not found. Use POST /v1/chat/completions", 404);
    }

    // ── Auth: extract Bearer token (App Store receipt data) ──
    const authHeader = request.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return jsonError("Missing Authorization header. Include your App Store receipt as Bearer token.", 401);
    }
    const receiptData = authHeader.slice(7);

    // ── Validate receipt ──
    const receipt = await validateReceipt(receiptData, env.APPLE_SHARED_SECRET);
    if (!receipt.valid || !receipt.transactionId) {
      return jsonError("Invalid or expired Pro subscription. Restore purchases in the app.", 403);
    }

    // ── Rate limit ──
    const dailyLimit = parseInt(env.DAILY_RATE_LIMIT) || 200;
    const rateCheck = await checkRateLimit(env.RATE_LIMIT, receipt.transactionId, dailyLimit);
    if (!rateCheck.allowed) {
      const res = jsonError(
        `Daily generation limit (${dailyLimit}) reached. Resets at midnight UTC.`,
        429
      );
      res.headers.set("X-RateLimit-Remaining", "0");
      res.headers.set("X-RateLimit-Reset", todayKey());
      return res;
    }

    // ── Parse request body ──
    let body: ChatRequest;
    try {
      body = (await request.json()) as ChatRequest;
    } catch {
      return jsonError("Invalid JSON body.", 400);
    }

    if (!body.messages?.length) {
      return jsonError("Request must include a non-empty 'messages' array.", 400);
    }

    // ── Relay to OpenAI ──
    try {
      const response = await relayToOpenAI(env.OPENAI_API_KEY, body, env.DEFAULT_MODEL);

      // Add rate-limit headers
      const headers = new Headers(response.headers);
      headers.set("X-RateLimit-Remaining", String(rateCheck.remaining));
      Object.entries(cors).forEach(([k, v]) => headers.set(k, v));

      return new Response(response.body, {
        status: response.status,
        headers,
      });
    } catch (err) {
      console.error("Upstream error:", err);
      return jsonError("AI service temporarily unavailable. Try again in a moment.", 502);
    }
  },
};
