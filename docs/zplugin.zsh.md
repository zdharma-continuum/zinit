zplugin.zsh(1)
==============

NAME
----
zplugin.zsh - a shell script

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
-zplg-add-report
-zplg-any-to-user-plugin
-zplg-clear-debug-report
-zplg-compdef-clear
-zplg-compdef-replay
-zplg-debug-start
-zplg-debug-stop
-zplg-debug-unload
-zplg-deploy-message
-zplg-diff
-zplg-diff-env
-zplg-diff-functions
-zplg-diff-options
-zplg-diff-parameter
-zplg-find-other-matches
-zplg-ice
-zplg-load
-zplg-load-plugin
-zplg-load-snippet
-zplg-pack-ice
-zplg-prepare-home
-zplg-register-plugin
@zplg-register-z-plugin
--zplg-reload-and-run
-zplg-run-task
-zplg-service
--zplg-shadow-alias
--zplg-shadow-autoload
--zplg-shadow-bindkey
--zplg-shadow-compdef
-zplg-shadow-off
-zplg-shadow-on
--zplg-shadow-zle
--zplg-shadow-zstyle
-zplg-submit-turbo
-zplg-unregister-plugin
-zplg-wrap-track-functions
zplugin
-zplugin_scheduler_add_sh
AUTOLOAD add-zsh-hook
AUTOLOAD compinit
AUTOLOAD is-at-least
PRECMD-HOOK -zplg-scheduler
```

DETAILS
-------

## Script Body

Has 117 line(s). Calls functions:

```text
Script-Body
|-- add-zsh-hook
|-- is-at-least
`-- -zplg-prepare-home
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
`-- -zplg-load-snippet
|-- -zplg-deploy-message
|-- -zplg-pack-ice
|-- -zplg-wrap-track-functions
`-- zplugin-install.zsh/-zplg-download-snippet
```

Uses feature(s): _zstyle_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## zpcdclear

```text 
A wrapper for `zplugin cdclear -q' which can be called from hook
ices like the atinit'', atload'', etc. ices.
```

Has 1 line(s). Calls functions:

```text
zpcdclear
`-- -zplg-compdef-clear
```

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## zpcdreplay

```text 
A function that can be invoked from within `atinit', `atload', etc.
ice-mod.  It works like `zplugin cdreplay', which cannot be invoked
from such hook ices.
```

Has 1 line(s). Calls functions:

```text
zpcdreplay
`-- -zplg-compdef-replay
```

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## zpcompdef

```text 
Stores compdef for a replay with `zpcdreplay' (turbo mode) or
with `zplugin cdreplay' (normal mode). An utility functton of
an undefined use case.
```

Has 1 line(s). Doesn't call other functions.

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## zpcompinit

```text 
A function that can be invoked from within `atinit', `atload', etc.
ice-mod.  It runs `autoload compinit; compinit' and respects
ZPLGM[ZCOMPDUMP_PATH] and ZPLGM[COMPINIT_OPTS].
```

Has 1 line(s). Calls functions:

```text
zpcompinit
`-- compinit
```

Uses feature(s): _autoload_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## -zplg-add-report

```text
Adds a report line for given plugin.

$1 - uspl2, i.e. user/plugin
$2, ... - the text
```

Has 2 line(s). Doesn't call other functions.

Called by:

```text
-zplg-load-plugin
--zplg-shadow-alias
--zplg-shadow-autoload
--zplg-shadow-bindkey
--zplg-shadow-compdef
--zplg-shadow-zle
--zplg-shadow-zstyle
```

## -zplg-any-to-user-plugin

```text
Allows elastic plugin-spec across the code.

$1 - plugin spec (2 formats: user/plugin, user plugin)
$2 - plugin (only when $1 - i.e. user - given)

Returns user and plugin in $reply
```
Has 23 line(s). Doesn't call other functions.

Called by:

```text
-zplg-load
-zplg-unregister-plugin
zplugin-autoload.zsh/-zplg-any-to-uspl2
zplugin-autoload.zsh/-zplg-changes
zplugin-autoload.zsh/-zplg-compiled
zplugin-autoload.zsh/-zplg-compile-uncompile-all
zplugin-autoload.zsh/-zplg-compute-ice
zplugin-autoload.zsh/-zplg-create
zplugin-autoload.zsh/-zplg-delete
zplugin-autoload.zsh/-zplg-edit
zplugin-autoload.zsh/-zplg-find-completions-of-plugin
zplugin-autoload.zsh/-zplg-get-path
zplugin-autoload.zsh/-zplg-glance
zplugin-autoload.zsh/-zplg-show-report
zplugin-autoload.zsh/-zplg-stress
zplugin-autoload.zsh/-zplg-uncompile-plugin
zplugin-autoload.zsh/-zplg-unload
zplugin-autoload.zsh/-zplg-update-or-status-all
zplugin-autoload.zsh/-zplg-update-or-status
zplugin-install.zsh/-zplg-compile-plugin
zplugin-install.zsh/-zplg-get-latest-gh-r-version
zplugin-install.zsh/-zplg-install-completions
zplugin-side.zsh/-zplg-any-colorify-as-uspl2
zplugin-side.zsh/-zplg-exists-physically
zplugin-side.zsh/-zplg-first
```

## -zplg-clear-debug-report

```text 
Forgets dtrace repport gathered up to this moment.
```

Has 1 line(s). Calls functions:

```text
-zplg-clear-debug-report
`-- zplugin-autoload.zsh/-zplg-clear-report-for
```

Called by:

```text
zplugin
zplugin-autoload.zsh/-zplg-unload
```

## -zplg-compdef-clear

```text 
Implements user-exposed functionality to clear gathered compdefs.
```

Has 3 line(s). Doesn't call other functions.

Called by:

```text
zpcdclear
zplugin
```

## -zplg-compdef-replay

```text 
Runs gathered compdef calls. This allows to run `compinit'
after loading plugins.
```

Has 16 line(s). Doesn't call other functions.

Called by:

```text
zpcdreplay
zplugin
```

## -zplg-debug-start

```text 
Starts Dtrace, i.e. session tracking for changes in Zsh state.
```

Has 9 line(s). Calls functions:

```text
-zplg-debug-start
|-- -zplg-diff
|   |-- -zplg-diff-env
|   |-- -zplg-diff-functions
|   |-- -zplg-diff-options
|   `-- -zplg-diff-parameter
`-- -zplg-shadow-on
```

Called by:

```text
zplugin
```

## -zplg-debug-stop

```text 
Stops Dtrace, i.e. session tracking for changes in Zsh state.
```

Has 3 line(s). Calls functions:

```text
-zplg-debug-stop
|-- -zplg-diff
|   |-- -zplg-diff-env
|   |-- -zplg-diff-functions
|   |-- -zplg-diff-options
|   `-- -zplg-diff-parameter
`-- -zplg-shadow-off
```

Called by:

```text
zplugin
```

## -zplg-debug-unload

```text 
Reverts changes detected by dtrace run.
```

Has 5 line(s). Calls functions:

```text
-zplg-debug-unload
`-- zplugin-autoload.zsh/-zplg-unload
```

Called by:

```text
zplugin
```

## -zplg-deploy-message

```text 
Deploys a sub-prompt message to be displayed OR a `zle
.reset-prompt' call to be invoked
```

Has 12 line(s). Doesn't call other functions.

Uses feature(s): _read_, _zle_

Called by:

```text
-zplg-load-snippet
-zplg-load
```

## -zplg-diff

```text 
Performs diff actions of all types
```

Has 4 line(s). Calls functions:

```text
-zplg-diff
|-- -zplg-diff-env
|-- -zplg-diff-functions
|-- -zplg-diff-options
`-- -zplg-diff-parameter
```

Called by:

```text
-zplg-debug-start
-zplg-debug-stop
-zplg-load-plugin
```

## -zplg-diff-env

```text 
Implements detection of change in PATH and FPATH.

$1 - user/plugin (i.e. uspl2 format)
$2 - command, can be "begin" or "end"
```

Has 18 line(s). Doesn't call other functions.

Called by:

```text
-zplg-diff
-zplg-load-plugin
```

## -zplg-diff-functions

```text 
Implements detection of newly created functions. Performs
data gathering, computation is done in *-compute().

$1 - user/plugin (i.e. uspl2 format)
$2 - command, can be "begin" or "end"
```

Has 8 line(s). Doesn't call other functions.

Called by:

```text
-zplg-diff
```

## -zplg-diff-options

```text 
Implements detection of change in option state. Performs
data gathering, computation is done in *-compute().

$1 - user/plugin (i.e. uspl2 format)
$2 - command, can be "begin" or "end"
```

Has 7 line(s). Doesn't call other functions.

Called by:

```text
-zplg-diff
```

## -zplg-diff-parameter

```text 
Implements detection of change in any parameter's existence and type.
Performs data gathering, computation is done in *-compute().

$1 - user/plugin (i.e. uspl2 format)
$2 - command, can be "begin" or "end"
```

Has 9 line(s). Doesn't call other functions.

Called by:

```text
-zplg-diff
```

## -zplg-find-other-matches

```text 
Plugin's main source file is in general `name.plugin.zsh'. However,
there can be different conventions, if that file is not found, then
this functions examines other conventions in order of most expected
sanity.
```

Has 14 line(s). Doesn't call other functions.

Called by:

```text
-zplg-load-plugin
zplugin-side.zsh/-zplg-first
```

## -zplg-ice

```text 
Parses ICE specification (`zplg ice' subcommand), puts the result
into ZPLG_ICE global hash. The ice-spec is valid for next command
only (i.e. it "melts"), but it can then stick to plugin and activate
e.g. at update.
```

Has 8 line(s). Doesn't call other functions.

Called by:

```text
zplugin
```

_Environment variables used:_ ZPFX

## -zplg-load

```text 
Implements the exposed-to-user action of loading a plugin.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin name, if the third format is used
```

Has 42 line(s). Calls functions:

```text
-zplg-load
|-- -zplg-any-to-user-plugin
|-- -zplg-deploy-message
|-- -zplg-load-plugin
|   |-- -zplg-add-report
|   |-- -zplg-diff
|   |   |-- -zplg-diff-env
|   |   |-- -zplg-diff-functions
|   |   |-- -zplg-diff-options
|   |   `-- -zplg-diff-parameter
|   |-- -zplg-diff-env
|   |-- -zplg-find-other-matches
|   |-- -zplg-shadow-off
|   |-- -zplg-shadow-on
|   `-- -zplg-wrap-track-functions
|-- -zplg-pack-ice
|-- -zplg-register-plugin
`-- zplugin-install.zsh/-zplg-setup-plugin-dir
```

Uses feature(s): _eval_, _source_, _zle_

Called by:

```text
-zplg-run-task
-zplg-service
zplugin
```

## -zplg-load-plugin

```text 
Lower-level function for loading a plugin.

$1 - user
$2 - plugin
$3 - mode (light or load)
```

Has 96 line(s). Calls functions:

```text
-zplg-load-plugin
|-- -zplg-add-report
|-- -zplg-diff
|   |-- -zplg-diff-env
|   |-- -zplg-diff-functions
|   |-- -zplg-diff-options
|   `-- -zplg-diff-parameter
|-- -zplg-diff-env
|-- -zplg-find-other-matches
|-- -zplg-shadow-off
|-- -zplg-shadow-on
`-- -zplg-wrap-track-functions
```

Uses feature(s): _eval_, _source_, _zle_

Called by:

```text
-zplg-load
```

## -zplg-load-snippet

```text 
Implements the exposed-to-user action of loading a snippet.

$1 - url (can be local, absolute path)
```

Has 180 line(s). Calls functions:

```text
-zplg-load-snippet
|-- -zplg-deploy-message
|-- -zplg-pack-ice
|-- -zplg-wrap-track-functions
`-- zplugin-install.zsh/-zplg-download-snippet
```

Uses feature(s): _autoload_, _eval_, _source_, _unfunction_, _zparseopts_, _zstyle_

Called by:

```text
pmodload
-zplg-run-task
-zplg-service
zplugin
zplugin-autoload.zsh/-zplg-update-or-status-snippet
```

## -zplg-pack-ice

```text 
Remembers all ice-mods, assigns them to concrete plugin. Ice spec
is in general forgotten for second-next command (that's why it's
called "ice" - it melts), however they glue to the object (plugin
or snippet) mentioned in the next command – for later use with e.g.
`zplugin update ...'
```

Has 3 line(s). Doesn't call other functions.

Called by:

```text
-zplg-load-snippet
-zplg-load
zplugin-autoload.zsh/-zplg-compute-ice
```

## -zplg-prepare-home

```text 
Creates all directories needed by Zplugin, first checks if they
already exist.
```

Has 28 line(s). Doesn't call other functions.

Called by:

```text
Script-Body
```

_Environment variables used:_ ZPFX

## -zplg-register-plugin

```text 
Adds the plugin to ZPLG_REGISTERED_PLUGINS array and to the
zsh_loaded_plugins array (managed according to the plugin standard:
http://zdharma.org/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html)
```

Has 23 line(s). Doesn't call other functions.

Called by:

```text
-zplg-load
```

## @zplg-register-z-plugin

```text 
Registers the z-plugin inside Zplugin – i.e. an Zplugin extension
```

Has 4 line(s). Doesn't call other functions.

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## --zplg-reload-and-run

```text 
Marks given function ($3) for autoloading, and executes it triggering the
load. $1 is the fpath dedicated to the function, $2 are autoload options.
This function replaces "autoload -X", because using that on older Zsh
versions causes problems with traps.

So basically one creates function stub that calls --zplg-reload-and-run()
instead of "autoload -X".

$1 - FPATH dedicated to function
$2 - autoload options
$3 - function name (one that needs autoloading)

Author: Bart Schaefer
```

Has 7 line(s). Doesn't call other functions.

Uses feature(s): _autoload_, _unfunction_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## -zplg-run-task

```text 
A backend, worker function of -zplg-scheduler. It obtains the tasks
index and a few of its properties (like the type: plugin, snippet,
service plugin, service snippet) and executes it first checking for
additional conditions (like non-numeric wait'' ice).

$1 - the pass number, either 1st or 2nd pass
$2 - the time assigned to the task
$3 - type: plugin, snippet, service plugin, service snippet
$4 - task's index in the ZPLGM[WAIT_ICE_...] fields
$5 - mode: load or light
$6 - the plugin-spec or snippet URL or alias name (from id-as'')
```

Has 41 line(s). Calls functions:

```text
-zplg-run-task
|-- -zplg-load
|   |-- -zplg-any-to-user-plugin
|   |-- -zplg-deploy-message
|   |-- -zplg-load-plugin
|   |   |-- -zplg-add-report
|   |   |-- -zplg-diff
|   |   |   |-- -zplg-diff-env
|   |   |   |-- -zplg-diff-functions
|   |   |   |-- -zplg-diff-options
|   |   |   `-- -zplg-diff-parameter
|   |   |-- -zplg-diff-env
|   |   |-- -zplg-find-other-matches
|   |   |-- -zplg-shadow-off
|   |   |-- -zplg-shadow-on
|   |   `-- -zplg-wrap-track-functions
|   |-- -zplg-pack-ice
|   |-- -zplg-register-plugin
|   `-- zplugin-install.zsh/-zplg-setup-plugin-dir
|-- -zplg-load-snippet
|   |-- -zplg-deploy-message
|   |-- -zplg-pack-ice
|   |-- -zplg-wrap-track-functions
|   `-- zplugin-install.zsh/-zplg-download-snippet
`-- zplugin-autoload.zsh/-zplg-unload
```

Uses feature(s): _eval_, _source_, _zle_, _zpty_

Called by:

```text
-zplg-scheduler
```

## -zplg-scheduler

```text 
Searches for timeout tasks, executes them. There's an array of tasks
waiting for execution, this scheduler manages them, detects which ones
should be run at current moment, decides to remove (or not) them from
the array after execution.

$1 - if "following", then it is non-first (second and more)
invocation of the scheduler; this results in chain of `sched'
invocations that results in repetitive -zplg-scheduler activity

if "burst", then all tasks are marked timeout and executed one
by one; this is handy if e.g. a docker image starts up and
needs to install all turbo-mode plugins without any hesitation
(delay), i.e. "burst" allows to run package installations from
script, not from prompt
```

Has 62 line(s). *Is a precmd hook*. Calls functions:

```text
-zplg-scheduler
|-- add-zsh-hook
`-- -zplg-run-task
|-- -zplg-load
|   |-- -zplg-any-to-user-plugin
|   |-- -zplg-deploy-message
|   |-- -zplg-load-plugin
|   |   |-- -zplg-add-report
|   |   |-- -zplg-diff
|   |   |   |-- -zplg-diff-env
|   |   |   |-- -zplg-diff-functions
|   |   |   |-- -zplg-diff-options
|   |   |   `-- -zplg-diff-parameter
|   |   |-- -zplg-diff-env
|   |   |-- -zplg-find-other-matches
|   |   |-- -zplg-shadow-off
|   |   |-- -zplg-shadow-on
|   |   `-- -zplg-wrap-track-functions
|   |-- -zplg-pack-ice
|   |-- -zplg-register-plugin
|   `-- zplugin-install.zsh/-zplg-setup-plugin-dir
|-- -zplg-load-snippet
|   |-- -zplg-deploy-message
|   |-- -zplg-pack-ice
|   |-- -zplg-wrap-track-functions
|   `-- zplugin-install.zsh/-zplg-download-snippet
`-- zplugin-autoload.zsh/-zplg-unload
```

Uses feature(s): _sched_, _zle_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## -zplg-service

```text 
Handles given service, i.e. obtains lock, runs it, or waits if no lock

$1 - type "p" or "s" (plugin or snippet)
$2 - mode - for plugin (light or load)
$3 - id - URL or plugin ID or alias name (from id-as'')
```

Has 30 line(s). Calls functions:

```text
-zplg-service
|-- -zplg-load
|   |-- -zplg-any-to-user-plugin
|   |-- -zplg-deploy-message
|   |-- -zplg-load-plugin
|   |   |-- -zplg-add-report
|   |   |-- -zplg-diff
|   |   |   |-- -zplg-diff-env
|   |   |   |-- -zplg-diff-functions
|   |   |   |-- -zplg-diff-options
|   |   |   `-- -zplg-diff-parameter
|   |   |-- -zplg-diff-env
|   |   |-- -zplg-find-other-matches
|   |   |-- -zplg-shadow-off
|   |   |-- -zplg-shadow-on
|   |   `-- -zplg-wrap-track-functions
|   |-- -zplg-pack-ice
|   |-- -zplg-register-plugin
|   `-- zplugin-install.zsh/-zplg-setup-plugin-dir
`-- -zplg-load-snippet
|-- -zplg-deploy-message
|-- -zplg-pack-ice
|-- -zplg-wrap-track-functions
`-- zplugin-install.zsh/-zplg-download-snippet
```

Uses feature(s): _kill_, _read_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## --zplg-shadow-alias

```text 
Function defined to hijack plugin's calls to `alias' builtin.

The hijacking is to gather report data (which is used in unload).
```

Has 34 line(s). Calls functions:

```text
--zplg-shadow-alias
`-- -zplg-add-report
```

Uses feature(s): _alias_, _zparseopts_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## --zplg-shadow-autoload

```text 
Function defined to hijack plugin's calls to `autoload' builtin.

The hijacking is not only to gather report data, but also to
run custom `autoload' function, that doesn't need FPATH.
```

Has 48 line(s). Calls functions:

```text
--zplg-shadow-autoload
`-- -zplg-add-report
```

Uses feature(s): _autoload_, _eval_, _zparseopts_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## --zplg-shadow-bindkey

```text 
Function defined to hijack plugin's calls to `bindkey' builtin.

The hijacking is to gather report data (which is used in unload).
```

Has 104 line(s). Calls functions:

```text
--zplg-shadow-bindkey
|-- is-at-least
`-- -zplg-add-report
```

Uses feature(s): _bindkey_, _zparseopts_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## --zplg-shadow-compdef

```text 
Function defined to hijack plugin's calls to `compdef' function.
The hijacking is not only for reporting, but also to save compdef
calls so that `compinit' can be called after loading plugins.
```

Has 4 line(s). Calls functions:

```text
--zplg-shadow-compdef
`-- -zplg-add-report
```

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## -zplg-shadow-off

```text 
Turn off shadowing completely for a given mode ("load", "light",
"light-b" (i.e. the `trackbinds' mode) or "compdef").
```

Has 18 line(s). Doesn't call other functions.

Uses feature(s): _unfunction_

Called by:

```text
-zplg-debug-stop
-zplg-load-plugin
```

## -zplg-shadow-on

```text 
Turn on shadowing of builtins and functions according to passed
mode ("load", "light", "light-b" or "compdef"). The shadowing is
to gather report data, and to hijack `autoload', `bindkey' and
`compdef' calls.
```

Has 25 line(s). Doesn't call other functions.

Called by:

```text
-zplg-debug-start
-zplg-load-plugin
```

## --zplg-shadow-zle

```text 
Function defined to hijack plugin's calls to `zle' builtin.

The hijacking is to gather report data (which is used in unload).
```

Has 38 line(s). Calls functions:

```text
--zplg-shadow-zle
`-- -zplg-add-report
```

Uses feature(s): _zle_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## --zplg-shadow-zstyle

```text 
Function defined to hijack plugin's calls to `zstyle' builtin.

The hijacking is to gather report data (which is used in unload).
```

Has 21 line(s). Calls functions:

```text
--zplg-shadow-zstyle
`-- -zplg-add-report
```

Uses feature(s): _zparseopts_, _zstyle_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## -zplg-submit-turbo

```text 
If `zplugin load`, `zplugin light` or `zplugin snippet`  will be
preceded with `wait', `load', `unload' or `on-update-of`/`subscribe'
ice-mods then the plugin or snipped is to be loaded in turbo-mode,
and this function adds it to internal data structures, so that
-zplg-scheduler can run (load, unload) this as a task.
```

Has 14 line(s). Doesn't call other functions.

Called by:

```text
zplugin
```

## -zplg-unregister-plugin

```text 
Removes the plugin from ZPLG_REGISTERED_PLUGINS array and from the
zsh_loaded_plugins array (managed according to the plugin standard)
```

Has 5 line(s). Calls functions:

```text
-zplg-unregister-plugin
`-- -zplg-any-to-user-plugin
```

Called by:

```text
zplugin-autoload.zsh/-zplg-unload
```

## -zplg-wrap-track-functions

Has 19 line(s). Doesn't call other functions.

Uses feature(s): _eval_

Called by:

```text
-zplg-load-plugin
-zplg-load-snippet
```

## zplugin

```text 
Main function directly exposed to user, obtains subcommand and its
arguments, has completion.
```

Has 290 line(s). Calls functions:

```text
zplugin
|-- compinit
|-- -zplg-clear-debug-report
|   `-- zplugin-autoload.zsh/-zplg-clear-report-for
|-- -zplg-compdef-clear
|-- -zplg-compdef-replay
|-- -zplg-debug-start
|   |-- -zplg-diff
|   |   |-- -zplg-diff-env
|   |   |-- -zplg-diff-functions
|   |   |-- -zplg-diff-options
|   |   `-- -zplg-diff-parameter
|   `-- -zplg-shadow-on
|-- -zplg-debug-stop
|   |-- -zplg-diff
|   |   |-- -zplg-diff-env
|   |   |-- -zplg-diff-functions
|   |   |-- -zplg-diff-options
|   |   `-- -zplg-diff-parameter
|   `-- -zplg-shadow-off
|-- -zplg-debug-unload
|   `-- zplugin-autoload.zsh/-zplg-unload
|-- -zplg-ice
|-- -zplg-load
|   |-- -zplg-any-to-user-plugin
|   |-- -zplg-deploy-message
|   |-- -zplg-load-plugin
|   |   |-- -zplg-add-report
|   |   |-- -zplg-diff
|   |   |   |-- -zplg-diff-env
|   |   |   |-- -zplg-diff-functions
|   |   |   |-- -zplg-diff-options
|   |   |   `-- -zplg-diff-parameter
|   |   |-- -zplg-diff-env
|   |   |-- -zplg-find-other-matches
|   |   |-- -zplg-shadow-off
|   |   |-- -zplg-shadow-on
|   |   `-- -zplg-wrap-track-functions
|   |-- -zplg-pack-ice
|   |-- -zplg-register-plugin
|   `-- zplugin-install.zsh/-zplg-setup-plugin-dir
|-- -zplg-load-snippet
|   |-- -zplg-deploy-message
|   |-- -zplg-pack-ice
|   |-- -zplg-wrap-track-functions
|   `-- zplugin-install.zsh/-zplg-download-snippet
|-- -zplg-submit-turbo
|-- zplugin-autoload.zsh/-zplg-cdisable
|-- zplugin-autoload.zsh/-zplg-cenable
|-- zplugin-autoload.zsh/-zplg-clear-completions
|-- zplugin-autoload.zsh/-zplg-compiled
|-- zplugin-autoload.zsh/-zplg-compile-uncompile-all
|-- zplugin-autoload.zsh/-zplg-compinit
|-- zplugin-autoload.zsh/-zplg-help
|-- zplugin-autoload.zsh/-zplg-list-bindkeys
|-- zplugin-autoload.zsh/-zplg-list-compdef-replay
|-- zplugin-autoload.zsh/-zplg-ls
|-- zplugin-autoload.zsh/-zplg-module
|-- zplugin-autoload.zsh/-zplg-recently
|-- zplugin-autoload.zsh/-zplg-search-completions
|-- zplugin-autoload.zsh/-zplg-self-update
|-- zplugin-autoload.zsh/-zplg-show-all-reports
|-- zplugin-autoload.zsh/-zplg-show-completions
|-- zplugin-autoload.zsh/-zplg-show-debug-report
|-- zplugin-autoload.zsh/-zplg-show-registered-plugins
|-- zplugin-autoload.zsh/-zplg-show-report
|-- zplugin-autoload.zsh/-zplg-show-times
|-- zplugin-autoload.zsh/-zplg-show-zstatus
|-- zplugin-autoload.zsh/-zplg-uncompile-plugin
|-- zplugin-autoload.zsh/-zplg-uninstall-completions
|-- zplugin-autoload.zsh/-zplg-unload
|-- zplugin-autoload.zsh/-zplg-update-or-status
|-- zplugin-autoload.zsh/-zplg-update-or-status-all
|-- zplugin-install.zsh/-zplg-compile-plugin
|-- zplugin-install.zsh/-zplg-forget-completion
`-- zplugin-install.zsh/-zplg-install-completions
```

Uses feature(s): _autoload_, _eval_, _source_

Not called by script or any function (may be e.g. a hook, a Zle widget, etc.).

## -zplugin_scheduler_add_sh

```text 
Copies task into ZPLG_RUN array, called when a task timeouts.
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
-zplg-scheduler
```

## compinit

Has 549 line(s). Doesn't call other functions.

Uses feature(s): _autoload_, _bindkey_, _eval_, _read_, _unfunction_, _zle_, _zstyle_

Called by:

```text
zpcompinit
zplugin
```

## is-at-least

Has 56 line(s). Doesn't call other functions.

Called by:

```text
Script-Body
--zplg-shadow-bindkey
```

