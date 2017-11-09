#!/bin/bash

##
# File-related utility functions.
#
# This script is dynamically loaded.
# @see cwt/bash_utils.sh
#
# Convention : functions names are all prefixed by "u" (for "utility").
#

##
# Tmp file-based variable getter / setter supporting "dict-like" structure.
#
# Caveat : it's really slow...
#
# We used another implementation instead for env aggregation.
# -> TODO : remove when 100% sure it will remain unused.
# See https://stackoverflow.com/questions/12944674/how-to-export-an-associative-array-hash-in-bash
#
# Usage :
#   # you can use mostly like you set vars in bash/shell
#   u_var test='Hello Welt!'
#   # if you need arrays set it like this:
#   u_var fruits/0='Apple'
#   u_var fruits/1='Banana'
#   # or if you need a dict:
#   u_var contacts/1/name="Max"
#   u_var contacts/1/surname="Musterman"
#
u_var() {
  case $1 in
    *=|*=*)
      local __var_part1=$( echo "$1" | sed -e 's/=.*//' -e 's/[+,-]//' ) # cut +=/=
      local __var_part2=$( echo "$1" | sed -e 's/.*.=//' )
      local __var12=$tmp_dir/$__var_part1
      mkdir -p ${__var12%/*} #create all subdirs if its an array
      case $1 in
        *+=*)
            # if its an array try to add new item
          if [ -d $tmp_dir/$__var_part1 ] ; then
            printf -- $__var_part2 > $tmp_dir/$__var_part1/$(( $( echo $tmp_dir/$__var_part2/* | tail | basename ) + 1 ))
          else
            printf -- "$__var_part2" >> $tmp_dir/$__var_part1
          fi
          ;;
        *-=*) false ;;
        # else just add content
        *) printf -- "$__var_part2" > $tmp_dir/$__var_part1 ;;
      esac
    ;;

    *) # just print var
      if [ -d $tmp_dir/$1 ]; then
        ls $tmp_dir/$1
      elif [ -e $tmp_dir/$1 ]; then
        cat $tmp_dir/$1
      else
        return 1
      fi
    ;;
  esac
}

##
# Prints bash script file absolute path (from where this function is called).
#
# @param 1 String : the bash script file - use ${BASH_SOURCE[0]} for the current
#   (calling) file.
#
# @example
#   FILE_ABS_PATH=$(u_get_script_path ${BASH_SOURCE[0]})
#
u_get_script_path() {
  echo $(cd "$(dirname "$1")" && pwd)/$(basename "$1")
}
