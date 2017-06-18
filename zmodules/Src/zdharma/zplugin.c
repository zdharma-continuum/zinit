/* -*- Mode: C; c-default-style: "linux"; c-basic-offset: 4; indent-tabs-mode: nil -*-
 * vim:sw=4:sts=4:et
 *
 * zplugin.c – module for Zplugin plugin manager
 *
 * Copyright (c) 2017 Sebastian Gniazdowski
 * All rights reserved.
 */

#include "zplugin.mdh"
#include "zplugin.pro"
#include <sys/mman.h>

#if !defined(MAP_VARIABLE)
#define MAP_VARIABLE 0
#endif
#if !defined(MAP_FILE)
#define MAP_FILE 0
#endif
#if !defined(MAP_NORESERVE)
#define MAP_NORESERVE 0
#endif

#define MMAP_ARGS (MAP_FILE | MAP_VARIABLE | MAP_SHARED | MAP_NORESERVE)

static HandlerFunc originalAutoload = NULL;


/* ARRAY: builtin {{{ */
static struct builtin bintab[] =
{
    BUILTIN("ziniload", 0, bin_ziniload, 0, -1, 0, "", NULL),
};
/* }}} */

static const char *out_hash = "ZPLG_FBODIES";

/* FUNCTION: bin_autoload2 {{{ */
/*
 * k   - ksh autoload
 * z   - zsh autoload
 * X,- - replace definition of function with autoloaded one, execute
 * X,+ - load immediately, do not execute
 * m   - name treated as pattern, used with +X
 * d   - search $fpath even with a path
 * U   - no aliases
 * W   - WARN_NESTED_VAR
 * r   - resolve absolute path, silent on error
 * R   - resolve absolute path, aborts on error
 * t   - turn on execution tracing
 * T   - as above, but turn off for called functions
 */

/**/
static int
bin_autoload2(char *name, char **argv, Options ops, int func)
{
    Shfunc shf;
    int on = 0, off = 0, roff;
    char **in_argv = argv;

    /* Do we have any flags defined? */
    if (OPT_ISSET(ops,'X'))
        on |= PM_UNDEFINED;
    if (OPT_MINUS(ops,'U'))
        on |= PM_UNALIASED|PM_UNDEFINED;
    else if (OPT_PLUS(ops,'U'))
        off |= PM_UNALIASED;
    if (OPT_MINUS(ops,'t'))
        on |= PM_TAGGED;
    else if (OPT_PLUS(ops,'t'))
        off |= PM_TAGGED;
    if (OPT_MINUS(ops,'T'))
        on |= PM_TAGGED_LOCAL;
    else if (OPT_PLUS(ops,'T'))
        off |= PM_TAGGED_LOCAL;
    if (OPT_MINUS(ops,'W'))
        on |= PM_WARNNESTED;
    else if (OPT_PLUS(ops,'W'))
        off |= PM_WARNNESTED;
    roff = off;
    if (OPT_MINUS(ops,'z')) {
        on |= PM_ZSHSTORED;
        off |= PM_KSHSTORED;
    } else if (OPT_PLUS(ops,'z')) {
        off |= PM_ZSHSTORED;
        roff |= PM_ZSHSTORED;
    }
    if (OPT_MINUS(ops,'k')) {
        on |= PM_KSHSTORED;
        off |= PM_ZSHSTORED;
    } else if (OPT_PLUS(ops,'k')) {
        off |= PM_KSHSTORED;
        roff |= PM_KSHSTORED;
    }
    if (OPT_MINUS(ops,'d')) {
        on |= PM_CUR_FPATH;
        off |= PM_CUR_FPATH;
    } else if (OPT_PLUS(ops,'d')) {
        off |= PM_CUR_FPATH;
        roff |= PM_CUR_FPATH;
    }

    /* If option recognizing is finished */
    int finished = 0;

    if ( (off & PM_UNDEFINED) || (OPT_ISSET(ops,'k') && OPT_ISSET(ops,'z')) ||
         (OPT_MINUS(ops,'X') && (OPT_ISSET(ops,'m') || !scriptname)) )
        {
            /**
             ** This path is: invalid options
             **/

            zwarnnam( name, "Invalid option(s)" );
            finished = 1;
        }

    if ( !finished && OPT_MINUS( ops,'X' ) ) {
        /**
         ** This path is: eval autoload
         % calendar() { autoload -X; }
         % calendar
         calendar:autoload: My: -X
         calendar:calendar: My: eval_autoload does -X, calls mkautofn, bin_eval
        **/

        zwarnnam( name, "-X path" );
        finished = 1;
    } else if ( !finished && !*argv) {
        /**
         ** This path is: print functions
         **/

        zwarnnam( name, "print functions" );
        finished = 1;
    }

    if ( !finished && OPT_ISSET( ops,'m' ) ) {
        /**
         ** This path is: apply options to matching functions
         **               or print functions if no options given
         autoload: -m
         calendar: check_autoload has seen X
         calendar: eval_autoload does loadautofn
         zsh: loadautofn
        **/

        zwarnnam( name, "print functions / apply options, to matching" );
        finished = 1;
    }

    if ( ! finished ) {
        /* Take the arguments literally -- do not glob */
        for (; *argv; argv++) {
            if (OPT_ISSET(ops,'w')) {
                /**
                 ** This path is: from-zcompile
                 **/
                // returnval = dump_autoload(name, *argv, on, ops, func);

                zwarnnam( name, "dump_autoload" );
                finished = 1;
            } else if ((shf = (Shfunc) shfunctab->getnode(shfunctab, *argv))) {
                if (on|off) {
                    /**
                     ** This path is: update options
                     **/

                    /**
                     ** This path is: change options, handle +X
                     % autoload calendar
                     autoload: & PM_UNDEFINED
                     autoload: add_autoload_function
                     autoload: Third check_autoload
                     % autoload +X calendar
                     autoload: Update options
                     autoload: First check_autoload
                     calendar: check_autoload has seen X
                     calendar: eval_autoload does loadautofn
                     zsh: loadautofn
                    **/
                    /* turn on/off the given flags */
                    // shf->node.flags = (shf->node.flags | (on & ~PM_UNDEFINED)) & ~off;
                    // if (check_autoload(shf, shf->node.nam, ops, func))
                    //     returnval = 1;

                    finished = 1;
                } else {
                    /**
                     ** This path is: print function
                     **/

                    finished = 1;
                }
            } else if (on & PM_UNDEFINED) {
                /**
                 ** This path is: +X or no -/+X
                 **/

                if ( **argv == '/' ) {
                    /**
                     ** This path is: update options, update path, handle +X
                     % autoload calendar
                     autoload: & PM_UNDEFINED
                     autoload: add_autoload_function
                     autoload: Third check_autoload
                     % autoload +X /usr/local/share/zsh/5.3.1-dev-0/functions/calendar
                     autoload: & PM_UNDEFINED
                     autoload: At == /
                     autoload: Second check_autoload
                     calendar: check_autoload has seen X
                     calendar: eval_autoload does loadautofn
                     zsh: loadautofn
                    **/

                    char *base = strrchr(*argv, '/') + 1;
                    if ( *base && ( shf = (Shfunc) shfunctab->getnode( shfunctab, base ) ) ) {
                        /* turn on/off the given flags */
                        // shf->node.flags = (shf->node.flags | (on & ~PM_UNDEFINED)) & ~off;
                        if (shf->node.flags & PM_UNDEFINED) {
                            /* update path if not yet loaded */
                            // dircache_set(&shf->filename, NULL);
                            // dircache_set(&shf->filename, dir);
                        }
                        // if (check_autoload(shf, shf->node.nam, ops, func))
                        //  returnval = 1;

                        finished = 1;
                        continue;
                    }
                }

                /**
                 ** This path is: add autoload function STUB
                 % autoload +X calendar
                 autoload: & PM_UNDEFINED
                 autoload: add_autoload_function
                 autoload: Third check_autoload
                 calendar: check_autoload has seen X
                 calendar: eval_autoload does loadautofn
                 zsh: loadautofn
                **/
                // if (ok && check_autoload(shf, shf->node.nam, ops, func))
                //    returnval = 1;

                zwarnnam( name, "Adding autoload stub" );
                finished = 1;
            } else {
                /**
                 ** This path is: bad arguments
                 **/
                // returnval = 1;

                zwarnnam( name, "bad arguments" );
                finished = 1;
            }
        }
    }

    return originalAutoload( name, in_argv, ops, func );
}
/* }}} */
/* FUNCTION: pack_function {{{ */
/**/
static void pack_function(const char *funname, char *mmptr, int len) {
    // fprintf(stderr, "Packing function %s:\n%s", funname, mmptr);
    // fflush(stderr);

    Param pm, val_pm;
    HashTable ht;
    HashNode hn;

    pm = (Param) paramtab->getnode(paramtab, out_hash);
    if(!pm) {
        zwarn("Aborting, no Zplugin parameter `%s', is Zplugin loaded?", out_hash);
        return;
    }

    ht = pm->u.hash;
    hn = gethashnode2(ht, funname);
    val_pm = (Param) hn;

    if (!val_pm) {
        val_pm = (Param) zshcalloc(sizeof (*val_pm));
        val_pm->node.flags = PM_SCALAR | PM_HASHELEM;
        val_pm->gsu.s = &stdscalar_gsu;;
        ht->addnode(ht, ztrdup(funname), val_pm); // sets pm->node.nam
    }

    /* Ensure there's no leak */
    if (val_pm->u.str) {
        zsfree(val_pm->u.str);
        val_pm->u.str = NULL;
    }

    val_pm->u.str = metafy(mmptr, len, META_DUP);

    /* Add short function, easy to parse */
    char fun_buf[256];
    const char *fun_stubfmt = "%s() { functions[%s]=\"${ZPLG_FBODIES[%s]}\"; %s \"$@\"; };";
    sprintf(fun_buf, fun_stubfmt, funname, funname, funname, funname);

    char *fargv[2];
    fargv[0] = fun_buf;
    fargv[1] = 0;

    Options ops = NULL;

    bin_eval("", fargv, ops, 0);
}
/* }}} */
/* FUNCTION: bin_ziniload {{{ */
/**/
static int
bin_ziniload(char *name, char **argv, Options ops, int func)
{
    char *fname;
    int umlen, fd;
    struct stat sbuf;
    caddr_t mmptr = 0;
    int mm_size = 0, mm_idx = 0, start_idx = 0;
    char *last_line;

    char *found, *found2;
    char funname[128];
    int retval = 0;
    int current_type = 0; /* blind read */

#define NAME_SIZE 128
#define ZINI_TYPE_BLIND 0
#define ZINI_TYPE_FUNCTION 1

    fname = *argv;

    unmetafy(fname = ztrdup(fname), &umlen);

    if ((fd = open(fname, O_RDONLY | O_NOCTTY)) < 0 ||
        fstat(fd, &sbuf) ||
        (mmptr = (caddr_t)mmap((caddr_t)0, mm_size = sbuf.st_size, PROT_READ,
                               MMAP_ARGS, fd, (off_t)0)) == (caddr_t)-1) {
        if (fd >= 0) {
            close(fd);
        }

        set_length(fname, umlen);
        zsfree(fname);

        return 1;
    }

    /* Don't need file name anymore */
    set_length(fname, umlen);
    zsfree(fname);

    last_line = mmptr;
    while (1) {
        /* Find new line */
        found = strchr(mmptr+mm_idx, '\n');
        mm_idx = found - mmptr + 1;

        if (!found) {
            // No full line, can abort
            break;
        }

        if (current_type == ZINI_TYPE_BLIND) {

            if ( NULL != (found2 = strnstr(last_line, "\001fun]", found - last_line))) {
                strncpy(funname, last_line + 1, found2 - (last_line + 1));
                funname[NAME_SIZE-1] = '\0';
                funname[found2 - (last_line + 1)] = '\0';
                start_idx = mm_idx;
                current_type = ZINI_TYPE_FUNCTION;
            }

            last_line = found + 1;
            continue;
        } else if (current_type == ZINI_TYPE_FUNCTION) {
            if (mmptr[mm_idx-1] != '\n') {
                zwarnnam(name, "Too long line in the function `%s', skipping whole function", funname);
                current_type = ZINI_TYPE_BLIND;
                last_line = found + 1;
                continue;
            }

            if (0 == strncmp(last_line, "PLG_END_F", 9)) {
                pack_function(funname, mmptr + start_idx, last_line - mmptr - start_idx);
                current_type = ZINI_TYPE_BLIND;
                last_line = found + 1;
            }

            last_line = found + 1;
            continue;
        }
    }

    if (mmptr) {
        munmap(mmptr, sbuf.st_size);
        close(fd);
        mmptr = NULL;
    }
    return retval;
}
/* }}} */
/* FUNCTION: set_length {{{ */
/*
 * For zsh-allocator, rest of Zsh seems to use
 * free() instead of zsfree(), and such length
 * restoration causes slowdown, but all is this
 * way strict - correct */
/**/
static void set_length(char *buf, int size) {
    buf[size]='\0';
    while (-- size >= 0) {
        buf[size]=' ';
    }
}
/* }}} */

static struct features module_features =
{
    bintab, sizeof(bintab)/sizeof(*bintab),
    NULL, 0,
    NULL, 0,
    NULL, 0,
    0
};

/**/
int
setup_(UNUSED(Module m))
{
    // Builtin bn = (Builtin) builtintab->getnode2(builtintab, "autoload");
    // originalAutoload = bn->handlerfunc;
    // bn->handlerfunc = bin_autoload2;

    printf("zdharma/zplugin module has been set up");

    fflush(stdout);
    return 0;
}

/**/
int
features_(Module m, char ***features)
{
    *features = featuresarray(m, &module_features);
    return 0;
}

/**/
int
enables_(Module m, int **enables)
{
    return handlefeatures(m, &module_features, enables);
}

/**/
int
boot_(Module m)
{
    return 0;
}

/**/
int
cleanup_(Module m)
{
    return setfeatureenables(m, &module_features, NULL);
}

/**/
int
finish_(UNUSED(Module m))
{
    // Builtin bn = (Builtin) builtintab->getnode2(builtintab, "autoload");
    // bn->handlerfunc = originalAutoload;

    printf("zdharma/zplugin module unloaded\n");
    fflush(stdout);
    return 0;
}
