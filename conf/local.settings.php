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
  'database' => $db_filename,
);

ini_set('memory_limit','1024M');
