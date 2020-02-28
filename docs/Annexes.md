# Annexes 

## What Are They?

They are Zinit extensions. An annex is added to Zinit by simply loading it
just as any other plugin.

## What Can They Do?

1.  Add a new Zinit subcommand (i.e. the command that’s placed after the
    function `zinit …` when calling Zinit).

2.  Add new ice-modifiers.

3.  Register four type of hooks:
    
    1.  `atclone` hook – run after cloning any plugin or downloading any
	snippet.
    
    2.  `atpull` hook – run after pulling new commits (i.e. updating) for any
        plugin / snippet.
    
    3.  `atinit` hook – run before loading any plugin / snippet, after it has
        been set-up (i.e. downloaded).
    
    4.  `atload` hook – run after loading any plugin / snippet.

4.  Register hooks for generating help text, shown by the `zinit help`
    subcommand.

## How To Code Them?

Below is an example body of an `atclone` hook (taken from
[**zinit/z-a-submods**](https://github.com/zinit/z-a-submods) annex). It
shows how to:

1.  Obtain the arguments passed to the hook.

2.  Use an ice modifier.

3.  It also shows an useful snippet that will trim the whitespace in array
    elements (see `# (4) …` in the code).

4.  Utilize the last hook argument – the plugin’s/snippet’s containing
    directory.

<!-- end list -->

``` zsh
emulate -L zsh -o extendedglob -o warncreateglobal -o typesetsilent

[[ -z "${ZINIT_ICE[submods]}" ]] && return 0

# (1) – get arguments
[[ "$1" = plugin ]] && \
    local type="$1" user="$2" plugin="$3" id_as="$4" dir="$5" hook="$6" || \
    local type="$1" url="$2" id_as="$3" dir="$4" hook="$6" # type: snippet

# (2) – we're interested only in plugins/snippets
# which have the submods'' ice in their load command
[[ -z ${ZINIT_ICE[submods]} ]] && return 0

local -a mods parts
local mod

# (3) – process the submods'' ice
mods=( ${(@s.;.)ZINIT_ICE[submods]} )
for mod in "${mods[@]}"; do
    parts=( "${(@s:->:)mod}" )
    # (4) Remove only leading and trailing whitespace
    parts=( "${parts[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )

    print "\nCloning submodule: ${parts[1]} to dir: ${parts[2]}"
    parts[1]="https://github.com/${parts[1]}"
    # (5) – the use of the input argument: `$dir'
    command git -C "$dir" clone --progress "${parts[1]}" "${parts[2]}"
done
```

The recommended method of creating a hook is to place its body into a file that
starts with a right arrow `→` ([more
information](http://zdharma.org/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html#namespacing),
and also a `za-` prefix, e.g. `→za-myproject-atclone-hook` and then to mark it
for autoloading via `autoload -Uz →za-myproject-atclone-hook`. Then register the
hook (presumably in the `myproject.plugin.zsh` file) with the API call:
`@zinit-register-annex`:

``` zsh
@zinit-register-annex myproject hook:atclone \
    →za-myproject-atclone-handler \
    →za-myproject-atclone-help-handler \
    "submods''" # register a new ice-mod: submods''
```

The general syntax of the API call is:

``` zsh
@zinit-register-annex {project-name} \
    {hook:<hook-type>|subcommand:<new-subcommand-name>} \
    {name-of-the-handler-function} \
    {name-of-the-HELP-handler-function} \
    "{ice-mod1}|{ice-mod2}|…"
```

The last argument, i.e. the `|`-separated ice-list, is optional. That’s all\!
After this loading the plugin `myproject` will set up the new ice-mod `submods`
that will have syntax `submods'{user}/{plugin} –> {output-dir}; …'` and
will clone submodules when installing the original plugin or snippet\! Example
real-world use of the ice-mod:

``` zsh
# Load the `zsh-autosuggestions' plugin via Prezto module: `autosuggestions'
zinit ice svn submods'zsh-users/zsh-autosuggestions -> external'
zinit snippet PZT::modules/autosuggestions
```

Checkout the project which fully implements this idea,
[**zinit/z-a-submods**](https://github.com/zinit/z-a-submods). It e.g. also
implements the `atpull` hook, i.e. supports automatic update of the submodules.
The `z-a-*` prefix is recommended for projects that are being annexes.

## Details

There are 2 or 3 subtypes for each of the hook:

1.  `atinit` or `!atinit` – the `!` version is ran before the `atinit`
    **ice-mod** (i.e. before `zinit ice atinit'echo this!'; …`), while
    the normal version runs after it.

2.  `atload` or `!atload` – analogous to the `atinit` case: the `!` version runs
    before the `atload` **ice-mod** (while the normal version runs after it).

3.  `atclone` or `!atclone` – analogous to the `atinit` and `atload` cases.

4.  `atpull`, `!atpull` or `%atpull` – the first two are being ran **only when
    there are new commits to be downloaded** during the update. The `%` version
    is being **always** run, regardless if the update will pull any actual
    commits or not, and it is being ran **after** the `atpull` **ice-mod**.

[]( vim:set ft=markdown tw=80: )
