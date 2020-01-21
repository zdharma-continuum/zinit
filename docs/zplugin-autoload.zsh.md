zinit-autoload.zsh(1)
=======================

NAME
----
zinit-autoload.zsh - a shell script

SYNOPSIS
--------
Documentation automatically generated with \`zshelldoc'

FUNCTIONS
---------

```text
.zinit-any-to-uspl2
.zinit-at-eval
.zinit-build-module
.zinit-cd
.zinit-cdisable
.zinit-cenable
.zinit-changes
.zinit-check-comp-consistency
.zinit-check-which-completions-are-enabled
.zinit-check-which-completions-are-installed
.zinit-clear-completions
.zinit-clear-report-for
.zinit-compiled
.zinit-compile-uncompile-all
.zinit-compinit
.zinit-compute-ice
.zinit-confirm
.zinit-create
.zinit-delete
.zinit-diff-env-compute
.zinit-diff-functions-compute
.zinit-diff-options-compute
.zinit-diff-parameter-compute
.zinit-edit
.zinit-exists-message
.zinit-find-completions-of-plugin
.zinit-format-env
.zinit-format-functions
.zinit-format-options
.zinit-format-parameter
.zinit-get-completion-owner
.zinit-get-completion-owner-uspl2col
.zinit-get-path
.zinit-glance
.zinit-help
.zinit-list-bindkeys
.zinit-list-compdef-replay
.zinit-ls
.zinit-module
.zinit-prepare-readlink
.zinit-recall
.zinit-recently
.zinit-restore-extendedglob
.zinit-save-set-extendedglob
.zinit-search-completions
.zinit-self-update
.zinit-show-all-reports
.zinit-show-completions
.zinit-show-debug-report
.zinit-show-registered-plugins
.zinit-show-report
.zinit-show-times
.zinit-show-zstatus
.zinit-stress
.zinit-uncompile-plugin
.zinit-uninstall-completions
.zinit-unload
.zinit-update-or-status
.zinit-update-or-status-all
.zinit-update-or-status-snippet
```
AUTOLOAD compinit

DETAILS
-------

## Script Body


Has 5 line(s). No functions are called (may set up e.g. a hook, a Zle widget bound to a key, etc.).

Uses feature(s): _source_

## .zinit-any-to-uspl2

```text 
Converts given plugin-spec to format that's used in keys for hash tables.
So basically, creates string "user/plugin" (this format is called: uspl2).

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - (optional) plugin (only when $1 - i.e. user - given)
```

Has 2 line(s). Calls functions:

```text
.zinit-any-to-uspl2
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
.zinit-clear-report-for
.zinit-exists-message
```

## .zinit-at-eval


Has 1 line(s). Doesn't call other functions.

Uses feature(s): _eval_

Called by:

```text
.zinit-update-or-status
```

## .zinit-build-module

```text 
Performs ./configure && make on the module and displays information
how to load the module in .zshrc.
```

Has 27 line(s). Calls functions:

```text
.zinit-build-module
`-- .zinit-module
```

Uses feature(s): _trap_

Called by:

```text
.zinit-module
```

## .zinit-cd

```text 
Jumps to plugin's directory (in Zinit's home directory).

User-action entry point.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 13 line(s). Calls functions:

```text
.zinit-cd
`-- .zinit-get-path
|-- zinit-side.zsh/.zinit-exists-physically
|-- zinit-side.zsh/.zinit-shands-exp
|-- zinit-side.zsh/.zinit-two-paths
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## .zinit-cdisable

```text 
Enables given installed completion.

User-action entry point.

$1 - e.g. "_mkdir" or "mkdir"
```

Has 30 line(s). Calls functions:

```text
.zinit-cdisable
|-- .zinit-check-comp-consistency
|-- .zinit-get-completion-owner-uspl2col
|   |-- .zinit-get-completion-owner
|   `-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
`-- .zinit-prepare-readlink
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-cenable

```text 
Disables given installed completion.

User-action entry point.

$1 - e.g. "_mkdir" or "mkdir"
```

Has 31 line(s). Calls functions:

```text
.zinit-cenable
|-- .zinit-check-comp-consistency
|-- .zinit-get-completion-owner-uspl2col
|   |-- .zinit-get-completion-owner
|   `-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
`-- .zinit-prepare-readlink
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-changes

```text 
Shows `git log` of given plugin.

User-action entry point.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 9 line(s). Calls functions:

```text
.zinit-changes
|-- zinit-side.zsh/.zinit-exists-physically-message
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## .zinit-check-comp-consistency

```text 
Zinit creates symlink for each installed completion.
This function checks whether given completion (i.e.
file like "_mkdir") is indeed a symlink. Backup file
is a completion that is disabled - has the leading "_"
removed.

$1 - path to completion within plugin's directory
$2 - path to backup file within plugin's directory
```

Has 11 line(s). Doesn't call other functions.

Called by:

```text
.zinit-cdisable
.zinit-cenable
```

## .zinit-check-which-completions-are-enabled

```text 
For each argument that each should be a path to completion
within a plugin's dir, it checks whether that completion
is disabled - returns 0 or 1 on corresponding positions
in reply.

Uninstalled completions will be reported as "0"
- i.e. disabled

$1, ... - path to completion within plugin's directory
```

Has 11 line(s). Doesn't call other functions.

Called by:

```text
.zinit-show-report
```

## .zinit-check-which-completions-are-installed

```text 
For each argument that each should be a path to completion
within a plugin's dir, it checks whether that completion
is installed - returns 0 or 1 on corresponding positions
in reply.

$1, ... - path to completion within plugin's directory
```

Has 12 line(s). Doesn't call other functions.

Called by:

```text
.zinit-show-report
```

## .zinit-clear-completions

```text 
Delete stray and improper completions.

Completions live even when plugin isn't loaded - if they are
installed and enabled.

User-action entry point.
```

Has 37 line(s). Calls functions:

```text
.zinit-clear-completions
|-- .zinit-get-completion-owner
|-- .zinit-prepare-readlink
`-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-clear-report-for

```text 
Clears all report data for given user/plugin. This is
done by resetting all related global ZINIT_* hashes.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - (optional) plugin (only when $1 - i.e. user - given)
```

Has 23 line(s). Calls functions:

```text
.zinit-clear-report-for
`-- .zinit-any-to-uspl2
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
.zinit-unload
zinit.zsh/.zinit-clear-debug-report
```

## .zinit-compiled

```text 
Displays list of plugins that are compiled.

User-action entry point.
```

Has 26 line(s). Calls functions:

```text
.zinit-compiled
|-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-compile-uncompile-all

```text 
Compiles or uncompiles all existing (on disk) plugins.

User-action entry point.
```

Has 23 line(s). Calls functions:

```text
.zinit-compile-uncompile-all
|-- .zinit-uncompile-plugin
|   |-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
|   `-- zinit.zsh/.zinit-any-to-user-plugin
|-- zinit-install.zsh/.zinit-compile-plugin
|-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-compinit

```text 
User-exposed `compinit' frontend which first ensures that all
completions managed by Zinit are forgotten by Zshell. After
that it runs normal `compinit', which should more easily detect
Zinit's completions.

No arguments.
```

Has 23 line(s). Calls functions:

```text
.zinit-compinit
|-- compinit
`-- zinit-install.zsh/.zinit-forget-completion
```

Uses feature(s): _autoload_, _unfunction_

Called by:

```text
zinit.zsh/zinit
```

## .zinit-compute-ice


```text
Computes ZINIT_ICE array (default, it can be specified via $3) from a) input
ZINIT_ICE, b) static ice, c) saved ice, taking priorities into account. Also
returns path to snippet directory and optional name of snippet file (only
valid if ZINIT_ICE[svn] is not set).

Can also pack resulting ices into ZINIT_SICE (see $2).

$1 - URL (also plugin-spec)
$2 - "pack" or "nopack" or "pack-nf" - packing means ZINIT_ICE wins with static ice;
"pack-nf" means that disk-ices will be ignored (no-file?)
$3 - name of output associative array, "ZINIT_ICE" is the default
$4 - name of output string parameter, to hold path to directory ("local_dir")
$5 - name of output string parameter, to hold filename ("filename")
```

Has 98 line(s). Calls functions:

```text
.zinit-compute-ice
|-- zinit-side.zsh/.zinit-exists-physically-message
|-- zinit-side.zsh/.zinit-shands-exp
|-- zinit-side.zsh/.zinit-two-paths
|-- zinit.zsh/.zinit-any-to-user-plugin
`-- zinit.zsh/.zinit-pack-ice
```

Uses feature(s): _wait_

Called by:

```text
.zinit-recall
.zinit-update-or-status-snippet
.zinit-update-or-status
```

## .zinit-confirm

```text 
Prints given question, waits for "y" key, evals
given expression if "y" obtained

$1 - question
$2 - expression
```

Has 5 line(s). Doesn't call other functions.

Uses feature(s): _eval_, _read_

Called by:

```text
.zinit-delete
```

## .zinit-create

```text 
Creates a plugin, also on Github (if not "_local/name" plugin).

User-action entry point.

$1 - (optional) plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - (optional) plugin (only when $1 - i.e. user - given)
```

Has 66 line(s). Calls functions:

```text
.zinit-create
|-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
|-- zinit-side.zsh/.zinit-exists-physically
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Uses feature(s): _vared_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## .zinit-delete

```text 
Deletes plugin's or snippet's directory (in Zinit's home directory).

User-action entry point.

$1 - snippet URL or plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 54 line(s). Calls functions:

```text
.zinit-delete
|-- .zinit-confirm
|-- zinit-side.zsh/.zinit-exists-physically-message
|-- zinit-side.zsh/.zinit-shands-exp
|-- zinit-side.zsh/.zinit-two-paths
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## .zinit-diff-env-compute

```text 
Computes ZINIT_PATH, ZINIT_FPATH that hold (f)path components
added by plugin. Uses data gathered earlier by .zinit-diff-env().

$1 - user/plugin
```

Has 30 line(s). Doesn't call other functions.

Called by:

```text
.zinit-show-report
.zinit-unload
```

## .zinit-diff-functions-compute

```text 
Computes FUNCTIONS that holds new functions added by plugin.
Uses data gathered earlier by .zinit-diff-functions().

$1 - user/plugin
```

Has 19 line(s). Doesn't call other functions.

Called by:

```text
.zinit-show-report
.zinit-unload
```

## .zinit-diff-options-compute

```text 
Computes OPTIONS that holds options changed by plugin.
Uses data gathered earlier by .zinit-diff-options().

$1 - user/plugin
```

Has 17 line(s). Doesn't call other functions.

Called by:

```text
.zinit-show-report
.zinit-unload
```

## .zinit-diff-parameter-compute

```text 
Computes ZINIT_PARAMETERS_PRE, ZINIT_PARAMETERS_POST that hold
parameters created or changed (their type) by plugin. Uses
data gathered earlier by .zinit-diff-parameter().

$1 - user/plugin
```

Has 28 line(s). Doesn't call other functions.

Called by:

```text
.zinit-show-report
.zinit-unload
```

## .zinit-edit

```text 
Runs $EDITOR on source of given plugin. If the variable is not
set then defaults to `vim'.

User-action entry point.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 13 line(s). Calls functions:

```text
.zinit-edit
|-- zinit-side.zsh/.zinit-exists-physically-message
|-- zinit-side.zsh/.zinit-first
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## .zinit-exists-message

```text 
Checks if plugin is loaded. Testable. Also outputs error
message if plugin is not loaded.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - (optional) plugin (only when $1 - i.e. user - given)
```

Has 7 line(s). Calls functions:

```text
.zinit-exists-message
|-- .zinit-any-to-uspl2
|   `-- zinit.zsh/.zinit-any-to-user-plugin
`-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
```

Called by:

```text
.zinit-show-report
.zinit-unload
```

## .zinit-find-completions-of-plugin

```text 
Searches for completions owned by given plugin.
Returns them in `reply' array.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 6 line(s). Calls functions:

```text
.zinit-find-completions-of-plugin
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
.zinit-show-report
```

## .zinit-format-env

```text 
Creates one-column text about FPATH or PATH elements
added when given plugin was loaded.

$1 - user/plugin (i.e. uspl2 format of plugin-spec)
$2 - if 1, then examine PATH, if 2, then examine FPATH
```

Has 16 line(s). Doesn't call other functions.

Called by:

```text
.zinit-show-report
```

## .zinit-format-functions

```text 
Creates a one or two columns text with functions created
by given plugin.

$1 - user/plugin (i.e. uspl2 format of plugin-spec)
```

Has 36 line(s). Doesn't call other functions.

Called by:

```text
.zinit-show-report
```

## .zinit-format-options

```text 
Creates one-column text about options that changed when
plugin "$1" was loaded.

$1 - user/plugin (i.e. uspl2 format of plugin-spec)
```

Has 21 line(s). Calls functions:

```text
.zinit-format-options
|-- .zinit-restore-extendedglob
`-- .zinit-save-set-extendedglob
```

Called by:

```text
.zinit-show-report
```

## .zinit-format-parameter

```text 
Creates one column text that lists global parameters that
changed when the given plugin was loaded.

$1 - user/plugin (i.e. uspl2 format of plugin-spec)
```

Has 34 line(s). Doesn't call other functions.

Called by:

```text
.zinit-show-report
```

## .zinit-get-completion-owner


```text
Returns "user---plugin" string (uspl1 format) of plugin that
owns given completion.

Both :A and readlink will be used, then readlink's output if
results differ. Readlink might not be available.

:A will read the link "twice" and give the final repository
directory, possibly without username in the uspl format;
readlink will read the link "once"

$1 - absolute path to completion file (in COMPLETIONS_DIR)
$2 - readlink command (":" or "readlink")
```

Has 22 line(s). Doesn't call other functions.

Called by:

```text
.zinit-clear-completions
.zinit-get-completion-owner-uspl2col
.zinit-show-completions
```

## .zinit-get-completion-owner-uspl2col

```text
For shortening of code - returns colorized plugin name
that owns given completion.

$1 - absolute path to completion file (in COMPLETIONS_DIR)
$2 - readlink command (":" or "readlink")
```

Has 2 line(s). Calls functions:

```text
.zinit-get-completion-owner-uspl2col
|-- .zinit-get-completion-owner
`-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
```

Called by:

```text
.zinit-cdisable
.zinit-cenable
```

## .zinit-get-path

```text 
Returns path of given ID-string, which may be a plugin-spec
(like "user/plugin" or "user" "plugin"), an absolute path
("%" "/home/..." and also "%SNIPPETS/..." etc.), or a plugin
nickname (i.e. id-as'' ice-mod), or a snippet nickname.
```

Has 35 line(s). Calls functions:

```text
.zinit-get-path
|-- zinit-side.zsh/.zinit-exists-physically
|-- zinit-side.zsh/.zinit-shands-exp
|-- zinit-side.zsh/.zinit-two-paths
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
.zinit-cd
.zinit-uninstall-completions
```

## .zinit-glance

```text 
Shows colorized source code of plugin. Is able to use pygmentize,
highlight, GNU source-highlight.

User-action entry point.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 39 line(s). Calls functions:

```text
.zinit-glance
|-- zinit-side.zsh/.zinit-exists-physically-message
|-- zinit-side.zsh/.zinit-first
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## .zinit-help

```text 
Shows usage information.

User-action entry point.
```

Has 68 line(s). Doesn't call other functions.

Called by:

```text
zinit.zsh/zinit
```

## .zinit-list-bindkeys


Has 42 line(s). Calls functions:

```text
.zinit-list-bindkeys
`-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-list-compdef-replay

```text 
Shows recorded compdefs (called by plugins loaded earlier).
Plugins often call `compdef' hoping for `compinit' being
already ran. Zinit solves this by recording compdefs.

User-action entry point.
```

Has 5 line(s). Doesn't call other functions.

Called by:

```text
zinit.zsh/zinit
```

## .zinit-ls


Has 19 line(s). Doesn't call other functions.

Called by:

```text
zinit.zsh/zinit
```

## .zinit-module

```text 
Function that has sub-commands passed as long-options (with two dashes, --).
It's an attempt to plugin only this one function into `zinit' function
defined in zinit.zsh, to not make this file longer than it's needed.
```

Has 24 line(s). Calls functions:

```text
.zinit-module
`-- .zinit-build-module
```

Called by:

```text
.zinit-build-module
zinit.zsh/zinit
```

## .zinit-prepare-readlink

```text 
Prepares readlink command, used for establishing completion's owner.

$REPLY = ":" or "readlink"
```

Has 4 line(s). Doesn't call other functions.

Uses feature(s): _type_

Called by:

```text
.zinit-cdisable
.zinit-cenable
.zinit-clear-completions
.zinit-show-completions
```

## .zinit-recall


Has 37 line(s). Calls functions:

```text
.zinit-recall
`-- .zinit-compute-ice
|-- zinit-side.zsh/.zinit-exists-physically-message
|-- zinit-side.zsh/.zinit-shands-exp
|-- zinit-side.zsh/.zinit-two-paths
|-- zinit.zsh/.zinit-any-to-user-plugin
`-- zinit.zsh/.zinit-pack-ice
```

Uses feature(s): _wait_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## .zinit-recently

```text 
Shows plugins that obtained commits in specified past time.

User-action entry point.

$1 - time spec, e.g. "1 week"
```

Has 26 line(s). Calls functions:

```text
.zinit-recently
`-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-restore-extendedglob

```text 
Restores extendedglob-option from state saved earlier.
```

Has 1 line(s). Doesn't call other functions.

Called by:

```text
.zinit-format-options
.zinit-show-registered-plugins
.zinit-unload
```

## .zinit-save-set-extendedglob

```text 
Enables extendedglob-option first saving if it was already
enabled, for restoration of this state later.
```

Has 2 line(s). Doesn't call other functions.

Called by:

```text
.zinit-format-options
.zinit-show-registered-plugins
.zinit-unload
```

## .zinit-search-completions

```text 
While .zinit-show-completions() shows what completions are
installed, this functions searches through all plugin dirs
showing what's available in general (for installation).

User-action entry point.
```

Has 43 line(s). Calls functions:

```text
.zinit-search-completions
`-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-self-update

```text 
Updates Zinit code (does a git pull).

User-action entry point.
```

Has 23 line(s). Doesn't call other functions.

Uses feature(s): _zcompile_

Called by:

```text
zinit.zsh/zinit
```

## .zinit-show-all-reports

```text 
Displays reports of all loaded plugins.

User-action entry point.
```

Has 5 line(s). Calls functions:

```text
.zinit-show-all-reports
`-- .zinit-show-report
|-- .zinit-check-which-completions-are-enabled
|-- .zinit-check-which-completions-are-installed
|-- .zinit-diff-env-compute
|-- .zinit-diff-functions-compute
|-- .zinit-diff-options-compute
|-- .zinit-diff-parameter-compute
|-- .zinit-exists-message
|   |-- .zinit-any-to-uspl2
|   |   `-- zinit.zsh/.zinit-any-to-user-plugin
|   `-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
|-- .zinit-find-completions-of-plugin
|   `-- zinit.zsh/.zinit-any-to-user-plugin
|-- .zinit-format-env
|-- .zinit-format-functions
|-- .zinit-format-options
|   |-- .zinit-restore-extendedglob
|   `-- .zinit-save-set-extendedglob
|-- .zinit-format-parameter
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-show-completions

```text 
Display installed (enabled and disabled), completions. Detect
stray and improper ones.

Completions live even when plugin isn't loaded - if they are
installed and enabled.

User-action entry point.
```

Has 72 line(s). Calls functions:

```text
.zinit-show-completions
|-- .zinit-get-completion-owner
|-- .zinit-prepare-readlink
`-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-show-debug-report

```text 
Displays dtrace report (data recorded in interactive session).

User-action entry point.
```

Has 1 line(s). Calls functions:

```text
.zinit-show-debug-report
`-- .zinit-show-report
|-- .zinit-check-which-completions-are-enabled
|-- .zinit-check-which-completions-are-installed
|-- .zinit-diff-env-compute
|-- .zinit-diff-functions-compute
|-- .zinit-diff-options-compute
|-- .zinit-diff-parameter-compute
|-- .zinit-exists-message
|   |-- .zinit-any-to-uspl2
|   |   `-- zinit.zsh/.zinit-any-to-user-plugin
|   `-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
|-- .zinit-find-completions-of-plugin
|   `-- zinit.zsh/.zinit-any-to-user-plugin
|-- .zinit-format-env
|-- .zinit-format-functions
|-- .zinit-format-options
|   |-- .zinit-restore-extendedglob
|   `-- .zinit-save-set-extendedglob
|-- .zinit-format-parameter
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-show-registered-plugins

```text 
Lists loaded plugins (subcommands list, lodaded).

User-action entry point.
```

Has 21 line(s). Calls functions:

```text
.zinit-show-registered-plugins
|-- .zinit-restore-extendedglob
|-- .zinit-save-set-extendedglob
`-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-show-report

```text 
Displays report of the plugin given.

User-action entry point.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user (+ plugin in $2), plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 71 line(s). Calls functions:

```text
.zinit-show-report
|-- .zinit-check-which-completions-are-enabled
|-- .zinit-check-which-completions-are-installed
|-- .zinit-diff-env-compute
|-- .zinit-diff-functions-compute
|-- .zinit-diff-options-compute
|-- .zinit-diff-parameter-compute
|-- .zinit-exists-message
|   |-- .zinit-any-to-uspl2
|   |   `-- zinit.zsh/.zinit-any-to-user-plugin
|   `-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
|-- .zinit-find-completions-of-plugin
|   `-- zinit.zsh/.zinit-any-to-user-plugin
|-- .zinit-format-env
|-- .zinit-format-functions
|-- .zinit-format-options
|   |-- .zinit-restore-extendedglob
|   `-- .zinit-save-set-extendedglob
|-- .zinit-format-parameter
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
.zinit-show-all-reports
.zinit-show-debug-report
zinit.zsh/zinit
```

## .zinit-show-times

```text 
Shows loading times of all loaded plugins.

User-action entry point.
```

Has 42 line(s). Calls functions:

```text
.zinit-show-times
`-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-show-zstatus

```text 
Shows Zinit status, i.e. number of loaded plugins,
of available completions, etc.

User-action entry point.
```

Has 41 line(s). Doesn't call other functions.

Called by:

```text
zinit.zsh/zinit
```

## .zinit-stress

```text 
Compiles plugin with various options on and off to see
how well the code is written. The options are:

NO_SHORT_LOOPS, IGNORE_BRACES, IGNORE_CLOSE_BRACES, SH_GLOB,
CSH_JUNKIE_QUOTES, NO_MULTI_FUNC_DEF.

User-action entry point.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 35 line(s). Calls functions:

```text
.zinit-stress
|-- zinit-side.zsh/.zinit-exists-physically-message
|-- zinit-side.zsh/.zinit-first
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Uses feature(s): _zcompile_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## .zinit-uncompile-plugin

```text 
Uncompiles given plugin.

User-action entry point.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user (+ plugin in $2), plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 22 line(s). Calls functions:

```text
.zinit-uncompile-plugin
|-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
.zinit-compile-uncompile-all
zinit.zsh/zinit
```

## .zinit-uninstall-completions

```text 
Removes all completions of given plugin from Zshell (i.e. from FPATH).
The FPATH is typically `~/.zinit/completions/'.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 41 line(s). Calls functions:

```text
.zinit-uninstall-completions
|-- .zinit-get-path
|   |-- zinit-side.zsh/.zinit-exists-physically
|   |-- zinit-side.zsh/.zinit-shands-exp
|   |-- zinit-side.zsh/.zinit-two-paths
|   `-- zinit.zsh/.zinit-any-to-user-plugin
`-- zinit-install.zsh/.zinit-forget-completion
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-unload

```text 
0. Call the Zsh Plugin's Standard *_plugin_unload function
1. Delete bindkeys (...)
2. Delete Zstyles
3. Restore options
4. Remove aliases
5. Restore Zle state
6. Unfunction functions (created by plugin)
7. Clean-up FPATH and PATH
8. Delete created variables
9. Forget the plugin

User-action entry point.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 347 line(s). Calls functions:

```text
.zinit-unload
|-- .zinit-clear-report-for
|   `-- .zinit-any-to-uspl2
|       `-- zinit.zsh/.zinit-any-to-user-plugin
|-- .zinit-diff-env-compute
|-- .zinit-diff-functions-compute
|-- .zinit-diff-options-compute
|-- .zinit-diff-parameter-compute
|-- .zinit-exists-message
|   |-- .zinit-any-to-uspl2
|   |   `-- zinit.zsh/.zinit-any-to-user-plugin
|   `-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
|-- .zinit-restore-extendedglob
|-- .zinit-save-set-extendedglob
|-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
|-- zinit.zsh/.zinit-any-to-user-plugin
|-- zinit.zsh/.zinit-clear-debug-report
`-- zinit.zsh/.zinit-unregister-plugin
```

Uses feature(s): _alias_, _bindkey_, _unalias_, _unfunction_, _zle_, _zstyle_

Called by:

```text
zinit.zsh/.zinit-debug-unload
zinit.zsh/.zinit-run-task
zinit.zsh/zinit
```

## .zinit-update-or-status

```text 
Updates (git pull) or does `git status' for given plugin.

User-action entry point.

$1 - "status" for status, other for update
$2 - plugin spec (4 formats: user---plugin, user/plugin, user (+ plugin in $2), plugin)
$3 - plugin (only when $1 - i.e. user - given)
```

Has 212 line(s). Calls functions:

```text
.zinit-update-or-status
|-- .zinit-at-eval
|-- .zinit-compute-ice
|   |-- zinit-side.zsh/.zinit-exists-physically-message
|   |-- zinit-side.zsh/.zinit-shands-exp
|   |-- zinit-side.zsh/.zinit-two-paths
|   |-- zinit.zsh/.zinit-any-to-user-plugin
|   `-- zinit.zsh/.zinit-pack-ice
|-- .zinit-update-or-status-snippet
|   |-- .zinit-compute-ice
|   |   |-- zinit-side.zsh/.zinit-exists-physically-message
|   |   |-- zinit-side.zsh/.zinit-shands-exp
|   |   |-- zinit-side.zsh/.zinit-two-paths
|   |   |-- zinit.zsh/.zinit-any-to-user-plugin
|   |   `-- zinit.zsh/.zinit-pack-ice
|   `-- zinit.zsh/.zinit-load-snippet
|-- zinit-install.zsh/.zinit-get-latest-gh-r-version
|-- zinit-install.zsh/.zinit-setup-plugin-dir
|-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
|-- zinit-side.zsh/.zinit-exists-physically-message
|-- zinit-side.zsh/.zinit-store-ices
|-- zinit-side.zsh/.zinit-two-paths
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Uses feature(s): _kill_, _read_, _source_, _wait_

Called by:

```text
.zinit-update-or-status-all
zinit.zsh/zinit
```

## .zinit-update-or-status-all

```text 
Updates (git pull) or does `git status` for all existing plugins.
This includes also plugins that are not loaded into Zsh (but exist
on disk). Also updates (i.e. redownloads) snippets.

User-action entry point.
```

Has 63 line(s). Calls functions:

```text
.zinit-update-or-status-all
|-- .zinit-update-or-status
|   |-- .zinit-at-eval
|   |-- .zinit-compute-ice
|   |   |-- zinit-side.zsh/.zinit-exists-physically-message
|   |   |-- zinit-side.zsh/.zinit-shands-exp
|   |   |-- zinit-side.zsh/.zinit-two-paths
|   |   |-- zinit.zsh/.zinit-any-to-user-plugin
|   |   `-- zinit.zsh/.zinit-pack-ice
|   |-- .zinit-update-or-status-snippet
|   |   |-- .zinit-compute-ice
|   |   |   |-- zinit-side.zsh/.zinit-exists-physically-message
|   |   |   |-- zinit-side.zsh/.zinit-shands-exp
|   |   |   |-- zinit-side.zsh/.zinit-two-paths
|   |   |   |-- zinit.zsh/.zinit-any-to-user-plugin
|   |   |   `-- zinit.zsh/.zinit-pack-ice
|   |   `-- zinit.zsh/.zinit-load-snippet
|   |-- zinit-install.zsh/.zinit-get-latest-gh-r-version
|   |-- zinit-install.zsh/.zinit-setup-plugin-dir
|   |-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
|   |-- zinit-side.zsh/.zinit-exists-physically-message
|   |-- zinit-side.zsh/.zinit-store-ices
|   |-- zinit-side.zsh/.zinit-two-paths
|   `-- zinit.zsh/.zinit-any-to-user-plugin
|-- .zinit-update-or-status-snippet
|   |-- .zinit-compute-ice
|   |   |-- zinit-side.zsh/.zinit-exists-physically-message
|   |   |-- zinit-side.zsh/.zinit-shands-exp
|   |   |-- zinit-side.zsh/.zinit-two-paths
|   |   |-- zinit.zsh/.zinit-any-to-user-plugin
|   |   `-- zinit.zsh/.zinit-pack-ice
|   `-- zinit.zsh/.zinit-load-snippet
|-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
zinit.zsh/zinit
```

## .zinit-update-or-status-snippet

```text 

Implements update or status operation for snippet given by URL.

$1 - "status" or "update"
$2 - snippet URL
```

Has 19 line(s). Calls functions:

```text
.zinit-update-or-status-snippet
|-- .zinit-compute-ice
|   |-- zinit-side.zsh/.zinit-exists-physically-message
|   |-- zinit-side.zsh/.zinit-shands-exp
|   |-- zinit-side.zsh/.zinit-two-paths
|   |-- zinit.zsh/.zinit-any-to-user-plugin
|   `-- zinit.zsh/.zinit-pack-ice
`-- zinit.zsh/.zinit-load-snippet
```

Called by:

```text
.zinit-update-or-status-all
.zinit-update-or-status
```

## compinit


Has 549 line(s). Doesn't call other functions.

Uses feature(s): _autoload_, _bindkey_, _eval_, _read_, _unfunction_, _zle_, _zstyle_

Called by:

```text
.zinit-compinit
```

<!--
Vim commands used to convert from asciidoc:
:%s/^\([-a-zA-Z0-9 :@]\+\)\n\~\+/## \1
:%s/____\n\(\_.\{-}\)\n____/```text\1^M```/g
:%s/^ \([ \-|Az`][a-z\-0-9`  \/.]\+\)/  \1/
:%s/\(\(^  [-a-z0-9.\/`|\\][-a-z0-9.\/`|\\  ]\+\n\)\+\)/```text\1```
:%s/^\s\+//
-->
