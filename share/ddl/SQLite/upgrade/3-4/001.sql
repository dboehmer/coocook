-- Convert schema 'share/ddl/_source/deploy/3/001-auto.yml' to 'share/ddl/_source/deploy/4/001-auto.yml':;

BEGIN;

CREATE TEMPORARY TABLE dish_ingredients_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  dish int NOT NULL,
  prepare bool NOT NULL,
  article int NOT NULL,
  unit int NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (article) REFERENCES articles(id),
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (dish) REFERENCES dishes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id)
);

INSERT INTO dish_ingredients_temp_alter SELECT id, id, dish, prepare, article, unit, value, comment FROM dish_ingredients;

DROP TABLE dish_ingredients;

CREATE TABLE dish_ingredients (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  dish int NOT NULL,
  prepare bool NOT NULL,
  article int NOT NULL,
  unit int NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (article) REFERENCES articles(id),
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (dish) REFERENCES dishes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id)
);

CREATE INDEX dish_ingredients_idx_article02 ON dish_ingredients (article);

CREATE INDEX dish_ingredients_idx_articl00 ON dish_ingredients (article, unit);

CREATE INDEX dish_ingredients_idx_dish02 ON dish_ingredients (dish);

CREATE INDEX dish_ingredients_idx_unit02 ON dish_ingredients (unit);

INSERT INTO dish_ingredients SELECT id, position, dish, prepare, article, unit, value, comment FROM dish_ingredients_temp_alter;

DROP TABLE dish_ingredients_temp_alter;

CREATE TEMPORARY TABLE recipe_ingredients_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  recipe int NOT NULL,
  prepare bool NOT NULL,
  article int NOT NULL,
  unit int NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (article) REFERENCES articles(id),
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (recipe) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id)
);

INSERT INTO recipe_ingredients_temp_alter SELECT id, id, recipe, prepare, article, unit, value, comment FROM recipe_ingredients;

DROP TABLE recipe_ingredients;

CREATE TABLE recipe_ingredients (
  id INTEGER PRIMARY KEY NOT NULL,
  position int NOT NULL DEFAULT 1,
  recipe int NOT NULL,
  prepare bool NOT NULL,
  article int NOT NULL,
  unit int NOT NULL,
  value real NOT NULL,
  comment text NOT NULL,
  FOREIGN KEY (article) REFERENCES articles(id),
  FOREIGN KEY (article, unit) REFERENCES articles_units(article, unit) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (recipe) REFERENCES recipes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (unit) REFERENCES units(id)
);

CREATE INDEX recipe_ingredients_idx_arti00 ON recipe_ingredients (article);

CREATE INDEX recipe_ingredients_idx_arti01 ON recipe_ingredients (article, unit); -- manually set 01

CREATE INDEX recipe_ingredients_idx_reci00 ON recipe_ingredients (recipe);

CREATE INDEX recipe_ingredients_idx_unit02 ON recipe_ingredients (unit);

INSERT INTO recipe_ingredients SELECT id, position, recipe, prepare, article, unit, value, comment FROM recipe_ingredients_temp_alter;

DROP TABLE recipe_ingredients_temp_alter;

COMMIT;
