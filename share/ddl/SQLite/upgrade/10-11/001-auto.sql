-- Convert schema 'share/ddl/_source/deploy/10/001-auto.yml' to 'share/ddl/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE faqs (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  anchor text NOT NULL,
  question_md text NOT NULL,
  answer_md text NOT NULL
);

;
CREATE UNIQUE INDEX faqs_anchor ON faqs (anchor);

;
CREATE UNIQUE INDEX users_password_hash ON users (password_hash);

;

COMMIT;

