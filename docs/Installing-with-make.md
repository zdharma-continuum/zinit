```zsh
zplugin ice as"program" pick"$ZPFX/bin/git-*" make"PREFIX=$ZPFX"
zplugin light tj/git-extras
```

 - `Makefile` of this project has only one needed target – `install`, which is called by default,
 - it also does building of the scripts that it installs, so it does 2 tasks,
 - for `Makefile` with 2 targets, one could use `make"all install PREFIX=..."`,
 - `pick'...'` will `chmod +x` all matching files and add `$ZPFX/bin/` to `$PATH`,
 - `$ZPFX` is provided by Zplugin, it is `~/.zplugin/polaris` by default, can be also customized.

----

Below is a hard core but fully working method of managing a software ([sdkman.io](https://sdkman.io)) with Zplugin.

```zsh
# The invocation uses https://github.com/zdharma/null repo as a placeholder
# for the atclone'' and atpull'' hooks

zplugin ice as"program" pick"$ZPFX/sdkman/bin/sdk" id-as'sdkman' run-atpull \
  atclone"wget https://get.sdkman.io -O scr.sh; SDKMAN_DIR=$ZPFX/sdkman bash scr.sh" \
  atpull"SDKMAN_DIR=$ZPFX/sdkman sdk selfupdate" \
  atinit"export SDKMAN_DIR=$ZPFX/sdkman; source $ZPFX/sdkman/bin/sdkman-init.sh"
zplugin light zdharma/null
```