<?php
/**
 * Local settings for Local environment only.
 * This should be overridden in staging and production environments.
 */

$databases['default']['default'] = array (
  'database' => '',
  'username' => '',
  'password' => '',
  'prefix' => '',
  'host' => 'localhost',
  'port' => '3306',
  'namespace' => 'Drupal\\Core\\Database\\Driver\\mysql',
  'driver' => 'mysql',
);

// CHANGE THIS.
$settings['hash_salt'] = 'some-hash-salt-please-change-this';

/*
 * Set configuration directy
 */
$config_directories['sync'] = '../staging';
