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
- [2018-05-25, received $50](#2018-05-25-received-50)

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

## 2018-05-25, received $50

 * **Project**: **[zdharma/fast-syntax-highlighting](https://github.com/zdharma/fast-syntax-highlighting)**
 * **Goal**: No goal set up.
 * **Status**: New ideas and features.

I was working from May, 25 to June, 9 and came up with key ideas and implemented them. First were *themes*
that were very special because they were using `INI` files instead of some Zsh-script format. Creating themes
for `fast-syntax-highlighting` is thus easy and fun. Then I came up with *chromas*, command-specific
highlighting, which redefine how syntax-highlighting for Zshell works – detailed highlighting for e.g. Git
became possible, the user is informed about e.g. a mistake even before running a command. Overall 178 commits
in 16 days.

```
2018-06-09 3f72e6c -git.ch: `revert' works almost like `checkout', attach `revert' there
2018-06-09 b892743 Updated CHROMA_GUIDE.adoc
2018-06-09 f05643d Revert "Revert "Updated CHROMA_GUIDE.md""
2018-06-09 729bf7f Revert "Revert "CHROMA_GUIDE: Remove redundant comments, uplift""
2018-06-09 48a4e0c Revert "CHROMA_GUIDE: Remove redundant comments, uplift"
2018-06-09 55ede0a Revert "Updated CHROMA_GUIDE.md"
2018-06-09 17a28ba New chroma `-docker.ch' that verifies image ID passed to `image rm'
2018-06-09 868812a -make.ch,*-make-targets: Check Makefile exists, use 7 second cache, #24
2018-06-09 73df278 -sh.ch: Attach fish, has -c option, though different syntax, let's try
2018-06-09 3a73b8e Updated CHROMA_GUIDE.md
2018-06-09 29d04c8 CHROMA_GUIDE: Remove redundant comments, uplift
2018-06-09 22ce1d8 -sh.ch,*-highlight: Attach to 2 other shells, Zsh and Bash
2018-06-09 f54e44f New chroma `-sh.ch', colorizes code passed to `sh' with -c option
2018-06-09 f5d2375 CHROMA_GUIDE: Add example code block (rendered broken in mdown)
2018-06-09 08f4b28 CHROMA_GUIDE: Switch to asciidoc (rename)
2018-06-09 4e03609 CHROMA_GUIDE.md
2018-06-09 bbcf2d6 -source.ch: Word "source" should be highlighted as builtin
2018-06-09 6739b8b New chroma – `source' to handle . and source builtins
2018-06-09 b961211 gitignore: ignore more paths
2018-06-09 59d5d09 Updated README.md
2018-06-09 f6d4d19 Updated README.md
2018-06-09 eb31324 Update README.md (figlet logo)
2018-06-09 71dcc5f Performance status 298 / 479
2018-06-09 00c5f8f *-highlight: Add comments
2018-06-09 232903c -awk.ch: Highlight `sub' function, not working {, } highlighting
2018-06-09 b5241ba *-highlight: Much better $( ) recursion, would say problems-free, maybe
2018-06-08 6c69437 *-highlight: Larger buffer (110 -> 250) for $( ) matching
2018-06-08 f2b7a96 -awk.ch: Syntax check code passed to awk. Awk is very forgiving, though
2018-06-08 c53d8ba -vim.ch: Pass almost everything to big-loop, check if vim exists
2018-06-08 7fbf7cd chroma: New chroma `vim', shows last opened files under prompt
2018-06-08 06e4570 gitignore: Extend .gitignore
2018-06-08 3184ba1 chroma: All chroma functions end chroma mode on e.g. | and similar
2018-06-08 070077d *-highlight,-example.ch: Rename arg_type -> __arg_type, use it to end
2018-06-08 6c2411e -awk.ch: Use the new theme style `subtle-bg'
2018-06-08 9ec8d63 themes: All themes (remaining 4) to support `subtle-bg' style
2018-06-08 66e848b fast-theme: New theme key `subtle-bg', default & clean.ini support it
2018-06-08 1e794f9 -awk.ch: More keywords highlighted
2018-06-08 f3bbaca -awk.ch: Don't highlight keywords when they only contain proper keyword
2018-06-08 e4d5283 -awk.ch: Fix mistake (indices), was highlighting 1 extra trailing letter
2018-06-08 eebbb19 -awk.ch: Initialize FSH_LIST
2018-06-08 8ec24ca *-highlight: Missing math function for awk
2018-06-08 d8e423a -awk.ch: Highlight more keywords, via more general code
2018-06-07 ee26e66 Commit missing -fast-make-targets
2018-06-07 9d4f2b5 New chroma `-awk.ch', colorizes regex characters and a keyword (print)
2018-06-07 def5133 -example.ch: Add comments
2018-06-07 f31a2d0 New chroma -make.ch, verifies if target is correct
2018-06-07 623b8ce -perl.ch: Use correct keys in FAST_HIGHLIGHT hash
2018-06-07 090f420 themes: Make all themes provide {in,}correct-subtle styles
2018-06-07 2201fb6 New -perl.ch chroma, syntax-checks perl code; 2 new theme entries
2018-06-06 4b9598e *-highlight: Fix bug in math highlight – allow variables starting with _
2018-06-06 708afec *-highlight: Fix FAST_BLIST_PATTERNS not expanding path to absolute one
2018-06-06 caef05a -example.ch: Update, fix typos, remove unused code
2018-06-06 3fb192a Updated README.md
2018-06-06 6de0c82 images: git_chroma.png
2018-06-06 2852fdd -grep.ch (new): Special highlighting for grep – -grep.ch chroma function
2018-06-06 f216785 -example.ch: Added comments
2018-06-06 4ab5b36 -example.ch: Add comments
2018-06-06 380cd12 -example.ch: Added comments
2018-06-06 c8947cc -example.ch: Add comments
2018-06-06 f2e273e -example.ch: Add comments
2018-06-06 2f3565b plugin.zsh: Fix parse error
2018-06-06 4f1a9bd plugin.zsh: Added $fpath handling, to match what README contains
2018-06-06 cc9adb5 -example.ch: Change and extend comments
2018-06-06 3128fff -git.ch: More intelligent `checkout' highlighting – ref is first
2018-06-06 4b6f54b -git.ch: Support for `checkout' subcommand
2018-06-06 1930d37 -example.ch: Added example chroma function
2018-06-05 d79cd85 -git.ch: Add comments
2018-06-05 1473c9e -git.ch: Add comments
2018-06-05 0cb1419 -git.ch: Message passed after -m is checked for the 72 chars boundary
2018-06-05 3f99944 -git.ch: Architectural uplift of git chroma
2018-06-05 e044d13 -git.ch: Single place to add entry to $reply (target: region_highlight)
2018-06-05 3a84364 -git.ch: Handle quoted non-option arguments, also partly quoted: "abc
2018-06-05 d635bf4 -fast-run-git-command, it handles cache automatically, decimates source
2018-06-05 102ea78 -git.ch: Smart handling of `git push', remotes and branches are verified
2018-06-04 be88850 Performance status [+] 39+77=116 / -26+24=-2
2018-06-04 0e033f8 Experimental chroma support, currently active only on command `git'
2018-06-04 43ae221 *-highlight: Emacs mode-line
2018-06-04 938ad29 test: New "-git" parsing option, test results, -git.ch included
2018-06-04 e433fbc fast-theme: Explicitly return 0; added Emacs mode-line
2018-06-04 66e9b3c *-highlight: Detection of $( ) now doesn't go for $(( )) as a candidate
2018-06-04 488a580 chroma: Empty chroma function for `git'
2018-06-04 f54d770 *-highlight: Rename $cur_cmd to $active_command
2018-06-04 3f24e68 *-highlight: Make sudo and always-block compatible with `case' handling
2018-06-02 cd82637 themes: forest.ini to support 3 new `case' styles
2018-06-02 e1e993e themes: safari.ini & zdharma.ini to support 3 new `case' styles
2018-06-02 2e78a02 themes: clean.ini & default.ini to support 3 new `case' styles
2018-06-02 c1c3aab themes: free.ini to support 3 new `case' styles
2018-06-02 70a7e18 fast-theme,*-highlight: 3 new styles for `case' higlighting
2018-06-02 8d90dc2 *-highlight: Support for `case' highlighting
2018-06-02 10d291c *-highlight: Softer state manipulation, less rigid =1 etc. assignments
2018-06-02 6159507 *-highlight: Don't highlight closing ) with style `assign'
2018-06-02 1fc2450 *-highlight: One complex math command optimization, top of the loop
2018-06-02 cc49247 *-highlight: Fix improper state after assignment (command | regular)
2018-06-02 02942b8 Updated README.md
2018-06-02 5e28259 images: eval_cmp.png
2018-06-02 df92fed *-highlight: Fix removal of trailing "/' when recursing in eval
2018-06-02 4f61938 Performance status 46 / 44
2018-06-02 a5ade0e *-highlight: Recursive highlighting of eval string argument
2018-06-02 e91847b *-highlight: Don't recurse when not at main *-process call
2018-06-02 fca8603 *-highlight: Support assignments of arrays when key is taken from array
2018-06-02 5d70f01 *-highlight: Math highlighting recognizes ${+VAR}
2018-06-02 c48eb0d *-highlight: Math colorizing recognizes variables in braces ${HISTISZE}
2018-06-02 53dd85a *-highlight: Allow -- for precommand modifiers command & exec
2018-06-02 d9fe110 *-highlight: Detect globbing also when `##' occurs
2018-06-02 55c923d Performance status 132 / 66
2018-06-02 3bd8f07 themes: safari.ini to have globbing color specifically selected
2018-06-02 2b55260 themes: free.ini to have globbing color specifically selected
2018-06-02 494868e themes: clean.ini to have globbing color specifically selected
2018-06-01 fca6b3d images: herestring.png #9
2018-06-01 f9842c1 themes: forest.ini to use underline instead of bg color #9
2018-06-01 c25c539 themes: Small tune-up of forest & zdharma themes for here-string #9
2018-06-01 988d504 themes: Rudimentary (all same) configuration of here-string tokens #9
2018-06-01 99842d2 fast-theme,*-highlight: Support for here-string, can use bg color #9
2018-06-01 f739c30 Updated README.md
2018-06-01 7fa8451 images: execfd.png execfd_cmp.png
2018-06-01 d7384f1 themes: All themes gained `exec-descriptor=` key, now supported by code
2018-06-01 d66d140 themes: Fix improper effect of s/red/.../ substitution in clean,forest
2018-06-01 f7ee5e2 fast-theme,*-highlight: Support highlighting of {FD} etc. passed to exec
2018-06-01 e5c5534 *-highlight: Proper states for precmd (command,exec) option handling
2018-06-01 647b198 images: New cmdsubst.png
2018-06-01 74bdc4c Updated README.md
2018-06-01 86eb15e images: theme.png
2018-06-01 5169e82 Updated README.md
2018-06-01 1c462b7 Updated README.md
2018-06-01 4c21da4 images: cmdsubst.png
2018-06-01 b39996e *-highlight: Switch theme to secondary when descending into $() #15
2018-06-01 bf96045 themes: Equip all themes with key `secondary' (an alternate theme) #15
2018-06-01 aa1b112 fast-theme: Generate secondary theme (from key `secondary' in theme) #15
2018-06-01 6dd3bd3 *-highlight: Support for multiple active themes #15
2018-06-01 8a32944 *-highlight: Fix "$() found?" comparison
2018-06-01 3651605 *-highlight: Significant change: the parser is called recursively on $()
2018-05-31 882d88b test,*-highlight: New -ooo performance test; highlighter takes arguments
2018-05-31 5ba1178 *-highlight: Optimization - compute __arg length once
2018-05-30 b2a0126 *-highlight: Allow multiple separate options for `command', `exec' (#10)
2018-05-30 5804e9a *-highlight: Correct state after option for precommand (#10)
2018-05-30 1247b64 *-highlight: Simpler and more accurate option-testing for exec, command (#10)
2018-05-30 d87fed4 *-highlight: Correctly highlight options for `command' and `exec' (#10)
2018-05-30 8c3e75e *-highlight: Double-hyphen (--) stops option recognition and colorizing
2018-05-30 1c5a56c *-highlight: Support ${VAR} at command position (not only $VAR)
2018-05-30 f19d761 Updated README.md
2018-05-30 4a27351 images: for-loop
2018-05-30 4d650de themes: zdharma.ini to support for-loop
2018-05-30 45cafbc themes: safari.ini to support for-loop
2018-05-30 8bb9ee0 themes: free.ini to support for-loop
2018-05-30 f25a059 themes: forest.ini to support for-loop
2018-05-29 093d79e themes: default.ini to support for-loop
2018-05-29 446cb7b clean.ini,fast-theme: Clean-theme & theme subsystem to support for-loop
2018-05-29 1bb701f *-highlight: Move $variable highlighting from case to if-block
2018-05-29 b8413e9 *-highlight: For-loop highlighting, working, needs few upgrades
2018-05-28 7bec6e5 *-highlight: Three more simple vs. complex math operation optimizations
2018-05-27 baae683 *-highlight: Optimise complex math command into single one with & and ~
2018-05-27 2dc3103 *-highlight: Optimise complex math command into single one with & and ~
2018-05-27 291f905 _fast-theme: Update -t/--test description
2018-05-27 ec305f6 fast-theme: Help message treats about -t/--test
2018-05-27 0e1d19a Updated README.md
2018-05-27 5c3c911 Updated README.md
2018-05-26 76af248 themes: A fix for zdharma theme, 61 -> 63, a lighter color for builtins
2018-05-26 8eca0f2 *fast-theme: Ability to test theme after setting it (-t/--test)
2018-05-26 d3a7922 *-highlight: Fix in_array_assignment setting when closing ) found
2018-05-26 796c482 *-highlight: Make parameters' names exotic blank-var detection to work
2018-05-26 ae3913f _fast-theme: Complete theme names
2018-05-26 d212945 *-highlight,plugin.zsh,default.ini: Uplift of fg=112-fix code
2018-05-26 ee56f65 *-highlight,plugin.zsh: Final fix for fg=112 assignment – use zstyle
2018-05-26 391f5a4 fast-theme: Set `theme' zstyle in `:plugin:fast...' to given theme
2018-05-26 e0dc086 plugin.zsh: Fix the fg=112 assignment done for `variable' style
2018-05-26 17c9286 Updated README.md
2018-05-26 4774c1c fast-theme: Add completion for this function
2018-05-26 d971f39 fast-theme: Detect lack of theme name in arguments
2018-05-26 74f0d4d fast-theme: Use standard option parsing (zparseopts) and typical options
2018-05-26 d9c6180 New theme: `forest'
2018-05-26 419c156 New theme: `zdharma'
2018-05-26 a7735df gitignore
2018-05-26 99db69a New theme: `free'
2018-05-26 73619ff New theme: `clean'
2018-05-25 52307fb Theme support, 1 extra theme – `safari'
2018-05-25 41df55b *-highlight: (k) subscript flag is sufficient, no need for (K)
2018-05-25 cb21c05 Updated README.md
2018-05-25 a580cff *-highlight: FAST_BLIST_PATTERNS
```
