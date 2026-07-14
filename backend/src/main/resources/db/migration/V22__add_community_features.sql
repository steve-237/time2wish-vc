-- Add Party Details to birthdays
ALTER TABLE birthdays ADD COLUMN party_date DATE;
ALTER TABLE birthdays ADD COLUMN party_time VARCHAR(10);
ALTER TABLE birthdays ADD COLUMN party_location VARCHAR(200);
ALTER TABLE birthdays ADD COLUMN party_description TEXT;

-- Create Party Tasks
CREATE TABLE party_tasks (
    id BIGSERIAL PRIMARY KEY,
    birthday_id BIGINT NOT NULL,
    description VARCHAR(200) NOT NULL,
    assignee_name VARCHAR(100),
    assignee_session_id VARCHAR(100),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_party_tasks_birthday FOREIGN KEY (birthday_id) REFERENCES birthdays(id) ON DELETE CASCADE
);

-- Create Gift Votes
CREATE TABLE gift_votes (
    id BIGSERIAL PRIMARY KEY,
    gift_id BIGINT NOT NULL,
    voter_name VARCHAR(100) NOT NULL,
    voter_session_id VARCHAR(100),
    vote_type VARCHAR(10) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_gift_votes_gift FOREIGN KEY (gift_id) REFERENCES gifts(id) ON DELETE CASCADE
);
