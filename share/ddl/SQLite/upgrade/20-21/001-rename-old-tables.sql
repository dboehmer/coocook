DROP INDEX articles_project_name;
DROP INDEX blacklist_emails_email_fc;
DROP INDEX blacklist_usernames_username_fc;
DROP INDEX dbix_class_deploymenthandler_versions_version;
DROP INDEX faqs_anchor;
DROP INDEX items_purchase_list_article_unit;
DROP INDEX meals_project_date_name;
DROP INDEX organizations_name;
DROP INDEX organizations_name_fc;
DROP INDEX projects_name02;
DROP INDEX projects_url_name02;
DROP INDEX projects_url_name_fc02;
DROP INDEX purchase_lists_project_name;
DROP INDEX quantities_project_name;
DROP INDEX recipes_project_name;
DROP INDEX shop_sections_project_name;
DROP INDEX tag_groups_project_name;
DROP INDEX tags_project_name;
DROP INDEX terms_valid_from;
DROP INDEX units_project_long_name;
DROP INDEX users_email_fc;
DROP INDEX users_name;
DROP INDEX users_name_fc;
DROP INDEX users_password_hash;
DROP INDEX users_token_hash;

ALTER TABLE articles RENAME TO articles_old;
ALTER TABLE articles_tags RENAME TO articles_tags_old;
ALTER TABLE articles_units RENAME TO articles_units_old;
ALTER TABLE blacklist_emails RENAME TO blacklist_emails_old;
ALTER TABLE blacklist_usernames RENAME TO blacklist_usernames_old;
ALTER TABLE dbix_class_deploymenthandler_versions RENAME TO dbix_class_deploymenthandler_versions_old;
ALTER TABLE dishes RENAME TO dishes_old;
ALTER TABLE dishes_tags RENAME TO dishes_tags_old;
ALTER TABLE dish_ingredients RENAME TO dish_ingredients_old;
ALTER TABLE faqs RENAME TO faqs_old;
ALTER TABLE items RENAME TO items_old;
ALTER TABLE meals RENAME TO meals_old;
ALTER TABLE organizations RENAME TO organizations_old;
ALTER TABLE organizations_projects RENAME TO organizations_projects_old;
ALTER TABLE organizations_users RENAME TO organizations_users_old;
ALTER TABLE projects RENAME TO projects_old;
ALTER TABLE projects_users RENAME TO projects_users_old;
ALTER TABLE purchase_lists RENAME TO purchase_lists_old;
ALTER TABLE quantities RENAME TO quantities_old;
ALTER TABLE recipe_ingredients RENAME TO recipe_ingredients_old;
ALTER TABLE recipes RENAME TO recipes_old;
ALTER TABLE recipes_tags RENAME TO recipes_tags_old;
ALTER TABLE roles_users RENAME TO roles_users_old;
ALTER TABLE sessions RENAME TO sessions_old;
ALTER TABLE shop_sections RENAME TO shop_sections_old;
ALTER TABLE tag_groups RENAME TO tag_groups_old;
ALTER TABLE tags RENAME TO tags_old;
ALTER TABLE terms RENAME TO terms_old;
ALTER TABLE terms_users RENAME TO terms_users_old;
ALTER TABLE units RENAME TO units_old;
ALTER TABLE users RENAME TO users_old;