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
