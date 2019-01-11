-- these columns have datatype REAL NOT NULL
-- but in producation many rows have the empty string ''
-- in these columns

UPDATE   dish_ingredients SET value = 0 WHERE value = '';
UPDATE recipe_ingredients SET value = 0 WHERE value = '';
UPDATE items              SET value = 0 WHERE value = '';
