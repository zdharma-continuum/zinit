# NAME

zplugin.zsh - a shell script

# SYNOPSIS

Documentation automatically generated with \`zshelldoc'

# FUNCTIONS

``` 
 --zplg-reload-and-run
 --zplg-shadow-alias
 --zplg-shadow-autoload
 --zplg-shadow-bindkey
 --zplg-shadow-compdef
 --zplg-shadow-zle
 --zplg-shadow-zstyle
 -zplg-add-report
 -zplg-any-to-user-plugin
 -zplg-clear-debug-report
 -zplg-compdef-clear
 -zplg-compdef-replay
 -zplg-debug-start
 -zplg-debug-stop
 -zplg-debug-unload
 -zplg-deploy-message
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
 -zplg-run-task
 -zplg-service
 -zplg-shadow-off
 -zplg-shadow-on
 -zplg-submit-turbo
 -zplg-unregister-plugin
 -zplugin_scheduler_add_sh
 @zplg-register-z-plugin
 pmodload
 zpcdclear
 zpcdreplay
 zpcompdef
 zpcompinit
 zplugin
AUTOLOAD add-zsh-hook
AUTOLOAD compinit
AUTOLOAD is-at-least
PRECMD-HOOK -zplg-scheduler
```

# DETAILS

## Script Body

Has 137 line(s). Calls functions:

    Script-Body
    |-- -zplg-prepare-home
    |-- add-zsh-hook
    `-- is-at-least

Uses feature(s): *alias*, *autoload*, *export*, *zmodload*, *zstyle*

*Exports (environment):* ZPFX

## \--zplg-reload-and-run

> 
> 
>     Marks given function ($3) for autoloading, and executes it triggering the
>     load. $1 is the fpath dedicated to the function, $2 are autoload options.
>     This function replaces "autoload -X", because using that on older Zsh
>     versions causes problems with traps.
> 
>     So basically one creates function stub that calls --zplg-reload-and-run()
>     instead of "autoload -X".
> 
>     $1 - FPATH dedicated to function
>     $2 - autoload options
>     $3 - function name (one that needs autoloading)
> 
>     Author: Bart Schaefer

Has 7 line(s). Doesn’t call other functions.

Uses feature(s): *autoload*, *unfunction*

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## \--zplg-shadow-alias

> 
> 
>     Function defined to hijack plugin's calls to `alias' builtin.
> 
>     The hijacking is to gather report data (which is used in unload).

Has 39 line(s). Calls functions:

    --zplg-shadow-alias
    `-- -zplg-add-report

Uses feature(s): *alias*, *unfunction*, *zparseopts*

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## \--zplg-shadow-autoload

> 
> 
>     Function defined to hijack plugin's calls to `autoload' builtin.
> 
>     The hijacking is not only to gather report data, but also to
>     run custom `autoload' function, that doesn't need FPATH.

Has 45 line(s). Calls functions:

    --zplg-shadow-autoload
    `-- -zplg-add-report

Uses feature(s): *autoload*, *eval*, *zparseopts*

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## \--zplg-shadow-bindkey

> 
> 
>     Function defined to hijack plugin's calls to `bindkey' builtin.
> 
>     The hijacking is to gather report data (which is used in unload).

Has 108 line(s). Calls functions:

    --zplg-shadow-bindkey
    `-- -zplg-add-report

Uses feature(s): *bindkey*, *unfunction*, *zparseopts*

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## \--zplg-shadow-compdef

> 
> 
>     Function defined to hijack plugin's calls to `compdef' function.
>     The hijacking is not only for reporting, but also to save compdef
>     calls so that `compinit' can be called after loading plugins.

Has 4 line(s). Calls functions:

    --zplg-shadow-compdef
    `-- -zplg-add-report

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## \--zplg-shadow-zle

> 
> 
>     Function defined to hijack plugin's calls to `zle' builtin.
> 
>     The hijacking is to gather report data (which is used in unload).

Has 40 line(s). Calls functions:

    --zplg-shadow-zle
    `-- -zplg-add-report

Uses feature(s): *unfunction*, *zle*

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## \--zplg-shadow-zstyle

> 
> 
>     Function defined to hijack plugin's calls to `zstyle' builtin.
> 
>     The hijacking is to gather report data (which is used in unload).

Has 26 line(s). Calls functions:

    --zplg-shadow-zstyle
    `-- -zplg-add-report

Uses feature(s): *unfunction*, *zparseopts*, *zstyle*

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## \-zplg-add-report

> 
> 
>     Adds a report line for given plugin.
> 
>     $1 - uspl2, i.e. user/plugin
>     $2, … - the text

Has 2 line(s). Doesn’t call other functions.

Called by:

    --zplg-shadow-alias
    --zplg-shadow-autoload
    --zplg-shadow-bindkey
    --zplg-shadow-compdef
    --zplg-shadow-zle
    --zplg-shadow-zstyle
    -zplg-load-plugin

## \-zplg-any-to-user-plugin

> 
> 
>     Allows elastic plugin-spec across the code.
> 
>     $1 - plugin spec (2 formats: user/plugin, user plugin)
>     $2 - plugin (only when $1 - i.e. user - given)
> 
>     Returns user and plugin in $reply

Has 23 line(s). Doesn’t call other functions.

Called by:

    -zplg-load
    -zplg-unregister-plugin
    zplugin-autoload.zsh/-zplg-any-to-uspl2
    zplugin-autoload.zsh/-zplg-changes
    zplugin-autoload.zsh/-zplg-compile-uncompile-all
    zplugin-autoload.zsh/-zplg-compiled
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

## \-zplg-clear-debug-report

> 
> 
>     Forgets dtrace repport gathered up to this moment.

Has 1 line(s). Calls functions:

    -zplg-clear-debug-report
    `-- zplugin-autoload.zsh/-zplg-clear-report-for

Called by:

    zplugin
    zplugin-autoload.zsh/-zplg-unload

## \-zplg-compdef-clear

> 
> 
>     Implements user-exposed functionality to clear gathered compdefs.

Has 3 line(s). Doesn’t call other functions.

Called by:

    zpcdclear
    zplugin

## \-zplg-compdef-replay

> 
> 
>     Runs gathered compdef calls. This allows to run `compinit'
>     after loading plugins.

Has 16 line(s). Doesn’t call other functions.

Called by:

    zpcdreplay
    zplugin

## \-zplg-debug-start

> 
> 
>     Starts Dtrace, i.e. session tracking for changes in Zsh state.

Has 12 line(s). Calls functions:

    -zplg-debug-start
    |-- -zplg-diff-env
    |-- -zplg-diff-functions
    |-- -zplg-diff-options
    |-- -zplg-diff-parameter
    `-- -zplg-shadow-on

Called by:

    zplugin

## \-zplg-debug-stop

> 
> 
>     Stops Dtrace, i.e. session tracking for changes in Zsh state.

Has 6 line(s). Calls functions:

    -zplg-debug-stop
    |-- -zplg-diff-env
    |-- -zplg-diff-functions
    |-- -zplg-diff-options
    |-- -zplg-diff-parameter
    `-- -zplg-shadow-off

Called by:

    zplugin

## \-zplg-debug-unload

> 
> 
>     Reverts changes detected by dtrace run.

Has 5 line(s). Calls functions:

    -zplg-debug-unload
    `-- zplugin-autoload.zsh/-zplg-unload

Called by:

    zplugin

## \-zplg-deploy-message

> 
> 
>     Deploys a sub-prompt message to be displayed OR a `zle
>     .reset-prompt' call to be invoked

Has 11 line(s). Doesn’t call other functions.

Uses feature(s): *read*, *zle*

Called by:

    -zplg-load-snippet
    -zplg-load

## \-zplg-diff-env

> 
> 
>     Implements detection of change in PATH and FPATH.
> 
>     $1 - user/plugin (i.e. uspl2 format)
>     $2 - command, can be "begin" or "end"

Has 17 line(s). Doesn’t call other functions.

Called by:

    -zplg-debug-start
    -zplg-debug-stop
    -zplg-load-plugin

## \-zplg-diff-functions

> 
> 
>     Implements detection of newly created functions. Performs
>     data gathering, computation is done in *-compute().
> 
>     $1 - user/plugin (i.e. uspl2 format)
>     $2 - command, can be "begin" or "end"

Has 5 line(s). Doesn’t call other functions.

Called by:

    -zplg-debug-start
    -zplg-debug-stop
    -zplg-load-plugin

## \-zplg-diff-options

> 
> 
>     Implements detection of change in option state. Performs
>     data gathering, computation is done in *-compute().
> 
>     $1 - user/plugin (i.e. uspl2 format)
>     $2 - command, can be "begin" or "end"

Has 5 line(s). Doesn’t call other functions.

Called by:

    -zplg-debug-start
    -zplg-debug-stop
    -zplg-load-plugin

## \-zplg-diff-parameter

> 
> 
>     Implements detection of change in any parameter's existence and type.
>     Performs data gathering, computation is done in *-compute().
> 
>     $1 - user/plugin (i.e. uspl2 format)
>     $2 - command, can be "begin" or "end"

Has 10 line(s). Doesn’t call other functions.

Called by:

    -zplg-debug-start
    -zplg-debug-stop
    -zplg-load-plugin

## \-zplg-find-other-matches

> 
> 
>     Plugin's main source file is in general `name.plugin.zsh'. However,
>     there can be different conventions, if that file is not found, then
>     this functions examines other conventions in order of most expected
>     sanity.

Has 14 line(s). Doesn’t call other functions.

Called by:

    -zplg-load-plugin
    zplugin-side.zsh/-zplg-first

## \-zplg-ice

> 
> 
>     Parses ICE specification (`zplg ice' subcommand), puts the result
>     into ZPLG_ICE global hash. The ice-spec is valid for next command
>     only (i.e. it "melts"), but it can then stick to plugin and activate
>     e.g. at update.

Has 8 line(s). Doesn’t call other functions.

Called by:

    zplugin

*Environment variables used:* ZPFX

## \-zplg-load

> 
> 
>     Implements the exposed-to-user action of loading a plugin.
> 
>     $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
>     $2 - plugin name, if the third format is used

Has 42 line(s). Calls functions:

    -zplg-load
    |-- -zplg-any-to-user-plugin
    |-- -zplg-deploy-message
    |-- -zplg-load-plugin
    |   |-- -zplg-add-report
    |   |-- -zplg-diff-env
    |   |-- -zplg-diff-functions
    |   |-- -zplg-diff-options
    |   |-- -zplg-diff-parameter
    |   |-- -zplg-find-other-matches
    |   |-- -zplg-shadow-off
    |   `-- -zplg-shadow-on
    |-- -zplg-pack-ice
    |-- -zplg-register-plugin
    `-- zplugin-install.zsh/-zplg-setup-plugin-dir

Uses feature(s): *eval*, *source*, *zle*

Called by:

    -zplg-run-task
    -zplg-service
    zplugin

## \-zplg-load-plugin

> 
> 
>     Lower-level function for loading a plugin.
> 
>     $1 - user
>     $2 - plugin
>     $3 - mode (light or load)

Has 102 line(s). Calls functions:

    -zplg-load-plugin
    |-- -zplg-add-report
    |-- -zplg-diff-env
    |-- -zplg-diff-functions
    |-- -zplg-diff-options
    |-- -zplg-diff-parameter
    |-- -zplg-find-other-matches
    |-- -zplg-shadow-off
    `-- -zplg-shadow-on

Uses feature(s): *eval*, *source*, *zle*

Called by:

    -zplg-load

## \-zplg-load-snippet

> 
> 
>     Implements the exposed-to-user action of loading a snippet.
> 
>     $1 - url (can be local, absolute path)

Has 173 line(s). Calls functions:

    -zplg-load-snippet
    |-- -zplg-deploy-message
    |-- -zplg-pack-ice
    `-- zplugin-install.zsh/-zplg-download-snippet

Uses feature(s): *autoload*, *eval*, *source*, *unfunction*,
*zparseopts*, *zstyle*

Called by:

    -zplg-run-task
    -zplg-service
    pmodload
    zplugin
    zplugin-autoload.zsh/-zplg-update-or-status-snippet

## \-zplg-pack-ice

> 
> 
>     Remembers all ice-mods, assigns them to concrete plugin. Ice spec
>     is in general forgotten for second-next command (that's why it's
>     called "ice" - it melts), however they glue to the object (plugin
>     or snippet) mentioned in the next command – for later use with e.g.
>     `zplugin update …'

Has 3 line(s). Doesn’t call other functions.

Called by:

    -zplg-load-snippet
    -zplg-load
    zplugin-autoload.zsh/-zplg-compute-ice

## \-zplg-prepare-home

> 
> 
>     Creates all directories needed by Zplugin, first checks if they
>     already exist.

Has 25 line(s). Doesn’t call other functions.

Called by:

    Script-Body

*Environment variables used:* ZPFX

## \-zplg-register-plugin

> 
> 
>     Adds the plugin to ZPLG_REGISTERED_PLUGINS array and to the
>     LOADED_PLUGINS array (managed according to the plugin standard:
>     http://zdharma.org/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html)

Has 19 line(s). Doesn’t call other functions.

Called by:

    -zplg-load

## \-zplg-run-task

> 
> 
>     A backend, worker function of -zplg-scheduler. It obtains the tasks
>     index and a few of its properties (like the type: plugin, snippet,
>     service plugin, service snippet) and executes it first checking for
>     additional conditions (like non-numeric wait'' ice).
> 
>     $1 - the pass number, either 1st or 2nd pass
>     $2 - the time assigned to the task
>     $3 - type: plugin, snippet, service plugin, service snippet
>     $4 - task's index in the ZPLGM[WAIT_ICE_…] fields
>     $5 - mode: load or light
>     $6 - the plugin-spec or snippet URL or alias name (from id-as'')

Has 40 line(s). Calls functions:

    -zplg-run-task
    |-- -zplg-load
    |   |-- -zplg-any-to-user-plugin
    |   |-- -zplg-deploy-message
    |   |-- -zplg-load-plugin
    |   |   |-- -zplg-add-report
    |   |   |-- -zplg-diff-env
    |   |   |-- -zplg-diff-functions
    |   |   |-- -zplg-diff-options
    |   |   |-- -zplg-diff-parameter
    |   |   |-- -zplg-find-other-matches
    |   |   |-- -zplg-shadow-off
    |   |   `-- -zplg-shadow-on
    |   |-- -zplg-pack-ice
    |   |-- -zplg-register-plugin
    |   `-- zplugin-install.zsh/-zplg-setup-plugin-dir
    |-- -zplg-load-snippet
    |   |-- -zplg-deploy-message
    |   |-- -zplg-pack-ice
    |   `-- zplugin-install.zsh/-zplg-download-snippet
    `-- zplugin-autoload.zsh/-zplg-unload

Uses feature(s): *eval*, *source*, *zle*, *zpty*

Called by:

    -zplg-scheduler

## \-zplg-scheduler

> 
> 
>     Searches for timeout tasks, executes them. There's an array of tasks
>     waiting for execution, this scheduler manages them, detects which ones
>     should be run at current moment, decides to remove (or not) them from
>     the array after execution.
> 
>     $1 - if "following", then it is non-first (second and more)
>     invocation of the scheduler; this results in chain of `sched'
>     invocations that results in repetitive -zplg-scheduler activity
> 
>     if "burst", then all tasks are marked timeout and executed one
>     by one; this is handy if e.g. a docker image starts up and
>     needs to install all Turbo mode plugins without any hesitation
>     (delay), i.e. "burst" allows to run package installations from
>     script, not from prompt

Has 61 line(s). **Is a precmd hook**. Calls functions:

    -zplg-scheduler
    |-- -zplg-run-task
    |   |-- -zplg-load
    |   |   |-- -zplg-any-to-user-plugin
    |   |   |-- -zplg-deploy-message
    |   |   |-- -zplg-load-plugin
    |   |   |   |-- -zplg-add-report
    |   |   |   |-- -zplg-diff-env
    |   |   |   |-- -zplg-diff-functions
    |   |   |   |-- -zplg-diff-options
    |   |   |   |-- -zplg-diff-parameter
    |   |   |   |-- -zplg-find-other-matches
    |   |   |   |-- -zplg-shadow-off
    |   |   |   `-- -zplg-shadow-on
    |   |   |-- -zplg-pack-ice
    |   |   |-- -zplg-register-plugin
    |   |   `-- zplugin-install.zsh/-zplg-setup-plugin-dir
    |   |-- -zplg-load-snippet
    |   |   |-- -zplg-deploy-message
    |   |   |-- -zplg-pack-ice
    |   |   `-- zplugin-install.zsh/-zplg-download-snippet
    |   `-- zplugin-autoload.zsh/-zplg-unload
    `-- add-zsh-hook

Uses feature(s): *sched*, *zle*

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## \-zplg-service

> 
> 
>     Handles given service, i.e. obtains lock, runs it, or waits if no lock
> 
>     $1 - type "p" or "s" (plugin or snippet)
>     $2 - mode - for plugin (light or load)
>     $3 - id - URL or plugin ID or alias name (from id-as'')

Has 30 line(s). Calls functions:

    -zplg-service
    |-- -zplg-load
    |   |-- -zplg-any-to-user-plugin
    |   |-- -zplg-deploy-message
    |   |-- -zplg-load-plugin
    |   |   |-- -zplg-add-report
    |   |   |-- -zplg-diff-env
    |   |   |-- -zplg-diff-functions
    |   |   |-- -zplg-diff-options
    |   |   |-- -zplg-diff-parameter
    |   |   |-- -zplg-find-other-matches
    |   |   |-- -zplg-shadow-off
    |   |   `-- -zplg-shadow-on
    |   |-- -zplg-pack-ice
    |   |-- -zplg-register-plugin
    |   `-- zplugin-install.zsh/-zplg-setup-plugin-dir
    `-- -zplg-load-snippet
        |-- -zplg-deploy-message
        |-- -zplg-pack-ice
        `-- zplugin-install.zsh/-zplg-download-snippet

Uses feature(s): *kill*, *read*

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## \-zplg-shadow-off

> 
> 
>     Turn off shadowing completely for a given mode ("load", "light",
>     "light-b" (i.e. the `trackbinds' mode) or "compdef").

Has 18 line(s). Doesn’t call other functions.

Uses feature(s): *unfunction*

Called by:

    -zplg-debug-stop
    -zplg-load-plugin

## \-zplg-shadow-on

> 
> 
>     Turn on shadowing of builtins and functions according to passed
>     mode ("load", "light", "light-b" or "compdef"). The shadowing is
>     to gather report data, and to hijack `autoload', `bindkey' and
>     `compdef' calls.

Has 25 line(s). Doesn’t call other functions.

Called by:

    -zplg-debug-start
    -zplg-load-plugin

## \-zplg-submit-turbo

> 
> 
>     If `zplugin load`, `zplugin light` or `zplugin snippet`  will be
>     preceded with `wait', `load', `unload' or `on-update-of`/`subscribe'
>     ice-mods then the plugin or snipped is to be loaded in Turbo mode,
>     and this function adds it to internal data structures, so that
>     -zplg-scheduler can run (load, unload) this as a task.

Has 14 line(s). Doesn’t call other functions.

Called by:

    zplugin

## \-zplg-unregister-plugin

> 
> 
>     Removes the plugin from ZPLG_REGISTERED_PLUGINS array and from the
>     LOADED_PLUGINS array (managed according to the plugin standard)

Has 5 line(s). Calls functions:

    -zplg-unregister-plugin
    `-- -zplg-any-to-user-plugin

Called by:

    zplugin-autoload.zsh/-zplg-unload

## \-zplugin\_scheduler\_add\_sh

> 
> 
>     Copies task into ZPLG_RUN array, called when a task timeouts.
>     A small function ran from pattern in /-substitution as a math
>     function.

Has 7 line(s). Doesn’t call other functions.

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## @zplg-register-z-plugin

> 
> 
>     Registers the z-plugin inside Zplugin – i.e. an Zplugin extension

Has 4 line(s). Doesn’t call other functions.

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## pmodload

> 
> 
>     Compatibility with Prezto. Calls can be recursive.

Has 9 line(s). Calls functions:

    pmodload
    `-- -zplg-load-snippet
        |-- -zplg-deploy-message
        |-- -zplg-pack-ice
        `-- zplugin-install.zsh/-zplg-download-snippet

Uses feature(s): *zstyle*

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## zpcdclear

> 
> 
>     A wrapper for `zplugin cdclear -q' which can be called from hook
>     ices like the atinit'', atload'', etc. ices.

Has 1 line(s). Calls functions:

    zpcdclear
    `-- -zplg-compdef-clear

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## zpcdreplay

> 
> 
>     A function that can be invoked from within `atinit', `atload', etc.
>     ice-mod.  It works like `zplugin cdreplay', which cannot be invoked
>     from such hook ices.

Has 1 line(s). Calls functions:

    zpcdreplay
    `-- -zplg-compdef-replay

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## zpcompdef

> 
> 
>     Stores compdef for a replay with `zpcdreplay' (Turbo mode) or
>     with `zplugin cdreplay' (normal mode). An utility functton of
>     an undefined use case.

Has 1 line(s). Doesn’t call other functions.

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## zpcompinit

> 
> 
>     A function that can be invoked from within `atinit', `atload', etc.
>     ice-mod.  It runs `autoload compinit; compinit' and respects
>     ZPLGM[ZCOMPDUMP_PATH] and ZPLGM[COMPINIT_OPTS].

Has 1 line(s). Calls functions:

    zpcompinit
    `-- compinit

Uses feature(s): *autoload*

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## zplugin

> 
> 
>     Main function directly exposed to user, obtains subcommand and its
>     arguments, has completion.

Has 284 line(s). Calls functions:

    zplugin
    |-- -zplg-clear-debug-report
    |   `-- zplugin-autoload.zsh/-zplg-clear-report-for
    |-- -zplg-compdef-clear
    |-- -zplg-compdef-replay
    |-- -zplg-debug-start
    |   |-- -zplg-diff-env
    |   |-- -zplg-diff-functions
    |   |-- -zplg-diff-options
    |   |-- -zplg-diff-parameter
    |   `-- -zplg-shadow-on
    |-- -zplg-debug-stop
    |   |-- -zplg-diff-env
    |   |-- -zplg-diff-functions
    |   |-- -zplg-diff-options
    |   |-- -zplg-diff-parameter
    |   `-- -zplg-shadow-off
    |-- -zplg-debug-unload
    |   `-- zplugin-autoload.zsh/-zplg-unload
    |-- -zplg-ice
    |-- -zplg-load
    |   |-- -zplg-any-to-user-plugin
    |   |-- -zplg-deploy-message
    |   |-- -zplg-load-plugin
    |   |   |-- -zplg-add-report
    |   |   |-- -zplg-diff-env
    |   |   |-- -zplg-diff-functions
    |   |   |-- -zplg-diff-options
    |   |   |-- -zplg-diff-parameter
    |   |   |-- -zplg-find-other-matches
    |   |   |-- -zplg-shadow-off
    |   |   `-- -zplg-shadow-on
    |   |-- -zplg-pack-ice
    |   |-- -zplg-register-plugin
    |   `-- zplugin-install.zsh/-zplg-setup-plugin-dir
    |-- -zplg-load-snippet
    |   |-- -zplg-deploy-message
    |   |-- -zplg-pack-ice
    |   `-- zplugin-install.zsh/-zplg-download-snippet
    |-- -zplg-submit-turbo
    |-- compinit
    |-- zplugin-autoload.zsh/-zplg-cdisable
    |-- zplugin-autoload.zsh/-zplg-cenable
    |-- zplugin-autoload.zsh/-zplg-clear-completions
    |-- zplugin-autoload.zsh/-zplg-compile-uncompile-all
    |-- zplugin-autoload.zsh/-zplg-compiled
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

Uses feature(s): *autoload*, *eval*, *source*

Not called by script or any function (may be e.g. a hook, a Zle widget,
etc.).

## add-zsh-hook

Has 93 line(s). Doesn’t call other functions.

Uses feature(s): *autoload*, *getopts*

Called by:

    -zplg-scheduler
    Script-Body

## compinit

Has 544 line(s). Doesn’t call other functions.

Uses feature(s): *autoload*, *bindkey*, *eval*, *read*, *unfunction*,
*zle*, *zstyle*

Called by:

    zpcompinit
    zplugin

## is-at-least

Has 56 line(s). Doesn’t call other functions.

Called by:

    Script-Body

[]( vim:set ft=markdown tw=80: )
