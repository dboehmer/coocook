-- Convert schema 'share/ddl/_source/deploy/9/001-auto.yml' to 'share/ddl/_source/deploy/10/001-auto.yml':;

BEGIN;

CREATE TEMPORARY TABLE projects_temp_alter (
  id,
  name,
  url_name,
  url_name_fc,
  is_public,
  owner
);

INSERT INTO projects_temp_alter
SELECT
  id,
  name,
  url_name,
  url_name_fc,
  is_public,
  owner
FROM projects;

DROP TABLE projects;

CREATE TABLE projects (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  url_name text NOT NULL,
  url_name_fc text NOT NULL,
  description text NOT NULL,
  is_public bool NOT NULL DEFAULT '1',
  owner int NOT NULL,
  FOREIGN KEY (owner) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX projects_idx_owner ON projects (owner);
CREATE UNIQUE INDEX projects_name ON projects (name);
CREATE UNIQUE INDEX projects_url_name ON projects (url_name);
CREATE UNIQUE INDEX projects_url_name_fc ON projects (url_name_fc);

INSERT INTO projects
SELECT
  id,
  name,
  url_name,
  url_name_fc,
  '',
  is_public,
  owner
FROM projects_temp_alter;

DROP TABLE projects_temp_alter;

COMMIT;
