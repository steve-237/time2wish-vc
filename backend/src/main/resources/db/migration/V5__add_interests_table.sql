CREATE TABLE birthday_interests (
    birthday_id BIGINT NOT NULL,
    interest VARCHAR(255) NOT NULL,
    CONSTRAINT fk_birthday_interests FOREIGN KEY (birthday_id) REFERENCES birthdays(id) ON DELETE CASCADE
);
