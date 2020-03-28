--
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Tue Dec 29 09:30:31 2020
--
;
--
-- Table: blacklist_emails
--
CREATE TABLE "blacklist_emails" (
  "id" serial NOT NULL,
  "email_fc" text NOT NULL,
  "email_type" text DEFAULT 'cleartext' NOT NULL,
  "comment" text NOT NULL,
  "created" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "blacklist_emails_email_fc" UNIQUE ("email_fc")
);

;
--
-- Table: blacklist_usernames
--
CREATE TABLE "blacklist_usernames" (
  "id" serial NOT NULL,
  "username_fc" text NOT NULL,
  "username_type" text DEFAULT 'cleartext' NOT NULL,
  "comment" text NOT NULL,
  "created" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "blacklist_usernames_username_fc" UNIQUE ("username_fc")
);

;
--
-- Table: faqs
--
CREATE TABLE "faqs" (
  "id" serial NOT NULL,
  "position" integer DEFAULT 1 NOT NULL,
  "anchor" text NOT NULL,
  "question_md" text NOT NULL,
  "answer_md" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "faqs_anchor" UNIQUE ("anchor")
);

;
--
-- Table: sessions
--
CREATE TABLE "sessions" (
  "id" text NOT NULL,
  "expires" integer,
  "session_data" text,
  PRIMARY KEY ("id")
);

;
--
-- Table: terms
--
CREATE TABLE "terms" (
  "id" serial NOT NULL,
  "valid_from" date NOT NULL,
  "content_md" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "terms_valid_from" UNIQUE ("valid_from")
);

;
--
-- Table: users
--
CREATE TABLE "users" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "name_fc" text NOT NULL,
  "password_hash" text NOT NULL,
  "display_name" text NOT NULL,
  "admin_comment" text DEFAULT '' NOT NULL,
  "email_fc" text NOT NULL,
  "email_verified" timestamp without time zone,
  "token_hash" text,
  "token_expires" timestamp without time zone,
  "created" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "users_email_fc" UNIQUE ("email_fc"),
  CONSTRAINT "users_name" UNIQUE ("name"),
  CONSTRAINT "users_name_fc" UNIQUE ("name_fc"),
  CONSTRAINT "users_password_hash" UNIQUE ("password_hash"),
  CONSTRAINT "users_token_hash" UNIQUE ("token_hash")
);

;
--
-- Table: organizations
--
CREATE TABLE "organizations" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "name_fc" text NOT NULL,
  "owner_id" integer NOT NULL,
  "description_md" text NOT NULL,
  "display_name" text NOT NULL,
  "admin_comment" text DEFAULT '' NOT NULL,
  "created" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "organizations_name" UNIQUE ("name"),
  CONSTRAINT "organizations_name_fc" UNIQUE ("name_fc")
);
CREATE INDEX "organizations_idx_owner_id" on "organizations" ("owner_id");

;
--
-- Table: projects
--
CREATE TABLE "projects" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "url_name" text NOT NULL,
  "url_name_fc" text NOT NULL,
  "description" text NOT NULL,
  "is_public" boolean DEFAULT '1' NOT NULL,
  "owner_id" integer NOT NULL,
  "created" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "archived" timestamp without time zone,
  PRIMARY KEY ("id"),
  CONSTRAINT "projects_name" UNIQUE ("name"),
  CONSTRAINT "projects_url_name" UNIQUE ("url_name"),
  CONSTRAINT "projects_url_name_fc" UNIQUE ("url_name_fc")
);
CREATE INDEX "projects_idx_owner_id" on "projects" ("owner_id");

;
--
-- Table: roles_users
--
CREATE TABLE "roles_users" (
  "role" text NOT NULL,
  "user_id" integer NOT NULL,
  PRIMARY KEY ("role", "user_id")
);
CREATE INDEX "roles_users_idx_user_id" on "roles_users" ("user_id");

;
--
-- Table: meals
--
CREATE TABLE "meals" (
  "id" serial NOT NULL,
  "project_id" integer NOT NULL,
  "date" date NOT NULL,
  "name" text NOT NULL,
  "comment" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "meals_project_id_date_name" UNIQUE ("project_id", "date", "name")
);
CREATE INDEX "meals_idx_project_id" on "meals" ("project_id");

;
--
-- Table: organizations_users
--
CREATE TABLE "organizations_users" (
  "organization_id" integer NOT NULL,
  "user_id" integer NOT NULL,
  "role" text NOT NULL,
  PRIMARY KEY ("organization_id", "user_id")
);
CREATE INDEX "organizations_users_idx_organization_id" on "organizations_users" ("organization_id");
CREATE INDEX "organizations_users_idx_user_id" on "organizations_users" ("user_id");

;
--
-- Table: projects_users
--
CREATE TABLE "projects_users" (
  "project_id" integer NOT NULL,
  "user_id" integer NOT NULL,
  "role" text NOT NULL,
  PRIMARY KEY ("project_id", "user_id")
);
CREATE INDEX "projects_users_idx_project_id" on "projects_users" ("project_id");
CREATE INDEX "projects_users_idx_user_id" on "projects_users" ("user_id");

;
--
-- Table: purchase_lists
--
CREATE TABLE "purchase_lists" (
  "id" serial NOT NULL,
  "project_id" integer NOT NULL,
  "name" text NOT NULL,
  "date" date NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "purchase_lists_project_id_name" UNIQUE ("project_id", "name")
);
CREATE INDEX "purchase_lists_idx_project_id" on "purchase_lists" ("project_id");

;
--
-- Table: recipes
--
CREATE TABLE "recipes" (
  "id" serial NOT NULL,
  "project_id" integer NOT NULL,
  "name" text NOT NULL,
  "preparation" text NOT NULL,
  "description" text NOT NULL,
  "servings" integer NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "recipes_project_id_name" UNIQUE ("project_id", "name")
);
CREATE INDEX "recipes_idx_project_id" on "recipes" ("project_id");

;
--
-- Table: shop_sections
--
CREATE TABLE "shop_sections" (
  "id" serial NOT NULL,
  "project_id" integer NOT NULL,
  "name" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "shop_sections_project_id_name" UNIQUE ("project_id", "name")
);
CREATE INDEX "shop_sections_idx_project_id" on "shop_sections" ("project_id");

;
--
-- Table: tag_groups
--
CREATE TABLE "tag_groups" (
  "id" serial NOT NULL,
  "project_id" integer NOT NULL,
  "color" integer,
  "name" text NOT NULL,
  "comment" text DEFAULT '' NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "tag_groups_project_id_name" UNIQUE ("project_id", "name")
);
CREATE INDEX "tag_groups_idx_project_id" on "tag_groups" ("project_id");

;
--
-- Table: terms_users
--
CREATE TABLE "terms_users" (
  "terms_id" integer NOT NULL,
  "user_id" integer NOT NULL,
  "approved" timestamp without time zone NOT NULL,
  PRIMARY KEY ("terms_id", "user_id")
);
CREATE INDEX "terms_users_idx_terms_id" on "terms_users" ("terms_id");
CREATE INDEX "terms_users_idx_user_id" on "terms_users" ("user_id");

;
--
-- Table: articles
--
CREATE TABLE "articles" (
  "id" serial NOT NULL,
  "project_id" integer NOT NULL,
  "shop_section_id" integer,
  "shelf_life_days" integer,
  "preorder_servings" integer,
  "preorder_workdays" integer,
  "name" text NOT NULL,
  "comment" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "articles_project_id_name" UNIQUE ("project_id", "name")
);
CREATE INDEX "articles_idx_project_id" on "articles" ("project_id");
CREATE INDEX "articles_idx_shop_section_id" on "articles" ("shop_section_id");

;
--
-- Table: organizations_projects
--
CREATE TABLE "organizations_projects" (
  "organization_id" integer NOT NULL,
  "project_id" integer NOT NULL,
  "role" text NOT NULL,
  PRIMARY KEY ("organization_id", "project_id")
);
CREATE INDEX "organizations_projects_idx_organization_id" on "organizations_projects" ("organization_id");
CREATE INDEX "organizations_projects_idx_project_id" on "organizations_projects" ("project_id");

;
--
-- Table: quantities
--
CREATE TABLE "quantities" (
  "id" serial NOT NULL,
  "project_id" integer NOT NULL,
  "name" text NOT NULL,
  "default_unit_id" integer,
  PRIMARY KEY ("id"),
  CONSTRAINT "quantities_project_id_name" UNIQUE ("project_id", "name")
);
CREATE INDEX "quantities_idx_default_unit_id" on "quantities" ("default_unit_id");
CREATE INDEX "quantities_idx_project_id" on "quantities" ("project_id");

;
--
-- Table: recipes_of_the_day
--
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
--
-- Table: tags
--
CREATE TABLE "tags" (
  "id" serial NOT NULL,
  "project_id" integer NOT NULL,
  "tag_group_id" integer,
  "name" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "tags_project_id_name" UNIQUE ("project_id", "name")
);
CREATE INDEX "tags_idx_project_id" on "tags" ("project_id");
CREATE INDEX "tags_idx_tag_group_id" on "tags" ("tag_group_id");

;
--
-- Table: units
--
CREATE TABLE "units" (
  "id" serial NOT NULL,
  "project_id" integer NOT NULL,
  "quantity_id" integer NOT NULL,
  "to_quantity_default" real,
  "space" boolean NOT NULL,
  "short_name" text NOT NULL,
  "long_name" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "units_project_id_long_name" UNIQUE ("project_id", "long_name")
);
CREATE INDEX "units_idx_project_id" on "units" ("project_id");
CREATE INDEX "units_idx_quantity_id" on "units" ("quantity_id");

;
--
-- Table: dishes
--
CREATE TABLE "dishes" (
  "id" serial NOT NULL,
  "meal_id" integer NOT NULL,
  "from_recipe_id" integer,
  "name" text NOT NULL,
  "servings" integer NOT NULL,
  "prepare_at_meal_id" integer,
  "preparation" text NOT NULL,
  "description" text NOT NULL,
  "comment" text NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "dishes_idx_meal_id" on "dishes" ("meal_id");
CREATE INDEX "dishes_idx_prepare_at_meal_id" on "dishes" ("prepare_at_meal_id");
CREATE INDEX "dishes_idx_from_recipe_id" on "dishes" ("from_recipe_id");

;
--
-- Table: recipes_tags
--
CREATE TABLE "recipes_tags" (
  "recipe_id" integer NOT NULL,
  "tag_id" integer NOT NULL,
  PRIMARY KEY ("recipe_id", "tag_id")
);
CREATE INDEX "recipes_tags_idx_recipe_id" on "recipes_tags" ("recipe_id");
CREATE INDEX "recipes_tags_idx_tag_id" on "recipes_tags" ("tag_id");

;
--
-- Table: articles_tags
--
CREATE TABLE "articles_tags" (
  "article_id" integer NOT NULL,
  "tag_id" integer NOT NULL,
  PRIMARY KEY ("article_id", "tag_id")
);
CREATE INDEX "articles_tags_idx_article_id" on "articles_tags" ("article_id");
CREATE INDEX "articles_tags_idx_tag_id" on "articles_tags" ("tag_id");

;
--
-- Table: articles_units
--
CREATE TABLE "articles_units" (
  "article_id" integer NOT NULL,
  "unit_id" integer NOT NULL,
  PRIMARY KEY ("article_id", "unit_id")
);
CREATE INDEX "articles_units_idx_article_id" on "articles_units" ("article_id");
CREATE INDEX "articles_units_idx_unit_id" on "articles_units" ("unit_id");

;
--
-- Table: dishes_tags
--
CREATE TABLE "dishes_tags" (
  "dish_id" integer NOT NULL,
  "tag_id" integer NOT NULL,
  PRIMARY KEY ("dish_id", "tag_id")
);
CREATE INDEX "dishes_tags_idx_dish_id" on "dishes_tags" ("dish_id");
CREATE INDEX "dishes_tags_idx_tag_id" on "dishes_tags" ("tag_id");

;
--
-- Table: items
--
CREATE TABLE "items" (
  "id" serial NOT NULL,
  "purchase_list_id" integer NOT NULL,
  "value" real NOT NULL,
  "offset" real DEFAULT 0 NOT NULL,
  "unit_id" integer NOT NULL,
  "article_id" integer NOT NULL,
  "purchased" boolean DEFAULT '0' NOT NULL,
  "comment" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "items_purchase_list_id_article_id_unit_id" UNIQUE ("purchase_list_id", "article_id", "unit_id")
);
CREATE INDEX "items_idx_article_id" on "items" ("article_id");
CREATE INDEX "items_idx_article_id_unit_id" on "items" ("article_id", "unit_id");
CREATE INDEX "items_idx_purchase_list_id" on "items" ("purchase_list_id");
CREATE INDEX "items_idx_unit_id" on "items" ("unit_id");

;
--
-- Table: recipe_ingredients
--
CREATE TABLE "recipe_ingredients" (
  "id" serial NOT NULL,
  "position" integer DEFAULT 1 NOT NULL,
  "recipe_id" integer NOT NULL,
  "prepare" boolean NOT NULL,
  "article_id" integer NOT NULL,
  "unit_id" integer NOT NULL,
  "value" real NOT NULL,
  "comment" text NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "recipe_ingredients_idx_article_id" on "recipe_ingredients" ("article_id");
CREATE INDEX "recipe_ingredients_idx_article_id_unit_id" on "recipe_ingredients" ("article_id", "unit_id");
CREATE INDEX "recipe_ingredients_idx_recipe_id" on "recipe_ingredients" ("recipe_id");
CREATE INDEX "recipe_ingredients_idx_unit_id" on "recipe_ingredients" ("unit_id");

;
--
-- Table: dish_ingredients
--
CREATE TABLE "dish_ingredients" (
  "id" serial NOT NULL,
  "position" integer DEFAULT 1 NOT NULL,
  "dish_id" integer NOT NULL,
  "prepare" boolean NOT NULL,
  "article_id" integer NOT NULL,
  "unit_id" integer NOT NULL,
  "value" real NOT NULL,
  "comment" text NOT NULL,
  "item_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "dish_ingredients_idx_article_id" on "dish_ingredients" ("article_id");
CREATE INDEX "dish_ingredients_idx_article_id_unit_id" on "dish_ingredients" ("article_id", "unit_id");
CREATE INDEX "dish_ingredients_idx_dish_id" on "dish_ingredients" ("dish_id");
CREATE INDEX "dish_ingredients_idx_item_id" on "dish_ingredients" ("item_id");
CREATE INDEX "dish_ingredients_idx_unit_id" on "dish_ingredients" ("unit_id");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "organizations" ADD CONSTRAINT "organizations_fk_owner_id" FOREIGN KEY ("owner_id")
  REFERENCES "users" ("id") DEFERRABLE;

;
ALTER TABLE "projects" ADD CONSTRAINT "projects_fk_owner_id" FOREIGN KEY ("owner_id")
  REFERENCES "users" ("id") DEFERRABLE;

;
ALTER TABLE "roles_users" ADD CONSTRAINT "roles_users_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "meals" ADD CONSTRAINT "meals_fk_project_id" FOREIGN KEY ("project_id")
  REFERENCES "projects" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "organizations_users" ADD CONSTRAINT "organizations_users_fk_organization_id" FOREIGN KEY ("organization_id")
  REFERENCES "organizations" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "organizations_users" ADD CONSTRAINT "organizations_users_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "projects_users" ADD CONSTRAINT "projects_users_fk_project_id" FOREIGN KEY ("project_id")
  REFERENCES "projects" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "projects_users" ADD CONSTRAINT "projects_users_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "purchase_lists" ADD CONSTRAINT "purchase_lists_fk_project_id" FOREIGN KEY ("project_id")
  REFERENCES "projects" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "recipes" ADD CONSTRAINT "recipes_fk_project_id" FOREIGN KEY ("project_id")
  REFERENCES "projects" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "shop_sections" ADD CONSTRAINT "shop_sections_fk_project_id" FOREIGN KEY ("project_id")
  REFERENCES "projects" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "tag_groups" ADD CONSTRAINT "tag_groups_fk_project_id" FOREIGN KEY ("project_id")
  REFERENCES "projects" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "terms_users" ADD CONSTRAINT "terms_users_fk_terms_id" FOREIGN KEY ("terms_id")
  REFERENCES "terms" ("id") DEFERRABLE;

;
ALTER TABLE "terms_users" ADD CONSTRAINT "terms_users_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "articles" ADD CONSTRAINT "articles_fk_project_id" FOREIGN KEY ("project_id")
  REFERENCES "projects" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "articles" ADD CONSTRAINT "articles_fk_shop_section_id" FOREIGN KEY ("shop_section_id")
  REFERENCES "shop_sections" ("id") DEFERRABLE;

;
ALTER TABLE "organizations_projects" ADD CONSTRAINT "organizations_projects_fk_organization_id" FOREIGN KEY ("organization_id")
  REFERENCES "organizations" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "organizations_projects" ADD CONSTRAINT "organizations_projects_fk_project_id" FOREIGN KEY ("project_id")
  REFERENCES "projects" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "quantities" ADD CONSTRAINT "quantities_fk_default_unit_id" FOREIGN KEY ("default_unit_id")
  REFERENCES "units" ("id") DEFERRABLE;

;
ALTER TABLE "quantities" ADD CONSTRAINT "quantities_fk_project_id" FOREIGN KEY ("project_id")
  REFERENCES "projects" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "recipes_of_the_day" ADD CONSTRAINT "recipes_of_the_day_fk_recipe_id" FOREIGN KEY ("recipe_id")
  REFERENCES "recipes" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "tags" ADD CONSTRAINT "tags_fk_project_id" FOREIGN KEY ("project_id")
  REFERENCES "projects" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "tags" ADD CONSTRAINT "tags_fk_tag_group_id" FOREIGN KEY ("tag_group_id")
  REFERENCES "tag_groups" ("id") DEFERRABLE;

;
ALTER TABLE "units" ADD CONSTRAINT "units_fk_project_id" FOREIGN KEY ("project_id")
  REFERENCES "projects" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "units" ADD CONSTRAINT "units_fk_quantity_id" FOREIGN KEY ("quantity_id")
  REFERENCES "quantities" ("id") DEFERRABLE;

;
ALTER TABLE "dishes" ADD CONSTRAINT "dishes_fk_meal_id" FOREIGN KEY ("meal_id")
  REFERENCES "meals" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "dishes" ADD CONSTRAINT "dishes_fk_prepare_at_meal_id" FOREIGN KEY ("prepare_at_meal_id")
  REFERENCES "meals" ("id") DEFERRABLE;

;
ALTER TABLE "dishes" ADD CONSTRAINT "dishes_fk_from_recipe_id" FOREIGN KEY ("from_recipe_id")
  REFERENCES "recipes" ("id") DEFERRABLE;

;
ALTER TABLE "recipes_tags" ADD CONSTRAINT "recipes_tags_fk_recipe_id" FOREIGN KEY ("recipe_id")
  REFERENCES "recipes" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "recipes_tags" ADD CONSTRAINT "recipes_tags_fk_tag_id" FOREIGN KEY ("tag_id")
  REFERENCES "tags" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "articles_tags" ADD CONSTRAINT "articles_tags_fk_article_id" FOREIGN KEY ("article_id")
  REFERENCES "articles" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "articles_tags" ADD CONSTRAINT "articles_tags_fk_tag_id" FOREIGN KEY ("tag_id")
  REFERENCES "tags" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "articles_units" ADD CONSTRAINT "articles_units_fk_article_id" FOREIGN KEY ("article_id")
  REFERENCES "articles" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "articles_units" ADD CONSTRAINT "articles_units_fk_unit_id" FOREIGN KEY ("unit_id")
  REFERENCES "units" ("id") DEFERRABLE;

;
ALTER TABLE "dishes_tags" ADD CONSTRAINT "dishes_tags_fk_dish_id" FOREIGN KEY ("dish_id")
  REFERENCES "dishes" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "dishes_tags" ADD CONSTRAINT "dishes_tags_fk_tag_id" FOREIGN KEY ("tag_id")
  REFERENCES "tags" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "items" ADD CONSTRAINT "items_fk_article_id" FOREIGN KEY ("article_id")
  REFERENCES "articles" ("id") DEFERRABLE;

;
ALTER TABLE "items" ADD CONSTRAINT "items_fk_article_id_unit_id" FOREIGN KEY ("article_id", "unit_id")
  REFERENCES "articles_units" ("article_id", "unit_id") DEFERRABLE;

;
ALTER TABLE "items" ADD CONSTRAINT "items_fk_purchase_list_id" FOREIGN KEY ("purchase_list_id")
  REFERENCES "purchase_lists" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "items" ADD CONSTRAINT "items_fk_unit_id" FOREIGN KEY ("unit_id")
  REFERENCES "units" ("id") DEFERRABLE;

;
ALTER TABLE "recipe_ingredients" ADD CONSTRAINT "recipe_ingredients_fk_article_id" FOREIGN KEY ("article_id")
  REFERENCES "articles" ("id") DEFERRABLE;

;
ALTER TABLE "recipe_ingredients" ADD CONSTRAINT "recipe_ingredients_fk_article_id_unit_id" FOREIGN KEY ("article_id", "unit_id")
  REFERENCES "articles_units" ("article_id", "unit_id") DEFERRABLE;

;
ALTER TABLE "recipe_ingredients" ADD CONSTRAINT "recipe_ingredients_fk_recipe_id" FOREIGN KEY ("recipe_id")
  REFERENCES "recipes" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "recipe_ingredients" ADD CONSTRAINT "recipe_ingredients_fk_unit_id" FOREIGN KEY ("unit_id")
  REFERENCES "units" ("id") DEFERRABLE;

;
ALTER TABLE "dish_ingredients" ADD CONSTRAINT "dish_ingredients_fk_article_id" FOREIGN KEY ("article_id")
  REFERENCES "articles" ("id") DEFERRABLE;

;
ALTER TABLE "dish_ingredients" ADD CONSTRAINT "dish_ingredients_fk_article_id_unit_id" FOREIGN KEY ("article_id", "unit_id")
  REFERENCES "articles_units" ("article_id", "unit_id") DEFERRABLE;

;
ALTER TABLE "dish_ingredients" ADD CONSTRAINT "dish_ingredients_fk_dish_id" FOREIGN KEY ("dish_id")
  REFERENCES "dishes" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "dish_ingredients" ADD CONSTRAINT "dish_ingredients_fk_item_id" FOREIGN KEY ("item_id")
  REFERENCES "items" ("id") ON DELETE SET NULL DEFERRABLE;

;
ALTER TABLE "dish_ingredients" ADD CONSTRAINT "dish_ingredients_fk_unit_id" FOREIGN KEY ("unit_id")
  REFERENCES "units" ("id") DEFERRABLE;

;
