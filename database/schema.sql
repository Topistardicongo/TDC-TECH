CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(254) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('customer','admin') NOT NULL DEFAULT 'customer',
  status ENUM('active','suspended') NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE services (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  slug VARCHAR(80) NOT NULL UNIQUE,
  name VARCHAR(160) NOT NULL,
  price DECIMAL(12,2) NOT NULL DEFAULT 0,
  pricing_mode ENUM('fixed','per_1000','per_gb') NOT NULL DEFAULT 'fixed',
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE wallet_ledger (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  kind ENUM('credit','debit','refund','adjustment') NOT NULL,
  status ENUM('pending','posted','reversed') NOT NULL DEFAULT 'posted',
  reference VARCHAR(120) NULL,
  note VARCHAR(500) NULL,
  created_by BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_ledger_user(user_id,created_at),
  UNIQUE KEY uq_ledger_kind_reference(kind,reference),
  CONSTRAINT fk_ledger_user FOREIGN KEY(user_id) REFERENCES users(id),
  CONSTRAINT fk_ledger_actor FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE orders (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  service_id BIGINT UNSIGNED NOT NULL,
  description VARCHAR(255) NOT NULL,
  details JSON NULL,
  admin_note TEXT NULL,
  amount DECIMAL(12,2) NOT NULL,
  status ENUM('pending','processing','completed','rejected','cancelled') NOT NULL DEFAULT 'pending',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_orders_user(user_id,created_at),
  INDEX idx_orders_status(status,created_at),
  CONSTRAINT fk_order_user FOREIGN KEY(user_id) REFERENCES users(id),
  CONSTRAINT fk_order_service FOREIGN KEY(service_id) REFERENCES services(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE audit_log (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  actor_user_id BIGINT UNSIGNED NULL,
  event VARCHAR(100) NOT NULL,
  ip_address VARCHAR(45) NOT NULL,
  metadata JSON NULL,
  created_at DATETIME NOT NULL,
  INDEX idx_audit_created(created_at),
  CONSTRAINT fk_audit_actor FOREIGN KEY(actor_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE login_attempt_limits (
  email_hash CHAR(64) NOT NULL,
  ip_hash CHAR(64) NOT NULL,
  attempt_count SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  window_started DATETIME NOT NULL,
  PRIMARY KEY(email_hash,ip_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO services(slug,name,price,pricing_mode) VALUES
('social-ads','Social Media Ads campaign',350.00,'fixed'),('music','Music distribution',15.00,'fixed'),
('verification','Verification application',250.00,'fixed'),('web-dev','Custom development brief',0.00,'fixed'),
('template-nexus','Nexus SaaS template',49.99,'fixed'),('template-storefront','StoreFront Pro template',69.99,'fixed'),('template-vibe','Vibe Music template',59.99,'fixed'),
('account-social','Full Social Media Management',299.00,'fixed'),('account-publicist','VIP Publicist retainer',499.00,'fixed'),('account-youtube','YouTube Channel Monetization setup',199.00,'fixed'),('account-meta','Meta Business Manager setup',150.00,'fixed'),('account-dmca','DMCA Takedown service',99.00,'fixed'),
('press-tier1','Press release · Tier 1',85.00,'fixed'),('press-tier2','Press release · Tier 2',250.00,'fixed'),('wiki-tier1','Wikipedia · Assessment and draft',150.00,'fixed'),('wiki-tier2','Wikipedia · Full creation',450.00,'fixed'),
('smm-followers','SMM followers · per 1,000',1.50,'per_1000'),('smm-likes','SMM likes · per 1,000',1.00,'per_1000'),('smm-views','SMM views · per 1,000',0.80,'per_1000'),('smm-comments','SMM comments · per 1,000',25.00,'per_1000'),
('numbers','Virtual number',2.00,'fixed'),('bots','Custom bot deployment',30.00,'fixed'),('proxies','Residential proxy · per GB',6.00,'per_gb');

CREATE TABLE gateway_fx_rates (
  currency CHAR(3) NOT NULL PRIMARY KEY,
  units_per_gbp DECIMAL(18,6) NOT NULL DEFAULT 0,
  active TINYINT(1) NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO gateway_fx_rates(currency,units_per_gbp,active) VALUES
('KES',0,0),('CDF',0,0),('UGX',0,0),('XOF',0,0),('XAF',0,0),('RWF',0,0),('ZMW',0,0),('SLE',0,0),('USD',0,0);
CREATE TABLE topup_payments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  ledger_id BIGINT UNSIGNED NOT NULL,
  local_reference VARCHAR(48) NOT NULL UNIQUE,
  provider_reference VARCHAR(120) NULL UNIQUE,
  requested_gbp DECIMAL(12,2) NOT NULL,
  provider_amount DECIMAL(18,2) NOT NULL,
  currency CHAR(3) NOT NULL,
  gateway VARCHAR(20) NOT NULL,
  status ENUM('initiated','pending','processing','completed','failed') NOT NULL DEFAULT 'initiated',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_topup_user(user_id,created_at),
  INDEX idx_topup_status(status,created_at),
  CONSTRAINT fk_topup_user FOREIGN KEY(user_id) REFERENCES users(id),
  CONSTRAINT fk_topup_ledger FOREIGN KEY(ledger_id) REFERENCES wallet_ledger(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
