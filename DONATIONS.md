<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [2018-08-14, received $30](#2018-08-14-received-30)
- [2018-08-03, received $8](#2018-08-03-received-8)
- [2018-08-02, received $3 from Patreon](#2018-08-02-received-3-from-patreon)
- [2018-07-31, received $7](#2018-07-31-received-7)
- [2018-07-28, received $2](#2018-07-28-received-2)
- [2018-07-25, received $3](#2018-07-25-received-3)
- [2018-07-20, received $3](#2018-07-20-received-3)
- [2018-06-17, received ~$155 (200 CAD)](#2018-06-17-received-155-200-cad)
- [2018-06-10, received $10](#2018-06-10-received-10)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

Below are reports about what is being done with donations, i.e. which commits
are created thanks to them, which new features are added, etc. From the money
I receive I buy myself coffee and organize the time to work on the requested
features, sometimes many days in a row.

## 2018-08-14, received $30

 * **Project**: **[Zplugin](https://github.com/zdharma/zplugin)**
 * **Goal**: Create a binary Zsh module with one Zplugin optimization and optionally some
   other features.
 * **Status**: The job is done.

Thanks to this donation I have finally started to code **[binary Zplugin module](
https://github.com/zdharma/zplugin#quick-start-module-only)**, which is a big step onward
in evolution of Zplugin. I've implemented and published the module with 3 complete
features: 1) `load` optimization, 2) autocompilation of scripts, 3) profiling of script
load times.

Commit list:
```
2018-08-22 7b96fad doc: mod-install.sh
2018-08-22 ba1ba64 module: Update zpmod usage text
2018-08-22 b0d72e8 zplugin,*autoload: `module' command, manages new zdharma/zplugin module
2018-08-22 706bbb3 Update Zsh source files to latest
2018-08-20 b77426f module: source-study builds report with milliseconds without fractions
2018-08-20 c3cc09b module: Updated zpmod_usage, i.a. with `source-study' sub-command
2018-08-20 6190295 module: Go back to subcommand-interface to `zpmod'; simple option parser
2018-08-20 881005f module: Report on sourcing times is shown on `zpmod -S`. Done generation
2018-08-19 e5d046a module: Correct conditions on zwc file vs. script file (after stats)
2018-08-19 1282c21 module: Duration of sourcing a file is measured and stored into a hash
2018-08-18 e080153 module: Overload both `source' and `.' builtins
2018-08-18 580efb8 module: Invoke bin_zcompile with -U option (i.e. no alias expansion)
2018-08-18 b7d9836 module: Custom `source' ensures script is compiled, compiles if not
2018-08-18 1e75a47 module: Code cleanup, vim folding
2018-08-18 a4a02f3 module: Finally working `source'/`.' overload (used options translating)
2018-08-16 99bba56 module: zpmod_usage gained content
2018-08-16 04703cd module: Add the main builtin zpmod with report-append which is working
2018-08-16 cd6dc19 module: my_ztrdup_glen, zp_unmetafy_zalloc
2018-08-16 6d44e36 module: Cleanup, `source' overload after patron leoj3n restarted module
```

## 2018-08-03, received $8

 * **Project**: **[zdharma/history-search-multi-word](https://github.com/zdharma/history-search-multi-word)**
 * **Goal**: Allow calling `zle reset-prompt` (Zshell feature).
 * **Status**: The job is done.

A user wanted to be able to call `reset-prompt` Zshell widget without disturbing my project
`history-search-multi-word`. I've implemented the necessary changes to HSMW.

Commit list:

```
2018-08-04 9745d3d hsmw: reset-prompt-protect zstyle – allow users to run zle reset-prompt
2018-08-04 ce48a53 hsmw: More typo-like lackings of % substitution
2018-08-04 7e2d79b hsmw: A somewhat typo, missing % substitution
```

## 2018-08-02, received $3 from Patreon

 * **Project**: **[zdharma/fast-syntax-highlighting](https://github.com/zdharma/fast-syntax-highlighting)**
 * **Goal**: No goal set up.
 * **Status**: Bug-fixing work.

I did bug-fixing run on `fast-syntax-highlighting`, spotted many small and sometimes important things to
improve. Did one bigger thing – added global-aliases functionality.

Commit list:

```
2018-08-02 1e854f5 -autoload.ch: Don't check existence for arguments that are variables
2018-08-02 14cdc5e *-string-*: Support highlighter cooperation in presence of $PREBUFFER
2018-08-02 2d8f0e4 *-highlight: Correctly highlight $VAR, $~VAR, ${+VAR}, etc. in strings
2018-08-02 e3032d9 *-highlight: ${#PREBUFFER} -> __PBUFLEN, equal performance
2018-08-02 f0a7121 *-highlight: Make case conditions and brackets highlighter compatible
2018-08-02 781f68e *-highlight: Recognize more case-item-end tokens
2018-08-02 206c122 *-highlight: Remove unused 4th __arg_type
2018-08-02 c6da477 *-string-*: Handle 'abc\' – no slash-quoting here. Full quoting support
2018-08-02 52e0176 *-string-*: Fix bug, third level was getting wrong style
2018-08-02 5edbfae -git.ch: Support "--message=..." syntax (commit)
2018-08-02 669d4b7 -git.ch: Handle "--" argument (stops options)
2018-08-02 4fae1f2 -make.ch: Handle make's -f option
2018-08-02 3fd32fe -make.ch: Handle make's -C option
2018-08-02 31751f5 -make.ch: Recognize options that obtain argument
2018-08-02 e480f18 -make.ch: Fix reply-var clash, gained consistency
2018-08-02 0e8bc1e Updated README.md
2018-08-02 eee0034 images: global-alias.png
2018-08-02 00b41ef *-highlight,themes,fast-theme: Support for global aliases #41
```

## 2018-07-31, received $7

 * **Project**: **[zdharma/fast-syntax-highlighting](https://github.com/zdharma/fast-syntax-highlighting)**
 * **Goal**: Implement ideal brackets highlighting.
 * **Status**: The job is done.

When a source code is edited e.g. in `Notepad++` or some IDE, then most often brackets are somehow matched to
each other, so that the programmer can detect mistakes. `Fast-syntax-highlighting` too gained that feature. It
was done in such a way that FSH cannot make any mistake, colors will perfectly match brackets to each other.

Commit list:

```
2018-07-31 2889860 *-highlight: Correct place to initialize $_FAST_COMPLEX_BRACKETS
2018-07-31 2bde2a9 Performance status -15/8/8
2018-07-31 5078261 *-highlight,README: Brackets highlighter active by default
2018-07-31 2ee3073 *-highlight,*string-*: Brackets in [[..]], ((..)), etc. handled normally
2018-07-31 776b12d plugin.zsh: $_ZSH_HIGHLIGHT_MAIN_CACHE -> $_FAST_MAIN_CACHE
2018-07-30 2867712 plugin.zsh: Fix array parameter created without declaring #43
2018-07-30 cbe5fc8 Updated README.md
2018-07-30 2bd3291 images: brackets.gif
2018-07-30 ef23a96 *-string-*: Bug-fix, correctly use theme styles
2018-07-30 9046f82 plugin.zsh: Attach the new brackets highlighter; F_H[use_brackets]=1
2018-07-30 b33a5fd fast-theme: Support 4 new styles (for brackets)
2018-07-30 a03f004 themes: Add 4 new styles (brackets)
2018-07-30 2448cdc *-string-*: Additional highlight of bracket under cursor; more styles
2018-07-30 5e1795e *-string-*: Highlighter for brackets, handles all quotings; detached
```

## 2018-07-28, received $2

 * **Project**: **[zdharma/fast-syntax-highlighting](https://github.com/zdharma/fast-syntax-highlighting)**
 * **Goal**: Distinguish file and directory when highlighting
 * **Status**: The job is done.

A user requested that when `fast-syntax-highlighting` colorizes the command line it should use different
styles (e.g. colors) for token that's a *file* and that's a *directory*. It was a reasonable idea and I've
implemented it.

Commit list:
```
2018-07-28 7f48e04 themes: Extend all themes with new style `path-to-dir'
2018-07-28 c7c6a91 fast-theme: Support for new style `path-to-dir'
2018-07-28 264676c *-highlight: Differentiate path and to-dir path. New style: path-to-dir
```

## 2018-07-25, received $3

 * **Project**: **[zdharma/zshelldoc](https://github.com/zdharma/zshelldoc)**
 * **Goal**: Implement documenting of used environment variables.
 * **Status**: The job is done.

Zshelldoc generates code-documentation like Doxygen or Javadoc, etc. User requested a
new feature: the generated docs should enumerate environment variables used and/or
exported by every function. Everything went fine and this feature has been implemented.

Commit list:

```
2018-07-26 f63ea25 Updated README.md
2018-07-26 3af0cf7 *detect: Get `var' from ${var:-...} and ${...:+${var}} and other subst
2018-07-25 2932510 *adoc: Better language in output document (about exported vars) #5
2018-07-25 f858dd8 *adoc: Include (in the output document) data on env-vars used #5
2018-07-25 80e3763 *adoc: Include data on exports (environment) in the output document #5
2018-07-25 ca576e2 *detect: Detect which env-vars are used, store meta-data in data/ #5
2018-07-25 f369dcc *detect: Function `find-variables' reported "$" as a variable, fixed #5
2018-07-25 e243dab *detect: Function `find-variables' #5
2018-07-25 5b34bb1 *transform: Detect exports done by function/script-body, store #5
```

## 2018-07-20, received $3

 * **Project**: **[zdharma/zshelldoc](https://github.com/zdharma/zshelldoc)**
 * **Goal**: Implement stripping of leading `#` char from functions' descriptions.
 * **Status**: The job is done.

A user didn't like that functions' descriptions in the JavaDoc-like document (generated with Zshelldoc) all
contain a leading `#` character. I've added stripping of this character (it is there in the processed source
code) controlled by a new Zshelldoc option.

Commit list:
```
2018-07-20 172c220 zsd,*adoc,README: Option --scomm to strip "#" from function descriptions
```

## 2018-06-17, received ~$155 (200 CAD)

 * **Project**: **[zdharma/fast-syntax-highlighting](https://github.com/zdharma/fast-syntax-highlighting)**
 * **Goal**: No goal set up.
 * **Status**: Done intense research.

I've created 2 new branches: `Hue-optimization` (33 commits) and `Tidbits-feature` (22 commits). Those were
branches with architectural changes and extraordinary features. The changes yielded to be too slow, and I had
to withdraw the merge. Below are fixing and optimizing commits (i.e. the valuable ones) that I've restored
from the two branches into master.

Commit list:
```
2018-07-21 dab6576 *-highlight: Merge-restore: remove old comments
2018-07-21 637521f *-highlight: Merge-restore: a threshold on # of zle .redisplay calls
2018-07-21 4163d4d *-highlight: Merge-restore: optimize four $__arg[1] = ... cases
2018-07-21 0f01195 *-highlight: Merge-restore: can remove one (Q) dequoting
2018-07-21 39a4ec6 *-highlight: Merge-restore: $v = A* is faster than $v[1] = A, tests:
2018-07-21 99d6b33 *-highlight: Merge-restore: optimize-out ${var:1} Bash syntax
2018-07-21 719c092 *-highlight: Merge-restore: allow $V/cmd, "$V/cmd, "$V/cmd", "${V}/cmd"
2018-07-21 026941d *-highlight: Merge-restore: stack pop in single instruction, not two
2018-07-21 3467e3d *-highlight: Merge-restore: more reasonable redirection-detecting code
2018-07-21 00d25ee *-highlight: Merge-restore: one active_command="$__arg" not needed (?)
2018-07-21 1daa6b3 *-highlight: Merge-restore: simplify ; and \n code short-paths
2018-07-21 55d65be *-highlight: Merge-restore: proc_buf advancement via patterns (not (i))
2018-07-21 cc55546 *-highlight: Merge-restore: pattern matching to replace (i) flag
```

## 2018-06-10, received $10

 * **Project**: **[zdharma/fast-syntax-highlighting](https://github.com/zdharma/fast-syntax-highlighting)**
 * **Goal**: No goal set up.
 * **Status**: Done intense experimenting.

I was working on *chromas* – command-specific colorization. I've added `which` and
`printf` colorization, then added asynchronous path checking (needed on slow network
drives), then coded experimental `ZPath` feature for chromas, but it couldn't be optimized
so I had to resign of it.

Commit list:
```
2018-06-12 c4ed1c6 Optimization – the same idea as in previous patch, better method
2018-06-12 c36feef Optimization – a) don't index large buffer, b) with negative index
2018-06-12 2f03829 Performance status  2298 / 1850
2018-06-12 14f5159 New working feature – ZPath. It requires optimization
2018-06-12 e027c40 -which.ch: One of commands can apparently return via stderr (#27)
2018-06-11 5b8004f New chroma `ruby', works like chroma `perl', checks syntax via -ce opts
2018-06-10 ca2e18b *-highlight: Async path checking has now 8-second cache
2018-06-10 e071469 *-highlight: Remove path-exists queue clearing
2018-06-10 5a6684c *-highlight: Support for asynchronous path checking
2018-06-10 1d7d6f5 New chroma: `printf', highlights special sequences like %s, %20s, etc.
2018-06-10 8f59868 -which.ch: Update main comment on purpose of this chroma
2018-06-10 5f4ece2 -which.ch: Added `whatis', it has only 1st line if output used
2018-06-10 e2d173e -which.ch: Uplift: handle `which' called on a function, /usr/bin/which
```
