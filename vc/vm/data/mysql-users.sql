create database drupal;
create user 'drupal'@'localhost' identified by 'drupal';
grant usage on *.* to 'drupal'@'localhost';
grant all privileges on `drupal`.* to 'drupal'@'localhost';
grant all privileges on `drupal`.* to ''@'localhost';

-- This is for VividCortex. We need to set these credentials in the UI.
-- See https://docs.vividcortex.com/getting-started/privileges/.
create user 'vividcortex'@'localhost' identified by 'vckey';
grant select, process, replication client on *.* to 'vividcortex'@'localhost';
