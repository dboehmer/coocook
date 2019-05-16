-- Convert schema 'share/ddl/_source/deploy/11/001-auto.yml' to 'share/ddl/_source/deploy/12/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE terms (
  id INTEGER PRIMARY KEY NOT NULL,
  valid_from date NOT NULL,
  content_md text NOT NULL
);

;
CREATE UNIQUE INDEX terms_valid_from ON terms (valid_from);

;
CREATE TABLE terms_users (
  terms int NOT NULL,
  user int NOT NULL,
  approved datetime NOT NULL,
  PRIMARY KEY (terms, user),
  FOREIGN KEY (terms) REFERENCES terms(id) ON DELETE CASCADE,
  FOREIGN KEY (user) REFERENCES users(id)
);

;
CREATE INDEX terms_users_idx_terms ON terms_users (terms);

;
CREATE INDEX terms_users_idx_user ON terms_users (user);

;

COMMIT;

