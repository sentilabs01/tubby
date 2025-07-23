# Tubby AI – Local & Production Configuration Cheat Sheet

> Keep this file up-to-date whenever OAuth endpoints, ports, or environment variables change. It is **the single source of truth** for running Tubby locally or in production.

---

## 1. Standard Ports
| Service          | Local Port | Production |
|------------------|-----------|------------|
| React Frontend   | **3001**  | https://tubbyai.com |
| Flask Backend    | **5004**  | https://tubby-backend-prod.eba-6fzzpyej.us-east-1.elasticbeanstalk.com |
| Socket.IO WS     | 5004 (same as backend) | same host |

*Always run Vite on 3001.  If the port is busy:*  
`netstat -ano | findstr :3001` → `taskkill /PID <pid> /F`

---

## 2. Environment Variables
### Backend (PowerShell example)
```powershell
# ── Core Flask ───────────────────────────
$env:FLASK_ENV = "production"               # or development
$env:PORT       = "5004"
$env:HOST       = "0.0.0.0"

# ── Frontend origin for OAuth redirect_to ─
$env:FRONTEND_URL = "http://localhost:3001"  # <- change to https://tubbyai.com in prod

# ── Supabase ─────────────────────────────
$env:SUPABASE_URL              = "https://ewrbezytnhuovvmkepeg.supabase.co"
$env:SUPABASE_ANON_KEY         = "<full-anon-key>"
$env:SUPABASE_SERVICE_ROLE_KEY = "<full-service-role-key>"

# ── Google OAuth ─────────────────────────
$env:GOOGLE_CLIENT_ID     = "117261848322-rgs0fd2fsk2emdgcd0jhjv4380rcmibh.apps.googleusercontent.com"
$env:GOOGLE_CLIENT_SECRET = "<secret>"

# ── GitHub OAuth ─────────────────────────
$env:GITHUB_CLIENT_ID     = "Ov231i0VjZz21dCiQ9oj"
$env:GITHUB_CLIENT_SECRET = "<secret>"

# ── Stripe ───────────────────────────────
$env:STRIPE_SECRET_KEY          = "sk_live_…"
$env:STRIPE_PUBLISHABLE_KEY     = "pk_live_…"
$env:STRIPE_WEBHOOK_SECRET      = "whsec_…"      # optional for local
$env:STRIPE_BASIC_PRICE_ID      = "price_1RnI7vKoB6ANfJLNft6upLIC"
$env:STRIPE_PRO_PRICE_ID        = "price_1RnI8LBKoB6ANfJLNRNUyRVIX"
$env:STRIPE_ENTERPRISE_PRICE_ID = "price_1RnI9FKoB6ANfJLNwZTZ5M8A"
```

### Frontend – `.env.local` (git-ignored)
```env
VITE_API_URL=http://127.0.0.1:5004
FRONTEND_URL=http://localhost:3001
```
Build for production with:
```bash
VITE_API_URL=https://tubby-backend-prod.eba-6fzzpyej.us-east-1.elasticbeanstalk.com npm run build
```

---

## 3. Authorized Redirect URIs
### Google Cloud Console → OAuth 2.0 Client
```
http://localhost:3001/auth/callback
https://ewrbezytnhuovvmkepeg.supabase.co/auth/v1/callback
```
> Remove **all other** localhost ports or old project refs – Google matches exactly.

### GitHub OAuth App (single allowed URI)
```
https://ewrbezytnhuovvmkepeg.supabase.co/auth/v1/callback
```
GitHub always calls Supabase; Supabase then redirects to `redirect_to`.

---

## 4. Start-Up Commands
```powershell
# 1️⃣ Terminal A – Backend
cd backend
# (export env vars as above or ensure backend/.env exists)
python app.py

# 2️⃣ Terminal B – Frontend
npm run dev -- --port 3001
```

Open `http://localhost:3001` → Login with Google/GitHub → Subscribe → Stripe checkout.

---

## 5. Troubleshooting Quick Refs
| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Google “redirect_uri_mismatch” shows `bemssf…` | `SUPABASE_URL` not set in backend terminal | export correct `SUPABASE_URL` then restart `python app.py` |
| Google mismatch shows wrong port (3002/3003) | Vite picked a different port | free 3001 (`taskkill`) and restart `npm run dev -- --port 3001` |
| Stripe 500 on `/stripe/create-checkout-session` | Missing/invalid Stripe env vars | export all Stripe keys & price IDs and restart backend |

---

When everything here is satisfied, **OAuth and Stripe work locally and in production** without further tweaks. 

## 6. Stripe Integration & Local Testing

Follow these steps to configure and verify Stripe in your local development setup.

### A. Environment Variables (PowerShell)
```powershell
# Replace with your actual Stripe test or live keys
$env:STRIPE_SECRET_KEY          = "sk_test_XXXXXXXXXXXXXXXXXXXXXXXX"
$env:STRIPE_PUBLISHABLE_KEY     = "pk_test_XXXXXXXXXXXXXXXXXXXXXXXX"
$env:STRIPE_WEBHOOK_SECRET      = "whsec_XXXXXXXXXXXXXXXXXXXXXXXX"    # optional until testing webhooks

# Price IDs for your Tubby plans (from Stripe Dashboard)
$env:STRIPE_BASIC_PRICE_ID      = "price_1RnI7vKoB6ANfJLNft6upLIC"
$env:STRIPE_PRO_PRICE_ID        = "price_1RnI8LBKoB6ANfJLNRNUyRVIX"
$env:STRIPE_ENTERPRISE_PRICE_ID = "price_1RnI9FKoB6ANfJLNwZTZ5M8A"
```

> TIP: You can also store these in your `backend/.env` file under the same keys.

### B. Restart Backend
1. In the `tubby/backend` folder:
   ```powershell
   python app.py
   ```
2. Confirm StripeService initialized without errors; look for _no_ `ValueError` at startup.

### C. Frontend & Checkout Flow
1. In your frontend terminal (project root):
   ```powershell
   npm run dev -- --port 3001
   ```
2. Open [http://localhost:3001](http://localhost:3001) and log in via OAuth.
3. Click **Subscribe** on a plan:
   - You should be redirected to the Stripe Checkout page.
   - Use a Stripe test card (e.g. `4242 4242 4242 4242`, any future date, any CVC).
4. After completing payment, you’ll return to `/subscription/success`.

### D. Verifying in the Backend Logs
- The backend console will log something like:
  ```text
  Stripe create_checkout_session error: <if any>
  or
  {<checkout_session object printed>}
  ```
- Check that you receive a valid `session.id` starting with `cs_test_...` (test mode) or `cs_live_...` (live mode).

### E. Troubleshooting
- **500 on checkout**: Missing or incorrect `STRIPE_*` env-vars. Re-run `echo $env:STRIPE_SECRET_KEY` etc.
- **Webhook errors**: Ensure `STRIPE_WEBHOOK_SECRET` matches your Stripe Dashboard webhook endpoint secret, and test via Stripe CLI or Dashboard.

---

When this section is complete, your local Stripe integration will mirror production behavior for end-to-end testing. 