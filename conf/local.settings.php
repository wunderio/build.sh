<?php
/**
 * EXAMPLE SETTINGS FOR LOCAL ENVIRONMENT
 */

// DATABASE

$db_filename = dirname(__FILE__);
$db_filename = explode("/", $db_filename);
array_pop($db_filename);
$db_filename = implode('/', $db_filename) . '/drupal.sqlite';

$databases['default']['default'] = [
  'driver' => 'sqlite',
  'prefix' => '',
  'namespace' => 'Drupal\\Core\\Database\\Driver\\sqlite',
  'database' => $db_filename,
];

ini_set('memory_limit','1024M');

$conf['drupal_http_request_fails'] = FALSE;

$settings['install_profile'] = 'config_installer';
$config_directories['sync'] = DRUPAL_ROOT . '/../config/sync';
$settings['hash_salt'] = '_Yfo_5ZbqO2oOOrypjh7QlMMmnpkeA2_Egvdn09ZTAa3ajv19494SKvJ06NZcsdb_2piGYqqGA';
