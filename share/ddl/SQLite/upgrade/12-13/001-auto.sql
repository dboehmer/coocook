-- Convert schema 'share/ddl/_source/deploy/12/001-auto.yml' to 'share/ddl/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
DROP INDEX recipe_ingredients_fk_recipe;

;

;
DROP INDEX terms_users_fk_user;

;

;

COMMIT;

