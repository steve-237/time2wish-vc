CREATE TABLE time_capsule_videos (
    id BIGSERIAL PRIMARY KEY,
    birthday_id BIGINT NOT NULL,
    guest_name VARCHAR(100) NOT NULL,
    video_url VARCHAR(255) NOT NULL,
    is_viewed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_time_capsule_birthday FOREIGN KEY (birthday_id) REFERENCES birthdays(id) ON DELETE CASCADE
);
