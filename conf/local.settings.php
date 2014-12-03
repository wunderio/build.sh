<?php
/**
 * EXAMPLE SETTINGS FOR LOCAL ENVIRONMENT
 */


// DATABASE

$databases = array (
  'default' => 
  array (
    'default' => 
    array (
      'database' => 'drupal',
      'username' => 'drupal',
      'password' => 'password',
      'host'     => 'localhost',
      'port'     => '',
      'driver'   => 'mysql',
      'prefix'   => '',
    ),
  ),
);

// CACHING
$conf['cache_backends'][] = 'sites/all/modules/contrib/memcache/memcache.inc';
$conf['cache_class_cache_form'] = 'DrupalDatabaseCache';
$conf['cache_default_class'] = 'MemCacheDrupal';
$conf['memcache_key_prefix'] = 'wk';

$conf['cache_backends'][] = 'sites/all/modules/contrib/varnish/varnish.cache.inc';
$conf['cache_class_cache_page']  = 'VarnishCache';

// Varnish
$conf['varnish_version'] = "3";


