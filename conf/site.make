; Example Drush Make File
; ----------------

core = 7.0
api = 2

projects[drupal][type] = core
projects[drupal][version] = 7.32

; PATCH: user_save might on occasion delete images from users
projects[drupal][patch][935592] = https://www.drupal.org/files/issues/935592-89.patch

defaults[projects][subdir] = "contrib"

; Contrib
; ----------------

projects[admin_views][version] = 1.3
projects[ctools][version] = 1.4
projects[devel][version] = 1.5 
projects[entity][version] = 1.5
projects[entity_translation][version] = 1.0-beta3
projects[field_collection][version] = 1.0-beta7
projects[memcache][version] = 1.2
projects[pathologic][version] = 2.12
projects[rules][version] = 2.7
projects[search_api][version] = 1.13
projects[search_api_solr][version] = 1.6
projects[varnish][version] = 1.0-beta3
projects[views][version] = 1.2
projects[views][version] = 3.8
projects[views_bulk_operations][version] = 3.2
projects[webform][version] = 4.1

