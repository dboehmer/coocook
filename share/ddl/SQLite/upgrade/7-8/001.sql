-- Convert schema 'share/ddl/_source/deploy/7/001-auto.yml' to 'share/ddl/_source/deploy/8/001-auto.yml':;

BEGIN;

CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  password_hash text NOT NULL,
  display_name text NOT NULL,
  role text NOT NULL,
  email text NOT NULL,
  email_verified datetime,
  token text,
  token_expires datetime
);

CREATE UNIQUE INDEX users_name ON users (name);

CREATE TABLE projects_users (
  project int NOT NULL,
  user int NOT NULL,
  role text NOT NULL,
  PRIMARY KEY (project, user),
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (user) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX projects_users_idx_project ON projects_users (project);

CREATE INDEX projects_users_idx_user ON projects_users (user);

CREATE TEMPORARY TABLE alter_projects (id,name,url_name,url_name_fc);
INSERT INTO alter_projects
SELECT id,name,url_name,url_name_fc FROM projects;

DROP TABLE projects;

CREATE TABLE projects (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  url_name text NOT NULL,
  url_name_fc text NOT NULL,
  is_public bool NOT NULL,
  owner int NOT NULL,
  FOREIGN KEY (owner) REFERENCES users(id)
);

CREATE INDEX projects_idx_owner ON projects (owner);

CREATE UNIQUE INDEX projects_name ON projects (name);

CREATE UNIQUE INDEX projects_url_name ON projects (url_name);

CREATE UNIQUE INDEX projects_url_name_fc ON projects (url_name_fc);

INSERT INTO projects
SELECT id,name,url_name,url_name_fc,1,1
FROM alter_projects;

INSERT INTO users VALUES (
  1,
  'coocook',
  'coocook',
  'Default User',
  'admin',
  'cooocook-user@example.com',
  DATETIME('now'),
  NULL,
  NULL
);

INSERT INTO projects_users
SELECT id,1,'owner'
FROM projects;

COMMIT;
