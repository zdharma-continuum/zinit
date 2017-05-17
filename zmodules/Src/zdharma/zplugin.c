/*
 * zplugin.c – module for Zplugin plugin manager
 *
 * Copyright (c) 2017 Sebastian Gniazdowski
 * All rights reserved.
 */

#include "zplugin.mdh"
#include "zplugin.pro"

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
    int returnval = 0;
    int on = 0, off = 0, roff;

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

    return returnval;
}

static struct features module_features = { 0 };

/**/
int
setup_(UNUSED(Module m))
{
    Builtin bn = (Builtin) builtintab->getnode2(builtintab, "autoload");
    bn->handlerfunc = bin_autoload2;

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
    printf("Thank you for using the example module.  Have a nice day.\n");
    fflush(stdout);
    return 0;
}
