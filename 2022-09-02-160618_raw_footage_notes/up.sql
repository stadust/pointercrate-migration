-- Your SQL goes here

ALTER TABLE record_notes ADD COLUMN is_raw_footage BOOLEAN NOT NULL DEFAULT FALSE;
