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

## 2018-07-24, received $7

 * **Project**: **[zdharma/zshelldoc](https://github.com/zdharma/zshelldoc)**
 * **Goal**: Document all used environment variables.
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

## 2018-07-20, received $4

 * **Project**: **[zdharma/zshelldoc](https://github.com/zdharma/zshelldoc)**
 * **Goal**: Implement stripping of leading `#` char from functions' descriptions.
 * **Status**: The job is done.

Commit list:
```
2018-07-20 172c220 zsd,*adoc,README: Option --scomm to strip "#" from function descriptions
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
