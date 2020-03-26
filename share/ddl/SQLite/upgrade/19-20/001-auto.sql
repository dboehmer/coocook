-- Convert schema 'share/ddl/_source/deploy/19/001-auto.yml' to 'share/ddl/_source/deploy/20/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE organizations (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  name_fc text NOT NULL,
  owner int NOT NULL,
  description_md text NOT NULL,
  display_name text NOT NULL,
  admin_comment text NOT NULL DEFAULT '',
  created datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner) REFERENCES users(id)
);

;
CREATE INDEX organizations_idx_owner ON organizations (owner);

;
CREATE UNIQUE INDEX organizations_name ON organizations (name);

;
CREATE UNIQUE INDEX organizations_name_fc ON organizations (name_fc);

;
CREATE TABLE organizations_projects (
  organization int NOT NULL,
  project int NOT NULL,
  role text NOT NULL,
  PRIMARY KEY (organization, project),
  FOREIGN KEY (organization) REFERENCES organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (project) REFERENCES projects(id) ON DELETE CASCADE
);

;
CREATE INDEX organizations_projects_idx_organization ON organizations_projects (organization);

;
CREATE INDEX organizations_projects_idx_project ON organizations_projects (project);

;
CREATE TABLE organizations_users (
  organization int NOT NULL,
  user int NOT NULL,
  role text NOT NULL,
  PRIMARY KEY (organization, user),
  FOREIGN KEY (organization) REFERENCES organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (user) REFERENCES users(id) ON DELETE CASCADE
);

;
CREATE INDEX organizations_users_idx_organization ON organizations_users (organization);

;
CREATE INDEX organizations_users_idx_user ON organizations_users (user);

;

COMMIT;

