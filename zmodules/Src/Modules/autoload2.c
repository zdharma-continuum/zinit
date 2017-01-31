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

/* Helper for bin_functions() for -X and -r options */

/**/
static int
check_autoload(Shfunc shf, char *name, Options ops, int func)
{
    if (OPT_ISSET(ops,'X'))
    {
	return eval_autoload(shf, name, ops, func);
    }
    if ((OPT_ISSET(ops,'r') || OPT_ISSET(ops,'R')) &&
	(shf->node.flags & PM_UNDEFINED))
    {
	char *dir_path;
	if (shf->filename && (shf->node.flags & PM_LOADDIR)) {
	    char *spec_path[2];
	    spec_path[0] = shf->filename;
	    spec_path[1] = NULL;
	    if (getfpfunc(shf->node.nam, NULL, &dir_path, spec_path, 1)) {
		/* shf->filename is already correct. */
		return 0;
	    }
	    if (!OPT_ISSET(ops,'d')) {
		if (OPT_ISSET(ops,'R')) {
		    zerr("%s: function definition file not found",
			 shf->node.nam);
		    return 1;
		}
		return 0;
	    }
	}
	if (getfpfunc(shf->node.nam, NULL, &dir_path, NULL, 1)) {
	    dircache_set(&shf->filename, NULL);
	    if (*dir_path != '/') {
		dir_path = zhtricat(metafy(zgetcwd(), -1, META_HEAPDUP),
				    "/", dir_path);
		dir_path = xsymlink(dir_path, 1);
	    }
	    dircache_set(&shf->filename, dir_path);
	    shf->node.flags |= PM_LOADDIR;
	    return 0;
	}
	if (OPT_ISSET(ops,'R')) {
	    zerr("%s: function definition file not found",
		 shf->node.nam);
	    return 1;
	}
	/* with -r, we don't flag an error, just let it be found later. */
    }
    return 0;
}

static void
add_autoload_function(Shfunc shf, char *funcname)
{
    char *nam;
    if (*funcname == '/' && funcname[1] &&
	(nam = strrchr(funcname, '/')) && nam[1] &&
	(shf->node.flags & PM_UNDEFINED)) {
	char *dir;
	nam = strrchr(funcname, '/');
	if (nam == funcname) {
	    dir = "/";
	} else {
	    *nam++ = '\0';
	    dir = funcname;
	}
	dircache_set(&shf->filename, NULL);
	dircache_set(&shf->filename, dir);
	shf->node.flags |= PM_LOADDIR;
	shfunctab->addnode(shfunctab, ztrdup(nam), shf);
    } else {
	shfunctab->addnode(shfunctab, ztrdup(funcname), shf);
    }
}

/**/
static void
listusermathfunc(MathFunc p)
{
    int showargs;

    if (p->module)
	showargs = 3;
    else if (p->maxargs != (p->minargs ? p->minargs : -1))
	showargs = 2;
    else if (p->minargs)
	showargs = 1;
    else
	showargs = 0;

    printf("functions -M %s", p->name);
    if (showargs) {
	printf(" %d", p->minargs);
	showargs--;
    }
    if (showargs) {
	printf(" %d", p->maxargs);
	showargs--;
    }
    if (showargs) {
	/*
	 * function names are not required to consist of ident characters
	 */
	putchar(' ');
	quotedzputs(p->module, stdout);
	showargs--;
    }
    putchar('\n');
}

/**/
static int
bin_autoload2(char *name, char **argv, Options ops, int func)
{
    Patprog pprog;
    Shfunc shf;
    int i, returnval = 0;
    int on = 0, off = 0, pflags = 0, roff, expand = 0;

    /* Do we have any flags defined? */
    if (OPT_PLUS(ops,'u'))
	off |= PM_UNDEFINED;
    else if (OPT_MINUS(ops,'u') || OPT_ISSET(ops,'X'))
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

    if ((off & PM_UNDEFINED) || (OPT_ISSET(ops,'k') && OPT_ISSET(ops,'z')) ||
	(OPT_ISSET(ops,'x') && !OPT_HASARG(ops,'x')) ||
	(OPT_MINUS(ops,'X') && (OPT_ISSET(ops,'m') || !scriptname))) {
	zwarnnam(name, "invalid option(s)");
	return 1;
    }

    if (OPT_ISSET(ops,'x')) {
	char *eptr;
	expand = (int)zstrtol(OPT_ARG(ops,'x'), &eptr, 10);
	if (*eptr) {
	    zwarnnam(name, "number expected after -x");
	    return 1;
	}
	if (expand == 0)	/* no indentation at all */
	    expand = -1;
    }

    if (OPT_PLUS(ops,'f') || roff || OPT_ISSET(ops,'+'))
	pflags |= PRINT_NAMEONLY;

    if (OPT_MINUS(ops,'M') || OPT_PLUS(ops,'M')) {
	MathFunc p, q;
	/*
	 * Add/remove/list function as mathematical.
	 */
	if (on || off || pflags || OPT_ISSET(ops,'X') || OPT_ISSET(ops,'u')
	    || OPT_ISSET(ops,'U') || OPT_ISSET(ops,'w')) {
	    zwarnnam(name, "invalid option(s)");
	    return 1;
	}
	if (!*argv) {
	    /* List functions. */
	    queue_signals();
	    for (p = mathfuncs; p; p = p->next)
		if (p->flags & MFF_USERFUNC)
		    listusermathfunc(p);
	    unqueue_signals();
	} else if (OPT_ISSET(ops,'m')) {
	    /* List matching functions. */
	    for (; *argv; argv++) {
		queue_signals();
		tokenize(*argv);
		if ((pprog = patcompile(*argv, PAT_STATIC, 0))) {
		    for (p = mathfuncs, q = NULL; p; q = p) {
			MathFunc next;
			do {
			    next = NULL;
			    if ((p->flags & MFF_USERFUNC) &&
				pattry(pprog, p->name)) {
				if (OPT_PLUS(ops,'M')) {
				    next = p->next;
				    removemathfunc(q, p);
				    p = next;
				} else
				    listusermathfunc(p);
			    }
			    /* if we deleted one, retry with the new p */
			} while (next);
			if (p)
			    p = p->next;
		    }
		} else {
		    untokenize(*argv);
		    zwarnnam(name, "bad pattern : %s", *argv);
		    returnval = 1;
		}
		unqueue_signals();
	    }
	} else if (OPT_PLUS(ops,'M')) {
	    /* Delete functions. -m is allowed but is handled above. */
	    for (; *argv; argv++) {
		queue_signals();
		for (p = mathfuncs, q = NULL; p; q = p, p = p->next) {
		    if (!strcmp(p->name, *argv)) {
			if (!(p->flags & MFF_USERFUNC)) {
			    zwarnnam(name, "+M %s: is a library function",
				     *argv);
			    returnval = 1;
			    break;
			}
			removemathfunc(q, p);
			break;
		    }
		}
		unqueue_signals();
	    }
	} else {
	    /* Add a function */
	    int minargs = 0, maxargs = -1;
	    char *funcname = *argv++;
	    char *modname = NULL;
	    char *ptr;

	    ptr = itype_end(funcname, IIDENT, 0);
	    if (idigit(*funcname) || funcname == ptr || *ptr) {
		zwarnnam(name, "-M %s: bad math function name", funcname);
		return 1;
	    }

	    if (*argv) {
		minargs = (int)zstrtol(*argv, &ptr, 0);
		if (minargs < 0 || *ptr) {
		    zwarnnam(name, "-M: invalid min number of arguments: %s",
			     *argv);
		    return 1;
		}
		maxargs = minargs;
		argv++;
	    }
	    if (*argv) {
		maxargs = (int)zstrtol(*argv, &ptr, 0);
		if (maxargs < -1 ||
		    (maxargs != -1 && maxargs < minargs) ||
		    *ptr) {
		    zwarnnam(name,
			     "-M: invalid max number of arguments: %s",
			     *argv);
		    return 1;
		}
		argv++;
	    }
	    if (*argv)
		modname = *argv++;
	    if (*argv) {
		zwarnnam(name, "-M: too many arguments");
		return 1;
	    }

	    p = (MathFunc)zshcalloc(sizeof(struct mathfunc));
	    p->name = ztrdup(funcname);
	    p->flags = MFF_USERFUNC;
	    p->module = modname ? ztrdup(modname) : NULL;
	    p->minargs = minargs;
	    p->maxargs = maxargs;

	    queue_signals();
	    for (q = mathfuncs; q; q = q->next) {
		if (!strcmp(q->name, funcname)) {
		    unqueue_signals();
		    zwarnnam(name, "-M %s: function already exists",
			     funcname);
		    zsfree(p->name);
		    zsfree(p->module);
		    zfree(p, sizeof(struct mathfunc));
		    return 1;
		}
	    }

	    p->next = mathfuncs;
	    mathfuncs = p;
	    unqueue_signals();
	}

	return returnval;
    }

    if (OPT_MINUS(ops,'X')) {
	Funcstack fs;
	char *funcname = NULL;
	int ret;
	if (*argv && argv[1]) {
	    zwarnnam(name, "-X: too many arguments");
	    return 1;
	}
	queue_signals();
	for (fs = funcstack; fs; fs = fs->prev) {
	    if (fs->tp == FS_FUNC) {
		/*
		 * dupstring here is paranoia but unlikely to be
		 * problematic
		 */
		funcname = dupstring(fs->name);
		break;
	    }
	}
	if (!funcname)
	{
	    zerrnam(name, "bad autoload");
	    ret = 1;
	} else {
	    if ((shf = (Shfunc) shfunctab->getnode(shfunctab, funcname))) {
		DPUTS(!shf->funcdef,
		      "BUG: Calling autoload from empty function");
	    } else {
		shf = (Shfunc) zshcalloc(sizeof *shf);
		shfunctab->addnode(shfunctab, ztrdup(funcname), shf);
	    }
	    if (*argv) {
		dircache_set(&shf->filename, NULL);
		dircache_set(&shf->filename, *argv);
		on |= PM_LOADDIR;
	    }
	    shf->node.flags = on;
	    ret = eval_autoload(shf, funcname, ops, func);
	}
	unqueue_signals();
	return ret;
    } else if (!*argv) {
	/* If no arguments given, we will print functions.  If flags *
	 * are given, we will print only functions containing these  *
	 * flags, else we'll print them all.                         */
	int ret = 0;

	queue_signals();
	if (OPT_ISSET(ops,'U') && !OPT_ISSET(ops,'u'))
		on &= ~PM_UNDEFINED;
	    scanshfunc(1, on|off, DISABLED, shfunctab->printnode,
		       pflags, expand);
	unqueue_signals();
	return ret;
    }

    /* With the -m option, treat arguments as glob patterns */
    if (OPT_ISSET(ops,'m')) {
	on &= ~PM_UNDEFINED;
	for (; *argv; argv++) {
	    queue_signals();
	    /* expand argument */
	    tokenize(*argv);
	    if ((pprog = patcompile(*argv, PAT_STATIC, 0))) {
		/* with no options, just print all functions matching the glob pattern */
		if (!(on|off) && !OPT_ISSET(ops,'X')) {
		    scanmatchshfunc(pprog, 1, 0, DISABLED,
				   shfunctab->printnode, pflags, expand);
		} else {
		    /* apply the options to all functions matching the glob pattern */
		    for (i = 0; i < shfunctab->hsize; i++) {
			for (shf = (Shfunc) shfunctab->nodes[i]; shf;
			     shf = (Shfunc) shf->node.next)
			    if (pattry(pprog, shf->node.nam) &&
				!(shf->node.flags & DISABLED)) {
				shf->node.flags = (shf->node.flags |
					      (on & ~PM_UNDEFINED)) & ~off;
				if (check_autoload(shf, shf->node.nam,
						   ops, func)) {
				    returnval = 1;
				}
			    }
		    }
		}
	    } else {
		untokenize(*argv);
		zwarnnam(name, "bad pattern : %s", *argv);
		returnval = 1;
	    }
	    unqueue_signals();
	}
	return returnval;
    }

    /* Take the arguments literally -- do not glob */
    queue_signals();
    for (; *argv; argv++) {
	if (OPT_ISSET(ops,'w'))
	    returnval = dump_autoload(name, *argv, on, ops, func);
	else if ((shf = (Shfunc) shfunctab->getnode(shfunctab, *argv))) {
	    /* if any flag was given */
	    if (on|off) {
		/* turn on/off the given flags */
		shf->node.flags = (shf->node.flags | (on & ~PM_UNDEFINED)) & ~off;
		if (check_autoload(shf, shf->node.nam, ops, func))
		    returnval = 1;
	    } else
		/* no flags, so just print */
		printshfuncexpand(&shf->node, pflags, expand);
	} else if (on & PM_UNDEFINED) {
	    int signum = -1, ok = 1;

	    if (!strncmp(*argv, "TRAP", 4) &&
		(signum = getsignum(*argv + 4)) != -1) {
		/*
		 * Because of the possibility of alternative names,
		 * we must remove the trap explicitly.
		 */
		removetrapnode(signum);
	    }

	    if (**argv == '/') {
		char *base = strrchr(*argv, '/') + 1;
		if (*base &&
		    (shf = (Shfunc) shfunctab->getnode(shfunctab, base))) {
		    char *dir;
		    /* turn on/off the given flags */
		    shf->node.flags =
			(shf->node.flags | (on & ~PM_UNDEFINED)) & ~off;
		    if (shf->node.flags & PM_UNDEFINED) {
			/* update path if not yet loaded */
			if (base == *argv + 1)
			    dir = "/";
			else {
			    dir = *argv;
			    base[-1] = '\0';
			}
			dircache_set(&shf->filename, NULL);
			dircache_set(&shf->filename, dir);
		    }
		    if (check_autoload(shf, shf->node.nam, ops, func))
			returnval = 1;
		    continue;
		}
	    }

	    /* Add a new undefined (autoloaded) function to the *
	     * hash table with the corresponding flags set.     */
	    shf = (Shfunc) zshcalloc(sizeof *shf);
	    shf->node.flags = on;
	    shf->funcdef = mkautofn(shf);
	    shfunc_set_sticky(shf);
	    add_autoload_function(shf, *argv);

	    if (signum != -1) {
		if (settrap(signum, NULL, ZSIG_FUNC)) {
		    shfunctab->removenode(shfunctab, *argv);
		    shfunctab->freenode(&shf->node);
		    returnval = 1;
		    ok = 0;
		}
	    }

	    if (ok && check_autoload(shf, shf->node.nam, ops, func))
		returnval = 1;
	} else
	    returnval = 1;
    }
    unqueue_signals();
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
