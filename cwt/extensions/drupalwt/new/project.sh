#!/usr/bin/env bash

##
# Starts a new project using 'composer create-project'.
#
# @param 1 String : the composer project template (or "distro").
# @param 2 [optional] String : the way to deal with a pre-existing destination
#   folder if it already exists. Because 'composer create-project' requires that
#   the folder $APP_DOCROOT be empty, the default behavior is to delete
#   everything inside it before executing it. As it could contain the .git
#   folder when we are creating a new project (i.e. cloned - even empty - during
#   instance init if $APP_GIT_INIT_CLONE is set to 'yes'), this then re-executes
#   the 'init' hook implementation in the 'git' subject from CWT core.
#   @see cwt/git/init.hook.sh
#   Another option is to make a temporary copy, then merge it back afterwards.
#   There are 2 values to distinguish between keeping or discarding the existing
#   files during the merge : respectively 'keep' and 'discard'.
#   Default value : 'delete'.
# @param 3 [optional] String : 'composer create-project' params override. When
#   set, this param replaces the following default arguments entirely :
#   --no-interaction --no-install --prefer-dist --remove-vcs
#
# @example
#   # Create a new project based on the "Thunder" Drupal distribution. If the
#   # $APP_DOCROOT folder exists, by default, its content is deleted first. And
#   # if $APP_GIT_INIT_CLONE is set to 'yes', the git work tree will be
#   # reinitialized :
#   make new-project thunder/thunder-project
#   # Or :
#   cwt/extensions/drupalwt/new/project.sh thunder/thunder-project
#
#   # Same, but if the $APP_DOCROOT folder exists and is not empty, in case of
#   # conflicts when merging the temporary backup copy, preserve its contents -
#   # *overwriting* the conflicting files newly created by Composer :
#   make new-project thunder/thunder-project 'keep'
#   # Or :
#   cwt/extensions/drupalwt/new/project.sh thunder/thunder-project 'keep'
#
#   # Same, but preserving the files newly created by Composer instead -
#   # *disarding* any conflicting pre-existing files in $APP_DOCROOT folder :
#   make new-project thunder/thunder-project 'discard'
#   # Or :
#   cwt/extensions/drupalwt/new/project.sh thunder/thunder-project 'discard'
#

. cwt/bootstrap.sh

# Prerequisites checks.
if [[ -z "$1" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: argument 1 (the Composer project template, or distro) is required." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

# Default value for $2 : what to do if destination dir exists.
edd_decision='delete'
if [[ -n "$2" ]]; then
  ccp_args="$2"
fi

# Default value for $3 : composer create-project arguments.
ccp_args='--no-interaction --no-install --prefer-dist --remove-vcs'
if [[ -n "$3" ]]; then
  ccp_args="$3"
fi

echo "Creating new project based on '$1' ..."

# Deal with pre-existing destination dir.
merge_overwrite=''
tmp_merge_dir="${APP_DOCROOT}.tmp.bak"

if [[ -d "$APP_DOCROOT" ]]; then
  echo "  The command 'composer create-project' requires the folder '$APP_DOCROOT' to be empty."
  case "$edd_decision" in

    # By default, we assume this would primarily be used to begin a new project.
    # Thus, if the folder exists, it would likely only contain an empty git work
    # tree - meaning just the "$APP_DOCROOT/.git" folder, and nothing else.
    'delete')
      echo "  -> Remove all its contents, then re-execute the 'init' hook implementation in the 'git' subject from CWT core."
      rm -rf $APP_DOCROOT/*
      rm -rf $APP_DOCROOT/.* 2>/dev/null
      . cwt/git/init.hook.sh
      ;;

    # Alternatively, temporarily move the existing folder then merge it back
    # (overwriting the newly created files) afterwards in order to preserve its
    # contents.
    'keep')
      merge_overwrite='yes'
      echo "  -> Make a temporary copy of the '$APP_DOCROOT' dir."
      echo "  It will be merged back afterwards, and in case of conflict, the previously existing files will be kept intact (*not* preserving files newly created by Composer)."
      ;;

    # Same, but discarding the old files to keep the newly created ones.
    'discard')
      merge_overwrite='no'
      echo "  -> Make a temporary copy of the '$APP_DOCROOT' dir."
      echo "  It will be merged back afterwards, and in case of conflict, the files newly created by Composer will be kept intact (*not* preserving previously existing files)."
      ;;
  esac

  # Temporarily move the $APP_DOCROOT folder for both these cases :
  case "$edd_decision" in 'keep'|'discard')
    mv "$APP_DOCROOT" "$tmp_merge_dir"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: unable to temporarily move the '$APP_DOCROOT' dir (to '$tmp_merge_dir')." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    fi
  esac
fi

# When using docker-compose, 'composer' is likely an alias running from a
# container -> deal with path conversion.
destination_dir="$APP_DOCROOT"
case "$PROVISION_USING" in 'docker-compose')
  if [[ -n "$APP_DOCROOT_C" ]]; then
    destination_dir="$APP_DOCROOT_C"
  fi
esac

composer create-project "$1" "$destination_dir" $ccp_args

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: 'composer create-project' exited with a non-zero code." >&2
  echo "-> Aborting (3)." >&2
  echo >&2
  exit 3
fi

# If a temporary copy was made, restore it.
if [[ -d "$tmp_merge_dir" ]]; then
  u_fs_merge_dirs "$tmp_merge_dir" "$APP_DOCROOT" "$merge_overwrite"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: an error occurred while restoring the temporary merge dir." >&2
    echo "-> Aborting (4)." >&2
    echo >&2
    exit 4
  fi
fi

# By default, we use a separate step for composer install.
case "$ccp_args" in *'--no-install'*)
  composer install

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: 'composer install' exited with a non-zero code." >&2
    echo "-> Aborting (5)." >&2
    echo >&2
    exit 5
  fi
esac

echo "Creating new project based on '$1' : done."
