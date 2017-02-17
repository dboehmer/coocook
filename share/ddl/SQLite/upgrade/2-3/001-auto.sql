-- Convert schema 'share/ddl/_source/deploy/2/001-auto.yml' to 'share/ddl/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE tag_groups ADD COLUMN comment text NOT NULL DEFAULT '';

;

COMMIT;

