-- Convert schema 'share/ddl/_source/deploy/17/001-auto.yml' to 'share/ddl/_source/deploy/18/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE blacklist_emails (
  id INTEGER PRIMARY KEY NOT NULL,
  email text NOT NULL,
  wildcard bool NOT NULL DEFAULT '0',
  created datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  comment text NOT NULL DEFAULT ''
);

;
CREATE UNIQUE INDEX blacklist_emails_email ON blacklist_emails (email);

;
CREATE TABLE blacklist_usernames (
  id INTEGER PRIMARY KEY NOT NULL,
  username text NOT NULL,
  wildcard bool NOT NULL DEFAULT '0',
  created datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  comment text NOT NULL DEFAULT ''
);

;
CREATE UNIQUE INDEX blacklist_usernames_username ON blacklist_usernames (username);

;

COMMIT;

