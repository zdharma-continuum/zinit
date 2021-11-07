# Zsh/NPM Packages

## Introduction

Zinit can install NPM packages if they contain Zsh-related metadata (i.e.: the
field `"zsh-data"`) in the `package.json`.

So basically what this means is that you can install plugins normally, like
before, however with use of a metadata stored in the NPM package registry. This
way you don't have to (but still can) specify ices, which might be handy when
the ice-mod list is long and complex.

## Pros Of Using Zinit NPM-Support For Regular Software Installations

Using Zinit to install software where one could use a regular package manager
has several advantages:

1. **Pro:** The Zinit NPM packages typically use the URLs to the official and
   *latest* distributions of the software (like e.g.: the
   [ecs-cli](https://github.com/zdharma-continuum/zinit-package-ecs-cli)
   package, which uses the following URL:
   `https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest` (when
   run on Linux).

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

## Adding Your Own Package

You can contact me to have the repository at the Zsh-Packages organization.
Then, you'll only need to:

1. Create an NPM account

2. Invoke `npm login`.

3. Populate the `package.json` – I suggest grabbing the one for `fzf` or
   `doctoc` and doing a few substitutions like `doctoc` → `your-project` and
   then simply filling the `default` profile in the `zinit-ices` object – it's
   obvious how to do this.

4. The project name in the `package.json` should start with `zsh-`. The prefix
   will be skipped when specifying it with Zinit.

5. Commit and invoke `npm publish`.

That's all!

[]( vim:set ft=markdown tw=80 fo+=a1n autoindent: )
