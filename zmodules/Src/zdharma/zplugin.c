/* -*- Mode: C; c-default-style: "linux"; c-basic-offset: 4; indent-tabs-mode: nil -*-
 * vim:sw=4:sts=4:et
 *
 * zplugin.c – module for Zplugin plugin manager
 *
 * Copyright (c) 2017 Sebastian Gniazdowski
 * All rights reserved.
 *
 * The file contains code copied from Zshell source (e.g. code of builtins that are
 * then customized by me) and this code is under license:
 *
 * Permission is hereby granted, without written agreement and without
 * license or royalty fees, to use, copy, modify, and distribute this
 * software and to distribute modified versions of this software for any
 * purpose, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * In no event shall Paul Falstad or the Zsh Development Group be liable
 * to any party for direct, indirect, special, incidental, or consequential
 * damages arising out of the use of this software and its documentation,
 * even if Paul Falstad and the Zsh Development Group have been advised of
 * the possibility of such damage.
 *
 * Paul Falstad and the Zsh Development Group specifically disclaim any
 * warranties, including, but not limited to, the implied warranties of
 * merchantability and fitness for a particular purpose.  The software
 * provided hereunder is on an "as is" basis, and Paul Falstad and the
 * Zsh Development Group have no obligation to provide maintenance,
 * support, updates, enhancements, or modifications.
 */

#include "zplugin.mdh"
#include "zplugin.pro"

static HandlerFunc originalDot = NULL;
static HashTable zp_hash = NULL;

struct basic_node {
    struct hashnode node;
};

/* FUNCTION: bin_custom_dot {{{ */
/**/
int
bin_custom_dot(char *name, char **argv, UNUSED(Options ops), UNUSED(int func))
{
    char **old, *old0 = NULL;
    int diddot = 0, dotdot = 0;
    char *s, **t, *enam, *arg0, *buf;
    struct stat st;
    enum source_return ret;

    if (!*argv)
	return 0;
    old = pparams;
    /* get arguments for the script */
    if (argv[1])
	pparams = zarrdup(argv + 1);

    enam = arg0 = ztrdup(*argv);
    if (isset(FUNCTIONARGZERO)) {
	old0 = argzero;
	argzero = ztrdup(arg0);
    }
    s = unmeta(enam);
    errno = ENOENT;
    ret = SOURCE_NOT_FOUND;
    /* for source only, check in current directory first */
    if (*name != '.' && access(s, F_OK) == 0
	&& stat(s, &st) >= 0 && !S_ISDIR(st.st_mode)) {
	diddot = 1;
	ret = source(enam);
    }
    if (ret == SOURCE_NOT_FOUND) {
	/* use a path with / in it */
	for (s = arg0; *s; s++)
	    if (*s == '/') {
		if (*arg0 == '.') {
		    if (arg0 + 1 == s)
			++diddot;
		    else if (arg0[1] == '.' && arg0 + 2 == s)
			++dotdot;
		}
		ret = source(arg0);
		break;
	    }
	if (!*s || (ret == SOURCE_NOT_FOUND &&
		    isset(PATHDIRS) && diddot < 2 && dotdot == 0)) {
	    pushheap();
	    /* search path for script */
	    for (t = path; *t; t++) {
		if (!(*t)[0] || ((*t)[0] == '.' && !(*t)[1])) {
		    if (diddot)
			continue;
		    diddot = 1;
		    buf = dupstring(arg0);
		} else
		    buf = zhtricat(*t, "/", arg0);

		s = unmeta(buf);
		if (access(s, F_OK) == 0 && stat(s, &st) >= 0
		    && !S_ISDIR(st.st_mode)) {
		    ret = source(enam = buf);
		    break;
		}
	    }
	    popheap();
	}
    }
    /* clean up and return */
    if (argv[1]) {
	freearray(pparams);
	pparams = old;
    }
    if (ret == SOURCE_NOT_FOUND) {
	if (isset(POSIXBUILTINS)) {
	    /* hard error in POSIX (we'll exit later) */
	    zerrnam(name, "%e: %s", errno, enam);
	} else {
	    zwarnnam(name, "%e: %s", errno, enam);
	}
    }
    zsfree(arg0);
    if (old0) {
	zsfree(argzero);
	argzero = old0;
    }
    return ret == SOURCE_OK ? lastval : 128 - ret;
}
/* }}} */

/* FUNCTION: bin_zpmod {{{ */
static int
bin_zpmod( char *nam, char **argv, UNUSED( Options ops ), UNUSED( int func ) ) {
    char *subcmd = NULL;
    int ret = 0;

    if ( OPT_ISSET( ops, 'h' ) ) {
        zpmod_usage();
        return 0;
    }

    if ( !*argv ) {
        zwarnnam( nam, "`zpmod' takes a sub-command as first argument, see -h" );
        return 1;
    }

    subcmd = *argv ++;

    if ( 0 == strcmp( subcmd, "report-append" ) ) {
        char *target = NULL, *body = NULL;
        int target_len = 0, body_len = 0;

        target = *argv ++;
        if ( !target ) {
            zwarnnam( nam, "`report-append' is missing the target plugin ID (like \"zdharma/zbrowse\", see -h" );
            return 1;
        }
        target = zp_unmetafy_zalloc( target, &target_len );
        if ( !target ) {
            zwarnnam( nam, "Couldn't allocate new memory (1), operation aborted" );
            return 1;
        }

        body = *argv ++;
        if ( !body ) {
            zwarnnam( nam, "`report-append' is missing the report-body to append, see -h" );
            return 1;
        }
        body_len = strlen( body );

        ret = zp_append_report( nam, target, target_len, body, body_len );
        zfree( target, target_len );
    } else {
        zwarnnam( nam, "Unknown zplugin-module command: `%s', see `-h'", subcmd );
    }

    return ret;
}
/* }}} */

/* FUNCTION: zp_append_report {{{ */
/**/
static int
zp_append_report( const char *nam, const char *target, int target_len, const char *body, int body_len ) {
    Param pm = NULL, val_pm = NULL;
    HashTable ht = NULL;
    HashNode hn = NULL;
    char *target_string = NULL;
    int target_string_len = 0, new_extended_len = 0;

    /* Get ZPLG_REPORTS associative array */
    pm = ( Param ) paramtab->getnode( paramtab, "ZPLG_REPORTS" );
    if ( !pm ) {
        zwarnnam( nam, "Parameter $ZPLG_REPORTS isn't declared. Zplugin is not loaded? I.e. not sourced." );
        return 1;
    }

    /* Get ZPLG_REPORTS[{target}] hashed Param */
    ht = pm->u.hash;
    hn = gethashnode2( ht, target );
    val_pm = ( Param ) hn;
    if ( !val_pm ) {
        zwarnnam( nam, "Plugin %s isn't registered, cannot append to its report.", target );
        return 1;
    }

    /* Nothing to append? */
    if ( body_len == 0 ) {
        return 0;
    }

    /* Get string that the hashed Param holds */
    target_string = val_pm->u.str;
    if( !target_string ) {
        target_string_len = 0;
    } else {
        target_string_len = strlen( target_string );
    }

    /* Extend the string with additional body_len-bytes */
    new_extended_len = target_string_len + body_len;
    target_string = realloc( target_string, ( new_extended_len + 1 ) * sizeof( char ) );
    if ( NULL == target_string ) {
        zwarnnam( nam, "Couldn't allocate new memory (2), operation aborted" );
        return 1;
    }

    /* Copy contents of body, null terminate */
    memcpy( target_string + target_string_len, body, sizeof( char ) * body_len );
    target_string[ new_extended_len ] = '\0';

    /* Store the pointer in case realloc() allocated a new buffer */
    val_pm->u.str = target_string;

    return 0;
}
/* }}} */
/* FUNCTION: zpmod_usage {{{ */
/**/
void zpmod_usage() {
    fprintf( stdout, "Usage: zpmod {subcommand} {subcommand-arguments}\n" );
    fprintf( stdout, "       zpmod report-append {plugin-ID} {new-report-body}\n");
}
/* }}} */

/* FUNCTION: zp_createhashtable {{{ */
/**/
static HashTable
zp_createhashtable( char *name )
{
    HashTable ht;

    ht = newhashtable( 8, name, NULL );

    ht->hash        = hasher;
    ht->emptytable  = emptyhashtable;
    ht->filltable   = NULL;
    ht->cmpnodes    = strcmp;
    ht->addnode     = addhashnode;
    ht->getnode     = gethashnode2;
    ht->getnode2    = gethashnode2;
    ht->removenode  = removehashnode;
    ht->disablenode = NULL;
    ht->enablenode  = NULL;
    ht->freenode    = zp_freebasicnode;
    ht->printnode   = NULL;

    return ht;
}
/* }}} */
/* FUNCTION: zp_createhashparam {{{ */
/**/
static Param
zp_createhashparam( char *name, int flags )
{
    Param pm;
    HashTable ht;

    pm = createparam( name, flags | PM_SPECIAL | PM_HASHED );
    if ( !pm ) {
        return NULL;
    }

    if ( pm->old )
        pm->level = locallevel;

    /* This creates standard hash. */
    ht = pm->u.hash = newparamtable( 7, name );
    if ( !pm->u.hash ) {
        paramtab->removenode( paramtab, name );
        paramtab->freenode( &pm->node );
        zwarnnam( name, "Out of memory when allocating user-visible hash parameter" );
        return NULL;
    }

    /* Does free Param (unsetfn is called) */
    ht->freenode = zp_freeparamnode;

    return pm;
}
/* }}} */
/* FUNCTION: zp_freebasicnode {{{ */
/**/
static void
zp_freebasicnode( HashNode hn )
{
    zsfree( hn->nam );
    zfree( hn, sizeof( struct basic_node ) );
}
/* }}} */
/* FUNCTION: zp_freeparamnode {{{ */
/**/
void
zp_freeparamnode( HashNode hn )
{
    Param pm = ( Param ) hn;

    /* Upstream: The second argument of unsetfn() is used by modules to
     * differentiate "exp"licit unset from implicit unset, as when
     * a parameter is going out of scope.  It's not clear which
     * of these applies here, but passing 1 has always worked.
     */

    /* if (delunset) */
    pm->gsu.s->unsetfn( pm, 1 );

    zsfree( pm->node.nam );
    /* If this variable was tied by the user, ename was ztrdup'd */
    if ( pm->node.flags & PM_TIED && pm->ename ) {
        zsfree( pm->ename );
        pm->ename = NULL;
    }
    zfree( pm, sizeof( struct param ) );
}
/* }}} */


/* FUNCTION: my_ztrdup_glen {{{ */
/**/
char *
my_ztrdup_glen( const char *s, unsigned *len_ret )
{
    char *t;

    if ( !s )
        return NULL;
    t = ( char * )zalloc( ( *len_ret = strlen( ( char * )s ) ) + 1 );
    strcpy( t, s );
    return t;
}
/* }}} */
/* FUNCTION: zp_unmetafy_zalloc {{{ */
/*
 * Unmetafy that:
 * - duplicates buffer to work on it - original buffer is unchanged, can be zsfree'd,
 * - does zalloc of exact size for the new unmeta-string - this string can be zfree'd,
 * - restores work-buffer to original meta-content, to restore strlen - thus work-buffer can be zsfree'd,
 * - returns actual length of the output unmeta-string, which should be passed to zfree.
 *
 * This function can be avoided if there's no need for new buffer, user should first strlen
 * the metafied string, store the length into a variable (e.g. meta_length), then unmetafy,
 * use the unmeta-content, then zfree( buf, meta_length ).
 */

/**/
char *
zp_unmetafy_zalloc( const char *to_copy, int *new_len )
{
    char *work, *to_return;
    int my_new_len = 0;
    unsigned meta_length = 0;

    work = my_ztrdup_glen( to_copy, &meta_length );
    if ( !work ) {
        return NULL;
    }

    work = unmetafy( work, &my_new_len );

    if ( new_len )
        *new_len = my_new_len;

    to_return = ( char * )zalloc( ( my_new_len + 1 ) * sizeof( char ) );
    if ( !to_return ) {
        zfree( work, meta_length );
        return NULL;
    }

    memcpy( to_return, work, sizeof( char ) * my_new_len ); /* memcpy handles $'\0' */
    to_return[ my_new_len ] = '\0';

    /* Restore original content and correctly zsfree(). */
    /* UPDATE: instead of zsfree() here now it is
     * zfree() that's used and the length it needs
     * is taken above from my_ztrdup_glen */
    zfree( work, meta_length );

    return to_return;
}
/* }}} */

/* ARRAY: struct builtin bintab[] {{{ */
static struct builtin bintab[] =
{
    BUILTIN( "custom_dot", 0, bin_custom_dot, 1, -1, 0, NULL, NULL ),
    BUILTIN( "zpmod", 0, bin_zpmod, 0, -1, 0, "h", NULL ),
};
/* }}} */
/* STRUCT: struct features module_features {{{ */
static struct features module_features =
{
    bintab, sizeof( bintab )/sizeof( *bintab ),
    NULL, 0,
    NULL, 0,
    NULL, 0,
    0
};
/* }}} */

/**/
int
setup_( UNUSED( Module m ) )
{
    Builtin bn = ( Builtin ) builtintab->getnode2( builtintab, "." );
    originalDot = bn->handlerfunc;
    bn->handlerfunc = bin_custom_dot;

    /* Create private hash with source_prepare requests */
    if ( !( zp_hash = zp_createhashtable( "zp_hash" ) ) ) {
        zwarn( "Cannot create the hash table" );
        return 1;
    }

    return 0;
}

/**/
int
features_( Module m, char ***features )
{
    *features = featuresarray( m, &module_features );
    return 0;
}

/**/
int
enables_( Module m, int **enables )
{
    return handlefeatures( m, &module_features, enables );
}

/**/
int
boot_( Module m )
{
    return 0;
}

/**/
int
cleanup_( Module m )
{
    return setfeatureenables( m, &module_features, NULL );
}

/**/
int
finish_( UNUSED( Module m ) )
{
    Builtin bn = ( Builtin ) builtintab->getnode2( builtintab, "." );
    bn->handlerfunc = originalDot;

    printf( "zdharma/zplugin module unloaded\n" );
    fflush( stdout );
    return 0;
}
