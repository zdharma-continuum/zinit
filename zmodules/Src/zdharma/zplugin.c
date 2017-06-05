/* -*- Mode: C; c-basic-offset: 4 -*-
 * vim:sw=4:sts=4:et
 *
 * zplugin.c – module for Zplugin plugin manager
 *
 * Copyright (c) 2017 Sebastian Gniazdowski
 * All rights reserved.
 */

#include "zplugin.mdh"
#include "zplugin.pro"

static HandlerFunc originalAutoload = NULL;

/* ARRAY: builtin {{{ */
static struct builtin bintab[] = {
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
void pack_function(const char *funname, char *funbody) {
    // fprintf(stderr, "Packing function %s:\n%s", funname, funbody);
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

    val_pm->u.str = metafy(funbody, strlen(funbody), META_DUP);

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
    const char *fname, *obtained;
    char *blind, *funbody, *new, *found, *last_line;
    char funname[128];
    int blind_size = 1024, size, retval = 0;
    int funbody_size = 128, funbody_idx = 0;
    int current_type = 0; /* blind read */

#define LINE_SIZE 1024
#define NAME_SIZE 128
#define ZINI_TYPE_BLIND 0
#define ZINI_TYPE_FUNCTION 1

    fname = *argv;
    blind = zalloc(sizeof(char) * blind_size);
    funbody = zalloc(sizeof(char) * funbody_size);

    FILE *in = fopen(fname,"r");
    if (!in) {
        zwarnnam(name, "File doesn't exist: %s", fname);
        retval = 1;
        goto cleanup;
    }

    while (!feof(in)) {
        if (current_type == ZINI_TYPE_BLIND) {
            clearerr(in);
            obtained = fgets(blind, blind_size, in);
            if (obtained) {
                size = strlen(blind);
                if (blind[size-1] != '\n') {
                    /* Don't process such a long line, however correctly skip it */
                    while (blind[size-1] != '\n') {
                        clearerr(in);
                        obtained = fgets(blind, blind_size, in);
                        if (!obtained) {
                            break;
                        } else {
                            size = strlen(blind);
                        }
                    }
                    continue;
                }

                if ( NULL != (found = strstr(blind,"\001fun]"))) {
                    *found = '\0';
                    strncpy(funname, blind+1, NAME_SIZE);
                    funname[NAME_SIZE-1] = '\0';
                    current_type = ZINI_TYPE_FUNCTION;
                    funbody_idx = 0;
                    continue;
                }
            }
        } else if (current_type == ZINI_TYPE_FUNCTION) {
            while(funbody_idx + LINE_SIZE + 1 > funbody_size) {
                new = (char *) zrealloc(funbody, sizeof(char) * funbody_size * 2);
                if (new) {
                    funbody = new;
                    funbody_size = funbody_size * 2;
                    new = NULL;
                } else {
                    zwarnnam(name, "Out of memory, aborting");
                    retval = 1;
                    goto cleanup;
                }
            }

            clearerr(in);
            obtained = fgets(funbody+funbody_idx, LINE_SIZE, in);
            (funbody+funbody_idx)[LINE_SIZE] = '\0';

            if (!obtained) {
                if (feof(in)) {
                    pack_function(funname, funbody);
                    current_type = ZINI_TYPE_BLIND;
                    funbody_idx = 0;
                } else if(ferror(in)) {
                    zwarnnam(name, "Error when reading function's `%s' body (%s)", funname, strerror(errno));
                    break;
                } else {
                    pack_function(funname, funbody);
                    current_type = ZINI_TYPE_BLIND;
                    funbody_idx = 0;
                }
                continue; 
            }

            last_line = funbody+funbody_idx;
            size = strlen(funbody+funbody_idx);
            funbody_idx += size;

            if (funbody[funbody_idx - 1] != '\n') {
                zwarnnam(name, "Too long line in the function `%s', skipping whole function", funname);
                current_type = ZINI_TYPE_BLIND;
                funbody_idx = 0;
                continue;
            }

            if (0 == strncmp(last_line, "PLG_END_F", 9)) {
                *last_line = '\0';
                pack_function(funname, funbody);
                current_type = ZINI_TYPE_BLIND;
                funbody_idx = 0;
                continue;
            }
        }
    }

cleanup:

    if (blind) {
        zfree(blind, sizeof(char) * blind_size);   
        blind = NULL;
    }
    if (funbody) {
        zfree(funbody, sizeof(char) * funbody_size);
        funbody = NULL;
    }
    return retval;
}
/* }}} */

static struct features module_features = {
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

    printf("The example module has now been set up.\n");

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

    printf("Thank you for using the example module.  Have a nice day.\n");
    fflush(stdout);
    return 0;
}
