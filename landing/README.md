# InterfaceForge Landing Page

Marketing landing page for InterfaceForge — a native iOS app for AI-powered UI component generation.

## Stack

- Pure HTML + CSS + JS (zero dependencies, zero build step)
- Google Fonts: Inter + JetBrains Mono
- Dark glass-morphism theme matching the app's Aurora palette

## Deploy

### Cloudflare Pages (recommended)

1. In your Cloudflare dashboard, go to **Workers & Pages → Create application → Pages**
2. Connect your GitHub repo
3. Set build output directory to `landing/`
4. No build command needed — it's static HTML
5. Deploy

Or via CLI:
```bash
cd landing
npx wrangler pages deploy . --project-name=interfaceforge
```

### Alternative: any static host

Drop the `landing/` folder contents onto Netlify, Vercel, GitHub Pages, or any static file server.

## Customization

- **Colors:** All CSS custom properties are in `:root` in `style.css`
- **Copy:** All text is in `index.html` — no build step needed
- **App Store link:** Replace the `href="#"` on the App Store badge in the final CTA section
- **OG image:** Add `assets/og-image.png` (1200×630px recommended)
- **Favicon:** Add your favicon files to the root

## Features

- Fixed glassmorphic nav with scroll state
- Animated device mockup with typing effect
- Scroll-reveal animations with IntersectionObserver
- Responsive: desktop → tablet → mobile
- Accessible: semantic HTML, proper heading hierarchy, focus states
- Fast: no framework, no build, ~25KB total (excluding fonts)
