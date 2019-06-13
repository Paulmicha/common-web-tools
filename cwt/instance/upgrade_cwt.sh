#!/usr/bin/env bash

##
# Upgrades CWT from the source repo on Github.
#
# Deletes and replaces the ./cwt folder with contents from the main public repo.
# Preserves extensions that aren't part of the list bundled with CWT (based on
# the latest remote sources).
#
# The remote git URL is overridable using a global named 'CWT_REPO'.
#
# @example
#   make upgrade-cwt
#   # Or :
#   cwt/instance/upgrade_cwt.sh
#
#   # If the temporary directory already exists, use existing folder without
#   # prompt :
#   make upgrade-cwt n
#   # Or :
#   cwt/instance/upgrade_cwt.sh n
#
#   # If the temporary directory already exists, force re-download the sources
#   # from remote repo without prompt :
#   make upgrade-cwt y
#   # Or :
#   cwt/instance/upgrade_cwt.sh y
#
#   # To keep the temporary directory once completed, use arg 2 (value 'k') :
#   make upgrade-cwt n k
#   # Or :
#   cwt/instance/upgrade_cwt.sh n k
#

. cwt/bootstrap.sh

echo "Upgrading CWT from the source repo on Github..."

tmp_dir="scripts/cwt/local/tmp-core-upgrade"

if [[ ! -d 'scripts/cwt/local' ]]; then
  mkdir -p 'scripts/cwt/local'
fi

# Support retries without having to re-download the sources from remote repo
# every time.
proceed_with_download='y'

if [[ -d "$tmp_dir" ]]; then
  if [[ -z "$1" ]]; then
    echo
    echo "It seems the temporary directory '$tmp_dir' already exists."
    echo "Should we delete it and re-download the sources from the main public repository on Github ?"
    read -p "Yes/no (y/n); 'no' = skip download, use existing folder : " proceed_with_download
  else
    case "$1" in n)
      proceed_with_download='n'
    esac
  fi
fi

case "$proceed_with_download" in y*|Y*)
  if [[ -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi

  git clone --depth 1 "${CWT_REPO:=https://github.com/Paulmicha/common-web-tools.git}" "$tmp_dir"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to clone CWT 'core' from the main public repository on Github." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
esac

# Delete individually all bundled extensions in existing project instance.
u_fs_dir_list "$tmp_dir/cwt/extensions"
for dir in $dir_list; do
  if [[ -d "cwt/extensions/$dir" ]]; then
    rm -rf "cwt/extensions/$dir"
  fi
done

# If there are any extension left in existing project instance, move them
# temporarily.
dir_list=''
u_fs_dir_list "cwt/extensions"
if [[ -n "$dir_list" ]]; then
  mkdir "$tmp_dir/_extensions_backup"
  for dir in $dir_list; do
    mv "cwt/extensions/$dir" "$tmp_dir/_extensions_backup/"
  done
fi

# Delete ./cwt folder from current project instance.
rm -rf ./cwt

# Replace it with the new one.
cp -r "$tmp_dir/cwt" ./cwt

if [[ $? -ne 0 ]] || [[ ! -d ./cwt ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to copy the new sources from '$tmp_dir/cwt' to './cwt'." >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

# Restore any extensions previously backed up (if any).
if [[ -d "$tmp_dir/_extensions_backup" ]]; then
  dir_list=''
  u_fs_dir_list "$tmp_dir/_extensions_backup"
  for dir in $dir_list; do
    mv "$tmp_dir/_extensions_backup/$dir" "cwt/extensions/"
  done
  rm -rf "$tmp_dir/_extensions_backup"
fi

# Clean up temporary folder, unless prevented in arg 2 (pass 'k').
if [[ "$2" != 'k' ]]; then
  rm -rf "$tmp_dir"
fi

echo "Upgrading CWT from the source repo on Github : done."
echo
