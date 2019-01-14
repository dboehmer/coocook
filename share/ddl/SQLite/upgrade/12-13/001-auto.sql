-- Convert schema 'share/ddl/_source/deploy/12/001-auto.yml' to 'share/ddl/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;

;

;

;

;

;

;
DROP INDEX dish_ingredients_fk_unit;

;

;

;

;
DROP INDEX dishes_fk_prepare_at_meal;

;

;
DROP INDEX items_fk_article;

;
DROP INDEX items_fk_article_unit;

;
DROP INDEX items_fk_unit;

;

;

;

;
DROP INDEX projects_fk_owner;

;

;
DROP INDEX recipe_ingredients_fk_article;

;
DROP INDEX recipe_ingredients_fk_article_unit;

;
DROP INDEX recipe_ingredients_fk_recipe;

;
DROP INDEX recipe_ingredients_fk_unit;

;

;

;

;

;
DROP INDEX terms_users_fk_terms;

;
DROP INDEX terms_users_fk_user;

;

;

;

COMMIT;

