-- Convert schema 'share/ddl/_source/deploy/22/001-auto.yml' to 'share/ddl/_source/deploy/23/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "recipes_of_the_day" (
  "id" serial NOT NULL,
  "recipe_id" integer NOT NULL,
  "day" date NOT NULL,
  "admin_comment" text DEFAULT '' NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "recipes_of_the_day_recipe_id_day" UNIQUE ("recipe_id", "day")
);
CREATE INDEX "recipes_of_the_day_idx_recipe_id" on "recipes_of_the_day" ("recipe_id");

;
ALTER TABLE "recipes_of_the_day" ADD CONSTRAINT "recipes_of_the_day_fk_recipe_id" FOREIGN KEY ("recipe_id")
  REFERENCES "recipes" ("id") ON DELETE CASCADE DEFERRABLE;

;

COMMIT;

