#!/usr/bin/env bash

##
# Bootstrap phase: initialize CWT primitives (cache or u_cwt_extend).
#
# Sourced only from cwt/bootstrap.sh (inside CWT_BS_FLAG).
#
# @see cwt/bootstrap.sh
#

# Initializes "primitives" for hooks and lookups (CWT extension mecanisms).
# These are : subjects, actions, prefixes, variants and extensions.
# Update 2024-06 cache results.
if [[ -f data/cwt/cache/cwt.sh ]]; then
  . data/cwt/cache/cwt.sh
else
  export cwt_primitives_cache_str=''
  CWT_INC=''
  u_cwt_extend
  mkdir -p data/cwt/cache
  cat > data/cwt/cache/cwt.sh <<CACHE
#!/usr/bin/env bash

##
# Generated cache file for CWT primitives.
#
# @see cwt/bootstrap.sh
#

$cwt_primitives_cache_str

CACHE
fi
