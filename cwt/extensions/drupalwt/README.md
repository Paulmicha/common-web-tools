# Drupal web tools extension

This extension :

- provides global environment variables specific to Drupal settings and drupalwt containers
- implements permissions and ownership hooks
- ensures gitignored folders exist (e.g. for private or public uploads)
- automatically generates local settings (during *instance init* and after *instance rebuild*) using minimal template syntax, see e.g. `cwt/extensions/drupalwt/app/drupal_settings.7.tpl.php`
- provides Make shortcuts for `drush`, `composer`, and `drupal` commands (aliased during CWT bootstrap)
- provides optional crontab setup during *app install* on current host (see the `DWT_USE_CRONTAB` global)
- provides docker-compose stack presets, see `cwt/extensions/drupalwt/stack/*`

## Getting started ex. : creating a new Drupal 8 project

These steps assume you will use a dedicated Git repo for the Drupal application source code, and `docker-compose` with the default stack preset provided in `cwt/extensions/drupalwt/stack`.

### 1. Prepare the dev stack

```sh
cd /path/to/my.project.com

# Get CWT core files.
git clone https://github.com/Paulmicha/common-web-tools.git .
rm -rf .git

# Enable required CWT extensions (same principle as .gitignore : list the
# disabled ones in this file).
cat > 'scripts/cwt/override/.cwt_extensions_ignore' <<EOF
apache
pgsql
EOF

# Create basic settings (server docroot folder name is 'web' by default, but
# here we choose to use 'docroot' as in distributions like 'lightning' and
# 'thunder').
cat > '.cwt.yml' <<EOF
app:
  repo: git@my-git-host.com:TheGitUserAccount/the.project.repo.git
  docroot: app
server:
  docroot: app/docroot
EOF
```

### 2. Initialize the local dev instance and start containers

```sh
# By default, this will create a "local dev" instance.
# See cwt/instance/setup.sh for details.
make setup
```

Fore details about the `docker-compose` "stack" that will be installed, see :

- `cwt/extensions/drupalwt/stack/docker-compose.yml`
- `cwt/extensions/drupalwt/stack/docker-compose.override.local.dev.yml`

### 3. Choose a Composer template and do the first install

Here we chose the Composer template from the `thunder` distro, but you can use
the standard `drupal-composer/drupal-project` (if you do, make sure to leave the
`SERVER_DOCROOT` value to its default value `app/web`), or any other Composer
template.

```sh
make new-project 'thunder/thunder-project'
make new-site-install "My project" 'thunder'
```

This will install the new Drupal site named *My project* with the `thunder`
install profile, and the superadmin account credentials will be : `admin` / `admin`.

Resulting services accessible on your local host :

- Drupal site : http://localhost
- Adminer : http://localhost:9000
- Mailhog : http://localhost:8025

More details can be found in the comments of the scripts - see :

- `cwt/extensions/drupalwt/new/project.sh`
- `cwt/extensions/drupalwt/new/site-install.sh`

### 4. [optional] Adapt drupal settings

The instance is already usable by now, but you may want to adapt the drupal settings file - e.g. to only keep the generic settings in `app/docroot/sites/default/settings.php` and have them versionned in the application Git repo, while using the local settings this extension generates by default in `app/docroot/sites/default/settings.local.php` (git-ignored) :

```sh
# In docroot/sites/default/settings.php, uncomment the following lines and put
# them at the very end of the file :
#   if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
#     include $app_root . '/' . $site_path . '/settings.local.php';
#   }
# Then re-generate the local settings :
make reinit
```
