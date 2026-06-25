-- Add share token to birthdays table
ALTER TABLE birthdays ADD COLUMN share_token VARCHAR(36) UNIQUE;

-- Create gifts table
CREATE TABLE gifts (
    id BIGSERIAL PRIMARY KEY,
    birthday_id BIGINT NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price_range VARCHAR(50),
    url TEXT,
    is_reserved BOOLEAN NOT NULL DEFAULT FALSE,
    reserved_by_name VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_gifts_birthday FOREIGN KEY (birthday_id) REFERENCES birthdays (id) ON DELETE CASCADE
);

CREATE INDEX idx_gifts_birthday_id ON gifts(birthday_id);
