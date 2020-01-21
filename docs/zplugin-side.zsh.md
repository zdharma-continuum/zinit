zinit-side.zsh(1)
===================

NAME
----
zinit-side.zsh - a shell script

SYNOPSIS
--------
Documentation automatically generated with \`zshelldoc'

FUNCTIONS
---------

```text
.zinit-any-colorify-as-uspl2
.zinit-exists-physically
.zinit-exists-physically-message
.zinit-first
.zinit-get-plg-dir
.zinit-shands-exp
.zinit-store-ices
.zinit-two-paths
```

DETAILS
-------

## Script Body

Has 1 line(s). No functions are called (may set up e.g. a hook, a Zle widget bound to a key, etc.).

## .zinit-any-colorify-as-uspl2

```text
Returns ANSI-colorified "user/plugin" string, from any supported
plugin spec (user---plugin, user/plugin, user plugin, plugin).

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
$REPLY = ANSI-colorified "user/plugin" string
```

Has 11 line(s). Calls functions:

```text
.zinit-any-colorify-as-uspl2
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
.zinit-exists-physically-message
zinit-autoload.zsh/.zinit-clear-completions
zinit-autoload.zsh/.zinit-compiled
zinit-autoload.zsh/.zinit-compile-uncompile-all
zinit-autoload.zsh/.zinit-create
zinit-autoload.zsh/.zinit-exists-message
zinit-autoload.zsh/.zinit-get-completion-owner-uspl2col
zinit-autoload.zsh/.zinit-list-bindkeys
zinit-autoload.zsh/.zinit-recently
zinit-autoload.zsh/.zinit-search-completions
zinit-autoload.zsh/.zinit-show-completions
zinit-autoload.zsh/.zinit-show-registered-plugins
zinit-autoload.zsh/.zinit-show-times
zinit-autoload.zsh/.zinit-uncompile-plugin
zinit-autoload.zsh/.zinit-unload
zinit-autoload.zsh/.zinit-update-or-status-all
zinit-autoload.zsh/.zinit-update-or-status
zinit-install.zsh/.zinit-install-completions
zinit-install.zsh/.zinit-setup-plugin-dir
```

## .zinit-exists-physically

```text
Checks if directory of given plugin exists in PLUGIN_DIR.

Testable.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 10 line(s). Calls functions:

```text
.zinit-exists-physically
|-- .zinit-shands-exp
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
.zinit-exists-physically-message
zinit-autoload.zsh/.zinit-create
zinit-autoload.zsh/.zinit-get-path
```

## .zinit-exists-physically-message

```text 
Checks if directory of given plugin exists in PLUGIN_DIR,
and outputs error message if it doesn't.

Testable.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 11 line(s). Calls functions:

```text
.zinit-exists-physically-message
|-- .zinit-any-colorify-as-uspl2
|   `-- zinit.zsh/.zinit-any-to-user-plugin
|-- .zinit-exists-physically
|   |-- .zinit-shands-exp
|   `-- zinit.zsh/.zinit-any-to-user-plugin
`-- .zinit-shands-exp
```

Called by:

```text
zinit-autoload.zsh/.zinit-changes
zinit-autoload.zsh/.zinit-compute-ice
zinit-autoload.zsh/.zinit-delete
zinit-autoload.zsh/.zinit-edit
zinit-autoload.zsh/.zinit-glance
zinit-autoload.zsh/.zinit-stress
zinit-autoload.zsh/.zinit-update-or-status
zinit-install.zsh/.zinit-install-completions
```

## .zinit-first

```text
Finds the main file of plugin. There are multiple file name
formats, they are ordered in order starting from more correct
ones, and matched. .zinit-load-plugin() has similar code parts
and doesn't call .zinit-first() – for performance. Obscure matching
is done in .zinit-find-other-matches, here and in .zinit-load().
Obscure = non-standard main-file naming convention.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 17 line(s). Calls functions:

```text
.zinit-first
|-- .zinit-get-plg-dir
|-- zinit.zsh/.zinit-any-to-user-plugin
`-- zinit.zsh/.zinit-find-other-matches
```

Called by:

```text
zinit-autoload.zsh/.zinit-edit
zinit-autoload.zsh/.zinit-glance
zinit-autoload.zsh/.zinit-stress
zinit-install.zsh/.zinit-compile-plugin
```

## .zinit-get-plg-dir

Has 9 line(s). Doesn't call other functions.

Called by:

```text
.zinit-first
```

## .zinit-shands-exp

```text
Does expansion of currently little unstandarized
shorthands like "%SNIPPETS", "%HOME", "OMZ::", "PZT::".
```

Has 3 line(s). Doesn't call other functions.

Called by:

```text
.zinit-exists-physically-message
.zinit-exists-physically
zinit-autoload.zsh/.zinit-compute-ice
zinit-autoload.zsh/.zinit-delete
zinit-autoload.zsh/.zinit-get-path
```

## .zinit-store-ices

```text
Saves ice mods in given hash onto disk.

$1 - directory where to create / delete files
$2 - name of hash that holds values
$3 - additional keys of hash to store, space separated
$4 - additional keys of hash to store, empty-meaningful ices, space separated
```

Has 30 line(s). Doesn't call other functions.

Uses feature(s): _wait_

Called by:

```text
zinit-autoload.zsh/.zinit-update-or-status
zinit-install.zsh/.zinit-download-snippet
zinit-install.zsh/.zinit-setup-plugin-dir
```

## .zinit-two-paths

```text
Obtains a snippet URL without specification if it is an SVN URL (points to
directory) or regular URL (points to file), returns 2 possible paths for
further examination
```

Has 19 line(s). Doesn't call other functions.

Called by:

```text
zinit-autoload.zsh/.zinit-compute-ice
zinit-autoload.zsh/.zinit-delete
zinit-autoload.zsh/.zinit-get-path
zinit-autoload.zsh/.zinit-update-or-status
```


