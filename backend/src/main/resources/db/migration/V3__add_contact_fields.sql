-- Add contact info and display preference fields to birthdays table
ALTER TABLE birthdays ADD COLUMN show_age BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE birthdays ADD COLUMN email VARCHAR(255);
ALTER TABLE birthdays ADD COLUMN whatsapp VARCHAR(50);
