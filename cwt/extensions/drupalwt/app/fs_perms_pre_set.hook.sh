#!/usr/bin/env bash

##
# Implements hook -a 'fs_perms_pre_set' -s 'app instance' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# (Re)sets filesystem permissions in application source files. This hook is
# triggered before the 'normal' hook so that specific lists of paths (which may
# be contained in app sources) get their permissions applied correctly, without
# being caught by recursion - i.e. when subfolder needs different permissions.
#
# @see cwt/app/fs_perms_set.hook.sh
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_set_permissions() in cwt/instance/instance.inc.sh
#
# To verify which files can be used (and will be sourced) when this hook is
# triggered :
# $ make hook-debug s:app instance a:fs_perms_pre_set v:PROVISION_USING HOST_TYPE INSTANCE_TYPE
#

# Handle projects using different Git repos for dev-stack and app.
if [[ -n "$APP_DOCROOT" ]]; then
  # HACK : docker-compose projects may have subdirs where this returns many
  # errors we don't care about, so we prevent errors from polluting output.
  # (See docker-compose ownership issues).
  # Sets 'normal' file permissions (644 by default) to every single file in
  # application dir. Applies to files in subfolders.
  (find "$APP_DOCROOT" -type f -exec chmod $FS_NW_FILES {} +) 2> /dev/null
  # Sets 'normal' dir permissions (755 by default) to every single folder in
  # application dir. Applies to subfolders.
  (find "$APP_DOCROOT" -type d -exec chmod $FS_NW_DIRS {} +) 2> /dev/null
fi
