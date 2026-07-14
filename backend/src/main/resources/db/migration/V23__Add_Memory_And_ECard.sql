CREATE TABLE memory_items (
    id BIGSERIAL PRIMARY KEY,
    birthday_id BIGINT NOT NULL REFERENCES birthdays(id) ON DELETE CASCADE,
    guest_name VARCHAR(100) NOT NULL,
    guest_session_id VARCHAR(100),
    message TEXT,
    media_url VARCHAR(255),
    media_type VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ecard_signatures (
    id BIGSERIAL PRIMARY KEY,
    birthday_id BIGINT NOT NULL REFERENCES birthdays(id) ON DELETE CASCADE,
    guest_name VARCHAR(100) NOT NULL,
    guest_session_id VARCHAR(100),
    message TEXT NOT NULL,
    color VARCHAR(20) NOT NULL,
    font_family VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
