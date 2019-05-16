-- Convert schema 'share/ddl/_source/deploy/15/001-auto.yml' to 'share/ddl/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE projects ADD COLUMN archived datetime;

;

COMMIT;

