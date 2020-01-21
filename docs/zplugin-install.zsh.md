zinit-install.zsh(1)
======================

NAME
----
zinit-install.zsh - a shell script

SYNOPSIS
--------
Documentation automatically generated with \`zshelldoc'

FUNCTIONS
---------

```text
.zinit-at-eval
.zinit-compile-plugin
.zinit-download-file-stdout
.zinit-download-snippet
.zinit-forget-completion
.zinit-get-latest-gh-r-version
.zinit-handle-binary-file
.zinit-install-completions
.zinit-mirror-using-svn
.zinit-setup-plugin-dir
```

DETAILS
-------

## Script Body

Has 3 line(s). No functions are called (may set up e.g. a hook, a Zle widget bound to a key, etc.).

Uses feature(s): _source_

## .zinit-at-eval

Has 1 line(s). Doesn't call other functions.

Uses feature(s): _eval_

Called by:

```text
.zinit-download-snippet
```

## .zinit-compile-plugin

```text 
Compiles given plugin (its main source file, and also an
additional "....zsh" file if it exists).

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
```

Has 50 line(s). Calls functions:

```text
.zinit-compile-plugin
|-- zinit-side.zsh/.zinit-first
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Uses feature(s): _eval_, _zcompile_

Called by:

```text
.zinit-setup-plugin-dir
zinit-autoload.zsh/.zinit-compile-uncompile-all
zinit.zsh/zinit
```

## .zinit-download-file-stdout

```text 
Downloads file to stdout. Supports following backend commands:
curl, wget, lftp, lynx. Used by snippet loading.
```

Has 32 line(s). Calls functions:

```text
.zinit-download-file-stdout
```

Uses feature(s): _type_

Called by:

```text
.zinit-download-snippet
.zinit-setup-plugin-dir
```

## .zinit-download-snippet

```text
Downloads snippet – either a file – with curl, wget, lftp or lynx,
or a directory, with Subversion – when svn-ICE is active. Github
supports Subversion protocol and allows to clone subdirectories.
This is used to provide a layer of support for Oh-My-Zsh and Prezto.
```

Has 233 line(s). Calls functions:

```text
.zinit-download-snippet
|-- .zinit-at-eval
|-- .zinit-download-file-stdout
|-- .zinit-install-completions
|   |-- .zinit-forget-completion
|   |-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
|   |-- zinit-side.zsh/.zinit-exists-physically-message
|   `-- zinit.zsh/.zinit-any-to-user-plugin
|-- .zinit-mirror-using-svn
`-- zinit-side.zsh/.zinit-store-ices
```

Uses feature(s): _eval_, _zcompile_

Called by:

```text
zinit.zsh/.zinit-load-snippet
```

## .zinit-forget-completion

```text 
Implements alternation of Zsh state so that already initialized
completion stops being visible to Zsh.

$1 - completion function name, e.g. "_cp"; can also be "cp"
```

Has 15 line(s). Doesn't call other functions.

Uses feature(s): _unfunction_

Called by:

```text
.zinit-install-completions
zinit-autoload.zsh/.zinit-compinit
zinit-autoload.zsh/.zinit-uninstall-completions
zinit.zsh/zinit
```

## .zinit-get-latest-gh-r-version

```text 
Gets version string of latest release of given Github
package. Connects to Github releases page.
```

Has 14 line(s). Calls functions:

```text
.zinit-get-latest-gh-r-version
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
zinit-autoload.zsh/.zinit-update-or-status
```

## .zinit-handle-binary-file

```text 
If the file is an archive, it is extracted by this function.
Next stage is scanning of files with the common utility `file',
to detect executables. They are given +x mode. There are also
messages to the user on performed actions.

$1 - url
$2 - file
```

Has 66 line(s). Doesn't call other functions.

Uses feature(s): _unfunction_

Called by:

```text
.zinit-setup-plugin-dir
```

## .zinit-install-completions

```text 
Installs all completions of given plugin. After that they are
visible to `compinit'. Visible completions can be selectively
disabled and enabled. User can access completion data with
`clist' or `completions' subcommand.

$1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
$2 - plugin (only when $1 - i.e. user - given)
$3 - if 1, then reinstall, otherwise only install completions that aren't there
```

Has 34 line(s). Calls functions:

```text
.zinit-install-completions
|-- .zinit-forget-completion
|-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
|-- zinit-side.zsh/.zinit-exists-physically-message
`-- zinit.zsh/.zinit-any-to-user-plugin
```

Called by:

```text
.zinit-download-snippet
.zinit-setup-plugin-dir
zinit.zsh/zinit
```

## .zinit-mirror-using-svn

```text
Used to clone subdirectories from Github. If in update mode
(see $2), then invokes `svn update', in normal mode invokes
`svn checkout --non-interactive -q <URL>'. In test mode only
compares remote and local revision and outputs true if update
is needed.

$1 - URL
$2 - mode, "" - normal, "-u" - update, "-t" - test
$3 - subdirectory (not path) with working copy, needed for -t and -u
```

Has 27 line(s). Doesn't call other functions.

Called by:

```text
.zinit-download-snippet
```

## .zinit-setup-plugin-dir

```text 
Clones given plugin into PLUGIN_DIR. Supports multiple
sites (respecting `from' and `proto' ice modifiers).
Invokes compilation of plugin's main file.

$1 - user
$2 - plugin
```

Has 182 line(s). Calls functions:

```text
.zinit-setup-plugin-dir
|-- .zinit-compile-plugin
|   |-- zinit-side.zsh/.zinit-first
|   `-- zinit.zsh/.zinit-any-to-user-plugin
|-- .zinit-download-file-stdout
|-- .zinit-handle-binary-file
|-- .zinit-install-completions
|   |-- .zinit-forget-completion
|   |-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
|   |-- zinit-side.zsh/.zinit-exists-physically-message
|   `-- zinit.zsh/.zinit-any-to-user-plugin
|-- zinit-side.zsh/.zinit-any-colorify-as-uspl2
`-- zinit-side.zsh/.zinit-store-ices
```

Uses feature(s): _eval_

Called by:

```text
zinit-autoload.zsh/.zinit-update-or-status
zinit.zsh/.zinit-load
```

