-- Convert schema 'share/ddl/_source/deploy/7/001-auto.yml' to 'share/ddl/_source/deploy/8/001-auto.yml':;

BEGIN;

CREATE TABLE sessions (
  id text NOT NULL,
  expires int,
  session_data text,
  PRIMARY KEY (id)
);

CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  password_hash text NOT NULL,
  display_name text NOT NULL,
  email text NOT NULL,
  email_verified datetime,
  token_hash text,
  token_expires datetime
);

CREATE UNIQUE INDEX users_email      ON users (email);
CREATE UNIQUE INDEX users_name       ON users (name);
CREATE UNIQUE INDEX users_token_hash ON users (token_hash);

CREATE TABLE roles_users (
  role text NOT NULL,
  user int NOT NULL,
  PRIMARY KEY (role, user),
  FOREIGN KEY (user) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX roles_users_idx_user ON roles_users (user);

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

-- create default site admin user for existing installations
-- to avoid orphaned projects
INSERT INTO users VALUES (
  1,
  'coocook',

  -- Argon2-crypted version of 'coocook'
  '$argon2i$v=19$m=32768,t=3,p=1$YtI+qVwB3ZG/icw3Z5qazw$ELUfsvpzWxWoAw8YTKMeXg',
  'Default User',
  'cooocook-user@example.com',
  DATETIME('now'),
  NULL,
  NULL
);

INSERT INTO roles_users VALUES('site_admin',1);

INSERT INTO projects_users
SELECT id,1,'owner'
FROM projects;

DROP TABLE alter_projects;

COMMIT;
