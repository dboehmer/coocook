-- Convert schema 'share/ddl/_source/deploy/1/001-auto.yml' to 'share/ddl/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE units_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  quantity int NOT NULL,
  to_quantity_default real,
  space bool NOT NULL,
  short_name text NOT NULL,
  long_name text NOT NULL,
  FOREIGN KEY (quantity) REFERENCES quantities(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
INSERT INTO units_temp_alter( id, quantity, to_quantity_default, space, short_name, long_name) SELECT id, quantity, to_quantity_default, space, short_name, long_name FROM units;

;
DROP TABLE units;

;
CREATE TABLE units (
  id INTEGER PRIMARY KEY NOT NULL,
  quantity int NOT NULL,
  to_quantity_default real,
  space bool NOT NULL,
  short_name text NOT NULL,
  long_name text NOT NULL,
  FOREIGN KEY (quantity) REFERENCES quantities(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX units_idx_quantity02 ON units (quantity);

;
CREATE UNIQUE INDEX units_long_name02 ON units (long_name);

;
INSERT INTO units SELECT id, quantity, to_quantity_default, space, short_name, long_name FROM units_temp_alter;

;
DROP TABLE units_temp_alter;

;

COMMIT;

