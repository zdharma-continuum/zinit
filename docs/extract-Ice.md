# The Automatic Archive-Extraction Ice-Tool

Zinit has a swiss-knife tool for unpacking all kinds of archives – the
`extract''` ice. It works in two modes – automatic mode and fixed mode.

## Automatic Mode

It is active if the ice is empty (or contains only flags – more on them later).
It works as follows:

1. At first, a recursive search for files of known [file
   extensions](#supported_file_formats) located not deeper than in
   a sub-directory is being performed. All such found files are then extracted.
    - The directory-level limit is to skip extraction of some helper archive
      files, which are typically located somewhere deeper in the directory tree.
2. **IF** no such files will be found, then a recursive search for files of
   known archive **types** will be performed. This is basically done by running
   the `file` Unix command on each file in the plugin or snippet directory and
   then grepping the output for strings like `Zip`, `bzip2`, etc. All such
   discovered files are then extracted.
    - The directory-level requirement is imposed also during this stage - files
      located deeper in the tree than in a sub-directory are omitted.
3. If no archive files will be discovered then no action is being performed and
   also no warning message is being printed.

## Fixed Mode

It is active when a filename is being passed as the `extract`'s argument, e.g.:
`zinit extract=archive.zip for zdharma-continuum/null`. Multiple files can be specified
– separated by spaces. In this mode all and only the specified files are being
extracted.

#### Filenames With Spaces

The filenames with spaces in them are supported by a trick – to correctly pass
such a filename to `extract` use the non-breaking space in place of the
in-filename original spaces. The non-breaking space is easy to type by pressing
right Alt and the Space.

## Flags

The value of the ice can begin with a two special characters:

1. Exclamation mark (`!`), i.e.: `extract='!…'` – it'll cause the files to be
   moved one directory-level up upon unpacking,
2. Dash (`-`), i.e.: `extract'-…'` – it'll prevent removal of the archive after
   unpacking.
    - This flag is useful to allow comparing timestamps with the server in case
      of snippet-downloaded file – it will prevent unnecessary downloads during
      `zinit update`, as the timestamp of the archive file on the disk will be
      first compared with the HTTP last-modification time header.

The flags can be combined in any order, e.g.: `extract'!-'`.

## `ziextract` Function

Sometimes a more uncommon unpacking operation is needed. In such case you can
directly use the function that implements the ice – it is called `ziextract`. It
recognizes the following options:

1. `--auto` – runs the automatic extraction.
2. `--move` – performs the one-directory-level-up move of the files after
   unpacking.
3. `--norm` - prevents the archive file removal.
4. And also one option specific only to the function: `--nobkp`, which prevents
   clearing of the plugin's dir before the extraction – normally all the files
   except the archive are being moved into `._backup` directory and after that
   the extraction is performed.
    - `extract` ice also skips creating the backup **if** more than one archive
      is found or given as the argument.

## Supported File Formats

- Zip,
- RAR,
- tar.gz,
- tar.bz2,
- tar.xz,
- tar.7z,
- tar,
- gz,
- bz2,
- xz,
- 7z,
- OS X **dmg images**.

[]( vim:set ft=markdown tw=80 fo+=a1n autoindent: )
