/*
 * autoload2.c – alternative autoload for Zsh, via module
 *
 * Copyright (c) 2017 Sebastian Gniazdowski
 * All rights reserved.
 */

#include "autoload2.mdh"
#include "autoload2.pro"

/* parameters */

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
