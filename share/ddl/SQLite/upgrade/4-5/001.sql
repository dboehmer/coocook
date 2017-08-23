-- Convert schema 'share/ddl/_source/deploy/4/001-auto.yml' to 'share/ddl/_source/deploy/5/001-auto.yml':;

BEGIN;

-- automatically created but fails for me because index doesn't exist
--DROP INDEX dish_ingredients_fk_article;

CREATE TEMPORARY TABLE projects_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  url_name text NOT NULL,
  url_name_fc text NOT NULL
);

-- name for url_name and url_name_fc
INSERT INTO projects_temp_alter SELECT id, name, name, name FROM projects;

DROP TABLE projects;

CREATE TABLE projects (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  url_name text NOT NULL,
  url_name_fc text NOT NULL
);

CREATE UNIQUE INDEX projects_name02 ON projects (name);

INSERT INTO projects SELECT id, name, url_name, url_name_fc FROM projects_temp_alter;

DROP TABLE projects_temp_alter;

-- dito
--DROP INDEX recipe_ingredients_fk_article;

COMMIT;
