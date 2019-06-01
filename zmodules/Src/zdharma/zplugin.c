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

/* Source/bin_dot related data structures {{{ */
static HandlerFunc originalDot = NULL, originalSource = NULL;
static HashTable zp_source_events = NULL;
static int zp_sevent_count = 0;

struct source_event {
    int id;
    long ts;
    char *dir_path;
    char *file_name;
    char *full_path;
    double duration;
    int load_error;
};

struct zp_sevent_node {
    struct hashnode node;
    struct source_event event;
};

typedef struct zp_sevent_node *SEventNode;
/* }}} */

/* Option support {{{ */
static int zp_opt_for_zsh_version[256] = { 0 };

enum {
    OPT_INVALID__,
    ALIASESOPT__,
    ALIASFUNCDEF__,
    ALLEXPORT__,
    ALWAYSLASTPROMPT__,
    ALWAYSTOEND__,
    APPENDHISTORY__,
    AUTOCD__,
    AUTOCONTINUE__,
    AUTOLIST__,
    AUTOMENU__,
    AUTONAMEDIRS__,
    AUTOPARAMKEYS__,
    AUTOPARAMSLASH__,
    AUTOPUSHD__,
    AUTOREMOVESLASH__,
    AUTORESUME__,
    BADPATTERN__,
    BANGHIST__,
    BAREGLOBQUAL__,
    BASHAUTOLIST__,
    BASHREMATCH__,
    BEEP__,
    BGNICE__,
    BRACECCL__,
    BSDECHO__,
    CASEGLOB__,
    CASEMATCH__,
    CBASES__,
    CDABLEVARS__,
    CHASEDOTS__,
    CHASELINKS__,
    CHECKJOBS__,
    CHECKRUNNINGJOBS__,
    CLOBBER__,
    APPENDCREATE__,
    COMBININGCHARS__,
    COMPLETEALIASES__,
    COMPLETEINWORD__,
    CORRECT__,
    CORRECTALL__,
    CONTINUEONERROR__,
    CPRECEDENCES__,
    CSHJUNKIEHISTORY__,
    CSHJUNKIELOOPS__,
    CSHJUNKIEQUOTES__,
    CSHNULLCMD__,
    CSHNULLGLOB__,
    DEBUGBEFORECMD__,
    EMACSMODE__,
    EQUALS__,
    ERREXIT__,
    ERRRETURN__,
    EXECOPT__,
    EXTENDEDGLOB__,
    EXTENDEDHISTORY__,
    EVALLINENO__,
    FLOWCONTROL__,
    FORCEFLOAT__,
    FUNCTIONARGZERO__,
    GLOBOPT__,
    GLOBALEXPORT__,
    GLOBALRCS__,
    GLOBASSIGN__,
    GLOBCOMPLETE__,
    GLOBDOTS__,
    GLOBSTARSHORT__,
    GLOBSUBST__,
    HASHCMDS__,
    HASHDIRS__,
    HASHEXECUTABLESONLY__,
    HASHLISTALL__,
    HISTALLOWCLOBBER__,
    HISTBEEP__,
    HISTEXPIREDUPSFIRST__,
    HISTFCNTLLOCK__,
    HISTFINDNODUPS__,
    HISTIGNOREALLDUPS__,
    HISTIGNOREDUPS__,
    HISTIGNORESPACE__,
    HISTLEXWORDS__,
    HISTNOFUNCTIONS__,
    HISTNOSTORE__,
    HISTREDUCEBLANKS__,
    HISTSAVEBYCOPY__,
    HISTSAVENODUPS__,
    HISTSUBSTPATTERN__,
    HISTVERIFY__,
    HUP__,
    IGNOREBRACES__,
    IGNORECLOSEBRACES__,
    IGNOREEOF__,
    INCAPPENDHISTORY__,
    INCAPPENDHISTORYTIME__,
    INTERACTIVE__,
    INTERACTIVECOMMENTS__,
    KSHARRAYS__,
    KSHAUTOLOAD__,
    KSHGLOB__,
    KSHOPTIONPRINT__,
    KSHTYPESET__,
    KSHZEROSUBSCRIPT__,
    LISTAMBIGUOUS__,
    LISTBEEP__,
    LISTPACKED__,
    LISTROWSFIRST__,
    LISTTYPES__,
    LOCALLOOPS__,
    LOCALOPTIONS__,
    LOCALPATTERNS__,
    LOCALTRAPS__,
    LOGINSHELL__,
    LONGLISTJOBS__,
    MAGICEQUALSUBST__,
    MAILWARNING__,
    MARKDIRS__,
    MENUCOMPLETE__,
    MONITOR__,
    MULTIBYTE__,
    MULTIFUNCDEF__,
    MULTIOS__,
    NOMATCH__,
    NOTIFY__,
    NULLGLOB__,
    NUMERICGLOBSORT__,
    OCTALZEROES__,
    OVERSTRIKE__,
    PATHDIRS__,
    PATHSCRIPT__,
    PIPEFAIL__,
    POSIXALIASES__,
    POSIXARGZERO__,
    POSIXBUILTINS__,
    POSIXCD__,
    POSIXIDENTIFIERS__,
    POSIXJOBS__,
    POSIXSTRINGS__,
    POSIXTRAPS__,
    PRINTEIGHTBIT__,
    PRINTEXITVALUE__,
    PRIVILEGED__,
    PROMPTBANG__,
    PROMPTCR__,
    PROMPTPERCENT__,
    PROMPTSP__,
    PROMPTSUBST__,
    PUSHDIGNOREDUPS__,
    PUSHDMINUS__,
    PUSHDSILENT__,
    PUSHDTOHOME__,
    RCEXPANDPARAM__,
    RCQUOTES__,
    RCS__,
    RECEXACT__,
    REMATCHPCRE__,
    RESTRICTED__,
    RMSTARSILENT__,
    RMSTARWAIT__,
    SHAREHISTORY__,
    SHFILEEXPANSION__,
    SHGLOB__,
    SHINSTDIN__,
    SHNULLCMD__,
    SHOPTIONLETTERS__,
    SHORTLOOPS__,
    SHWORDSPLIT__,
    SINGLECOMMAND__,
    SINGLELINEZLE__,
    SOURCETRACE__,
    SUNKEYBOARDHACK__,
    TRANSIENTRPROMPT__,
    TRAPSASYNC__,
    TYPESETSILENT__,
    UNSET__,
    VERBOSE__,
    VIMODE__,
    WARNCREATEGLOBAL__,
    WARNNESTEDVAR__,
    XTRACE__,
    USEZLE__,
    DVORAK__,
    OPT_SIZE__
};

struct zp_option_name {
    const char *name;
    int enum_val;
};

static struct zp_option_name zp_options[] = {
{"aliases",             ALIASESOPT__},
{"aliasfuncdef",        ALIASFUNCDEF__},
{"allexport",           ALLEXPORT__},
{"alwayslastprompt",    ALWAYSLASTPROMPT__},
{"alwaystoend",         ALWAYSTOEND__},
{"appendcreate",        APPENDCREATE__},
{"appendhistory",       APPENDHISTORY__},
{"autocd",              AUTOCD__},
{"autocontinue",        AUTOCONTINUE__},
{"autolist",            AUTOLIST__},
{"automenu",            AUTOMENU__},
{"autonamedirs",        AUTONAMEDIRS__},
{"autoparamkeys",       AUTOPARAMKEYS__},
{"autoparamslash",      AUTOPARAMSLASH__},
{"autopushd",           AUTOPUSHD__},
{"autoremoveslash",     AUTOREMOVESLASH__},
{"autoresume",          AUTORESUME__},
{"badpattern",          BADPATTERN__},
{"banghist",            BANGHIST__},
{"bareglobqual",        BAREGLOBQUAL__},
{"bashautolist",        BASHAUTOLIST__},
{"bashrematch",         BASHREMATCH__},
{"beep",                BEEP__},
{"bgnice",              BGNICE__},
{"braceccl",            BRACECCL__},
{"bsdecho",             BSDECHO__},
{"caseglob",            CASEGLOB__},
{"casematch",           CASEMATCH__},
{"cbases",              CBASES__},
{"cprecedences",        CPRECEDENCES__},
{"cdablevars",          CDABLEVARS__},
{"chasedots",           CHASEDOTS__},
{"chaselinks",          CHASELINKS__},
{"checkjobs",           CHECKJOBS__},
{"checkrunningjobs",    CHECKRUNNINGJOBS__},
{"clobber",             CLOBBER__},
{"combiningchars",      COMBININGCHARS__},
{"completealiases",     COMPLETEALIASES__},
{"completeinword",      COMPLETEINWORD__},
{"continueonerror",     CONTINUEONERROR__},
{"correct",             CORRECT__},
{"correctall",          CORRECTALL__},
{"cshjunkiehistory",    CSHJUNKIEHISTORY__},
{"cshjunkieloops",      CSHJUNKIELOOPS__},
{"cshjunkiequotes",     CSHJUNKIEQUOTES__},
{"cshnullcmd",          CSHNULLCMD__},
{"cshnullglob",         CSHNULLGLOB__},
{"debugbeforecmd",      DEBUGBEFORECMD__},
{"emacs",               EMACSMODE__},
{"equals",              EQUALS__},
{"errexit",             ERREXIT__},
{"errreturn",           ERRRETURN__},
{"exec",                EXECOPT__},
{"extendedglob",        EXTENDEDGLOB__},
{"extendedhistory",     EXTENDEDHISTORY__},
{"evallineno",          EVALLINENO__},
{"flowcontrol",         FLOWCONTROL__},
{"forcefloat",          FORCEFLOAT__},
{"functionargzero",     FUNCTIONARGZERO__},
{"glob",                GLOBOPT__},
{"globalexport",        GLOBALEXPORT__},
{"globalrcs",           GLOBALRCS__},
{"globassign",          GLOBASSIGN__},
{"globcomplete",        GLOBCOMPLETE__},
{"globdots",            GLOBDOTS__},
{"globstarshort",       GLOBSTARSHORT__},
{"globsubst",           GLOBSUBST__},
{"hashcmds",            HASHCMDS__},
{"hashdirs",            HASHDIRS__},
{"hashexecutablesonly", HASHEXECUTABLESONLY__},
{"hashlistall",         HASHLISTALL__},
{"histallowclobber",    HISTALLOWCLOBBER__},
{"histbeep",            HISTBEEP__},
{"histexpiredupsfirst", HISTEXPIREDUPSFIRST__},
{"histfcntllock",       HISTFCNTLLOCK__},
{"histfindnodups",      HISTFINDNODUPS__},
{"histignorealldups",   HISTIGNOREALLDUPS__},
{"histignoredups",      HISTIGNOREDUPS__},
{"histignorespace",     HISTIGNORESPACE__},
{"histlexwords",        HISTLEXWORDS__},
{"histnofunctions",     HISTNOFUNCTIONS__},
{"histnostore",         HISTNOSTORE__},
{"histsubstpattern",    HISTSUBSTPATTERN__},
{"histreduceblanks",    HISTREDUCEBLANKS__},
{"histsavebycopy",      HISTSAVEBYCOPY__},
{"histsavenodups",      HISTSAVENODUPS__},
{"histverify",          HISTVERIFY__},
{"hup",                 HUP__},
{"ignorebraces",        IGNOREBRACES__},
{"ignoreclosebraces",   IGNORECLOSEBRACES__},
{"ignoreeof",           IGNOREEOF__},
{"incappendhistory",    INCAPPENDHISTORY__},
{"incappendhistorytime",INCAPPENDHISTORYTIME__},
{"interactive",         INTERACTIVE__},
{"interactivecomments", INTERACTIVECOMMENTS__},
{"ksharrays",           KSHARRAYS__},
{"kshautoload",         KSHAUTOLOAD__},
{"kshglob",             KSHGLOB__},
{"kshoptionprint",      KSHOPTIONPRINT__},
{"kshtypeset",          KSHTYPESET__},
{"kshzerosubscript",    KSHZEROSUBSCRIPT__},
{"listambiguous",       LISTAMBIGUOUS__},
{"listbeep",            LISTBEEP__},
{"listpacked",          LISTPACKED__},
{"listrowsfirst",       LISTROWSFIRST__},
{"listtypes",           LISTTYPES__},
{"localoptions",        LOCALOPTIONS__},
{"localloops",          LOCALLOOPS__},
{"localpatterns",       LOCALPATTERNS__},
{"localtraps",          LOCALTRAPS__},
{"login",               LOGINSHELL__},
{"longlistjobs",        LONGLISTJOBS__},
{"magicequalsubst",     MAGICEQUALSUBST__},
{"mailwarning",         MAILWARNING__},
{"markdirs",            MARKDIRS__},
{"menucomplete",        MENUCOMPLETE__},
{"monitor",             MONITOR__},
{"multibyte",           MULTIBYTE__},
{"multifuncdef",        MULTIFUNCDEF__},
{"multios",             MULTIOS__},
{"nomatch",             NOMATCH__},
{"notify",              NOTIFY__},
{"nullglob",            NULLGLOB__},
{"numericglobsort",     NUMERICGLOBSORT__},
{"octalzeroes",         OCTALZEROES__},
{"overstrike",          OVERSTRIKE__},
{"pathdirs",            PATHDIRS__},
{"pathscript",          PATHSCRIPT__},
{"pipefail",            PIPEFAIL__},
{"posixaliases",        POSIXALIASES__},
{"posixargzero",        POSIXARGZERO__},
{"posixbuiltins",       POSIXBUILTINS__},
{"posixcd",             POSIXCD__},
{"posixidentifiers",    POSIXIDENTIFIERS__},
{"posixjobs",           POSIXJOBS__},
{"posixstrings",        POSIXSTRINGS__},
{"posixtraps",          POSIXTRAPS__},
{"printeightbit",       PRINTEIGHTBIT__},
{"printexitvalue",      PRINTEXITVALUE__},
{"privileged",          PRIVILEGED__},
{"promptbang",          PROMPTBANG__},
{"promptcr",            PROMPTCR__},
{"promptpercent",       PROMPTPERCENT__},
{"promptsp",            PROMPTSP__},
{"promptsubst",         PROMPTSUBST__},
{"pushdignoredups",     PUSHDIGNOREDUPS__},
{"pushdminus",          PUSHDMINUS__},
{"pushdsilent",         PUSHDSILENT__},
{"pushdtohome",         PUSHDTOHOME__},
{"rcexpandparam",       RCEXPANDPARAM__},
{"rcquotes",            RCQUOTES__},
{"rcs",                 RCS__},
{"recexact",            RECEXACT__},
{"rematchpcre",         REMATCHPCRE__},
{"restricted",          RESTRICTED__},
{"rmstarsilent",        RMSTARSILENT__},
{"rmstarwait",          RMSTARWAIT__},
{"sharehistory",        SHAREHISTORY__},
{"shfileexpansion",     SHFILEEXPANSION__},
{"shglob",              SHGLOB__},
{"shinstdin",           SHINSTDIN__},
{"shnullcmd",           SHNULLCMD__},
{"shoptionletters",     SHOPTIONLETTERS__},
{"shortloops",          SHORTLOOPS__},
{"shwordsplit",         SHWORDSPLIT__},
{"singlecommand",       SINGLECOMMAND__},
{"singlelinezle",       SINGLELINEZLE__},
{"sourcetrace",         SOURCETRACE__},
{"sunkeyboardhack",     SUNKEYBOARDHACK__},
{"transientrprompt",    TRANSIENTRPROMPT__},
{"trapsasync",          TRAPSASYNC__},
{"typesetsilent",       TYPESETSILENT__},
{"unset",               UNSET__},
{"verbose",             VERBOSE__},
{"vi",                  VIMODE__},
{"warncreateglobal",    WARNCREATEGLOBAL__},
{"warnnestedvar",       WARNNESTEDVAR__},
{"xtrace",              XTRACE__},
{"zle",                 USEZLE__},
{"dvorak",              DVORAK__},
/* Below follow *aliases*, i.e. not-main, alternate option names */
/* There are 10 uncommented entries */
/* {"braceexpand",         -IGNOREBRACES__}, */
{"dotglob",             GLOBDOTS__},
{"hashall",             HASHCMDS__},
{"histappend",          APPENDHISTORY__},
{"histexpand",          BANGHIST__},
/* {"log",                 -HISTNOFUNCTIONS__}, */
{"mailwarn",            MAILWARNING__},
{"onecmd",              SINGLECOMMAND__},
{"physical",            CHASELINKS__},
{"promptvars",          PROMPTSUBST__},
{"stdin",               SHINSTDIN__},
{"trackall",            HASHCMDS__},
{NULL, 0}
};
/* }}} */

/* Copied, repeated Zsh macros, data structures, etc. {{{ */
#define FD_EXT ".zwc"
#define FD_MINMAP 4096

#define FD_PRELEN 12
#define FD_MAGIC  0x04050607
#define FD_OMAGIC 0x07060504

#define FDF_MAP   1
#define FDF_OTHER 2

typedef struct fdhead *FDHead;

struct fdhead {
    wordcode start;		/* offset to function definition */
    wordcode len;		/* length of wordcode/strings */
    wordcode npats;		/* number of patterns needed */
    wordcode strs;		/* offset to strings */
    wordcode hlen;		/* header length (incl. name) */
    wordcode flags;		/* flags and offset to name tail */
};

#define fdheaderlen(f) (((Wordcode) (f))[FD_PRELEN])

#define fdmagic(f)       (((Wordcode) (f))[0])
#define fdsetbyte(f,i,v) \
    ((((unsigned char *) (((Wordcode) (f)) + 1))[i]) = ((unsigned char) (v)))
#define fdbyte(f,i)      ((wordcode) (((unsigned char *) (((Wordcode) (f)) + 1))[i]))
#define fdflags(f)       fdbyte(f, 0)
#define fdsetflags(f,v)  fdsetbyte(f, 0, v)
#define fdother(f)       (fdbyte(f, 1) + (fdbyte(f, 2) << 8) + (fdbyte(f, 3) << 16))
#define fdsetother(f, o) \
    do { \
        fdsetbyte(f, 1, ((o) & 0xff)); \
        fdsetbyte(f, 2, (((o) >> 8) & 0xff)); \
        fdsetbyte(f, 3, (((o) >> 16) & 0xff)); \
    } while (0)
#define fdversion(f)     ((char *) ((f) + 2))

#define firstfdhead(f) ((FDHead) (((Wordcode) (f)) + FD_PRELEN))
#define nextfdhead(f)  ((FDHead) (((Wordcode) (f)) + (f)->hlen))

#define fdhflags(f)      (((FDHead) (f))->flags)
#define fdhtail(f)       (((FDHead) (f))->flags >> 2)
#define fdhbldflags(f,t) ((f) | ((t) << 2))

#define FDHF_KSHLOAD 1
#define FDHF_ZSHLOAD 2

#define fdname(f)      ((char *) (((FDHead) (f)) + 1))
/* }}} */

/*
 * Compatibility functions (i.e. support for multiple Zsh versions)
 */

/* STATIC FUNCTION: zp_setup_options_table {{{ */
/**/
static
void zp_setup_options_table() {
    int i, optno;
    for ( i = 0; i < sizeof( zp_options ) / sizeof( struct zp_option_name ) - 10 - 1; ++ i ) {
        optno = optlookup( zp_options[ i ].name );
        zp_opt_for_zsh_version[ zp_options[ i ].enum_val ] = optno;
    }
}
/* }}} */
/* STATIC FUNCTION: zp_conv_opt {{{ */
/**/
static
int zp_conv_opt( int zp_opt_num ) {
    int sign;
    sign = zp_opt_num >= 0 ? 1 : -1;
    return sign*zp_opt_for_zsh_version[ sign*zp_opt_num ];
}
/* }}} */

/*
 * `.' and `source' overload (profiling loading times)
 */

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
    if (isset(zp_conv_opt(FUNCTIONARGZERO__))) {
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
	ret = custom_source(enam);
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
		ret = custom_source(arg0);
		break;
	    }
	if (!*s || (ret == SOURCE_NOT_FOUND &&
		    isset(zp_conv_opt(PATHDIRS__)) && diddot < 2 && dotdot == 0)) {
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
		    ret = custom_source(enam = buf);
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
	if (isset(zp_conv_opt(POSIXBUILTINS__))) {
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
/* FUNCTION: custom_source {{{ */
/**/
mod_export enum source_return
custom_source(char *s)
{
    Eprog prog;
    int tempfd = -1, fd, cj;
    zlong oldlineno;
    int oldshst, osubsh, oloops;
    FILE *obshin;
    char *old_scriptname = scriptname, *us;
    char *old_scriptfilename = scriptfilename;
    unsigned char *ocs;
    int ocsp;
    int otrap_return = trap_return, otrap_state = trap_state;
    struct funcstack fstack;
    enum source_return ret = SOURCE_OK;

    /* ZP-CODE */
    SEventNode zp_node;
    struct timeval zp_tv;
    struct timezone zp_dummy_tz;
    double zp_prev_tv;
    zp_tv.tv_sec = zp_tv.tv_usec = 0;
    gettimeofday(&zp_tv, &zp_dummy_tz);
    zp_prev_tv = ((((double) zp_tv.tv_sec) * 1000.0) + (((double) zp_tv.tv_usec) / 1000.0));

    if (!s || 
	(!(prog = custom_try_source_file((us = unmeta(s)))) &&
	 (tempfd = movefd(open(us, O_RDONLY | O_NOCTTY))) == -1)) {
	return SOURCE_NOT_FOUND;
    }

    /* save the current shell state */
    fd        = SHIN;            /* store the shell input fd                  */
    obshin    = bshin;          /* store file handle for buffered shell input */
    osubsh    = subsh;           /* store whether we are in a subshell        */
    cj        = thisjob;         /* store our current job number              */
    oldlineno = lineno;          /* store our current lineno                  */
    oloops    = loops;           /* stored the # of nested loops we are in    */
    oldshst   = opts[zp_conv_opt(SHINSTDIN__)]; /* store current value of this option        */
    ocs = cmdstack;
    ocsp = cmdsp;
    cmdstack = (unsigned char *) zalloc(CMDSTACKSZ);
    cmdsp = 0;

    if (!prog) {
	SHIN = tempfd;
	bshin = fdopen(SHIN, "r");
    }
    subsh  = 0;
    lineno = 1;
    loops  = 0;
    dosetopt(zp_conv_opt(SHINSTDIN__), 0, 1, opts);
    scriptname = s;
    scriptfilename = s;

    if (isset(zp_conv_opt(SOURCETRACE__))) {
	printprompt4();
	fprintf(xtrerr ? xtrerr : stderr, "<sourcetrace>\n");
    }

    /*
     * The special return behaviour of traps shouldn't
     * trigger in files sourced from traps; the return
     * is just a return from the file.
     */
    trap_state = TRAP_STATE_INACTIVE;

    sourcelevel++;

    fstack.name = scriptfilename;
    fstack.caller = funcstack ? funcstack->name :
	dupstring(old_scriptfilename ? old_scriptfilename : "zsh");
    fstack.flineno = 0;
    fstack.lineno = oldlineno;
    fstack.filename = scriptfilename;
    fstack.prev = funcstack;
    fstack.tp = FS_SOURCE;
    funcstack = &fstack;

    if (prog) {
	pushheap();
	errflag &= ~ERRFLAG_ERROR;
	execode(prog, 1, 0, "filecode");
	popheap();
	if (errflag)
	    ret = SOURCE_ERROR;
    } else {
	int value;
	/* loop through the file to be sourced  */
	switch (value=loop(0, 0))
	{
	case LOOP_OK:
	    /* nothing to do but compilers like a complete enum */
	    break;

	case LOOP_EMPTY:
	    /* Empty code resets status */
	    lastval = 0;
	    break;

	case LOOP_ERROR:
	    ret = SOURCE_ERROR;
	    break;
	}
    }

    funcstack = funcstack->prev;
    sourcelevel--;

    trap_state = otrap_state;
    trap_return = otrap_return;

    /* restore the current shell state */
    if (prog)
	freeeprog(prog);
    else {
	fclose(bshin);
	fdtable[SHIN] = FDT_UNUSED;
	SHIN = fd;		     /* the shell input fd                   */
	bshin = obshin;		     /* file handle for buffered shell input */
    }
    subsh = osubsh;                  /* whether we are in a subshell         */
    thisjob = cj;                    /* current job number                   */
    lineno = oldlineno;              /* our current lineno                   */
    loops = oloops;                  /* the # of nested loops we are in      */
    dosetopt(zp_conv_opt(SHINSTDIN__), oldshst, 1, opts); /* SHINSTDIN option               */
    errflag &= ~ERRFLAG_ERROR;
    if (!exit_pending)
	retflag = 0;
    scriptname = old_scriptname;
    scriptfilename = old_scriptfilename;
    zfree(cmdstack, CMDSTACKSZ);
    cmdstack = ocs;
    cmdsp = ocsp;

    /* ZP-CODE */
    zp_tv.tv_sec = zp_tv.tv_usec = 0;
    gettimeofday(&zp_tv, &zp_dummy_tz);
    zp_node = (SEventNode) zshcalloc( sizeof( struct zp_sevent_node ) );

    if ( zp_node ) {
        char zp_tmp[20], bkp;
        char *dir_path, *file_name, *full_path, *slash;
        int is_dot_slash;

        /* Prepare paths */
        if ( s[0] == '/' ) {
            /* event.full_path */
            full_path = ztrdup( s );
        } else {
            int pwd_len, rel_len;
            is_dot_slash = ( s[0] == '.' && s[1] == '/' );
            /* event.full_path */
            pwd_len = strlen( pwd );
            rel_len = strlen( s ) - is_dot_slash * 2;
            full_path = (char *) zalloc( sizeof( char ) * ( pwd_len + rel_len + 2 ) );
            strcpy( full_path, pwd );
            strcat( full_path, "/" );
            strcat( full_path, s + is_dot_slash * 2 );
        }

        /* event.file_name */
        slash = strrchr( full_path, '/' );
        file_name = ztrdup( slash + 1 );
        /* event.dir_path */
        bkp = slash[1];
        slash[1] = '\0';
        dir_path = ztrdup( full_path );
        slash[1] = bkp;

        /* Fill and add zp_node */
        ++ zp_sevent_count;
        zp_node->event.id = zp_sevent_count;
        zp_node->event.ts = (long) zp_prev_tv;
        zp_node->event.dir_path = dir_path;
        zp_node->event.file_name = file_name;
        zp_node->event.full_path = full_path;
        zp_node->event.duration = ((((double) zp_tv.tv_sec) * 1000.0) + (((double) zp_tv.tv_usec) / 1000.0)) - zp_prev_tv;
        zp_node->event.load_error = ret;

        sprintf( zp_tmp, "%d", zp_node->event.id );
        zp_tmp[ 19 ] = '\0';

        addhashnode( zp_source_events, ztrdup( zp_tmp ), ( void * ) zp_node );
    }

    return ret;
}
/* }}} */
/* FUNCTION: custom_try_source_file {{{ */
/**/
Eprog
custom_try_source_file(char *file)
{
    Eprog prog;
    struct stat stc, stn;
    int rc, rn, faltered = 0, flen;
    char *wc, *tail, *file_dup;

    if ((tail = strrchr(file, '/')))
	tail++;
    else
	tail = file;

    if (strsfx(FD_EXT, file)) {
	queue_signals();
	prog = custom_check_dump_file(file, NULL, tail, NULL, 0);
	unqueue_signals();
	return prog;
    }
    wc = dyncat(file, FD_EXT);

    rc = stat(wc, &stc);
    rn = stat(file, &stn);

    /* ZP-CODE */
    if ( file != tail ) {
        faltered = 1;
        *--tail = '\0';
    }
    file_dup = ztrdup( file );
    flen = strlen( file );
    if ( faltered ) {
        *tail++ = '/';
    }
    /* If there is no zwc file, or if it is less recent than script file */
    if ( ( !rn && ( rc || ( stc.st_mtime < stn.st_mtime ) ) ) &&
            ( access( file_dup, W_OK ) == 0 || 0 == strcmp(
                getsparam( "ZPLG_MOD_DEBUG" ) ? getsparam( "ZPLG_MOD_DEBUG" ) : "0",
                "1" ) )
    ) {
        char *args[] = { file, NULL };
        struct options ops;

        /* Initialise options structure */
        memset(ops.ind, 0, MAX_OPS*sizeof(unsigned char));
        ops.args = NULL;
        ops.argscount = ops.argsalloc = 0;
        ops.ind['U'] = 1;

        /* Invoke compilation */
        bin_zcompile("ZpluginModule", args, &ops, 0);

        /* Repeat stat for newly created zwc */
        rc = stat(wc, &stc);
    }

    zfree(file_dup, flen);

    queue_signals();
    if (!rc && (rn || stc.st_mtime >= stn.st_mtime) &&
	(prog = custom_check_dump_file(wc, &stc, tail, NULL, 0))) {
	unqueue_signals();
	return prog;
    }
    unqueue_signals();
    return NULL;
}

/* }}} */

/* Code copied from Zshell's parse.c {{{ */
/**/
#if defined(HAVE_SYS_MMAN_H) && defined(HAVE_MMAP) && defined(HAVE_MUNMAP)

#include <sys/mman.h>

/**/
#if defined(MAP_SHARED) && defined(PROT_READ)

/**/
#define USE_MMAP 1

/**/
#endif
/**/
#endif

/**/
#ifdef USE_MMAP

/* List of dump files mapped. */

static FuncDump dumps;
/* }}} */
/* STATIC FUNCTION: custom_zwcstat {{{ */
/**/
static int
custom_zwcstat(char *filename, struct stat *buf)
{
    if (stat(filename, buf)) {
#ifdef HAVE_FSTAT
        FuncDump f;

	for (f = dumps; f; f = f->next) {
	    if (!strncmp(filename, f->filename, strlen(f->filename)) &&
		!fstat(f->fd, buf))
		return 0;
	}
#endif
	return 1;
    } else return 0;
}
/* }}} */
/* STATIC FUNCTION: custom_load_dump_file {{{ */
/* Load a dump file (i.e. map it). */
static void
custom_load_dump_file(char *dump, struct stat *sbuf, int other, int len)
{
    FuncDump d;
    Wordcode addr;
    int fd, off, mlen;

    if (other) {
	static size_t pgsz = 0;

	if (!pgsz) {

#ifdef _SC_PAGESIZE
	    pgsz = sysconf(_SC_PAGESIZE);     /* SVR4 */
#else
# ifdef _SC_PAGE_SIZE
	    pgsz = sysconf(_SC_PAGE_SIZE);    /* HPUX */
# else
	    pgsz = getpagesize();
# endif
#endif

	    pgsz--;
	}
	off = len & ~pgsz;
        mlen = len + (len - off);
    } else {
	off = 0;
        mlen = len;
    }
    if ((fd = open(dump, O_RDONLY)) < 0)
	return;

    fd = movefd(fd);
    if (fd == -1)
	return;

    if ((addr = (Wordcode) mmap(NULL, mlen, PROT_READ, MAP_SHARED, fd, off)) ==
	((Wordcode) -1)) {
	close(fd);
	return;
    }
    d = (FuncDump) zalloc(sizeof(*d));
    d->next = dumps;
    dumps = d;
    d->dev = sbuf->st_dev;
    d->ino = sbuf->st_ino;
    d->fd = fd;
#ifdef FD_CLOEXEC
    fcntl(fd, F_SETFD, FD_CLOEXEC);
#endif
    d->map = addr + (other ? (len - off) / sizeof(wordcode) : 0);
    d->addr = addr;
    d->len = len;
    d->count = 0;
    d->filename = ztrdup(dump);
}
/* }}} */
/* Code copied from Zshell's parse.c {{{ */
#else

#define custom_zwcstat(f, b) (!!stat(f, b))

/**/
#endif
/* }}} */
/* STATIC FUNCTION: custom_dump_find_func {{{ */
static FDHead
custom_dump_find_func(Wordcode h, char *name)
{
    FDHead n, e = (FDHead) (h + fdheaderlen(h));

    for (n = firstfdhead(h); n < e; n = nextfdhead(n))
	if (!strcmp(name, fdname(n) + fdhtail(n)))
	    return n;

    return NULL;
}
/* }}} */
/* STATIC FUNCTION: custom_check_dump_file {{{ */
/**/
static Eprog
custom_check_dump_file(char *file, struct stat *sbuf, char *name, int *ksh,
		int test_only)
{
    int isrec = 0;
    Wordcode d;
    FDHead h;
    FuncDump f;
    struct stat lsbuf;

    if (!sbuf) {
	if (custom_zwcstat(file, &lsbuf))
	    return NULL;
	sbuf = &lsbuf;
    }

#ifdef USE_MMAP

 rec:

#endif

    d = NULL;

#ifdef USE_MMAP

    for (f = dumps; f; f = f->next)
	if (f->dev == sbuf->st_dev && f->ino == sbuf->st_ino) {
	    d = f->map;
	    break;
	}

#else

    f = NULL;

#endif

    if (!f && (isrec || !(d = custom_load_dump_header(NULL, file, 0))))
	return NULL;

    if ((h = custom_dump_find_func(d, name))) {
	/* Found the name. If the file is already mapped, return the eprog,
	 * otherwise map it and just go up. */
	if (test_only)
	{
	    /* This is all we need.  Just return dummy. */
	    return &dummy_eprog;
	}

#ifdef USE_MMAP

	if (f) {
	    Eprog prog = (Eprog) zalloc(sizeof(*prog));
	    Patprog *pp;
	    int np;

	    prog->flags = EF_MAP;
	    prog->len = h->len;
	    prog->npats = np = h->npats;
	    prog->nref = 1;	/* allocated from permanent storage */
	    prog->pats = pp = (Patprog *) zalloc(np * sizeof(Patprog));
	    prog->prog = f->map + h->start;
	    prog->strs = ((char *) prog->prog) + h->strs;
	    prog->shf = NULL;
	    prog->dump = f;

	    incrdumpcount(f);

	    while (np--)
		*pp++ = dummy_patprog1;

	    if (ksh)
		*ksh = ((fdhflags(h) & FDHF_KSHLOAD) ? 2 :
			((fdhflags(h) & FDHF_ZSHLOAD) ? 0 : 1));

	    return prog;
	} else if (fdflags(d) & FDF_MAP) {
	    custom_load_dump_file(file, sbuf, (fdflags(d) & FDF_OTHER), fdother(d));
	    isrec = 1;
	    goto rec;
	} else

#endif

	{
	    Eprog prog;
	    Patprog *pp;
	    int np, fd, po = h->npats * sizeof(Patprog);

	    if ((fd = open(file, O_RDONLY)) < 0 ||
		lseek(fd, ((h->start * sizeof(wordcode)) +
			   ((fdflags(d) & FDF_OTHER) ? fdother(d) : 0)), 0) < 0) {
		if (fd >= 0)
		    close(fd);
		return NULL;
	    }
	    d = (Wordcode) zalloc(h->len + po);

	    if (read(fd, ((char *) d) + po, h->len) != (int)h->len) {
		close(fd);
		zfree(d, h->len);

		return NULL;
	    }
	    close(fd);

	    prog = (Eprog) zalloc(sizeof(*prog));

	    prog->flags = EF_REAL;
	    prog->len = h->len + po;
	    prog->npats = np = h->npats;
	    prog->nref = 1; /* allocated from permanent storage */
	    prog->pats = pp = (Patprog *) d;
	    prog->prog = (Wordcode) (((char *) d) + po);
	    prog->strs = ((char *) prog->prog) + h->strs;
	    prog->shf = NULL;
	    prog->dump = f;

	    while (np--)
		*pp++ = dummy_patprog1;

	    if (ksh)
		*ksh = ((fdhflags(h) & FDHF_KSHLOAD) ? 2 :
			((fdhflags(h) & FDHF_ZSHLOAD) ? 0 : 1));

	    return prog;
	}
    }
    return NULL;
}
/* }}} */
/* STATIC FUNCTION: custom_load_dump_header {{{ */
/**/
static Wordcode
custom_load_dump_header(char *nam, char *name, int err)
{
    int fd, v = 1;
    wordcode buf[FD_PRELEN + 1];

    if ((fd = open(name, O_RDONLY)) < 0) {
	if (err)
	    zwarnnam(nam, "can't open zwc file: %s", name);
	return NULL;
    }
    if (read(fd, buf, (FD_PRELEN + 1) * sizeof(wordcode)) !=
	((FD_PRELEN + 1) * sizeof(wordcode)) ||
	(v = (fdmagic(buf) != FD_MAGIC && fdmagic(buf) != FD_OMAGIC)) ||
	strcmp(fdversion(buf), getsparam("ZSH_VERSION"))) {
	if (err) {
	    if (!v) {
		zwarnnam(nam, "zwc file has wrong version (zsh-%s): %s",
			 fdversion(buf), name);
	    } else
		zwarnnam(nam, "invalid zwc file: %s" , name);
	}
	close(fd);
	return NULL;
    } else {
	int len;
	Wordcode head;

	if (fdmagic(buf) == FD_MAGIC) {
	    len = fdheaderlen(buf) * sizeof(wordcode);
	    head = (Wordcode) zhalloc(len);
	}
	else {
	    int o = fdother(buf);

	    if (lseek(fd, o, 0) == -1 ||
		read(fd, buf, (FD_PRELEN + 1) * sizeof(wordcode)) !=
		((FD_PRELEN + 1) * sizeof(wordcode))) {
		zwarnnam(nam, "invalid zwc file: %s" , name);
		close(fd);
		return NULL;
	    }
	    len = fdheaderlen(buf) * sizeof(wordcode);
	    head = (Wordcode) zhalloc(len);
	}
	memcpy(head, buf, (FD_PRELEN + 1) * sizeof(wordcode));

	len -= (FD_PRELEN + 1) * sizeof(wordcode);
	if (read(fd, head + (FD_PRELEN + 1), len) != len) {
	    close(fd);
	    zwarnnam(nam, "invalid zwc file: %s" , name);
	    return NULL;
	}
	close(fd);
	return head;
    }
}
/* }}} */

/*
 * readarray {{{
 *
 * readarray [-d delim] [-n count] [-O origin] [-s count] [-t] [-u fd]
 *   [-C callback] [-c quantum] [array]
 * 
 * Reads from stdin or from {fd} (-u option).
 * -d {delim} - terminator for each record read (default: newline)
 * -n {count} - copy at most {count} records
 * -O {origin} - begin storing in {array} at index {origin}
 * -s {count} - discard first {count} lines read
 * -t - remove trailing {delim} from result
 * -u {fd} - read from file descriptor {fd}
 * -C {callback} - eval {callback} each time {quantum} records are read
 * -c {quantum} - the # of records for the above -C option
 *
 * Default {quantum} is 5000. Callback obtains 2 arguments, <assign-index> <content-to-assign>,
 * i.e. where the record will be assigned in the {array}, and body of the record.
 *
 * Without -O, readarray clears the array at start.
 *
 * readarray returns successfully unless a bad option or option argument is
 * supplied, {array} is unassignable, or if {array} is not an indexed array.
 */
int bin_readarray( char *nam, char **argv, UNUSED( Options ops ), UNUSED( int func ) ) {
    int delim='\n', to_copy = 0, start_at = 1, skip_first = 0, remdel = 0, srcfd = 0, quantum = 5000;
    char *callback = NULL, *oarr_name = NULL; // unused: **oarr = NULL;
    FILE *stream = NULL;

    /* Usage message */
    if ( OPT_ISSET( ops, 'h' ) ) {
        readarray_usage();
        return 0;
    }

    /* -d {delim} - terminator for each record read (default: newline) */
    if ( OPT_ISSET( ops, 'd' ) ) {
        delim = OPT_ARG( ops, 'd' ) ? OPT_ARG( ops, 'd' )[0] : '\n';
    }

    /* -n {count} - copy at most {count} records */
    if ( OPT_ISSET( ops, 'n' ) ) {
        to_copy = OPT_ARG( ops, 'n' ) ? atoi( OPT_ARG( ops, 'n' ) ) : 0;
    }

    /* -O {origin} - begin storing in {array} at index {origin} */
    if ( OPT_ISSET( ops, 'O' ) ) {
        start_at = OPT_ARG( ops, 'O' ) ? atoi( OPT_ARG( ops, 'O' ) ) : 1;
    }

    /* -s {count} - discard first {count} lines read */
    if ( OPT_ISSET( ops, 's' ) ) {
        skip_first = OPT_ARG( ops, 's' ) ? atoi( OPT_ARG( ops, 's' ) ) : 0;
    }

    /* -t - remove trailing {delim} from result */
    if ( OPT_ISSET( ops, 't' ) ) {
        remdel = 1;
    }

    /* -u {fd} - read from file descriptor {fd} */
    if ( OPT_ISSET( ops, 'u' ) ) {
        srcfd = OPT_ARG( ops, 'u' ) ? atoi( OPT_ARG( ops, 'u' ) ) : 0;
    }

    /* -C {callback} - eval {callback} each time {quantum} records are read */
    if ( OPT_ISSET( ops, 'C' ) ) {
        callback = OPT_ARG( ops, 'C' ) ? ztrdup( OPT_ARG( ops, 'C' ) ) : NULL;
    }

    /* -c {quantum} - the # of records for the above -C option */
    if ( OPT_ISSET( ops, 'c' ) ) {
        quantum = OPT_ARG( ops, 'c' ) ? atoi( OPT_ARG( ops, 'c' ) ) : 5000;
    }

    /* The name of output array */
    if ( !*argv ) {
        zwarnnam( nam, "Name of the output array is required, aborting" );
        return 1;
    } else {
        oarr_name = ztrdup( *argv );
        ++ argv;
    }

    /* Extra arguments -> error */
    if ( *argv ) {
        zwarnnam( nam, "Extra arguments detected, only one argument is needed, see -h, aborting" );
        return 1;
    }

    stream = fdopen( srcfd, "r" );
    if ( !stream ) {
        zwarnnam( nam, "Couldn't read descriptor: %d" , nam, srcfd );
        return 1;
    }

#ifdef HAVE_GETLINE
    
#endif

    return 0;
}

/**/
static void
readarray_usage() {
    fprintf( stdout, "Usage: readarray\n" );
    fflush( stdout );
}
/* }}} */

/*
 * Main builtin `zpmod' and its subcommands
 */

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
    } else if ( 0 == strcmp( subcmd, "source-study" ) ) {
        char *report;
        int rep_size;
        report = zp_build_source_report( ! zp_has_option( argv, 'l' ), &rep_size );
        fprintf( stdout, "%s", report ? report : "Unknown error, aborted" );
        fflush( stdout );
        if ( rep_size ) {
            zfree( report, rep_size );
        } else if ( report ) {
            zsfree( report );
        }
    } else {
        zwarnnam( nam, "Unknown zplugin-module command: `%s', see `-h'", subcmd );
    }

    return ret;
}
/* }}} */
/* FUNCTION: zpmod_usage {{{ */
/**/
void zpmod_usage() {
    fprintf( stdout, "Usage: zpmod {subcommand} {subcommand-arguments}\n"
                     "       zpmod report-append {plugin-ID} {new-report-body}\n"
                     "       zpmod source-study [-l]\n"
                     "\n"
                     "[33mCommand <report-append>:[0m\n"
                     "\n"
                     "Used by Zplugin internally to speed up loading plugins with tracking (reporting).\n"
                     "It extends the given field {plugin-ID} in $ZPLG_REPORTS hash, with the given string\n"
                     "{new-report-body}.\n"
                     "\n"
                     "[33mCommand <source-study>:[0m\n"
                     "\n"
                     "Displays list of files loaded via `source' or `.' builtins, with duration that each\n"
                     "loading lasted, in milliseconds. The module tracks all calls to those builtins and\n"
                     "measures the time each call took. This can be used to e.g. profile loading of plugins,\n"
                     "regardless of the plugin manager used.\n"
                     "\n"
                     "Option -l shows full paths to the files.\n"
                     );
    fflush( stdout );
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
/* FUNCTION: zp_build_source_report {{{ */
/**/
char *zp_build_source_report( int no_paths, int *rep_size ) {
    char *report, zp_tmp[ 20 ];
    int current_size, space_left, current_end, idx, printed;
    SEventNode node;
    FILE *null_fle;

    current_size = 127;
    current_end = 0;
    report = ( char * ) zalloc( sizeof( char ) * ( current_size + 1 ) );
    space_left = 127;
    report[ current_end ] = '\0';
    *rep_size = current_size + 1;

    if ( ! report ) {
        *rep_size = 0;
        return ztrdup( "ERROR: couldn't allocate initial buffer, aborted\n" );
    }

    null_fle = fopen( "/dev/null", "w" );
    if ( ! null_fle ) {
        zfree( report, *rep_size );
        *rep_size = 0;
        return ztrdup( "ERROR: couldn't open /dev/null, aborted\n" );
    }

    for ( idx = 1; idx <= zp_sevent_count; ++ idx ) {
        sprintf( zp_tmp, "%d", idx );
        zp_tmp[ 19 ] = '\0';

        if ( ! ( node = ( SEventNode ) gethashnode2( zp_source_events, zp_tmp ) ) ) {
            continue;
        }

        printed = fprintf( null_fle, "%4.0lf ms    %s\n", node->event.duration,
                                                        no_paths ? node->event.file_name : node->event.full_path );
        if ( space_left < printed ) {
            char *report_;
            current_size += printed - space_left + 25;
            space_left += printed - space_left + 25;
            report_ = zrealloc( report, sizeof( char ) * ( current_size + 1 ) );
            if ( ! report_ ) {
                zfree( report, *rep_size );
                *rep_size = 0;
                fclose( null_fle );
                return ztrdup( "ERROR: Couldn't realloc buffer, aborted\n" );
            }
            report = report_;
            *rep_size = current_size + 1;
        }

        printed = sprintf( report + current_end, "%4.0lf ms    %s\n", node->event.duration,
                                                            no_paths ? node->event.file_name : node->event.full_path );
        current_end += printed;
        space_left -= printed;
    }
    fclose( null_fle );
    return report;
}
/* }}} */
/*
 * Needed tool-functions, like function creating a hash parameter
 */

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
    ht->freenode    = zp_free_sevent_node;
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
/* FUNCTION: zp_free_sevent_node {{{ */
/**/
static void
zp_free_sevent_node( HashNode hn )
{
    zsfree( hn->nam );
    zfree( hn, sizeof( struct zp_sevent_node ) );
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

/*
 * Tool-functions that are more hacky or problem-solving
 */

/* FUNCTION: zp_has_option {{{ */
/**/
static int
zp_has_option( char **argv, char opt ) {
    char *string;
    while ( ( string = *argv ) ) {
        if ( string[0] == '-' ) {
            while ( *++string ) {
                if ( string[0] == opt ) {
                    return 1;
                }
            }
        }
        ++ argv;
    }
    return 0;
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

/*
 * Zshell module architecture data structures
 */

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

/*
 * Zshell module architecture functions
 */

/* FUNCTION: setup_ {{{ */
/**/
int
setup_( UNUSED( Module m ) )
{
    zp_setup_options_table();
    Builtin bn = ( Builtin ) builtintab->getnode2( builtintab, "." );
    originalDot = bn->handlerfunc;
    bn->handlerfunc = bin_custom_dot;

    bn = ( Builtin ) builtintab->getnode2( builtintab, "source" );
    originalSource = bn->handlerfunc;
    bn->handlerfunc = bin_custom_dot;

    /* Create private hash with source_prepare requests */
    if ( !( zp_source_events = zp_createhashtable( "zp_source_events" ) ) ) {
        zwarn( "Cannot create the hash table" );
        return 1;
    }

    return 0;
}
/* }}} */
/* FUNCTION: features_ {{{ */
/**/
int
features_( Module m, char ***features )
{
    *features = featuresarray( m, &module_features );
    return 0;
}
/* }}} */
/* FUNCTION: enables_ {{{ */
/**/
int
enables_( Module m, int **enables )
{
    return handlefeatures( m, &module_features, enables );
}
/* }}} */
/* FUNCTION: boot_ {{{ */
/**/
int
boot_( Module m )
{
    return 0;
}
/* }}} */
/* FUNCTION: cleanup_ {{{ */
/**/
int
cleanup_( Module m )
{
    return setfeatureenables( m, &module_features, NULL );
}
/* }}} */
/* FUNCTION: finish_ {{{ */
/**/
int
finish_( UNUSED( Module m ) )
{
    Builtin bn = ( Builtin ) builtintab->getnode2( builtintab, "." );
    bn->handlerfunc = originalDot;

    bn = ( Builtin ) builtintab->getnode2( builtintab, "source" );
    bn->handlerfunc = originalSource;

    printf( "zdharma/zplugin module unloaded\n" );
    fflush( stdout );
    return 0;
}
/* }}} */
