-- Convert schema 'share/ddl/_source/deploy/22/001-auto.yml' to 'share/ddl/_source/deploy/23/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE recipes_of_the_day (
  id INTEGER PRIMARY KEY NOT NULL,
  recipe_id integer NOT NULL,
  day date NOT NULL,
  admin_comment text NOT NULL DEFAULT '',
  FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
);

;
CREATE INDEX recipes_of_the_day_idx_recipe_id ON recipes_of_the_day (recipe_id);

;
CREATE UNIQUE INDEX recipes_of_the_day_recipe_id_day ON recipes_of_the_day (recipe_id, day);

;

COMMIT;

