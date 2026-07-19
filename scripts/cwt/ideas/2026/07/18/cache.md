# CWT core concept : Cache

TODO data/cwt/cache ideal structure :

- `data/cwt/cache/$subject/$action/$file_name`
- `data/cwt/cache/$subject/$action/$args/$file_name`

The args transformation is like :

`hook -s 'instance' -p 'stage2' -a 'setup' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'`

Currently :

`data/cwt/cache/hook._w_s_instance_p_stage2_a_setup_v_v1_cwt_local_dev.sh`

Target : 

`data/cwt/cache/instance/setup/v1.cwt.local.dev.inc.sh`

Inside those cache files, which are raw bash script files that are sourced, we must be able to get the following information :

- $subject/$action (action by subject)
- cache file write triggered from which path = immediate extension point :
  - ./cwt
  - ./cwt/extensions/$extension
  - ./scripts/cwt/contrib/$extension
  - ./scripts/cwt/extend
