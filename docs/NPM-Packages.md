# Zsh/NPM Packages

## Introduction

Zplugin can install NPM packages if they contain Zsh-related metadata (i.e.: the
field `"zsh-data"`) in the `package.json`.

So basically what this means is that you can install plugins normally, like
before, however with use of a metadata stored in the NPM package registry. This
way you don't have to (but still can) specify ices, which might be handy when
the ice-mod list is long and complex.

## Motivation

The motivation for adding such functionality was:

1. Zplugin is a very flexible plugin manager however users often feel
   overwhelmed by its configuration.

2. It has many package-manager -like features, such as:
    - it can run `Makefiles`, 
    - automatically provide *shims* (i.e.: forwarder scripts) for the binaries,
    - extend `$PATH` to expose the binaries, and more.

3. In general, Zplugin has many hooks which allow surprising and beautiful
   things, however their content often evolves to a gradually better and better
   one and it's hard to keep track of the current version of them.

4. **So a solution came up**: why not publish a package at the NPM-registry with
   the plugin configurations (i.e.: ice-mods) stored in the `package.json` file?

## Introductory Example

This way, instead of the following command used to install `fzf`:

```zsh
zplugin lucid as=program pick="$ZPFX/bin/(fzf|fzf-tmux)" \
    atclone="cp shell/completion.zsh _fzf_completion; \
      cp bin/(fzf|fzf-tmux) $ZPFX/bin" \
    make="PREFIX=$ZPFX install" for \
        junegunn/fzf
```

you only need:

```zsh
zplugin pack for fzf
```

to get the complete setup of the fuzzy finder, including:

- the completion,
- the additional executable-script `fzf-tmux`.

The installation is real, package-manager -like, because you don't need to
invoke Zplugin anymore once installed to use `fzf` (that's because `fzf` is just
a binary program and not e.g.: a shell function).

You can also update the package with `zplugin update fzf` – it'll cause the
project to refresh and rebuild, like with a "normal" package manager such as
`apt-get`. However, it'll actually be more like to `emerge` from Gentoo, because
the installation will be from the source… unless… you'll pick a binary
installation :) So Zplugin is like `apt-get` and `emerge` in one!

## Pros Of Using Zplugin NPM-Support For Regular Software Installations

Using Zplugin to install software where one could use a regular package manager
has several advantages:

1. **Pro:** The Zplugin NPM packages typically use the URLs to the official and
   *latest* distributions of the software (like e.g.: the
   [ecs-cli](https://github.com/Zsh-Packages/ecs-cli) package, which uses the
   URL: `https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest`
   when installing on Linux).

2. **Pro:** You can influence the installation easily by specifying Zplugin
   ice-mods, e.g.:

    ```
    zplugin pack=bgn atclone="cp fzy.1 $ZPFX/man/man1" for fzy
    ```

    to install also the man page for the `fzy` fuzzy finder (this omission in
    the package will be fixed soon).

3. **Pro:** The installation is much more flexible than a normal package
   manager.  Example available degrees of freedom:

    - to install from Git or from release-tarball, or from binary-release file,
    - to install via shims or via extending `$PATH`, or by copying to
      `$ZPFX/bin`,
    - to download and apply patches to the source by using the
      [Patch-Dl](../z-a-patch-dl/) annex features.

4. **Pro:** The installations are located in the user home directory, which
   doesn't require root access. Also, for Gems and Node modules, they are
   installed in their plugin directory, which can have advantages (e.g.:
   isolation allowing e.g: easy removal by `rm -rf …`).

5. **Con:** You're somewhat "on your own", with no support from any package
   maintainer.

Thus, summing up 1. with 4., it might be nice/convenient to e.g.: have the
latest ECS CLI binary installed in the home directory, without using root access
and always the latest and – summing up with 2. and 3. – to, for example, have
always the latest `README` downloaded by an additional ice:
`dl'https://raw.githubusercontent.com/aws/amazon-ecs-cli/master/README.md'` (and
then to have the `README` turned into a man page by the `remark` tool or other
via an `atclone''` ice, as the tool doesn't have any official man page).

## The `Zsh-Packages` Organization

The home for the packages is [Zsh-Packages](https://github.com/Zsh-Packages)
GitHub organization. You can find the available packages there, which as of
`2019-12-11` include:

- [asciidoctor](https://github.com/Zsh-Packages/asciidoctor) – the AsciiDoc
  converter, installed as a Gem locally in the plugin directory with use of the
  [Bin-Gem-Node](../z-a-bin-gem-node) annex,
- [doctoc](https://github.com/Zsh-Packages/doctoc) – the TOC (table of contents)
  generator for Markdown documents, installed as a Node package locally in the
  plugin directory with use of the `Bin-Gem-Node` annex,
- [ecs-cli](https://github.com/Zsh-Packages/ecs-cli) – the Amazon ECS command
  line tool, downloaded directly from the
  [URL](https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest) (or
  from the
  [URL](https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-darwin-amd64-latest) for
  OS X – automatically selected),
- [firefox-dev](https://github.com/Zsh-Packages/firefox-dev) – Firefox Developer
  Edition, downloaded from the
  [URL](https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-US)
  (or from the
  [URL](https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=osx&lang=en-US)
  for OS X; the OS X installation only downloads the `dmg` image, so it is'nt
  yet complete),
- [fzf](https://github.com/Zsh-Packages/fzf) – the fuzzy-finder, installed from
  source (from a tarball or Git) or from the GitHub-releases binary,
- [LS\_COLORS](https://github.com/Zsh-Packages/LS_COLORS) – the
  [trapd00r/LS\_COLORS](https://github.com/trapd00r/LS_COLORS) color definitions
  for GNU `ls`, `ogham/exa` and Zshell's completion.

## Adding Your Own Package

You can contact me to have the repository at the Zsh-Packages organization.
Then, you'll only need to:

1. Create an NPM account

2. Invoke `npm login`.

3. Populate the `package.json` – I suggest grabbing the one for `fzf` or
   `doctoc` and doing a few substitutions like `doctoc` → `your-project` and
   then simply filling the `default` profile in the `zplugin-ices` object – it's
   obvious how to do this.

4. The project name in the `package.json` should start with `zsh-`. The prefix
   will be skipped when specifying it with Zplugin.

5. Commit and invoke `npm publish`.

That's all!

[]( vim:set ft=markdown tw=80 fo+=a1n autoindent: )
