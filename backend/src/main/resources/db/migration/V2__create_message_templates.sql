-- Create message_templates table
CREATE TABLE message_templates (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(100) NOT NULL,
    content VARCHAR(1000) NOT NULL,
    category VARCHAR(50) NOT NULL,
    CONSTRAINT fk_message_templates_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Index for performance optimization
CREATE INDEX idx_message_templates_user ON message_templates(user_id);
