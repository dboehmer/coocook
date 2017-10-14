-- Convert schema 'share/ddl/_source/deploy/7/001-auto.yml' to 'share/ddl/_source/deploy/8/001-auto.yml':;

BEGIN;

CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  password text NOT NULL,
  email text NOT NULL,
  display_name text NOT NULL
);

CREATE UNIQUE INDEX users_name ON users (name);

CREATE TABLE projects_users (
  project int NOT NULL,
  user int NOT NULL,
  PRIMARY KEY (project, user),
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (user) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX projects_users_idx_project ON projects_users (project);

CREATE INDEX projects_users_idx_user ON projects_users (user);

INSERT INTO users VALUES (1, 'coocook', 'coocook', 'cooocook-user@example.com', 'Default User');

INSERT INTO projects_users
SELECT id,1
FROM projects;

COMMIT;
