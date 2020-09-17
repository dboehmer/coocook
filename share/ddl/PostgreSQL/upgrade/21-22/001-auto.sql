-- Convert schema 'share/ddl/_source/deploy/21/001-auto.yml' to 'share/ddl/_source/deploy/22/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE blacklist_emails ALTER COLUMN created TYPE timestamp without time zone;

;
ALTER TABLE blacklist_emails ALTER COLUMN created SET DEFAULT CURRENT_TIMESTAMP;

;
ALTER TABLE blacklist_usernames ALTER COLUMN created TYPE timestamp without time zone;

;
ALTER TABLE blacklist_usernames ALTER COLUMN created SET DEFAULT CURRENT_TIMESTAMP;

;
ALTER TABLE dish_ingredients ALTER COLUMN prepare TYPE boolean;

;
ALTER TABLE items ALTER COLUMN purchased TYPE boolean;

;
ALTER TABLE organizations ALTER COLUMN created TYPE timestamp without time zone;

;
ALTER TABLE organizations ALTER COLUMN created SET DEFAULT CURRENT_TIMESTAMP;

;
ALTER TABLE projects ALTER COLUMN is_public TYPE boolean;

;
ALTER TABLE projects ALTER COLUMN created TYPE timestamp without time zone;

;
ALTER TABLE projects ALTER COLUMN created SET DEFAULT CURRENT_TIMESTAMP;

;
ALTER TABLE projects ALTER COLUMN archived TYPE timestamp without time zone;

;
ALTER TABLE recipe_ingredients ALTER COLUMN prepare TYPE boolean;

;
ALTER TABLE terms_users ALTER COLUMN approved TYPE timestamp without time zone;

;
ALTER TABLE units ALTER COLUMN space TYPE boolean;

;
ALTER TABLE users ALTER COLUMN email_verified TYPE timestamp without time zone;

;
ALTER TABLE users ALTER COLUMN token_expires TYPE timestamp without time zone;

;
ALTER TABLE users ALTER COLUMN created TYPE timestamp without time zone;

;
ALTER TABLE users ALTER COLUMN created SET DEFAULT CURRENT_TIMESTAMP;

;

COMMIT;

