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
ALTER TABLE services ADD COLUMN dashboard_icon VARCHAR(80) NOT NULL DEFAULT '✦';
CREATE TABLE service_pages (
  slug VARCHAR(80) PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  description VARCHAR(500) NOT NULL DEFAULT '',
  icon VARCHAR(80) NOT NULL DEFAULT '✦',
  active TINYINT(1) NOT NULL DEFAULT 1,
  sort_order INT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE service_page_services (
  page_slug VARCHAR(80) NOT NULL,
  service_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY(page_slug,service_id),
  CONSTRAINT fk_page_service_page FOREIGN KEY(page_slug) REFERENCES service_pages(slug) ON DELETE CASCADE,
  CONSTRAINT fk_page_service_service FOREIGN KEY(service_id) REFERENCES services(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO service_pages(slug,name,description,icon,sort_order) VALUES
('social-ads','Social Media Ads','Campaign requests, revenue, delivery status, and campaign analytics.','📣',10),
('music','Music & Distribution','Release submissions, publication status, and distribution analytics.','🎵',20),
('verification','Verification','Verification applications, requests, and delivery analytics.','☑️',30),
('web-dev','Web & App Development','Project briefs, development requests, and revenue analytics.','🌐',40),
('account-mgmt','Account Management','Managed accounts, retainers, requests, and client analytics.','💼',50),
('press','Press Releases','Press and publication requests, delivery status, and revenue.','📰',60),
('smm','Likes & Followers','SMM requests, delivery analytics, and service pricing.','❤️',70),
('numbers','Virtual Numbers','Number orders, requests, and revenue analytics.','📱',80),
('bots','Custom Bots','Bot deployment requests, orders, and analytics.','🤖',90),
('proxies','Proxies','Proxy orders, allocation requests, and revenue analytics.','🌍',100);
UPDATE services SET dashboard_icon=CASE slug
 WHEN 'social-ads' THEN '📣' WHEN 'music' THEN '🎵' WHEN 'verification' THEN '☑️' WHEN 'web-dev' THEN '🌐'
 WHEN 'account-social' THEN '💼' WHEN 'press-tier1' THEN '📰' WHEN 'smm-followers' THEN '❤️' WHEN 'numbers' THEN '📱' WHEN 'bots' THEN '🤖' WHEN 'proxies' THEN '🌍' ELSE dashboard_icon END;
INSERT INTO service_page_services(page_slug,service_id)
SELECT 'social-ads',id FROM services WHERE slug='social-ads';
INSERT INTO service_page_services(page_slug,service_id)
SELECT 'music',id FROM services WHERE slug='music';
INSERT INTO service_page_services(page_slug,service_id)
SELECT 'verification',id FROM services WHERE slug='verification';
INSERT INTO service_page_services(page_slug,service_id)
SELECT 'web-dev',id FROM services WHERE slug IN ('web-dev','template-nexus','template-storefront','template-vibe');
INSERT INTO service_page_services(page_slug,service_id)
SELECT 'account-mgmt',id FROM services WHERE slug IN ('account-social','account-publicist','account-youtube','account-meta','account-dmca');
INSERT INTO service_page_services(page_slug,service_id)
SELECT 'press',id FROM services WHERE slug IN ('press-tier1','press-tier2','wiki-tier1','wiki-tier2');
INSERT INTO service_page_services(page_slug,service_id)
SELECT 'smm',id FROM services WHERE slug LIKE 'smm-%';
INSERT INTO service_page_services(page_slug,service_id)
SELECT 'numbers',id FROM services WHERE slug='numbers';
INSERT INTO service_page_services(page_slug,service_id)
SELECT 'bots',id FROM services WHERE slug='bots';
INSERT INTO service_page_services(page_slug,service_id)
SELECT 'proxies',id FROM services WHERE slug='proxies';
CREATE TABLE site_settings (
  setting_key VARCHAR(80) PRIMARY KEY,
  setting_value MEDIUMTEXT NOT NULL,
  updated_by BIGINT UNSIGNED NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_site_setting_editor FOREIGN KEY(updated_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
INSERT INTO site_settings(setting_key,setting_value) VALUES
('meta_title','TDC Tech — Digital Services & Automation'),
('brand_name','TDC Tech'),
('meta_description','Digital growth services, music distribution, automation, and instant tools for creators and businesses.'),
('logo_url',''),('favicon_url',''),
('home_title','Grow faster with digital services that deliver'),
('home_subtitle','Run campaigns, distribute music, and automate your growth from one dashboard.'),
('ads_hashtags',''),
('footer_pricing_text','Service prices are managed by TDC Tech and shown before checkout.'),
('footer_partnerships','');
CREATE TABLE site_content_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  item_type ENUM('partner','brand','leader','testimonial') NOT NULL,
  title VARCHAR(180) NOT NULL,
  subtitle VARCHAR(180) NOT NULL DEFAULT '',
  body TEXT NULL,
  image_url VARCHAR(1000) NOT NULL DEFAULT '',
  icon_text VARCHAR(80) NOT NULL DEFAULT '',
  href VARCHAR(1000) NOT NULL DEFAULT '',
  rating TINYINT UNSIGNED NOT NULL DEFAULT 5,
  sort_order INT NOT NULL DEFAULT 0,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_site_items_type(item_type,active,sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE notification_outbox (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NULL,
  recipient_email VARCHAR(254) NOT NULL,
  subject VARCHAR(250) NOT NULL,
  body_text TEXT NOT NULL,
  status ENUM('queued','sending','sent','failed') NOT NULL DEFAULT 'queued',
  attempts SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  last_error VARCHAR(500) NULL,
  sent_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_outbox_status(status,created_at),
  INDEX idx_outbox_user(user_id,created_at),
  CONSTRAINT fk_outbox_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
