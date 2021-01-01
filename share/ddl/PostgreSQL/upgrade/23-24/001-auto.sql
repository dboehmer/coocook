-- Convert schema 'share/ddl/_source/deploy/23/001-auto.yml' to 'share/ddl/_source/deploy/24/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users ADD COLUMN new_email_fc text;

;
ALTER TABLE users ADD COLUMN token_created timestamp without time zone;

;

COMMIT;

