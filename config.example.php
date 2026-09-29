<?php
// Copy to config.local.php and fill in values. Keep config.local.php out of web root and Git.
define('TDC_DB_HOST', 'localhost');
define('TDC_DB_NAME', 'your_database');
define('TDC_DB_USER', 'your_database_user');
define('TDC_DB_PASS', 'use-a-long-unique-database-password');

// Set true on production when TLS is enabled (recommended).
define('TDC_FORCE_HTTPS', true);

// Generate a unique 32+ character random key; keep it backed up and private.
define('TDC_APP_KEY', '');

// Xdigitex Pay credentials. Keep these values on the server only.
define('TDC_PAY_API_KEY', '');
define('TDC_PAY_WEBHOOK_SECRET', ''); // Generate a separate random 32+ character secret.
define('TDC_APP_URL', 'https://your-domain.example');
