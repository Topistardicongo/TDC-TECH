# TDC Tech

A PHP and MySQL application built around the supplied TDC Tech interface. The public pages have separate routes for the landing page, sign-in, registration, customer dashboard, each service, and the administrator panel.

## Requirements

- PHP 8.1 or newer with PDO MySQL and JSON extensions; `mbstring` is recommended.
- MySQL 5.7.8+ or a compatible current MariaDB release.
- HTTPS for production.

## Deploy on shared hosting

1. Upload or clone the repository outside the public web root if your host supports it.
2. Set the website document root to this repository's `public/` directory and enable SSL before opening the site; the Apache rules redirect HTTP to HTTPS. This keeps PHP source, SQL, templates, and configuration outside public access.
3. Create a MySQL database and user with access to that database.
4. Copy `config.example.php` to `config.local.php` in the repository root and set database credentials, `TDC_FORCE_HTTPS`, and a fixed random `TDC_APP_KEY` of at least 32 characters (generate one once with `php -r "echo bin2hex(random_bytes(32)), PHP_EOL;"` and store it in the local config). Keep the local config out of Git and back up the encryption key securely; customer-visible fulfillment notes are encrypted in the database and cannot be decrypted if that key is lost.
5. Import `database/schema.sql` into the database. If the app already has its earlier schema, instead apply `database/migrations/002_xdigitex_pay.sql` once.
6. From the repository root, run `php bin/create-admin.php` in the hosting terminal and enter the admin email and a unique password of at least 12 characters. The script creates or promotes that account to administrator.
7. Visit `/` and register a customer account. Use `/admin/` to manage the service catalog, customers, payment records, currency rates, and orders.

Do not deploy the repository root as the web root. Do not place `config.local.php` inside `public/`, commit credentials, or turn on PHP error display in production.

## Routes

- `/` — landing page
- `/login.php` — sign-in
- `/register.php` — account registration
- `/dashboard.php` — authenticated dashboard
- `/services/{service}.php` — direct authenticated service pages
- `/admin/` — administrator-only console
- `/api/*` — same-origin session-authenticated endpoints

## Security and behavior

- Registration creates customer accounts only; administrator privileges are assigned from the CLI or managed by an existing administrator.
- Passwords are stored using PHP's password hashing API. Sessions use HTTP-only, SameSite cookies and rotate after login.
- State-changing API requests require a session CSRF token. Login attempts are rate limited by account and source IP.
- Wallet balances are calculated from posted ledger entries. A browser cannot set a balance or order price.
- Service prices and order totals are looked up and calculated on the server. The customer must confirm the server quote before an order is charged.
- Wallet top-ups use Xdigitex Pay. The app credits GBP only after it verifies the provider payment status through the authenticated server-to-server API. Webhook messages are only triggers for a status check; their contents cannot directly credit a wallet.
- Xdigitex does not document GBP as a payment currency. Administrators must set and enable an FX rate under `/admin/` for each supported provider currency before customers can pay in it. Mobile money detects the currency from the international phone prefix.
- The Xdigitex API key and webhook secret stay in server configuration. Never add either value to browser code or commit them. The provider account and hosting configuration must be completed before live payments can be accepted.
- Order cancellations and rejections create a ledger refund once. Admin actions are written to the audit log.
- The interface preserves the existing styling and service pages. Social OAuth, royalty reporting, and automated provisioning are not configured; those controls are presented as unavailable or routed to manual admin review instead of simulating success.
- Frontend code is necessarily visible to browsers and to anyone with repository access. Passwords, database credentials, session checks, order validation, and account data are handled server-side.

## Configuration

`config.local.php` is loaded from the repository root. It must define `TDC_DB_HOST`, `TDC_DB_NAME`, `TDC_DB_USER`, `TDC_DB_PASS`, and `TDC_FORCE_HTTPS`. For live Xdigitex Pay, also set `TDC_PAY_API_KEY`, a separate random `TDC_PAY_WEBHOOK_SECRET` (at least 32 characters), and the public HTTPS origin in `TDC_APP_URL`. Generate a secret with `php -r "echo bin2hex(random_bytes(32)), PHP_EOL;"`. The included `.gitignore` excludes this file. The API key is created in the Xdigitex Pay dashboard under API Keys.
