-- Convert schema 'share/ddl/_source/deploy/16/001-auto.yml' to 'share/ddl/_source/deploy/17/001-auto.yml':;

-- rename 'site_admin' to 'site_owner'
UPDATE roles_users
    SET   role = 'site_owner'
    WHERE role = 'site_admin';
