zinit.zsh(1)
==============

NAME
----
zinit.zsh - a shell script

SYNOPSIS
--------
Documentation automatically generated with \`zshelldoc'

FUNCTIONS
---------

```text
pmodload
zpcdclear
zpcdreplay
zpcompdef
zpcompinit
.zinit-add-report
.zinit-any-to-user-plugin
.zinit-clear-debug-report
.zinit-compdef-clear
.zinit-compdef-replay
.zinit-debug-start
.zinit-debug-stop
.zinit-debug-unload
.zinit-deploy-message
.zinit-diff
.zinit-diff-env
.zinit-diff-functions
.zinit-diff-options
.zinit-diff-parameter
.zinit-find-other-matches
.zinit-ice
.zinit-load
.zinit-load-plugin
.zinit-load-snippet
.zinit-pack-ice
.zinit-prepare-home
.zinit-register-plugin
@zplg-register-z-plugin
:zinit-reload-and-run
.zinit-run-task
.zinit-service
:zinit-shadow-alias
:zinit-shadow-autoload
:zinit-shadow-bindkey
:zinit-shadow-compdef
.zinit-shadow-off
.zinit-shadow-on
:zinit-shadow-zle
:zinit-shadow-zstyle
.zinit-submit-turbo
.zinit-unregister-plugin
.zinit-wrap-track-functions
zinit
-zinit_scheduler_add_sh
AUTOLOAD add-zsh-hook
AUTOLOAD compinit
AUTOLOAD is-at-least
PRECMD-HOOK @zinit-scheduler
```

DETAILS
-------

## Script Body

Has 117 line(s). Calls functions:

```text
Script-Body
|-- add-zsh-hook
|-- is-at-least
`-- .zinit-prepare-home
```

Uses feature(s): _alias_, _autoload_, _export_, _zmodload_, _zstyle_

_Exports (environment):_ ZPFX

## pmodload

```text 
Compatibility with Prezto. Calls can be recursive.
```

Has 9 line(s). Calls functions:

```text
pmodload
`-- .zinit-load-snippet
|-- .zinit-deploy-message
|-- .zinit-pack-ice
|-- .zinit-wrap-track-functions
`-- zinit-install.zsh/.zinit-download-snippet
```

Uses feature(s): _zstyle_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## zpcdclear

```text 
A wrapper for `zinit cdclear -q' which can be called from hook
ices like the atinit'', atload'', etc. ices.
```

Has 1 line(s). Calls functions:

```text
zpcdclear
`-- .zinit-compdef-clear
```

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## zpcdreplay

```text 
A function that can be invoked from within `atinit', `atload', etc.
ice-mod.  It works like `zinit cdreplay', which cannot be invoked
from such hook ices.
```

Has 1 line(s). Calls functions:

```text
zpcdreplay
`-- .zinit-compdef-replay
```

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## zpcompdef

```text 
Stores compdef for a replay with `zpcdreplay' (turbo mode) or
with `zinit cdreplay' (normal mode). An utility functton of
an undefined use case.
```

Has 1 line(s). Doesn't call other functions.

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## zpcompinit

```text 
A function that can be invoked from within `atinit', `atload', etc.
ice-mod.  It runs `autoload compinit; compinit' and respects
ZINIT[ZCOMPDUMP_PATH] and ZINIT[COMPINIT_OPTS].
```

Has 1 line(s). Calls functions:

```text
zpcompinit
`-- compinit
```

Uses feature(s): _autoload_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## .zinit-add-report

```text
Adds a report line for given plugin.

$1 - uspl2, i.e. user/plugin
$2, ... - the text
```

Has 2 line(s). Doesn't call other functions.

Called by:

```text
.zinit-load-plugin
:zinit-shadow-alias
:zinit-shadow-autoload
:zinit-shadow-bindkey
:zinit-shadow-compdef
:zinit-shadow-zle
:zinit-shadow-zstyle
```

## .zinit-any-to-user-plugin

```text
Allows elastic plugin-spec across the code.

$1 - plugin spec (2 formats: user/plugin, user plugin)
$2 - plugin (only when $1 - i.e. user - given)

Returns user and plugin in $reply
```
Has 23 line(s). Doesn't call other functions.

Called by:

```text
.zinit-load
.zinit-unregister-plugin
zinit-autoload.zsh/.zinit-any-to-uspl2
zinit-autoload.zsh/.zinit-changes
zinit-autoload.zsh/.zinit-compiled
zinit-autoload.zsh/.zinit-compile-uncompile-all
zinit-autoload.zsh/.zinit-compute-ice
zinit-autoload.zsh/.zinit-create
zinit-autoload.zsh/.zinit-delete
zinit-autoload.zsh/.zinit-edit
zinit-autoload.zsh/.zinit-find-completions-of-plugin
zinit-autoload.zsh/.zinit-get-path
zinit-autoload.zsh/.zinit-glance
zinit-autoload.zsh/.zinit-show-report
zinit-autoload.zsh/.zinit-stress
zinit-autoload.zsh/.zinit-uncompile-plugin
zinit-autoload.zsh/.zinit-unload
zinit-autoload.zsh/.zinit-update-or-status-all
zinit-autoload.zsh/.zinit-update-or-status
zinit-install.zsh/.zinit-compile-plugin
zinit-install.zsh/.zinit-get-latest-gh-r-version
zinit-install.zsh/.zinit-install-completions
zinit-side.zsh/.zinit-any-colorify-as-uspl2
zinit-side.zsh/.zinit-exists-physically
zinit-side.zsh/.zinit-first
```

## .zinit-clear-debug-report

```text 
Forgets dtrace repport gathered up to this moment.
```

Has 1 line(s). Calls functions:

```text
.zinit-clear-debug-report
`-- zinit-autoload.zsh/.zinit-clear-report-for
```

Called by:

```text
zinit
zinit-autoload.zsh/.zinit-unload
```

## .zinit-compdef-clear

```text 
Implements user-exposed functionality to clear gathered compdefs.
```

Has 3 line(s). Doesn't call other functions.

Called by:

```text
zpcdclear
zinit
```

## .zinit-compdef-replay

```text 
Runs gathered compdef calls. This allows to run `compinit'
after loading plugins.
```

Has 16 line(s). Doesn't call other functions.

Called by:

```text
zpcdreplay
zinit
```

## .zinit-debug-start

```text 
Starts Dtrace, i.e. session tracking for changes in Zsh state.
```

Has 9 line(s). Calls functions:

```text
.zinit-debug-start
|-- .zinit-diff
|   |-- .zinit-diff-env
|   |-- .zinit-diff-functions
|   |-- .zinit-diff-options
|   `-- .zinit-diff-parameter
`-- .zinit-shadow-on
```

Called by:

```text
zinit
```

## .zinit-debug-stop

```text 
Stops Dtrace, i.e. session tracking for changes in Zsh state.
```

Has 3 line(s). Calls functions:

```text
.zinit-debug-stop
|-- .zinit-diff
|   |-- .zinit-diff-env
|   |-- .zinit-diff-functions
|   |-- .zinit-diff-options
|   `-- .zinit-diff-parameter
`-- .zinit-shadow-off
```

Called by:

```text
zinit
```

## .zinit-debug-unload

```text 
Reverts changes detected by dtrace run.
```

Has 5 line(s). Calls functions:

```text
.zinit-debug-unload
`-- zinit-autoload.zsh/.zinit-unload
```

Called by:

```text
zinit
```

## .zinit-deploy-message

```text 
Deploys a sub-prompt message to be displayed OR a `zle
.reset-prompt' call to be invoked
```

Has 12 line(s). Doesn't call other functions.

Uses feature(s): _read_, _zle_

Called by:

```text
.zinit-load-snippet
.zinit-load
```

## .zinit-diff

```text 
Performs diff actions of all types
```

Has 4 line(s). Calls functions:

```text
.zinit-diff
|-- .zinit-diff-env
|-- .zinit-diff-functions
|-- .zinit-diff-options
`-- .zinit-diff-parameter
```

Called by:

```text
.zinit-debug-start
.zinit-debug-stop
.zinit-load-plugin
```

## .zinit-diff-env

```text 
Implements detection of change in PATH and FPATH.

$1 - user/plugin (i.e. uspl2 format)
$2 - command, can be "begin" or "end"
```

Has 18 line(s). Doesn't call other functions.

Called by:

```text
.zinit-diff
.zinit-load-plugin
```

## .zinit-diff-functions

```text 
Implements detection of newly created functions. Performs
data gathering, computation is done in *-compute().

$1 - user/plugin (i.e. uspl2 format)
$2 - command, can be "begin" or "end"
```

Has 8 line(s). Doesn't call other functions.

Called by:

```text
.zinit-diff
```

## .zinit-diff-options

```text 
Implements detection of change in option state. Performs
data gathering, computation is done in *-compute().

$1 - user/plugin (i.e. uspl2 format)
$2 - command, can be "begin" or "end"
```

Has 7 line(s). Doesn't call other functions.

Called by:

```text
.zinit-diff
```

## .zinit-diff-parameter

```text 
Implements detection of change in any parameter's existence and type.
Performs data gathering, computation is done in *-compute().

$1 - user/plugin (i.e. uspl2 format)
$2 - command, can be "begin" or "end"
```

Has 9 line(s). Doesn't call other functions.

Called by:

```text
.zinit-diff
```

## .zinit-find-other-matches

```text 
Plugin's main source file is in general `name.plugin.zsh'. However,
there can be different conventions, if that file is not found, then
this functions examines other conventions in order of most expected
sanity.
```

Has 14 line(s). Doesn't call other functions.

Called by:

```text
.zinit-load-plugin
zinit-side.zsh/.zinit-first
```

## .zinit-ice

```text 
Parses ICE specification (`zplg ice' subcommand), puts the result
into ZINIT_ICE global hash. The ice-spec is valid for next command
only (i.e. it "melts"), but it can then stick to plugin and activate
e.g. at update.
```

Has 8 line(s). Doesn't call other functions.

Called by:

```text
zinit
```

_Environment variables used:_ ZPFX

## .zinit-load

```text 
Implements the exposed-to-user action of loading a plugin.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin name, if the third format is used
```

Has 42 line(s). Calls functions:

```text
.zinit-load
|-- .zinit-any-to-user-plugin
|-- .zinit-deploy-message
|-- .zinit-load-plugin
|   |-- .zinit-add-report
|   |-- .zinit-diff
|   |   |-- .zinit-diff-env
|   |   |-- .zinit-diff-functions
|   |   |-- .zinit-diff-options
|   |   `-- .zinit-diff-parameter
|   |-- .zinit-diff-env
|   |-- .zinit-find-other-matches
|   |-- .zinit-shadow-off
|   |-- .zinit-shadow-on
|   `-- .zinit-wrap-track-functions
|-- .zinit-pack-ice
|-- .zinit-register-plugin
`-- zinit-install.zsh/.zinit-setup-plugin-dir
```

Uses feature(s): _eval_, _source_, _zle_

Called by:

```text
.zinit-run-task
.zinit-service
zinit
```

## .zinit-load-plugin

```text 
Lower-level function for loading a plugin.

$1 - user
$2 - plugin
$3 - mode (light or load)
```

Has 96 line(s). Calls functions:

```text
.zinit-load-plugin
|-- .zinit-add-report
|-- .zinit-diff
|   |-- .zinit-diff-env
|   |-- .zinit-diff-functions
|   |-- .zinit-diff-options
|   `-- .zinit-diff-parameter
|-- .zinit-diff-env
|-- .zinit-find-other-matches
|-- .zinit-shadow-off
|-- .zinit-shadow-on
`-- .zinit-wrap-track-functions
```

Uses feature(s): _eval_, _source_, _zle_

Called by:

```text
.zinit-load
```

## .zinit-load-snippet

```text 
Implements the exposed-to-user action of loading a snippet.

$1 - url (can be local, absolute path)
```

Has 180 line(s). Calls functions:

```text
.zinit-load-snippet
|-- .zinit-deploy-message
|-- .zinit-pack-ice
|-- .zinit-wrap-track-functions
`-- zinit-install.zsh/.zinit-download-snippet
```

Uses feature(s): _autoload_, _eval_, _source_, _unfunction_, _zparseopts_, _zstyle_

Called by:

```text
pmodload
.zinit-run-task
.zinit-service
zinit
zinit-autoload.zsh/.zinit-update-or-status-snippet
```

## .zinit-pack-ice

```text 
Remembers all ice-mods, assigns them to concrete plugin. Ice spec
is in general forgotten for second-next command (that's why it's
called "ice" - it melts), however they glue to the object (plugin
or snippet) mentioned in the next command – for later use with e.g.
`zinit update ...'
```

Has 3 line(s). Doesn't call other functions.

Called by:

```text
.zinit-load-snippet
.zinit-load
zinit-autoload.zsh/.zinit-compute-ice
```

## .zinit-prepare-home

```text 
Creates all directories needed by Zinit, first checks if they
already exist.
```

Has 28 line(s). Doesn't call other functions.

Called by:

```text
Script-Body
```

_Environment variables used:_ ZPFX

## .zinit-register-plugin

```text 
Adds the plugin to ZINIT_REGISTERED_PLUGINS array and to the
zsh_loaded_plugins array (managed according to the plugin standard:
http://zdharma.org/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html)
```

Has 23 line(s). Doesn't call other functions.

Called by:

```text
.zinit-load
```

## @zplg-register-z-plugin

```text 
Registers the z-plugin inside Zinit – i.e. an Zinit extension
```

Has 4 line(s). Doesn't call other functions.

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## :zinit-reload-and-run

```text 
Marks given function ($3) for autoloading, and executes it triggering the
load. $1 is the fpath dedicated to the function, $2 are autoload options.
This function replaces "autoload -X", because using that on older Zsh
versions causes problems with traps.

So basically one creates function stub that calls :zinit-reload-and-run()
instead of "autoload -X".

$1 - FPATH dedicated to function
$2 - autoload options
$3 - function name (one that needs autoloading)

Author: Bart Schaefer
```

Has 7 line(s). Doesn't call other functions.

Uses feature(s): _autoload_, _unfunction_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## .zinit-run-task

```text 
A backend, worker function of .zinit-scheduler. It obtains the tasks
index and a few of its properties (like the type: plugin, snippet,
service plugin, service snippet) and executes it first checking for
additional conditions (like non-numeric wait'' ice).

$1 - the pass number, either 1st or 2nd pass
$2 - the time assigned to the task
$3 - type: plugin, snippet, service plugin, service snippet
$4 - task's index in the ZINIT[WAIT_ICE_...] fields
$5 - mode: load or light
$6 - the plugin-spec or snippet URL or alias name (from id-as'')
```

Has 41 line(s). Calls functions:

```text
.zinit-run-task
|-- .zinit-load
|   |-- .zinit-any-to-user-plugin
|   |-- .zinit-deploy-message
|   |-- .zinit-load-plugin
|   |   |-- .zinit-add-report
|   |   |-- .zinit-diff
|   |   |   |-- .zinit-diff-env
|   |   |   |-- .zinit-diff-functions
|   |   |   |-- .zinit-diff-options
|   |   |   `-- .zinit-diff-parameter
|   |   |-- .zinit-diff-env
|   |   |-- .zinit-find-other-matches
|   |   |-- .zinit-shadow-off
|   |   |-- .zinit-shadow-on
|   |   `-- .zinit-wrap-track-functions
|   |-- .zinit-pack-ice
|   |-- .zinit-register-plugin
|   `-- zinit-install.zsh/.zinit-setup-plugin-dir
|-- .zinit-load-snippet
|   |-- .zinit-deploy-message
|   |-- .zinit-pack-ice
|   |-- .zinit-wrap-track-functions
|   `-- zinit-install.zsh/.zinit-download-snippet
`-- zinit-autoload.zsh/.zinit-unload
```

Uses feature(s): _eval_, _source_, _zle_, _zpty_

Called by:

```text
@zinit-scheduler
```

## @zinit-scheduler

```text 
Searches for timeout tasks, executes them. There's an array of tasks
waiting for execution, this scheduler manages them, detects which ones
should be run at current moment, decides to remove (or not) them from
the array after execution.

$1 - if "following", then it is non-first (second and more)
invocation of the scheduler; this results in chain of `sched'
invocations that results in repetitive @zinit-scheduler activity

if "burst", then all tasks are marked timeout and executed one
by one; this is handy if e.g. a docker image starts up and
needs to install all turbo-mode plugins without any hesitation
(delay), i.e. "burst" allows to run package installations from
script, not from prompt
```

Has 62 line(s). *Is a precmd hook*. Calls functions:

```text
@zinit-scheduler
|-- add-zsh-hook
`-- .zinit-run-task
|-- .zinit-load
|   |-- .zinit-any-to-user-plugin
|   |-- .zinit-deploy-message
|   |-- .zinit-load-plugin
|   |   |-- .zinit-add-report
|   |   |-- .zinit-diff
|   |   |   |-- .zinit-diff-env
|   |   |   |-- .zinit-diff-functions
|   |   |   |-- .zinit-diff-options
|   |   |   `-- .zinit-diff-parameter
|   |   |-- .zinit-diff-env
|   |   |-- .zinit-find-other-matches
|   |   |-- .zinit-shadow-off
|   |   |-- .zinit-shadow-on
|   |   `-- .zinit-wrap-track-functions
|   |-- .zinit-pack-ice
|   |-- .zinit-register-plugin
|   `-- zinit-install.zsh/.zinit-setup-plugin-dir
|-- .zinit-load-snippet
|   |-- .zinit-deploy-message
|   |-- .zinit-pack-ice
|   |-- .zinit-wrap-track-functions
|   `-- zinit-install.zsh/.zinit-download-snippet
`-- zinit-autoload.zsh/.zinit-unload
```

Uses feature(s): _sched_, _zle_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## .zinit-service

```text 
Handles given service, i.e. obtains lock, runs it, or waits if no lock

$1 - type "p" or "s" (plugin or snippet)
$2 - mode - for plugin (light or load)
$3 - id - URL or plugin ID or alias name (from id-as'')
```

Has 30 line(s). Calls functions:

```text
.zinit-service
|-- .zinit-load
|   |-- .zinit-any-to-user-plugin
|   |-- .zinit-deploy-message
|   |-- .zinit-load-plugin
|   |   |-- .zinit-add-report
|   |   |-- .zinit-diff
|   |   |   |-- .zinit-diff-env
|   |   |   |-- .zinit-diff-functions
|   |   |   |-- .zinit-diff-options
|   |   |   `-- .zinit-diff-parameter
|   |   |-- .zinit-diff-env
|   |   |-- .zinit-find-other-matches
|   |   |-- .zinit-shadow-off
|   |   |-- .zinit-shadow-on
|   |   `-- .zinit-wrap-track-functions
|   |-- .zinit-pack-ice
|   |-- .zinit-register-plugin
|   `-- zinit-install.zsh/.zinit-setup-plugin-dir
`-- .zinit-load-snippet
|-- .zinit-deploy-message
|-- .zinit-pack-ice
|-- .zinit-wrap-track-functions
`-- zinit-install.zsh/.zinit-download-snippet
```

Uses feature(s): _kill_, _read_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## :zinit-shadow-alias

```text 
Function defined to hijack plugin's calls to `alias' builtin.

The hijacking is to gather report data (which is used in unload).
```

Has 34 line(s). Calls functions:

```text
:zinit-shadow-alias
`-- .zinit-add-report
```

Uses feature(s): _alias_, _zparseopts_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## :zinit-shadow-autoload

```text 
Function defined to hijack plugin's calls to `autoload' builtin.

The hijacking is not only to gather report data, but also to
run custom `autoload' function, that doesn't need FPATH.
```

Has 48 line(s). Calls functions:

```text
:zinit-shadow-autoload
`-- .zinit-add-report
```

Uses feature(s): _autoload_, _eval_, _zparseopts_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## :zinit-shadow-bindkey

```text 
Function defined to hijack plugin's calls to `bindkey' builtin.

The hijacking is to gather report data (which is used in unload).
```

Has 104 line(s). Calls functions:

```text
:zinit-shadow-bindkey
|-- is-at-least
`-- .zinit-add-report
```

Uses feature(s): _bindkey_, _zparseopts_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## :zinit-shadow-compdef

```text 
Function defined to hijack plugin's calls to `compdef' function.
The hijacking is not only for reporting, but also to save compdef
calls so that `compinit' can be called after loading plugins.
```

Has 4 line(s). Calls functions:

```text
:zinit-shadow-compdef
`-- .zinit-add-report
```

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## .zinit-shadow-off

```text 
Turn off shadowing completely for a given mode ("load", "light",
"light-b" (i.e. the `trackbinds' mode) or "compdef").
```

Has 18 line(s). Doesn't call other functions.

Uses feature(s): _unfunction_

Called by:

```text
.zinit-debug-stop
.zinit-load-plugin
```

## .zinit-shadow-on

```text 
Turn on shadowing of builtins and functions according to passed
mode ("load", "light", "light-b" or "compdef"). The shadowing is
to gather report data, and to hijack `autoload', `bindkey' and
`compdef' calls.
```

Has 25 line(s). Doesn't call other functions.

Called by:

```text
.zinit-debug-start
.zinit-load-plugin
```

## :zinit-shadow-zle

```text 
Function defined to hijack plugin's calls to `zle' builtin.

The hijacking is to gather report data (which is used in unload).
```

Has 38 line(s). Calls functions:

```text
:zinit-shadow-zle
`-- .zinit-add-report
```

Uses feature(s): _zle_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## :zinit-shadow-zstyle

```text 
Function defined to hijack plugin's calls to `zstyle' builtin.

The hijacking is to gather report data (which is used in unload).
```

Has 21 line(s). Calls functions:

```text
:zinit-shadow-zstyle
`-- .zinit-add-report
```

Uses feature(s): _zparseopts_, _zstyle_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## .zinit-submit-turbo

```text 
If `zinit load`, `zinit light` or `zinit snippet`  will be
preceded with `wait', `load', `unload' or `on-update-of`/`subscribe'
ice-mods then the plugin or snipped is to be loaded in turbo-mode,
and this function adds it to internal data structures, so that
@zinit-scheduler can run (load, unload) this as a task.
```

Has 14 line(s). Doesn't call other functions.

Called by:

```text
zinit
```

## .zinit-unregister-plugin

```text 
Removes the plugin from ZINIT_REGISTERED_PLUGINS array and from the
zsh_loaded_plugins array (managed according to the plugin standard)
```

Has 5 line(s). Calls functions:

```text
.zinit-unregister-plugin
`-- .zinit-any-to-user-plugin
```

Called by:

```text
zinit-autoload.zsh/.zinit-unload
```

## .zinit-wrap-track-functions

Has 19 line(s). Doesn't call other functions.

Uses feature(s): _eval_

Called by:

```text
.zinit-load-plugin
.zinit-load-snippet
```

## zinit

```text 
Main function directly exposed to user, obtains subcommand and its
arguments, has completion.
```

Has 290 line(s). Calls functions:

```text
zinit
|-- compinit
|-- .zinit-clear-debug-report
|   `-- zinit-autoload.zsh/.zinit-clear-report-for
|-- .zinit-compdef-clear
|-- .zinit-compdef-replay
|-- .zinit-debug-start
|   |-- .zinit-diff
|   |   |-- .zinit-diff-env
|   |   |-- .zinit-diff-functions
|   |   |-- .zinit-diff-options
|   |   `-- .zinit-diff-parameter
|   `-- .zinit-shadow-on
|-- .zinit-debug-stop
|   |-- .zinit-diff
|   |   |-- .zinit-diff-env
|   |   |-- .zinit-diff-functions
|   |   |-- .zinit-diff-options
|   |   `-- .zinit-diff-parameter
|   `-- .zinit-shadow-off
|-- .zinit-debug-unload
|   `-- zinit-autoload.zsh/.zinit-unload
|-- .zinit-ice
|-- .zinit-load
|   |-- .zinit-any-to-user-plugin
|   |-- .zinit-deploy-message
|   |-- .zinit-load-plugin
|   |   |-- .zinit-add-report
|   |   |-- .zinit-diff
|   |   |   |-- .zinit-diff-env
|   |   |   |-- .zinit-diff-functions
|   |   |   |-- .zinit-diff-options
|   |   |   `-- .zinit-diff-parameter
|   |   |-- .zinit-diff-env
|   |   |-- .zinit-find-other-matches
|   |   |-- .zinit-shadow-off
|   |   |-- .zinit-shadow-on
|   |   `-- .zinit-wrap-track-functions
|   |-- .zinit-pack-ice
|   |-- .zinit-register-plugin
|   `-- zinit-install.zsh/.zinit-setup-plugin-dir
|-- .zinit-load-snippet
|   |-- .zinit-deploy-message
|   |-- .zinit-pack-ice
|   |-- .zinit-wrap-track-functions
|   `-- zinit-install.zsh/.zinit-download-snippet
|-- .zinit-submit-turbo
|-- zinit-autoload.zsh/.zinit-cdisable
|-- zinit-autoload.zsh/.zinit-cenable
|-- zinit-autoload.zsh/.zinit-clear-completions
|-- zinit-autoload.zsh/.zinit-compiled
|-- zinit-autoload.zsh/.zinit-compile-uncompile-all
|-- zinit-autoload.zsh/.zinit-compinit
|-- zinit-autoload.zsh/.zinit-help
|-- zinit-autoload.zsh/.zinit-list-bindkeys
|-- zinit-autoload.zsh/.zinit-list-compdef-replay
|-- zinit-autoload.zsh/.zinit-ls
|-- zinit-autoload.zsh/.zinit-module
|-- zinit-autoload.zsh/.zinit-recently
|-- zinit-autoload.zsh/.zinit-search-completions
|-- zinit-autoload.zsh/.zinit-self-update
|-- zinit-autoload.zsh/.zinit-show-all-reports
|-- zinit-autoload.zsh/.zinit-show-completions
|-- zinit-autoload.zsh/.zinit-show-debug-report
|-- zinit-autoload.zsh/.zinit-show-registered-plugins
|-- zinit-autoload.zsh/.zinit-show-report
|-- zinit-autoload.zsh/.zinit-show-times
|-- zinit-autoload.zsh/.zinit-show-zstatus
|-- zinit-autoload.zsh/.zinit-uncompile-plugin
|-- zinit-autoload.zsh/.zinit-uninstall-completions
|-- zinit-autoload.zsh/.zinit-unload
|-- zinit-autoload.zsh/.zinit-update-or-status
|-- zinit-autoload.zsh/.zinit-update-or-status-all
|-- zinit-install.zsh/.zinit-compile-plugin
|-- zinit-install.zsh/.zinit-forget-completion
`-- zinit-install.zsh/.zinit-install-completions
```

Uses feature(s): _autoload_, _eval_, _source_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## -zinit_scheduler_add_sh

```text 
Copies task into ZINIT_RUN array, called when a task timeouts.
A small function ran from pattern in /-substitution as a math
function.
```

Has 7 line(s). Doesn't call other functions.

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## add-zsh-hook

Has 93 line(s). Doesn't call other functions.

Uses feature(s): _autoload_, _getopts_

Called by:

```text
Script-Body
@zinit-scheduler
```

## compinit

Has 549 line(s). Doesn't call other functions.

Uses feature(s): _autoload_, _bindkey_, _eval_, _read_, _unfunction_, _zle_, _zstyle_

Called by:

```text
zpcompinit
zinit
```

## is-at-least

Has 56 line(s). Doesn't call other functions.

Called by:

```text
Script-Body
:zinit-shadow-bindkey
```

