# InterfaceForge API Proxy

Cloudflare Worker that authenticates Pro subscribers via App Store receipt validation and relays AI generation requests to OpenAI using a server-side API key.

## Architecture

```
iOS App → Bearer {receipt} → [CF Worker] → validates receipt
                                          → checks daily rate limit (KV)
                                          → forwards to OpenAI with org key
                                          → streams response back to app
```

## Setup

### 1. Install dependencies

```bash
cd proxy
npm install
```

### 2. Create KV namespace

```bash
npx wrangler kv:namespace create RATE_LIMIT
```

Copy the output `id` into `wrangler.toml`.

### 3. Set secrets

```bash
npx wrangler secret put OPENAI_API_KEY
npx wrangler secret put APPLE_SHARED_SECRET
```

### 4. Deploy

```bash
npm run deploy
```

### 5. Update iOS app

In `ProxyService.swift`, set:
```swift
static var baseURL: URL? = URL(string: "https://interfaceforge-proxy.<your-subdomain>.workers.dev/v1/chat/completions")
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| POST | `/v1/chat/completions` | AI generation (requires Bearer receipt token) |

## Rate Limits

- Default: 200 requests/day per subscriber
- Configurable via `DAILY_RATE_LIMIT` in `wrangler.toml`
- Counters stored in Workers KV with 48h TTL
- `X-RateLimit-Remaining` header included in responses

## Local Development

```bash
npm run dev
```

This starts a local dev server at `http://localhost:8787`.
