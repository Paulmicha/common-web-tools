#!/usr/bin/env bash

##
# Git-related utility functions.
#
# This file is sourced during core CWT bootstrap.
# @see cwt/bootstrap.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Basic Git log "processor".
#
# Forwards all arguments to u_git_find_commits() in order to allow filtering
# commits to be processed, except the following first 2 optional arguments :
#
# @params 1 & 2 [optional] Strings : "callback" code to eval for each line.
#   Defaults to : --callback 'echo "$i : $d ${h:0:8} $t"'
#   meaning : print lines to stdout formatted like :
#   <line number> : <datestamp> <short commit ID> <commit message>
#   Variables available in "callback" scope :
#     - i : line number
#     - h : commit hash
#     - t : commit title
#     - e : commit author email
#     - d : commit date
#     - s : commit timestamp
#
# @see u_git_find_commits()
#
# @example
#   # Print log lines of all *merge* commits from the past 2 months in
#   # chronological order :
#   u_git_log --merges -s '2 months ago' -i
#
#   # Print the most recent commits from the past 3 weeks using format :
#   # <datestamp> <commit ID> <author email>
#   u_git_log --callback 'echo "$d $h $e"' -s '3 weeks ago'
#
#   # Print only merge commits' titles from 'master' branch from the past 3
#   # months in chronological order, filtering out some strings using a custom
#   # callback function :
#   _print_log_line() {
#     t=${t/"Merge branch "/}
#     t=${t//"'"/}
#     echo "$t"
#   }
#   u_git_log -c '_print_log_line' --merges -b 'master' -s '3 months ago' -i
#
u_git_log() {
  local p_evaled_code
  local i
  local h
  local t
  local e
  local d
  local s

  # Provide a way to set a custom process for each line. This *must* be the 1st
  # 2 args for simplicity.
  case "$1" in -c | --callback )
    shift
    p_evaled_code="$1"
    shift
  esac

  # By default, this will output all log lines to stdout using the following
  # format : <line number> : <datestamp> <short commit ID> <commit message>
  if [[ -z "$p_evaled_code" ]]; then
    p_evaled_code='echo "$i : $d ${h:0:8} $t"'
  fi

  u_git_find_commits "$@"

  for ((i = 0 ; i < ${#git_commits_hashes[@]} ; i++)); do
    h="${git_commits_hashes[$i]}"
    t="${git_commits_titles[$i]}"
    e="${git_commits_emails[$i]}"
    d="${git_commits_dates[$i]}"
    s="${git_commits_timestamps[$i]}"
    eval "$p_evaled_code"
  done
}

##
# Searches log messages and gets all files changed in all matching commits.
#
# This function writes its result to a variable subject to collision in calling
# scope :
# @var git_changed_files
#
# @param 1 String : The (grep) search pattern.
# @param 2 [optional] String : A branch name to restrict the search.
#   Defaults to all branches.
#
# @example
#   # Search log messages in all branches and get all files changed in all
#   # matching commits :
#   u_git_find_changed_files 'JRA-224'
#   for f in "${git_changed_files[@]}"; do
#     echo "$f"
#   done
#
#   # Same, by only search in a specific branch only :
#   u_git_find_changed_files 'JRA-224' 'my-branch-name'
#   for f in "${git_changed_files[@]}"; do
#     echo "$f"
#   done
#
u_git_find_changed_files() {
  local p_search="$1"
  local p_source_branch="$2"

  # By default, search in all branches.
  if [[ -z "$p_source_branch" ]]; then
    p_source_branch='--all'
  fi

  u_git_find_commits \
    -m "$p_search" \
    -f '<have-changed>' \
    -b "$p_source_branch" \
    -v
}

##
# Finds commits based on various filters.
#
# This function writes its results to variables subject to collision in calling
# scope :
#
# @var git_commits_hashes
# @var git_commits_titles
# @var git_commits_emails
# @var git_commits_dates
# @var git_commits_timestamps
# @var git_changed_files
#
# They can be preset in calling scope. This allows to call this function several
# times and append values to the same arrays.
# There's a flag available to trigger (re)setting these variables : -v.
#
# See https://git-scm.com/docs/git-log
#
# @param n [optional] String : custom search filter named params.
#
# @example
#   # Search log messages in all branches and get all files changed in all
#   # matching commits :
#   u_git_find_commits -m 'JRA-123[^0-9]' -f '<have-changed>' -v # <- Vars are set on 1st call.
#   u_git_find_commits -m 'JRA-124[^0-9]' -f '<have-changed>'    # <- Vars are NOT reset on 2nd call.
#   for f in "${git_changed_files[@]}"; do
#     echo "$f"
#   done
#
#   # Other iteration example :
#   for ((i = 0 ; i < ${#git_commits_hashes[@]} ; i++)); do
#     d="${git_commits_dates[$i]}"
#     t="${git_commits_titles[$i]}"
#     h="${git_commits_hashes[$i]}"
#     echo "Commit $i : $d / $t ($h) ..."
#   done
#
#   # TODO [doc] write more examples using the rest of arguments.
#
u_git_find_commits() {
  local search_params=''
  local branch_filter=''
  local email_filter=''
  local file_filter=''
  local title_inverted_filter=''
  local invert_order='false'

  local git_log_line
  local commit_date
  local commit_timestamp
  local commit_email
  local commit_hash
  local commit_title
  local commit_changed_files

  local f
  local any_file_matches
  local iteration_can_carry_on

  # By default, search in all branches (without any other filter).
  if [[ -z "$@" ]]; then
    search_params+='--all '

  # Custom search filters.
  else
    while [[ "$1" =~ ^- ]]; do
      case "$1" in

        # Search in commits' log messages.
        -m | --msg )
          shift
          search_params+="--grep='$1' "
          ;;

        # Search in commits' log messages using numerical filter suffix, i.e. to
        # avoid matching JR-123 when searching for JRA-12.
        -g | --msgnum )
          shift
          search_params+="--grep='$1[^0-9]' "
          ;;

        # Filter out commits whose log message title matches given pattern. The
        # pattern cannot contain "|" inside.
        # See https://unix.stackexchange.com/a/234415
        -n | --titlenotmatching )
          shift
          title_inverted_filter="$1"
          ;;

        # Filter by branch.
        -b | --branch )
          shift
          branch_filter="$1"
          ;;

        # Filter by commit author email. The pattern cannot contain "|" inside.
        # See https://unix.stackexchange.com/a/234415
        -e | --email )
          shift
          email_filter="$1"
          ;;

        # Filter by minimum date (discards older commits).
        # Show commits more recent than a specific date.
        -s | --since )
          shift
          search_params+="--since='$1' " # Alias : --after=<date>
          ;;

        # Filter by maximum date (discards newer commits).
        # Show commits older than a specific date.
        -u | --until )
          shift
          search_params+="--until='$1' " # Alias : --before=<date>
          ;;

        # Look in diffs where added or removed lines match given regex.
        -d | --diff )
          shift
          search_params+="-G '$1' "
          ;;

        # Filter by files.
        -f | --files )
          shift
          file_filter="$1"
          ;;

        # Flag : invert hashes order.
        -i | --invert )
          invert_order='true'
          ;;

        # Flag : (re)set the arrays variables. Prevents appending values in
        # multiple calls to this function in the same scope.
        -v | --varsreset )
          git_commits_hashes=()
          git_commits_titles=()
          git_commits_emails=()
          git_commits_dates=()
          git_commits_timestamps=()
          git_changed_files=()
          ;;

        # Forward all remaining args starting with '--' to the git-log command.
        # See https://www.git-scm.com/docs/git-log
        --*)
          search_params+="$1 "
          ;;
      esac

      shift
    done

    # If no branch filter was specified, we still need to apply the '--all'
    # search param.
    if [[ -z "$branch_filter" ]]; then
      search_params+='--all '
    else
      search_params+="$branch_filter "
    fi
  fi

  # Debug.
  # echo "debug search params :"
  # echo "  $search_params"
  # echo "debug $# unprocessed arg(s) :"
  # echo "  $@"
  # exit

  while IFS= read -r git_log_line _; do
    iteration_can_carry_on='false'
    u_str_split1 'commit_arr' "$git_log_line" '|'

    commit_date="${commit_arr[0]}"
    commit_email="${commit_arr[1]}"
    commit_hash="${commit_arr[2]}"
    commit_timestamp="${commit_arr[3]}"

    # Support titles which may contain the character we use as a separator '|'.
    commit_title="${git_log_line/$commit_date|$commit_email|$commit_hash|$commit_timestamp|/}"

    # Debug.
    # echo "log search $commit_date ($commit_timestamp) / $commit_title ($commit_hash)"

    # Apply filter by commit author email (pattern cannot contain "|" inside).
    if [[ -n "$email_filter" ]]; then
      case "$commit_email" in
        $email_filter)
          iteration_can_carry_on='true'
          ;;
        *)
          # Debug.
          # echo "  -> out : filtered by email ('$commit_email' does not match '$email_filter')"
          continue
          ;;
      esac
    else
      iteration_can_carry_on='true'
    fi

    # Filter out commits whose log message title matches given pattern (pattern
    # cannot contain "|" inside).
    if [[ -n "$title_inverted_filter" ]]; then
      case "$commit_title" in
        $title_inverted_filter)
          # Debug.
          # echo "  -> out : filtered by inverted title ('$commit_title' matches '$title_inverted_filter')"
          continue
          ;;
        *)
          iteration_can_carry_on='true'
          ;;
      esac
    else
      iteration_can_carry_on='true'
    fi

    # Apply file filters.
    if [[ -n "$file_filter" ]]; then
      commit_changed_files="$(u_git_wrapper diff-tree --no-commit-id --name-only -r "$commit_hash")"

      case "$file_filter" in

        # Filter out commits that have NOT made changes to any source file.
        # Populate the git_changed_files array in the process.
        '<have-changed>')
          if [[ -z "$commit_changed_files" ]]; then
            # Debug.
            # echo "  -> out : filtered because no modified files were found"
            continue
          fi
          iteration_can_carry_on='true'
          for f in $commit_changed_files; do
            u_array_add_once "$f" git_changed_files
          done
          ;;

        # Only get commits where files changed match given pattern.
        # The pattern cannot contain "|" inside.
        # See https://unix.stackexchange.com/a/234415
        # Populate the git_changed_files array in the process.
        *)
          any_file_matches='false'
          iteration_can_carry_on='false'

          for f in $commit_changed_files; do
            case "$f" in $file_filter)
              any_file_matches='true'
            esac
          done

          case "$any_file_matches" in 'true')
            iteration_can_carry_on='true'
            for f in $commit_changed_files; do
              u_array_add_once "$f" git_changed_files
            done
          esac
          ;;
      esac
    else
      iteration_can_carry_on='true'
    fi

    case "$iteration_can_carry_on" in 'false')
      continue
    esac

    git_commits_hashes+=("$commit_hash")
    git_commits_titles+=("$commit_title")
    git_commits_emails+=("$commit_email")
    git_commits_dates+=("$commit_date")
    git_commits_timestamps+=("$commit_timestamp")

  # Quick reference for git log's --pretty option tokens :
  # - %s : subject
  # - %f : sanitized subject line, suitable for a filename
  # - %H : commit hash
  # - %h : abbreviated commit hash
  # - %ae : author email
  # - %al : author local part (before the '@' sign)
  # - %aN : author name
  # - %cd : committer date (format respects --date= option)
  # - %cn : committer name
  # - %cs : committer date, short format (YYYY-MM-DD)
  # - %ct : committer date, UNIX timestamp
  # See https://git-scm.com/docs/git-log
  done < <(u_git_wrapper "log $search_params --pretty='format:%cd|%ae|%H|%ct|%s' --date=format:'%Y%m%d'")

  # Finally, invert all arrays order if requested.
  case "$invert_order" in 'true')
    u_array_reverse "${git_commits_hashes[@]}"
    git_commits_hashes=("${reversed_arr[@]}")
    u_array_reverse "${git_commits_titles[@]}"
    git_commits_titles=("${reversed_arr[@]}")
    u_array_reverse "${git_commits_emails[@]}"
    git_commits_emails=("${reversed_arr[@]}")
    u_array_reverse "${git_commits_dates[@]}"
    git_commits_dates=("${reversed_arr[@]}")
    u_array_reverse "${git_commits_timestamps[@]}"
    git_commits_timestamps=("${reversed_arr[@]}")
  esac
}

##
# Searches git log using multiple terms.
#
# Same as u_git_find_commits() but allows matching several search terms (OR).
#
# @example
#   # Find commits where title contains either 'JRA-123', 'jRA-124' or 'jRA-125'
#   # in 'master' branch, using numerical filter suffix, ordered by timestamp in
#   # ascending order (older to newer).
#   search_terms='JRA-123 JRA-124 JRA-125'
#   u_git_mfind_commits "$search_terms" --nfs -b 'master' -i
#
#   # Looping example :
#   for ((i = 0 ; i < ${#git_commits_hashes[@]} ; i++)); do
#     h="${git_commits_hashes[$i]}"
#     t="${git_commits_titles[$i]}"
#     e="${git_commits_emails[$i]}"
#     d="${git_commits_dates[$i]}"
#     s="${git_commits_timestamps[$i]}"
#     echo "$i : $d ($s) / $t ($h)"
#   done
#
u_git_mfind_commits() {
  local p_search_terms="$1"

  # All remaining arguments are forwarded, except for some options that require
  # specific pre-processing.
  shift

  local forwarded_args=''
  local search_op='-m'
  local search_term=''
  local sort='DESC'

  while [[ -n "$1" ]]; do
    case "$1" in
      # Results are sorted by timestamp DESC by default (most recent first), so
      # if the 'invert' flag is requested, it means "sort by ascending order".
      -i | --invert )
        sort='ASC'
        ;;
      # Flag : use numerical filter suffix, i.e. to avoid matching JR-123 when
      # searching for JRA-12.
      --nfs )
        search_op='-g'
        ;;
      *)
        forwarded_args+="$1 "
        ;;
    esac
    shift
  done

  git_commits_hashes=()
  git_commits_titles=()
  git_commits_emails=()
  git_commits_dates=()
  git_commits_timestamps=()
  git_changed_files=()

  for search_term in $p_search_terms; do
    u_git_find_commits "$search_op" "$search_term" $forwarded_args
  done

  # Prepare sorting by timestamp.
  local i
  local k
  local h
  local t
  local e
  local d
  local s
  local commits_to_sort

  declare -A commits_to_sort

  for ((i = 0 ; i < ${#git_commits_hashes[@]} ; i++)); do
    h="${git_commits_hashes[$i]}"
    t="${git_commits_titles[$i]}"
    e="${git_commits_emails[$i]}"
    d="${git_commits_dates[$i]}"
    s="${git_commits_timestamps[$i]}"

    # Results are keyed by timestamps, but if 2 commits happen in the same
    # second, a conflict may happen -> append the first 8 characters from hash.
    k="$s.${h:0:8}"

    commits_to_sort["$k|h"]="$h"
    commits_to_sort["$k|t"]="$t"
    commits_to_sort["$k|e"]="$e"
    commits_to_sort["$k|d"]="$d"
    commits_to_sort["$k|s"]="$s"
  done

  u_array_qsort "${!commits_to_sort[@]}"

  git_commits_hashes=()
  git_commits_titles=()
  git_commits_emails=()
  git_commits_dates=()
  git_commits_timestamps=()

  local k_split_arr

  for k in "${sorted_arr[@]}"; do
    u_str_split1 'k_split_arr' "$k" '|'

    case "${k_split_arr[1]}" in
      h) git_commits_hashes+=("${commits_to_sort[$k]}") ;;
      t) git_commits_titles+=("${commits_to_sort[$k]}") ;;
      e) git_commits_emails+=("${commits_to_sort[$k]}") ;;
      d) git_commits_dates+=("${commits_to_sort[$k]}") ;;
      s) git_commits_timestamps+=("${commits_to_sort[$k]}") ;;
    esac
  done

  # Sorting in descending order requires to invert current result at this stage.
  case "$sort" in 'DESC')
    u_array_reverse "${git_commits_hashes[@]}"
    git_commits_hashes=("${reversed_arr[@]}")
    u_array_reverse "${git_commits_titles[@]}"
    git_commits_titles=("${reversed_arr[@]}")
    u_array_reverse "${git_commits_emails[@]}"
    git_commits_emails=("${reversed_arr[@]}")
    u_array_reverse "${git_commits_dates[@]}"
    git_commits_dates=("${reversed_arr[@]}")
    u_array_reverse "${git_commits_timestamps[@]}"
    git_commits_timestamps=("${reversed_arr[@]}")
  esac
}

##
# (over)Writes Git hooks to use CWT hooks.
#
# Applies to folder "$APP_DOCROOT/.git/hooks" if it exists, otherwise to
# "$PROJECT_DOCROOT/.git/hooks".
#
# CWT hook triggers will have the following format :
# $ hook -s 'git' -a "$git_hook" -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# TODO [evol] Examine opt-in alternative to use a custom value for "git config
# core.hooksPath" (instead of just generating scripts in "$GIT_DIR/hooks").
#
# @see https://git-scm.com/docs/githooks
#
# @param 1 [optional] String : the space-separated Git hooks to (over)write.
#   Defaults to the following selection (when value is absent or empty) :
#   - 'pre-applypatch' : used to inspect the current working tree and refuse to
#     make a commit (exits with non-zero status) if it does not pass certain
#     test(s).
#   - 'pre-commit' (see post-merge) : used for permissions/ownership, ACLS, etc.
#     Prevents commit when exiting with a non-zero status. Can be bypassed with
#     the 'git commit --no-verify' option.
#   - 'post-checkout' : used to perform repository validity checks, auto-display
#     differences from the previous HEAD if different, or set working dir
#     metadata properties (e.g. permissions/ownership). The hook is given three
#     parameters: the ref of the previous HEAD, the ref of the new HEAD (which
#     may or may not have changed), and a flag indicating whether the checkout
#     was a branch checkout (changing branches, flag=1) or a file checkout
#     (retrieving a file from the index, flag=0).
#   - 'post-merge' (see pre-commit) : used for permissions/ownership, ACLS, etc.
#     This hook is invoked by git merge, which happens when a git pull is done
#     on a local repository. It takes a single parameter, a status flag
#     specifying whether or not the merge being done was a squash merge.
#   - 'pre-push' : can be used to prevent a push from taking place (exit with a
#     non-zero status). The hook is called with two parameters which provide the
#     name and location of the destination remote, if a named remote is not
#     being used both values will be the same.
#   - 'post-receive' : executes on the remote repository once after all the refs
#     have been updated. This hook does not affect the outcome of
#     git-receive-pack, as it is called after the real work is done.
# @param 2 [optional] String : the Git hooks folder to use. Defaults to
#   "$APP_DOCROOT/.git/hooks" if it exists, otherwise to
#   "$PROJECT_DOCROOT/.git/hooks".
#
# @example
#   u_git_write_hooks
#   u_git_write_hooks 'pre-commit post-merge'
#   u_git_write_hooks '' /my/custom/path/to/.git/hooks
#
u_git_write_hooks() {
  local p_git_hooks="$1"
  local p_git_hook_dir="$2"

  if [[ -z "$p_git_hooks" ]]; then
    p_git_hooks='pre-applypatch pre-commit post-checkout post-merge pre-push post-receive'
  fi

  if [[ -z "$p_git_hook_dir" ]]; then
    p_git_hook_dir="$PROJECT_DOCROOT/.git/hooks"

    if [[ -n "$APP_DOCROOT" ]]; then
      p_git_hook_dir="$APP_DOCROOT/.git/hooks"
    fi

    if [[ ! -d "$p_git_hook_dir" ]]; then
      echo >&2
      echo "Error in u_git_write_hooks() - $BASH_SOURCE line $LINENO: the Git hook dir '$p_git_hook_dir' is missing." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  fi

  # Whitelist allowed values for git hooks.
  local git_hook=''
  local git_hook_script_path=''
  local git_hooks_whitelist=()
  git_hooks_whitelist+=('applypatch-msg')
  git_hooks_whitelist+=('pre-applypatch')
  git_hooks_whitelist+=('post-applypatch')
  git_hooks_whitelist+=('pre-commit')
  git_hooks_whitelist+=('prepare-commit-msg')
  git_hooks_whitelist+=('commit-msg')
  git_hooks_whitelist+=('post-commit')
  git_hooks_whitelist+=('pre-rebase')
  git_hooks_whitelist+=('post-checkout')
  git_hooks_whitelist+=('post-merge')
  git_hooks_whitelist+=('pre-push')
  git_hooks_whitelist+=('pre-receive')
  git_hooks_whitelist+=('update')
  git_hooks_whitelist+=('post-update')
  git_hooks_whitelist+=('post-receive')
  git_hooks_whitelist+=('post-update')
  git_hooks_whitelist+=('push-to-checkout')
  git_hooks_whitelist+=('pre-auto-gc')
  git_hooks_whitelist+=('post-rewrite')
  git_hooks_whitelist+=('rebase')
  git_hooks_whitelist+=('sendemail-validate')
  git_hooks_whitelist+=('fsmonitor-watchman')

  for git_hook in $p_git_hooks; do

    # Whitelist allowed values for git hooks.
    if u_in_array "$git_hook" 'git_hooks_whitelist'; then
      git_hook_script_path="$p_git_hook_dir/$git_hook"

      relative_path=''
      u_fs_relative_path "$git_hook_script_path"

      # When Git triggers its hook, the path in which the script runs is either
      # APP_DOCROOT or PROJECT_DOCROOT.
      # -> Since CWT requires to be run from PROJECT_DOCROOT, we need to force the
      # execution path from within the generated scripts.
      echo "(over)Writing git hook $relative_path ..."
      cat > "$git_hook_script_path" <<EOF
#!/usr/bin/env bash

##
# Implements '$git_hook' git hook.
#
# This file is automatically generated during "instance init", and it will be
# entirely overwritten every time it is executed.
#
# @see u_git_write_hooks() in cwt/git/git.inc.sh
# @see u_instance_init() in cwt/instance/instance.inc.sh
#

cd $PROJECT_DOCROOT && \
  . cwt/bootstrap.sh && \
  hook -s 'git' -a "$git_hook" -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'

EOF
      chmod +x "$git_hook_script_path"
      echo "(over)Writing git hook $relative_path : done."

    else
      echo >&2
      echo "Error in u_git_write_hooks() - $BASH_SOURCE line $LINENO: the value '$git_hook' is invalid." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    fi
  done
}

##
# List staged files only.
#
# @param 1 [optional] String : the git "working dir". Defaults to $APP_DOCROOT.
# @param 2 [optional] String : the git dir. Defaults to "$1/.git".
#
# @example
#   # List staged files in current path.
#   staged="$(u_git_get_staged_files)"
#   for f in $staged; do
#     echo "staged file : $f"
#   done
#
#   # List staged files in given path.
#   staged="$(u_git_get_staged_files path/to/work/tree)"
#   for f in $staged; do
#     echo "staged file : $f"
#   done
#
u_git_get_staged_files() {
  local p_git_work_tree="$1"
  local p_git_dir=''

  if [[ -z "$p_git_work_tree" ]]; then
    p_git_work_tree="$APP_DOCROOT"
  fi

  if [[ -n "$2" ]]; then
    p_git_dir="$2"
  else
    p_git_dir="$p_git_work_tree/.git"
  fi

  echo "$(u_git_wrapper diff --name-only --cached)"
}

##
# List unmerged files only.
#
# @param 1 [optional] String : the git "working dir". Defaults to $APP_DOCROOT.
# @param 2 [optional] String : the git dir. Defaults to "$1/.git".
#
# @example
#   # List unmerged files in current path.
#   unmerged_paths="$(u_git_get_unmerged_paths)"
#   for f in $unmerged_paths; do
#     echo "unmerged : $f"
#   done
#
#   # List unmerged files in given path.
#   unmerged_paths="$(u_git_get_unmerged_paths path/to/work/tree)"
#   for f in $unmerged_paths; do
#     echo "unmerged : $f"
#   done
#
u_git_get_unmerged_paths() {
  local p_git_work_tree="$1"
  local p_git_dir=''

  if [[ -z "$p_git_work_tree" ]]; then
    p_git_work_tree="$APP_DOCROOT"
  fi

  if [[ -n "$2" ]]; then
    p_git_dir="$2"
  else
    p_git_dir="$p_git_work_tree/.git"
  fi

  echo "$(u_git_wrapper diff --name-only --diff-filter=U)"
}

##
# Wraps git calls to exec commands from PROJECT_DOCROOT for different repos.
#
# @uses the following [optional] vars in calling scope :
# - $p_git_work_tree - String : the git "working dir". Defaults to
#   APP_DOCROOT if it exists in calling scope, or none.
# - $p_git_dir - String : the git dir. Defaults to none or
#   "$p_git_work_tree/.git".
#
# @example
#   u_git_wrapper status
#
#   # Execute the same command in another dir.
#   p_git_work_tree=path/to/git-work-tree
#   u_git_wrapper status
#
u_git_wrapper() {
  local cmd=''
  local work_tree="$p_git_work_tree"

  if [[ -z "$work_tree" ]] && [[ -n "$APP_DOCROOT" ]]; then
    work_tree="$APP_DOCROOT"
  fi

  if [[ -n "$work_tree" ]]; then
    local git_dir="$work_tree/.git"

    if [[ -n "$p_git_dir" ]]; then
      git_dir="$p_git_dir"
    fi

    eval "git --git-dir=$git_dir --work-tree=$work_tree $@"

  else
    eval "git $@"
  fi
}
