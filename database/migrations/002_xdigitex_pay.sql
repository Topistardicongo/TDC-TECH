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
