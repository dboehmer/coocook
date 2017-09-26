-- Convert schema 'share/ddl/_source/deploy/6/001-auto.yml' to 'share/ddl/_source/deploy/7/001-auto.yml':;

BEGIN;

CREATE UNIQUE INDEX assure_no_multiple_ingredients ON ingredients_items(ingredient);

ALTER TABLE dish_ingredients ADD COLUMN item int;

UPDATE dish_ingredients
SET item = (
    SELECT item
    FROM ingredients_items
    WHERE ingredient = dish_ingredients.id
    LIMIT 1
);

DROP TABLE ingredients_items;

COMMIT;

