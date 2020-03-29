INSERT INTO articles SELECT * FROM articles_old;
DROP TABLE articles_old;

INSERT INTO articles_tags SELECT * FROM articles_tags_old;
DROP TABLE articles_tags_old;

INSERT INTO articles_units SELECT * FROM articles_units_old;
DROP TABLE articles_units_old;

INSERT INTO blacklist_emails SELECT * FROM blacklist_emails_old;
DROP TABLE blacklist_emails_old;

INSERT INTO blacklist_usernames SELECT * FROM blacklist_usernames_old;
DROP TABLE blacklist_usernames_old;

INSERT INTO dbix_class_deploymenthandler_versions SELECT * FROM dbix_class_deploymenthandler_versions_old;
DROP TABLE dbix_class_deploymenthandler_versions_old;

INSERT INTO dishes SELECT * FROM dishes_old;
DROP TABLE dishes_old;

INSERT INTO dishes_tags SELECT * FROM dishes_tags_old;
DROP TABLE dishes_tags_old;

INSERT INTO dish_ingredients SELECT * FROM dish_ingredients_old;
DROP TABLE dish_ingredients_old;

INSERT INTO faqs SELECT * FROM faqs_old;
DROP TABLE faqs_old;

INSERT INTO items SELECT * FROM items_old;
DROP TABLE items_old;

INSERT INTO meals SELECT * FROM meals_old;
DROP TABLE meals_old;

INSERT INTO organizations SELECT * FROM organizations_old;

    INSERT INTO organizations_projects SELECT * FROM organizations_projects_old;
    DROP TABLE organizations_projects_old;

    INSERT INTO organizations_users SELECT * FROM organizations_users_old;
    DROP TABLE organizations_users_old;

DROP TABLE organizations_old;

INSERT INTO projects SELECT * FROM projects_old;
DROP TABLE projects_old;

INSERT INTO projects_users SELECT * FROM projects_users_old;
DROP TABLE projects_users_old;

INSERT INTO purchase_lists SELECT * FROM purchase_lists_old;
DROP TABLE purchase_lists_old;

INSERT INTO quantities SELECT * FROM quantities_old;
DROP TABLE quantities_old;

INSERT INTO recipe_ingredients SELECT * FROM recipe_ingredients_old;
DROP TABLE recipe_ingredients_old;

INSERT INTO recipes SELECT * FROM recipes_old;
DROP TABLE recipes_old;

INSERT INTO recipes_tags SELECT * FROM recipes_tags_old;
DROP TABLE recipes_tags_old;

INSERT INTO roles_users SELECT * FROM roles_users_old;
DROP TABLE roles_users_old;

INSERT INTO sessions SELECT * FROM sessions_old;
DROP TABLE sessions_old;

INSERT INTO shop_sections SELECT * FROM shop_sections_old;
DROP TABLE shop_sections_old;

INSERT INTO tag_groups SELECT * FROM tag_groups_old;
DROP TABLE tag_groups_old;

INSERT INTO tags SELECT * FROM tags_old;
DROP TABLE tags_old;

INSERT INTO terms SELECT * FROM terms_old;
DROP TABLE terms_old;

INSERT INTO terms_users SELECT * FROM terms_users_old;
DROP TABLE terms_users_old;

INSERT INTO units SELECT * FROM units_old;
DROP TABLE units_old;

INSERT INTO users SELECT * FROM users_old;
DROP TABLE users_old;
