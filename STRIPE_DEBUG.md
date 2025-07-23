# STRIPE_DEBUG.md

This guide helps you debug Stripe checkout issues locally, referring back to `LOCAL_DEV_SETUP.md` for general environment setup.

## Prerequisites
- Ensure you have followed **Section 2** (Environment Variables) and **Section 6** (Stripe Integration) of `LOCAL_DEV_SETUP.md`.
- Backend running on http://127.0.0.1:5004
- Frontend running on http://localhost:3001

## 1. Verify Environment

```powershell
# In your backend terminal (tubby/backend):
echo $env:STRIPE_SECRET_KEY
echo $env:STRIPE_PUBLISHABLE_KEY
echo $env:STRIPE_BASIC_PRICE_ID
echo $env:STRIPE_PRO_PRICE_ID
echo $env:STRIPE_ENTERPRISE_PRICE_ID
```

All values must match those in the Stripe Dashboard (test or live mode).

## 2. Restart Backend with Debug Logging

```powershell
cd tubby/backend
python app.py  # watch for any errors on StripeService init
```

Look for no `ValueError: Stripe secret key not configured` and no missing price ID errors.

## 3. Trigger Checkout Session

1. In your frontend terminal:
   ```powershell
   npm run dev -- --port 3001
   ```
2. Open http://localhost:3001
3. Log in via OAuth and click **Subscribe** on any plan.

## 4. Inspect Backend Logs

The backend console should print:

```
Stripe create_checkout_session error: <message if error>
```

or, if successful:

```
{ checkout_session_object }
``` 

Verify the session contains:
- `id` (starts with `cs_test_` or `cs_live_`)
- correct `line_items` price and metadata

## 5. cURL Test (Optional)

To bypass the UI, you can test via cURL:

```bash
curl -X POST http://127.0.0.1:5004/stripe/create-checkout-session \
  -H "Content-Type: application/json" \
  --cookie "session=<your_access_token_cookie>" \
  -d '{"plan_type":"basic"}'
```

Inspect the JSON response:
- 200 OK with `{"checkout_url": ...}` on success
- 400 or 500 with `{"error": ...}` on failure

## 6. Common Errors & Fixes

| Error Message                                   | Likely Cause                                     | Fix Refer to |
|-------------------------------------------------|--------------------------------------------------|--------------|
| `Stripe secret key not configured`              | Missing `STRIPE_SECRET_KEY` in env               | LOCAL_DEV_SETUP.md#2A |
| `No Stripe price ID configured for plan '...'` | Missing or typoed `STRIPE_<PLAN>_PRICE_ID`       | LOCAL_DEV_SETUP.md#2A |
| `Internal server error` (500) on checkout POST  | Exception thrown in `create_checkout_session`    | Inspect logs above |
| Stripe JS/CORS errors in browser console        | Frontend using wrong `VITE_API_URL`              | LOCAL_DEV_SETUP.md#2B |

## 7. Next Steps
- Once checkout succeeds, proceed to test Webhooks via `stripe listen` or Dashboard.
- Document any new issues back in `STRIPE_DEBUG.md` and update `LOCAL_DEV_SETUP.md` as needed. 