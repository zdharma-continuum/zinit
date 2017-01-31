/*
 * autoload2.c – alternative autoload for Zsh, via module
 *
 * Copyright (c) 2017 Sebastian Gniazdowski
 * All rights reserved.
 */

#include "autoload2.mdh"
#include "autoload2.pro"

/*
 * Repeated, copied from exec.c, because it's static
 */

/**/
static void
loadautofnsetfile(Shfunc shf, char *fdir)
{
    /*
     * If shf->filename is already the load directory ---
     * keep it as we can still use it to get the load file.
     * This makes autoload with an absolute path particularly efficient.
     */
    if (!(shf->node.flags & PM_LOADDIR) ||
	strcmp(shf->filename, fdir) != 0) {
	/* Old directory name not useful... */
	dircache_set(&shf->filename, NULL);
	if (fdir) {
	    /* ...can still cache directory */
	    shf->node.flags |= PM_LOADDIR;
	    dircache_set(&shf->filename, fdir);
	} else {
	    /* ...no separate directory part to cache, for some reason. */
	    shf->node.flags &= ~PM_LOADDIR;
	    shf->filename = ztrdup(shf->node.nam);
	}
    }
}

/**/
Shfunc
loadautofn(Shfunc shf, int fksh, int autol, int current_fpath)
{
    int noalias = noaliases, ksh = 1;
    Eprog prog;
    char *fdir;			/* Directory path where func found */

    pushheap();

    noaliases = (shf->node.flags & PM_UNALIASED);
    if (shf->filename && shf->filename[0] == '/' &&
	(shf->node.flags & PM_LOADDIR))
    {
	char *spec_path[2];
	spec_path[0] = dupstring(shf->filename);
	spec_path[1] = NULL;
	prog = getfpfunc(shf->node.nam, &ksh, &fdir, spec_path, 0);
	if (prog == &dummy_eprog &&
	    (current_fpath || (shf->node.flags & PM_CUR_FPATH)))
	    prog = getfpfunc(shf->node.nam, &ksh, &fdir, NULL, 0);
    }
    else {
        Shfunc shf2;
        Funcstack fs;
        const char *calling_f = NULL;
        char *spec_path[2] = {NULL,NULL};

        /* Find calling function */
	for (fs = funcstack; fs; fs = fs->prev) {
	    if (fs->tp == FS_FUNC && 0 != strcmp(fs->name,shf->node.nam)) {
                calling_f = fs->name;
		break;
	    }
	}

        /* Get its Shfunc */
        if (calling_f) {
            if ((shf2 = (Shfunc) shfunctab->getnode2(shfunctab, calling_f))) {
                if (shf2->node.flags & PM_LOADDIR) {
                    spec_path[0] = dupstring(shf2->filename);
                }
            }
        }

        /* Load via associated directory */
        if (spec_path[0]) {
            prog = getfpfunc(shf->node.nam, &ksh, &fdir, spec_path, 0);
            if (prog == &dummy_eprog) {
                spec_path[0] = NULL;
            }
        }

        /* Load via fpath */
	if (!spec_path[0]) {
            prog = getfpfunc(shf->node.nam, &ksh, &fdir, NULL, 0);
        }
    }
    noaliases = noalias;

    if (ksh == 1) {
	ksh = fksh;
	if (ksh == 1)
	    ksh = (shf->node.flags & PM_KSHSTORED) ? 2 :
		  (shf->node.flags & PM_ZSHSTORED) ? 0 : 1;
    }

    if (prog == &dummy_eprog) {
	/* We're not actually in the function; decrement locallevel */
	locallevel--;
	zwarn("%s: function definition file not found", shf->node.nam);
	locallevel++;
	popheap();
	return NULL;
    }
    if (!prog) {
	popheap();
	return NULL;
    }
    if (ksh == 2 || (ksh == 1 && isset(KSHAUTOLOAD))) {
	if (autol) {
	    prog->flags |= EF_RUN;

	    freeeprog(shf->funcdef);
	    if (prog->flags & EF_MAP)
		shf->funcdef = prog;
	    else
		shf->funcdef = dupeprog(prog, 0);
	    shf->node.flags &= ~PM_UNDEFINED;
	    loadautofnsetfile(shf, fdir);
	} else {
	    VARARR(char, n, strlen(shf->node.nam) + 1);
	    strcpy(n, shf->node.nam);
	    execode(prog, 1, 0, "evalautofunc");
	    shf = (Shfunc) shfunctab->getnode(shfunctab, n);
	    if (!shf || (shf->node.flags & PM_UNDEFINED)) {
		/* We're not actually in the function; decrement locallevel */
		locallevel--;
		zwarn("%s: function not defined by file", n);
		locallevel++;
		popheap();
		return NULL;
	    }
	}
    } else {
	freeeprog(shf->funcdef);
	if (prog->flags & EF_MAP)
	    shf->funcdef = stripkshdef(prog, shf->node.nam);
	else
	    shf->funcdef = dupeprog(stripkshdef(prog, shf->node.nam), 0);
	shf->node.flags &= ~PM_UNDEFINED;
	loadautofnsetfile(shf, fdir);
    }
    popheap();

    return shf;
}

/**/
static int
bin_autoload2(char *nam, char **args, Options ops, UNUSED(int func))
{
    return 0;
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
