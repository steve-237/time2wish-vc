-- Chat Rooms
CREATE TABLE chat_rooms (
    id BIGSERIAL PRIMARY KEY,
    birthday_id BIGINT NOT NULL UNIQUE REFERENCES birthdays(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Chat Participants (Many to Many)
CREATE TABLE chat_room_participants (
    chat_room_id BIGINT NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    PRIMARY KEY (chat_room_id, user_id)
);

-- Chat Messages
CREATE TABLE chat_messages (
    id BIGSERIAL PRIMARY KEY,
    chat_room_id BIGINT NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Fundraisers (Cagnottes)
CREATE TABLE fundraisers (
    id BIGSERIAL PRIMARY KEY,
    gift_id BIGINT NOT NULL UNIQUE REFERENCES gifts(id) ON DELETE CASCADE,
    target_amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'EUR',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Pledges (Promesses de don)
CREATE TABLE pledges (
    id BIGSERIAL PRIMARY KEY,
    fundraiser_id BIGINT NOT NULL REFERENCES fundraisers(id) ON DELETE CASCADE,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    guest_name VARCHAR(100),
    amount DECIMAL(10,2) NOT NULL,
    message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
