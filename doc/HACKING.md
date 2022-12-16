# Documentation

## README: Update the table of content

1. Install [doctoc](https://github.com/thlorenz/doctoc)
2. To update the TOC run the following command:

```zsh
doctoc --github README.md
```

## Update asciidoc and/or zshelldoc

1. Make sure you have [docker](https://www.docker.com/) or [podman](https://podman.io/) installed.
2. From the root of the repo, run:

```zsh
make doc-container
```

If for some reason you want to build the zshelldocs or the PDF manually, you'll need:

1. Patience, zsd is very finicky about locales. You have been warned.
2. [zshelldoc (zsd)](https://github.com/zdharma-continuum/zshelldoc)
3. [asciidoc](https://asciidoc.org/)
4. `make doc`

## Generate the manpage (doc/zinit.1)

1. Install [pandoc](https://pandoc.org/)
2. From the root of the repo run:

```zsh
pandoc --standalone --to man README.md -o doc/zinit.1
```

## Updating the gh-pages (zdharma-continuum.github.io)

1. Check out the [documentation branch](https://github.com/zdharma-continuum/zinit/tree/documentation)

```shell
git fetch origin documentation
git checkout documentation
```

2. Do your modifications and push your changes
3. Keep an eye on [the CI logs](https://github.com/zdharma-continuum/zinit/actions/workflows/gh-pages.yaml)
4. If all went well you can head to https://zdharma-continuum.github.io/ to see your changes live.

**NOTE:** If you really **need** to push directly, without CI please refer to \[the README in the
documentation\]https://github.com/zdharma-continuum/zinit/blob/documentation/README.md

# Testing

We run out tests with [zunit](https://zunit.xyz).

To add a new test case:

1. Install [zunit](https://zunit.xyz) and [revolver](https://github.com/molovo/revolver):

```zsh
zinit for \
    as"program" \
    atclone"ln -sfv revolver.zsh-completion _revolver" \
    atpull"%atclone" \
    pick"revolver" \
  @molovo/revolver \
    as"completion" \
    atclone"./build.zsh; ln -sfv zunit.zsh-completion _zunit" \
    atpull"%atclone" \
    sbin"zunit" \
  @zunit-zsh/zunit
```

2. Create a new `.zunit` file in the `tests/` dir. Here's a template:

```zsh
#!/usr/bin/env zunit

@setup {
  load setup
  setup
}

@teardown {
  load teardown
  teardown
}

@test 'zinit-annex-bin-gem-node installation' {
  # This spawns the official zinit container, and executesa single zinit command
  # inside it
  run ./scripts/docker-run.sh --wrap --debug --zunit \
    zinit light as"null" for zdharma-continuum/null

  # Verify exit code of the command above
  assert $state equals 0
  assert "$output" contains "Downloading"

  local artifact="${PLUGINS_DIR}/zdharma-continuum---null/readme.md"
  # Check if we downloaded the file correctly and if it is readable
  assert "$artifact" is_file
  assert "$artifact" is_readable
}
```

You should of course also check out the existing tests ;)

3. To run your new test:

```zsh
zunit --verbose tests/your_test.zunit
```

## Debugging tests

If you ever need to inspect the `ZINIT[HOME_DIR]` dir, where zinit's internal data is stored you can do so by commenting
out the `@teardown` section in your test. Then you can re-run said test and head over to `${TMPDIR:-/tmp}/zunit-zinit`.
Good luck!

# Misc

## Get the list of supported ices

To get the list in a quick-and-dirty fashion you issue:

```zsh
zinit --help | tail -1
```

See
[zinit-autoload.zsh](https://github.com/zdharma-continuum/zinit/blob/2feb41cf70d2f782386bbaa6fda691e3bdc7f1ac/zinit-autoload.zsh#L3445-L3447)
for implementation details.
