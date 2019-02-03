# Overrides

If the "counterpart" of a given script exists in the folder `scripts/cwt/override`, it will be used *instead* of the original file.

This allows to replace any includes or hook implementations.

Example : if we want to override `cwt/git/init.hook.sh` - effectively bypassing the existing implementation, we'll create the following file :

```txt
scripts/cwt/override/git/init.hook.sh
```

The matching is done by by replacing the leading `cwt/` in filepaths with `scripts/cwt/override/`. It works for extensions too. Here's an example using an include instead of a hook implementation for a change :

```txt
cwt/extensions/docker-compose/docker-compose.inc.sh
-> scripts/cwt/override/extensions/docker-compose/docker-compose.inc.sh
```

For convenience, `cwt/extensions/.cwt_extensions_ignore` can be overridden using `scripts/cwt/override/.cwt_extensions_ignore` (instead of `scripts/cwt/override/extensions/.cwt_extensions_ignore`).
