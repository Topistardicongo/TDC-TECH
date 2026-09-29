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
