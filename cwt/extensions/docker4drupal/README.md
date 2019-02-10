# CWT docker4drupal extension

This extension builds upon the `docker-compose` extension, and :

- provides global environment variables specific to Drupal settings and docker4drupal containers
- implements permissions and ownership hooks
- ensures gitignored folders exist (e.g. for private or public uploads)
- automatically generates local settings (during *instance init* and after *instance rebuild*) using minimal template syntax, see e.g. `cwt/extensions/docker4drupal/app/drupal_settings.7.tpl.php`
- provides Make shortcuts for `drush`, `composer`, and `drupal` commands
- provides optional crontab setup during *app install* on current host (see the `D4D_USE_CRONTAB` global)
