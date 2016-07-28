<?php

/**
 * General settings.php for all environments.
 * You could use this to add general settings to be used for all environments.
 */

/**
 * Database settings (overridden per environment)
 */
$databases = array();

/**
 * Location of the site configuration files (overridden per environment).
 */
$config_directories = array();

/**
 * Salt for one-time login links, cancel links, form tokens, etc.
 *
 * Add the hash salt in local.settings.php
 */
# $settings['hash_salt'] = 'change-this-to-something-else';

/**
 * Access control for update.php script.
 */
$settings['update_free_access'] = FALSE;

/**
 * Load services definition file.
 */
$settings['container_yamls'][] = __DIR__ . '/services.yml';

/**
 * Environment specific override configuration, if available.
 */
if (file_exists(__DIR__ . '/settings.local.php')) {
   include __DIR__ . '/settings.local.php';
}
