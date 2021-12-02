# Zinit Packages

## Introduction

Zinit can install from so-called *packages* – GitHub repositories holding
a `package.json` file with the Zinit meta-data in them.

This way you don't have to (but still can) specify ices, which might be handy
when the ice-mod list is long and complex.

## Motivation

The motivation for adding such functionality was:

1. Zinit is a flexible plugin manager, however, users often feel overwhelmed by
   its configuration.

2. It has multiple package-manager -like features, such as:
    - it can run `Makefiles`, 
    - automatically provide *shims* (i.e.: forwarder scripts) for the binaries,
    - extend `$PATH` to expose the binaries, and more.

3. In general, Zinit has many hooks which allow surprising things, however their
   content often evolves to a gradually better and better one and it's hard to
   keep track of the current version of them.

4. So a solution appeared: why not publish a package at GitHub with the plugin
   configurations (i.e.: ice-mod lists) stored in a file?

## Introductory Example

This way, instead of the following command used to install `fzf`:

```zsh
zinit lucid as=program pick="$ZPFX/bin/(fzf|fzf-tmux)" \
    atclone="cp shell/completion.zsh _fzf_completion; \
      cp bin/(fzf|fzf-tmux) $ZPFX/bin" \
    make="PREFIX=$ZPFX install" for \
        junegunn/fzf
```

you only need:

```zsh
zinit pack for fzf
```

to get the complete setup of the fuzzy finder, including:

- the completion,
- the additional executable-script `fzf-tmux`.

The installation is real, package-manager -like, because you don't need to
invoke Zinit anymore once installed to use `fzf` (that's because `fzf` is just
a binary program and not e.g.: a shell function).

You can also update the package with `zinit update fzf` – it'll cause the
project to refresh and rebuild, like with a "normal" package manager such as
`apt-get`. However, it'll actually be more like to `emerge` from Gentoo, because
the installation will be from the source… unless… the user will pick up a binary
installation by profile-argument specified in the `pack''` ice :)

## Pros Of Using Zinit Package For Regular Software Installations

Using Zinit to install software where one could use a regular package manager
has several advantages:

1. **Pro:** The Zinit packages typically use the URLs to the official and
   *latest* distributions of the software (like e.g.: the
   [ecs-cli](https://github.com/zdharma-continuum/zinit-package-ecs-cli)
   package, which uses the URL:
   `https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest` when
   installing on Linux).

2. **Pro:** You can influence the installation easily by specifying Zinit
   ice-mods, e.g.:

    ```
    zinit pack=bgn atclone="cp fzy.1 $ZPFX/man/man1" for fzy
    ```

    to install also the man page for the `fzy` fuzzy finder (this omission in
    the package will be fixed soon).

3. **Pro:** The installation is much more flexible than a normal package
   manager.  Example available degrees of freedom:

    - to install from Git or from release-tarball, or from binary-release file,
    - to install via shims or via extending `$PATH`, or by copying to
      `$ZPFX/bin`,
    - to download files and apply patches to the source by using the
      [Patch-Dl](../z-a-patch-dl/) annex features.

4. **Pro:** The installations are located in the user home directory, which
   doesn't require root access. Also, for Gems and Node modules, they are
   installed in their plugin directory, which can have advantages (e.g.:
   isolation allowing e.g: easy removal by `rm -rf …`).

5. **Con:** You're somewhat "on your own", with no support from any package
   maintainer.

Thus, summing up 1. with 4., it might be nice/convenient to, for example, have
the latest ECS CLI binary installed in the home directory, without using root
access and always the latest, and – summing up with 2. and 3. – to, for example,
have always the latest `README` downloaded by an additional ice:
`dl'https://raw.githubusercontent.com/aws/amazon-ecs-cli/master/README.md'` (and
then to have the `README` converted into a man page by the `remark` Markdown
processor or other via an `atclone''` ice, as the tool doesn't have any official
man page).

## The `Zsh-Packages` Organization

Packages are hosted [on GitHub, by the zdharma-continuum
org](https://github.com/zdharma-continuum/zinit-packages):

- [asciidoctor](https://github.com/zdharma-continuum/zinit-packages/tree/main/asciidoctor) – the AsciiDoc
  converter, installed as a Gem locally in the plugin directory with use of the
  [Bin-Gem-Node](../z-a-bin-gem-node) annex,
- [doctoc](https://github.com/zdharma-continuum/zinit-packages/tree/main/doctoc) – the TOC (table of contents)
  generator for Markdown documents, installed as a Node package locally in the
  plugin directory with use of the `Bin-Gem-Node` annex,
- [ecs-cli](https://github.com/zdharma-continuum/zinit-packages/tree/main/ecs-cli) – the Amazon ECS command
  line tool, downloaded directly from the
  [URL](https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest) (or
  from the
  [URL](https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-darwin-amd64-latest) for
  OS X – automatically selected),
- [firefox-dev](https://github.com/zdharma-continuum/zinit-packages/tree/main/firefox-dev) – Firefox Developer
  Edition, downloaded from the
  [URL](https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-US)
  (or from the
  [URL](https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=osx&lang=en-US)
  for OS X; the OS X installation only downloads the `dmg` image, so it is'nt
  yet complete),
- [fzf](https://github.com/zdharma-continuum/zinit-packages/tree/main/fzf) – the fuzzy-finder, installed from
  source (from a tarball or Git) or from the GitHub-releases binary,
- [ls\_colors](https://github.com/zdharma-continuum/zinit-packages/tree/main/ls_colors) – the
  [trapd00r/LS\_COLORS](https://github.com/trapd00r/LS_COLORS) color definitions
  for GNU `ls`, `ogham/exa` and Zshell's completion.

## Adding Your Own Package

1. Contact the author to have the repository at Zsh-Packages organization.

2. Populate the `package.json` – I suggest grabbing the one for `fzf` or
   `doctoc` and doing a few substitutions like `doctoc` → `your-project` and
   then simply filling the `default` profile in the `zinit-ices` object – it's
   obvious how to do this.

3. The project name in the `package.json` should start with `zsh-`. The prefix
   will be skipped when specifying it with Zinit.

4. Commit and push.

That's all!

[]( vim:set ft=markdown tw=80 fo+=a1n autoindent: )
