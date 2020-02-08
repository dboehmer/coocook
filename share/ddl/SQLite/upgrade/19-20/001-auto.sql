-- Convert schema 'share/ddl/_source/deploy/19/001-auto.yml' to 'share/ddl/_source/deploy/20/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "groups" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "name" text NOT NULL,
  "name_fc" text NOT NULL,
  "owner" int NOT NULL,
  "description_md" text NOT NULL,
  "display_name" text NOT NULL,
  "admin_comment" text NOT NULL DEFAULT '',
  "created" datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("owner") REFERENCES "users"("id")
);

;
CREATE INDEX "groups_idx_owner" ON "groups" ("owner");

;
CREATE UNIQUE INDEX "groups_name" ON "groups" ("name");

;
CREATE UNIQUE INDEX "groups_name_fc" ON "groups" ("name_fc");

;
CREATE TABLE "groups_projects" (
  "group" int NOT NULL,
  "project" int NOT NULL,
  "role" text NOT NULL,
  PRIMARY KEY ("group", "project"),
  FOREIGN KEY ("group") REFERENCES "groups"("id") ON DELETE CASCADE,
  FOREIGN KEY ("project") REFERENCES "projects"("id") ON DELETE CASCADE
);

;
CREATE INDEX "groups_projects_idx_group" ON "groups_projects" ("group");

;
CREATE INDEX "groups_projects_idx_project" ON "groups_projects" ("project");

;
CREATE TABLE "groups_users" (
  "group" int NOT NULL,
  "user" int NOT NULL,
  "role" text NOT NULL,
  PRIMARY KEY ("group", "user"),
  FOREIGN KEY ("group") REFERENCES "groups"("id") ON DELETE CASCADE,
  FOREIGN KEY ("user") REFERENCES "users"("id") ON DELETE CASCADE
);

;
CREATE INDEX "groups_users_idx_group" ON "groups_users" ("group");

;
CREATE INDEX "groups_users_idx_user" ON "groups_users" ("user");

;

COMMIT;

