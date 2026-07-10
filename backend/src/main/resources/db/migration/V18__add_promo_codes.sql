CREATE TABLE promo_codes (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    discount_percentage INT NOT NULL CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    max_uses INT,
    current_uses INT NOT NULL DEFAULT 0,
    expires_at TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
