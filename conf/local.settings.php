<?php
/**
 * EXAMPLE SETTINGS FOR LOCAL ENVIRONMENT
 */

// DATABASE

$db_filename = dirname(__FILE__);
$db_filename = explode("/", $db_filename);
array_pop($db_filename);
$db_filename = implode('/', $db_filename) . '/drupal.sqlite';

$databases['default']['default'] = array(
  'driver' => 'sqlite',
  'prefix' => '',
  'namespace' => 'Drupal\\Core\\Database\\Driver\\sqlite',
  'database' => $db_filename,
);

ini_set('memory_limit','1024M');

$conf['drupal_http_request_fails'] = FALSE;

################################################################################
# Site install will inject settings below this line
################################################################################
$databases['default']['default'] = array (
  'database' => '/Users/tcmug/www/build.sh/drupal.sqlite',
  'prefix' => '',
  'namespace' => 'Drupal\\Core\\Database\\Driver\\sqlite',
  'driver' => 'sqlite',
);
$settings['hash_salt'] = '_Yfo_5ZbqO2oOOrypjh7QlMMmnpkeA2_Egvdn09ZTAa3ajv19494SKvJ06NZcsdb_2piGYqqGA';
$settings['install_profile'] = 'wk';
$config_directories['sync'] = 'sites/default/files/config_lJUh5WPtm0SacTKwhSYOhYRInRda6YfXkcC93SP26W_m2UMbC6rfLpq2lX3PEaa9cCgld4DzXA/sync';
