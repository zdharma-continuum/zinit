/*
 * compat.c - compatibility routines for the deprived
 *
 * This file is part of zsh, the Z shell.
 *
 * Copyright (c) 1992-1997 Paul Falstad
 * All rights reserved.
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
 *
 */

#include "zsh.mdh"
#include "compat.pro"

/* Return pointer to first occurence of string t *
 * in string s.  Return NULL if not present.     */

/**/
#ifndef HAVE_STRSTR

/**/
char *
strstr(const char *s, const char *t)
{
    const char *p1, *p2;

    for (; *s; s++) {
        for (p1 = s, p2 = t; *p2; p1++, p2++)
            if (*p1 != *p2)
                break;
        if (!*p2)
            return (char *)s;
    }
    return NULL;
}

/**/
#endif


/**/
#ifndef HAVE_GETHOSTNAME

/**/
int
gethostname(char *name, size_t namelen)
{
    struct utsname uts;

    uname(&uts);
    if(strlen(uts.nodename) >= namelen) {
	errno = EINVAL;
	return -1;
    }
    strcpy(name, uts.nodename);
    return 0;
}

/**/
#endif


/**/
#ifndef HAVE_GETTIMEOFDAY

/**/
int
gettimeofday(struct timeval *tv, struct timezone *tz)
{
    tv->tv_usec = 0;
    tv->tv_sec = (long)time((time_t) 0);
    return 0;
}

/**/
#endif


/* compute the difference between two calendar times */

/**/
#ifndef HAVE_DIFFTIME

/**/
double
difftime(time_t t2, time_t t1)
{
    return ((double)t2 - (double)t1);
}

/**/
#endif


/**/
#ifndef HAVE_STRERROR
extern char *sys_errlist[];

/* Get error message string associated with a particular  *
 * error number, and returns a pointer to that string.    *
 * This is not a particularly robust version of strerror. */

/**/
char *
strerror(int errnum)
{
    return (sys_errlist[errnum]);
}

/**/
#endif


#if 0
/* pathconf(_PC_PATH_MAX) is not currently useful to zsh.  The value *
 * returned varies depending on a number of factors, e.g. the amount *
 * of memory available to the operating system at a given time; thus *
 * it can't be used for buffer allocation, or even as an indication  *
 * of whether an attempt to use or create a given pathname may fail  *
 * at any future time.                                               *
 *                                                                   *
 * The call is also permitted to fail if the argument path is not an *
 * existing directory, so even to make sense of that one must search *
 * for a valid directory somewhere in the path and adjust.  Even if  *
 * it succeeds, the return value is relative to the input directory, *
 * and therefore potentially relative to the length of the shortest  *
 * path either to that directory or to our working directory.        *
 *                                                                   *
 * Finally, see the note below for glibc; detection of pathconf() is *
 * not by itself an indication that it works reliably.               */

/* The documentation for pathconf() says something like:             *
 *     The limit is returned, if one exists.  If the system  does    *
 *     not  have  a  limit  for  the  requested  resource,  -1 is    *
 *     returned, and errno is unchanged.  If there is  an  error,    *
 *     -1  is returned, and errno is set to reflect the nature of    *
 *     the error.                                                    *
 *                                                                   *
 * System calls are not permitted to set errno to 0; but we must (or *
 * some other flag value) in order to determine that the resource is *
 * unlimited.  What use is leaving errno unchanged?  Instead, define *
 * a wrapper that resets errno to 0 and returns 0 for "the system    *
 * does not have a limit," so that -1 always means a real error.     */

/**/
mod_export long
zpathmax(char *dir)
{
#ifdef HAVE_PATHCONF
    long pathmax;

    errno = 0;
    if ((pathmax = pathconf(dir, _PC_PATH_MAX)) >= 0) {
	/* Some versions of glibc pathconf return a hardwired value! */
	return pathmax;
    } else if (errno == EINVAL || errno == ENOENT || errno == ENOTDIR) {
	/* Work backward to find a directory, until we run out of path. */
	char *tail = strrchr(dir, '/');
	while (tail > dir && tail[-1] == '/')
	    --tail;
	if (tail > dir) {
	    *tail = 0;
	    pathmax = zpathmax(dir);
	    *tail = '/';
	} else {
	    errno = 0;
	    if (tail)
		pathmax = pathconf("/", _PC_PATH_MAX);
	    else
		pathmax = pathconf(".", _PC_PATH_MAX);
	}
	if (pathmax > 0) {
	    long taillen = (tail ? strlen(tail) : (strlen(dir) + 1));
	    if (taillen < pathmax)
		return pathmax - taillen;
	    else
		errno = ENAMETOOLONG;
	}
    }
    if (errno)
	return -1;
    else
	return 0; /* pathmax should be considered unlimited */
#else
    long dirlen = strlen(dir);

    /* The following is wrong if dir is not an absolute path. */
    return ((long) ((dirlen >= PATH_MAX) ?
		    ((errno = ENAMETOOLONG), -1) :
		    ((errno = 0), PATH_MAX - dirlen)));
#endif
}
#endif /* 0 */

/**/
#ifdef HAVE_SYSCONF
/*
 * This is replaced by a macro from system.h if not HAVE_SYSCONF.
 * 0 is returned by sysconf if _SC_OPEN_MAX is unavailable;
 * -1 is returned on error
 *
 * Neither of these should happen, but resort to OPEN_MAX rather
 * than return 0 or -1 just in case.
 *
 * We'll limit the open maximum to ZSH_INITIAL_OPEN_MAX to
 * avoid probing ridiculous numbers of file descriptors.
 */

/**/
mod_export long
zopenmax(void)
{
    long openmax;

    if ((openmax = sysconf(_SC_OPEN_MAX)) < 1) {
	openmax = OPEN_MAX;
    } else if (openmax > OPEN_MAX) {
	/* On some systems, "limit descriptors unlimited" or the  *
	 * equivalent will set openmax to a huge number.  Unless  *
	 * there actually is a file descriptor > OPEN_MAX already *
	 * open, nothing in zsh requires the true maximum, and in *
	 * fact it causes inefficiency elsewhere if we report it. *
	 * So, report the maximum of OPEN_MAX or the largest open *
	 * descriptor (is there a better way to find that?).      */
	long i, j = OPEN_MAX;
	if (openmax > ZSH_INITIAL_OPEN_MAX)
	    openmax = ZSH_INITIAL_OPEN_MAX;
	for (i = j; i < openmax; i += (errno != EINTR)) {
	    errno = 0;
	    if (fcntl(i, F_GETFL, 0) < 0 &&
		(errno == EBADF || errno == EINTR))
		continue;
	    j = i;
	}
	openmax = j;
    }

    return (max_zsh_fd > openmax) ? max_zsh_fd : openmax;
}

/**/
#endif

/*
 * Rationalise the current directory, returning the string.
 *
 * If "d" is not NULL, it is used to store information about the
 * directory.  The returned name is also present in d->dirname and is in
 * permanently allocated memory.  The handling of this case depends on
 * whether the fchdir() system call is available; if it is, it is assumed
 * the caller is able to restore the current directory.  On successfully
 * identifying the directory the function returns immediately rather
 * than ascending the hierarchy.
 *
 * If "d" is NULL, no assumption about the caller's behaviour is
 * made.  The returned string is in heap memory.  This case is
 * always handled by changing directory up the hierarchy.
 *
 * On Cygwin or other systems where USE_GETCWD is defined (at the
 * time of writing only QNX), we skip all the above and use the
 * getcwd() system call.
 */

/**/
mod_export char *
zgetdir(struct dirsav *d)
{
    char nbuf[PATH_MAX+3];
    char *buf;
    int bufsiz, pos;
    struct stat sbuf;
    ino_t pino;
    dev_t pdev;
#if !defined(__CYGWIN__) && !defined(USE_GETCWD)
    struct dirent *de;
    DIR *dir;
    dev_t dev;
    ino_t ino;
    int len;
#endif

    buf = zhalloc(bufsiz = PATH_MAX+1);
    pos = bufsiz - 1;
    buf[pos] = '\0';
    strcpy(nbuf, "../");
    if (stat(".", &sbuf) < 0) {
	return NULL;
    }

    /* Record the initial inode and device */
    pino = sbuf.st_ino;
    pdev = sbuf.st_dev;
    if (d)
	d->ino = pino, d->dev = pdev;
#if !defined(__CYGWIN__) && !defined(USE_GETCWD)
#ifdef HAVE_FCHDIR
    else
#endif
	holdintr();

    for (;;) {
	/* Examine the parent of the current directory. */
	if (stat("..", &sbuf) < 0)
	    break;

	/* Inode and device of curtent directory */
	ino = pino;
	dev = pdev;
	/* Inode and device of current directory's parent */
	pino = sbuf.st_ino;
	pdev = sbuf.st_dev;

	/* If they're the same, we've reached the root directory. */
	if (ino == pino && dev == pdev) {
	    if (!buf[pos])
		buf[--pos] = '/';
	    if (d) {
#ifndef HAVE_FCHDIR
		zchdir(buf + pos);
		noholdintr();
#endif
		return d->dirname = ztrdup(buf + pos);
	    }
	    zchdir(buf + pos);
	    noholdintr();
	    return buf + pos;
	}

	/* Search the parent for the current directory. */
	if (!(dir = opendir("..")))
	    break;

	while ((de = readdir(dir))) {
	    char *fn = de->d_name;
	    /* Ignore `.' and `..'. */
	    if (fn[0] == '.' &&
		(fn[1] == '\0' ||
		 (fn[1] == '.' && fn[2] == '\0')))
		continue;
#ifdef HAVE_STRUCT_DIRENT_D_STAT
	    if(de->d_stat.st_dev == dev && de->d_stat.st_ino == ino) {
		/* Found the directory we're currently in */
		strncpy(nbuf + 3, fn, PATH_MAX);
		break;
	    }
#else /* !HAVE_STRUCT_DIRENT_D_STAT */
# ifdef HAVE_STRUCT_DIRENT_D_INO
	    if (dev != pdev || (ino_t) de->d_ino == ino)
# endif /* HAVE_STRUCT_DIRENT_D_INO */
	    {
		/* Maybe found directory, need to check device & inode */
		strncpy(nbuf + 3, fn, PATH_MAX);
		lstat(nbuf, &sbuf);
		if (sbuf.st_dev == dev && sbuf.st_ino == ino)
		    break;
	    }
#endif /* !HAVE_STRUCT_DIRENT_D_STAT */
	}
	closedir(dir);
	if (!de)
	    break;		/* Not found */
	/*
	 * We get the "/" free just by copying from nbuf+2 instead
	 * of nbuf+3, which is where we copied the path component.
	 * This means buf[pos] is always a "/".
	 */
	len = strlen(nbuf + 2);
	pos -= len;
	while (pos <= 1) {
	    char *newbuf = zhalloc(2*bufsiz);
	    memcpy(newbuf + bufsiz, buf, bufsiz);
	    buf = newbuf;
	    pos += bufsiz;
	    bufsiz *= 2;
	}
	memcpy(buf + pos, nbuf + 2, len);
#ifdef HAVE_FCHDIR
	if (d)
	    return d->dirname = ztrdup(buf + pos + 1);
#endif
	if (chdir(".."))
	    break;
    }

    /*
     * Fix up the directory, if necessary.
     * We're changing back down the hierarchy, ignore the
     * "/" at buf[pos].
     */
    if (d) {
#ifndef HAVE_FCHDIR
	if (buf[pos])
	    zchdir(buf + pos + 1);
	noholdintr();
#endif
	return NULL;
    }

    if (buf[pos])
	zchdir(buf + pos + 1);
    noholdintr();

#else  /* __CYGWIN__, USE_GETCWD cases */

    if (!getcwd(buf, bufsiz)) {
	if (d) {
	    return NULL;
	}
    } else {
	if (d) {
	    return d->dirname = ztrdup(buf);
	}
	return buf;
    }
#endif

    /*
     * Something bad happened.
     * This has been seen when inside a special directory,
     * such as the Netapp .snapshot directory, that doesn't
     * appear as a directory entry in the parent directory.
     * We'll just need our best guess.
     *
     * We only get here from zgetcwd(); let that fall back to pwd.
     */

    return NULL;
}

/*
 * Try to find the current directory.
 * If we couldn't work it out internally, fall back to getcwd().
 * If it fails, fall back to pwd; if zgetcwd() is being used
 * to set pwd, pwd should be NULL and we just return ".".
 */

/**/
char *
zgetcwd(void)
{
    char *ret = zgetdir(NULL);
#ifdef HAVE_GETCWD
    if (!ret) {
#ifdef GETCWD_CALLS_MALLOC
	char *cwd = getcwd(NULL, 0);
	if (cwd) {
	    ret = dupstring(cwd);
	    free(cwd);
	}
#else
	char *cwdbuf = zalloc(PATH_MAX+1);
	ret = getcwd(cwdbuf, PATH_MAX);
	if (ret)
	    ret = dupstring(ret);
	zfree(cwdbuf, PATH_MAX+1);
#endif /* GETCWD_CALLS_MALLOC */
    }
#endif /* HAVE_GETCWD */
    if (!ret)
	ret = unmeta(pwd);
    if (!ret)
	ret = dupstring(".");
    return ret;
}

/*
 * chdir with arbitrary long pathname.  Returns 0 on success, -1 on normal *
 * failure and -2 when chdir failed and the current directory is lost.
 *
 * This is to be treated as if at system level, so dir is unmetafied but
 * terminated by a NULL.
 */

/**/
mod_export int
zchdir(char *dir)
{
    char *s;
    int currdir = -2;

    for (;;) {
	if (!*dir || chdir(dir) == 0) {
#ifdef HAVE_FCHDIR
           if (currdir >= 0)
               close(currdir);
#endif
	    return 0;
	}
	if ((errno != ENAMETOOLONG && errno != ENOMEM) ||
	    strlen(dir) < PATH_MAX)
	    break;
	for (s = dir + PATH_MAX - 1; s > dir && *s != '/'; s--)
	    ;
	if (s == dir)
	    break;
#ifdef HAVE_FCHDIR
	if (currdir == -2)
	    currdir = open(".", O_RDONLY|O_NOCTTY);
#endif
	*s = '\0';
	if (chdir(dir) < 0) {
	    *s = '/';
	    break;
	}
#ifndef HAVE_FCHDIR
	currdir = -1;
#endif
	*s = '/';
	while (*++s == '/')
	    ;
	dir = s;
    }
#ifdef HAVE_FCHDIR
    if (currdir >= 0) {
	if (fchdir(currdir) < 0) {
	    close(currdir);
	    return -2;
	}
	close(currdir);
	return -1;
    }
#endif
    return currdir == -2 ? -1 : -2;
}

/*
 * How to print out a 64 bit integer.  This isn't needed (1) if longs
 * are 64 bit, since ordinary %ld will work (2) if we couldn't find a
 * 64 bit type anyway.
 */
/**/
#ifdef ZSH_64_BIT_TYPE
/**/
mod_export char *
output64(zlong val)
{
    static char llbuf[DIGBUFSIZE];
    convbase(llbuf, val, 0);
    return llbuf;
}
/**/
#endif /* ZSH_64_BIT_TYPE */

/**/
#ifndef HAVE_STRTOUL

/*
 * Copyright (c) 1990, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/*
 * Convert a string to an unsigned long integer.
 *
 * Ignores `locale' stuff.  Assumes that the upper and lower case
 * alphabets and digits are each contiguous.
 */

/**/
unsigned long
strtoul(nptr, endptr, base)
	const char *nptr;
	char **endptr;
	int base;
{
	const char *s;
	unsigned long acc, cutoff;
	int c;
	int neg, any, cutlim;

	/* endptr may be NULL */

	s = nptr;
	do {
		c = (unsigned char) *s++;
	} while (isspace(c));
	if (c == '-') {
		neg = 1;
		c = *s++;
	} else {
		neg = 0;
		if (c == '+')
			c = *s++;
	}
	if ((base == 0 || base == 16) &&
	    c == '0' && (*s == 'x' || *s == 'X')) {
		c = s[1];
		s += 2;
		base = 16;
	}
	if (base == 0)
		base = c == '0' ? 8 : 10;

	cutoff = ULONG_MAX / (unsigned long)base;
	cutlim = (int)(ULONG_MAX % (unsigned long)base);
	for (acc = 0, any = 0;; c = (unsigned char) *s++) {
		if (isdigit(c))
			c -= '0';
		else if (isalpha(c)) {
			c -= isupper(c) ? 'A' - 10 : 'a' - 10;
		} else
			break;
		if (c >= base)
			break;
		if (any < 0)
			continue;
		if (acc > cutoff || (acc == cutoff && c > cutlim)) {
			any = -1;
			acc = ULONG_MAX;
			errno = ERANGE;
		} else {
			any = 1;
			acc *= (unsigned long)base;
			acc += c;
		}
	}
	if (neg && any > 0)
		acc = -acc;
	if (endptr != NULL)
		*endptr = any ? s - 1 : nptr;
	return (acc);
}

/**/
#endif /* HAVE_STRTOUL */

/**/
#ifdef ENABLE_UNICODE9
#include "./wcwidth9.h"

/**/
int
mk_wcwidth(wchar_t ucs)
{
  int w = wcwidth9(ucs);
  if (w < -1)
    return 1;
  return w;
}

/**/
#elif defined(BROKEN_WCWIDTH) && (defined(__STDC_ISO_10646__) || defined(__APPLE__))

/*
 * This is an implementation of wcwidth() and wcswidth() (defined in
 * IEEE Std 1002.1-2001) for Unicode.
 *
 * http://www.opengroup.org/onlinepubs/007904975/functions/wcwidth.html
 * http://www.opengroup.org/onlinepubs/007904975/functions/wcswidth.html
 *
 * In fixed-width output devices, Latin characters all occupy a single
 * "cell" position of equal width, whereas ideographic CJK characters
 * occupy two such cells. Interoperability between terminal-line
 * applications and (teletype-style) character terminals using the
 * UTF-8 encoding requires agreement on which character should advance
 * the cursor by how many cell positions. No established formal
 * standards exist at present on which Unicode character shall occupy
 * how many cell positions on character terminals. These routines are
 * a first attempt of defining such behavior based on simple rules
 * applied to data provided by the Unicode Consortium.
 *
 * For some graphical characters, the Unicode standard explicitly
 * defines a character-cell width via the definition of the East Asian
 * FullWidth (F), Wide (W), Half-width (H), and Narrow (Na) classes.
 * In all these cases, there is no ambiguity about which width a
 * terminal shall use. For characters in the East Asian Ambiguous (A)
 * class, the width choice depends purely on a preference of backward
 * compatibility with either historic CJK or Western practice.
 * Choosing single-width for these characters is easy to justify as
 * the appropriate long-term solution, as the CJK practice of
 * displaying these characters as double-width comes from historic
 * implementation simplicity (8-bit encoded characters were displayed
 * single-width and 16-bit ones double-width, even for Greek,
 * Cyrillic, etc.) and not any typographic considerations.
 *
 * Much less clear is the choice of width for the Not East Asian
 * (Neutral) class. Existing practice does not dictate a width for any
 * of these characters. It would nevertheless make sense
 * typographically to allocate two character cells to characters such
 * as for instance EM SPACE or VOLUME INTEGRAL, which cannot be
 * represented adequately with a single-width glyph. The following
 * routines at present merely assign a single-cell width to all
 * neutral characters, in the interest of simplicity. This is not
 * entirely satisfactory and should be reconsidered before
 * establishing a formal standard in this area. At the moment, the
 * decision which Not East Asian (Neutral) characters should be
 * represented by double-width glyphs cannot yet be answered by
 * applying a simple rule from the Unicode database content. Setting
 * up a proper standard for the behavior of UTF-8 character terminals
 * will require a careful analysis not only of each Unicode character,
 * but also of each presentation form, something the author of these
 * routines has avoided to do so far.
 *
 * http://www.unicode.org/unicode/reports/tr11/
 *
 * Markus Kuhn -- 2007-05-26 (Unicode 5.0)
 *
 * Permission to use, copy, modify, and distribute this software
 * for any purpose and without fee is hereby granted. The author
 * disclaims all warranties with regard to this software.
 *
 * Latest version: http://www.cl.cam.ac.uk/~mgk25/ucs/wcwidth.c
 */

struct interval {
  int first;
  int last;
};

/* auxiliary function for binary search in interval table */
static int bisearch(wchar_t ucs, const struct interval *table, int max) {
  int min = 0;
  int mid;

  if (ucs < table[0].first || ucs > table[max].last)
    return 0;
  while (max >= min) {
    mid = (min + max) / 2;
    if (ucs > table[mid].last)
      min = mid + 1;
    else if (ucs < table[mid].first)
      max = mid - 1;
    else
      return 1;
  }

  return 0;
}


/* The following two functions define the column width of an ISO 10646
 * character as follows:
 *
 *    - The null character (U+0000) has a column width of 0.
 *
 *    - Other C0/C1 control characters and DEL will lead to a return
 *      value of -1.
 *
 *    - Non-spacing and enclosing combining characters (general
 *      category code Mn or Me in the Unicode database) have a
 *      column width of 0.
 *
 *    - SOFT HYPHEN (U+00AD) has a column width of 1.
 *
 *    - Other format characters (general category code Cf in the Unicode
 *      database) and ZERO WIDTH SPACE (U+200B) have a column width of 0.
 *
 *    - Hangul Jamo medial vowels and final consonants (U+1160-U+11FF)
 *      have a column width of 0.
 *
 *    - Spacing characters in the East Asian Wide (W) or East Asian
 *      Full-width (F) category as defined in Unicode Technical
 *      Report #11 have a column width of 2.
 *
 *    - All remaining characters (including all printable
 *      ISO 8859-1 and WGL4 characters, Unicode control characters,
 *      etc.) have a column width of 1.
 *
 * This implementation assumes that wchar_t characters are encoded
 * in ISO 10646.
 */

/**/
int
mk_wcwidth(wchar_t ucs)
{
  /* sorted list of non-overlapping intervals of non-spacing characters */
  /* generated by "uniset +cat=Me +cat=Mn +cat=Cf -00AD +1160-11FF +200B c" */
  static const struct interval combining[] = {
    { 0x0300, 0x036F }, { 0x0483, 0x0486 }, { 0x0488, 0x0489 },
    { 0x0591, 0x05BD }, { 0x05BF, 0x05BF }, { 0x05C1, 0x05C2 },
    { 0x05C4, 0x05C5 }, { 0x05C7, 0x05C7 }, { 0x0600, 0x0603 },
    { 0x0610, 0x0615 }, { 0x064B, 0x065E }, { 0x0670, 0x0670 },
    { 0x06D6, 0x06E4 }, { 0x06E7, 0x06E8 }, { 0x06EA, 0x06ED },
    { 0x070F, 0x070F }, { 0x0711, 0x0711 }, { 0x0730, 0x074A },
    { 0x07A6, 0x07B0 }, { 0x07EB, 0x07F3 }, { 0x0901, 0x0902 },
    { 0x093C, 0x093C }, { 0x0941, 0x0948 }, { 0x094D, 0x094D },
    { 0x0951, 0x0954 }, { 0x0962, 0x0963 }, { 0x0981, 0x0981 },
    { 0x09BC, 0x09BC }, { 0x09C1, 0x09C4 }, { 0x09CD, 0x09CD },
    { 0x09E2, 0x09E3 }, { 0x0A01, 0x0A02 }, { 0x0A3C, 0x0A3C },
    { 0x0A41, 0x0A42 }, { 0x0A47, 0x0A48 }, { 0x0A4B, 0x0A4D },
    { 0x0A70, 0x0A71 }, { 0x0A81, 0x0A82 }, { 0x0ABC, 0x0ABC },
    { 0x0AC1, 0x0AC5 }, { 0x0AC7, 0x0AC8 }, { 0x0ACD, 0x0ACD },
    { 0x0AE2, 0x0AE3 }, { 0x0B01, 0x0B01 }, { 0x0B3C, 0x0B3C },
    { 0x0B3F, 0x0B3F }, { 0x0B41, 0x0B43 }, { 0x0B4D, 0x0B4D },
    { 0x0B56, 0x0B56 }, { 0x0B82, 0x0B82 }, { 0x0BC0, 0x0BC0 },
    { 0x0BCD, 0x0BCD }, { 0x0C3E, 0x0C40 }, { 0x0C46, 0x0C48 },
    { 0x0C4A, 0x0C4D }, { 0x0C55, 0x0C56 }, { 0x0CBC, 0x0CBC },
    { 0x0CBF, 0x0CBF }, { 0x0CC6, 0x0CC6 }, { 0x0CCC, 0x0CCD },
    { 0x0CE2, 0x0CE3 }, { 0x0D41, 0x0D43 }, { 0x0D4D, 0x0D4D },
    { 0x0DCA, 0x0DCA }, { 0x0DD2, 0x0DD4 }, { 0x0DD6, 0x0DD6 },
    { 0x0E31, 0x0E31 }, { 0x0E34, 0x0E3A }, { 0x0E47, 0x0E4E },
    { 0x0EB1, 0x0EB1 }, { 0x0EB4, 0x0EB9 }, { 0x0EBB, 0x0EBC },
    { 0x0EC8, 0x0ECD }, { 0x0F18, 0x0F19 }, { 0x0F35, 0x0F35 },
    { 0x0F37, 0x0F37 }, { 0x0F39, 0x0F39 }, { 0x0F71, 0x0F7E },
    { 0x0F80, 0x0F84 }, { 0x0F86, 0x0F87 }, { 0x0F90, 0x0F97 },
    { 0x0F99, 0x0FBC }, { 0x0FC6, 0x0FC6 }, { 0x102D, 0x1030 },
    { 0x1032, 0x1032 }, { 0x1036, 0x1037 }, { 0x1039, 0x1039 },
    { 0x1058, 0x1059 }, { 0x1160, 0x11FF }, { 0x135F, 0x135F },
    { 0x1712, 0x1714 }, { 0x1732, 0x1734 }, { 0x1752, 0x1753 },
    { 0x1772, 0x1773 }, { 0x17B4, 0x17B5 }, { 0x17B7, 0x17BD },
    { 0x17C6, 0x17C6 }, { 0x17C9, 0x17D3 }, { 0x17DD, 0x17DD },
    { 0x180B, 0x180D }, { 0x18A9, 0x18A9 }, { 0x1920, 0x1922 },
    { 0x1927, 0x1928 }, { 0x1932, 0x1932 }, { 0x1939, 0x193B },
    { 0x1A17, 0x1A18 }, { 0x1B00, 0x1B03 }, { 0x1B34, 0x1B34 },
    { 0x1B36, 0x1B3A }, { 0x1B3C, 0x1B3C }, { 0x1B42, 0x1B42 },
    { 0x1B6B, 0x1B73 }, { 0x1DC0, 0x1DCA }, { 0x1DFE, 0x1DFF },
    { 0x200B, 0x200F }, { 0x202A, 0x202E }, { 0x2060, 0x2063 },
    { 0x206A, 0x206F }, { 0x20D0, 0x20EF }, { 0x302A, 0x302F },
    { 0x3099, 0x309A }, { 0xA806, 0xA806 }, { 0xA80B, 0xA80B },
    { 0xA825, 0xA826 }, { 0xFB1E, 0xFB1E }, { 0xFE00, 0xFE0F },
    { 0xFE20, 0xFE23 }, { 0xFEFF, 0xFEFF }, { 0xFFF9, 0xFFFB },
    { 0x10A01, 0x10A03 }, { 0x10A05, 0x10A06 }, { 0x10A0C, 0x10A0F },
    { 0x10A38, 0x10A3A }, { 0x10A3F, 0x10A3F }, { 0x1D167, 0x1D169 },
    { 0x1D173, 0x1D182 }, { 0x1D185, 0x1D18B }, { 0x1D1AA, 0x1D1AD },
    { 0x1D242, 0x1D244 }, { 0xE0001, 0xE0001 }, { 0xE0020, 0xE007F },
    { 0xE0100, 0xE01EF }
  };

  /* test for 8-bit control characters */
  if (ucs == 0)
    return 0;
  if (ucs < 32 || (ucs >= 0x7f && ucs < 0xa0))
    return -1;

  /* binary search in table of non-spacing characters */
  if (bisearch(ucs, combining,
	       sizeof(combining) / sizeof(struct interval) - 1))
    return 0;

  /* if we arrive here, ucs is not a combining or C0/C1 control character */

  return 1 +
    (ucs >= 0x1100 &&
     (ucs <= 0x115f ||                    /* Hangul Jamo init. consonants */
      ucs == 0x2329 || ucs == 0x232a ||
      (ucs >= 0x2e80 && ucs <= 0xa4cf &&
       ucs != 0x303f) ||                  /* CJK ... Yi */
      (ucs >= 0xac00 && ucs <= 0xd7a3) || /* Hangul Syllables */
      (ucs >= 0xf900 && ucs <= 0xfaff) || /* CJK Compatibility Ideographs */
      (ucs >= 0xfe10 && ucs <= 0xfe19) || /* Vertical forms */
      (ucs >= 0xfe30 && ucs <= 0xfe6f) || /* CJK Compatibility Forms */
      (ucs >= 0xff00 && ucs <= 0xff60) || /* Fullwidth Forms */
      (ucs >= 0xffe0 && ucs <= 0xffe6) ||
      (ucs >= 0x20000 && ucs <= 0x2fffd) ||
      (ucs >= 0x30000 && ucs <= 0x3fffd)));
}


/*
 * The following functions are part of the original wcwidth.c:
 * we don't use them but I've kept them in case - pws.
 */
#if 0
int mk_wcswidth(const wchar_t *pwcs, size_t n)
{
  int w, width = 0;

  for (;*pwcs && n-- > 0; pwcs++)
    if ((w = mk_wcwidth(*pwcs)) < 0)
      return -1;
    else
      width += w;

  return width;
}


/*
 * The following functions are the same as mk_wcwidth() and
 * mk_wcswidth(), except that spacing characters in the East Asian
 * Ambiguous (A) category as defined in Unicode Technical Report #11
 * have a column width of 2. This variant might be useful for users of
 * CJK legacy encodings who want to migrate to UCS without changing
 * the traditional terminal character-width behaviour. It is not
 * otherwise recommended for general use.
 */
int mk_wcwidth_cjk(wchar_t ucs)
{
  /* sorted list of non-overlapping intervals of East Asian Ambiguous
   * characters, generated by "uniset +WIDTH-A -cat=Me -cat=Mn -cat=Cf c" */
  static const struct interval ambiguous[] = {
    { 0x00A1, 0x00A1 }, { 0x00A4, 0x00A4 }, { 0x00A7, 0x00A8 },
    { 0x00AA, 0x00AA }, { 0x00AE, 0x00AE }, { 0x00B0, 0x00B4 },
    { 0x00B6, 0x00BA }, { 0x00BC, 0x00BF }, { 0x00C6, 0x00C6 },
    { 0x00D0, 0x00D0 }, { 0x00D7, 0x00D8 }, { 0x00DE, 0x00E1 },
    { 0x00E6, 0x00E6 }, { 0x00E8, 0x00EA }, { 0x00EC, 0x00ED },
    { 0x00F0, 0x00F0 }, { 0x00F2, 0x00F3 }, { 0x00F7, 0x00FA },
    { 0x00FC, 0x00FC }, { 0x00FE, 0x00FE }, { 0x0101, 0x0101 },
    { 0x0111, 0x0111 }, { 0x0113, 0x0113 }, { 0x011B, 0x011B },
    { 0x0126, 0x0127 }, { 0x012B, 0x012B }, { 0x0131, 0x0133 },
    { 0x0138, 0x0138 }, { 0x013F, 0x0142 }, { 0x0144, 0x0144 },
    { 0x0148, 0x014B }, { 0x014D, 0x014D }, { 0x0152, 0x0153 },
    { 0x0166, 0x0167 }, { 0x016B, 0x016B }, { 0x01CE, 0x01CE },
    { 0x01D0, 0x01D0 }, { 0x01D2, 0x01D2 }, { 0x01D4, 0x01D4 },
    { 0x01D6, 0x01D6 }, { 0x01D8, 0x01D8 }, { 0x01DA, 0x01DA },
    { 0x01DC, 0x01DC }, { 0x0251, 0x0251 }, { 0x0261, 0x0261 },
    { 0x02C4, 0x02C4 }, { 0x02C7, 0x02C7 }, { 0x02C9, 0x02CB },
    { 0x02CD, 0x02CD }, { 0x02D0, 0x02D0 }, { 0x02D8, 0x02DB },
    { 0x02DD, 0x02DD }, { 0x02DF, 0x02DF }, { 0x0391, 0x03A1 },
    { 0x03A3, 0x03A9 }, { 0x03B1, 0x03C1 }, { 0x03C3, 0x03C9 },
    { 0x0401, 0x0401 }, { 0x0410, 0x044F }, { 0x0451, 0x0451 },
    { 0x2010, 0x2010 }, { 0x2013, 0x2016 }, { 0x2018, 0x2019 },
    { 0x201C, 0x201D }, { 0x2020, 0x2022 }, { 0x2024, 0x2027 },
    { 0x2030, 0x2030 }, { 0x2032, 0x2033 }, { 0x2035, 0x2035 },
    { 0x203B, 0x203B }, { 0x203E, 0x203E }, { 0x2074, 0x2074 },
    { 0x207F, 0x207F }, { 0x2081, 0x2084 }, { 0x20AC, 0x20AC },
    { 0x2103, 0x2103 }, { 0x2105, 0x2105 }, { 0x2109, 0x2109 },
    { 0x2113, 0x2113 }, { 0x2116, 0x2116 }, { 0x2121, 0x2122 },
    { 0x2126, 0x2126 }, { 0x212B, 0x212B }, { 0x2153, 0x2154 },
    { 0x215B, 0x215E }, { 0x2160, 0x216B }, { 0x2170, 0x2179 },
    { 0x2190, 0x2199 }, { 0x21B8, 0x21B9 }, { 0x21D2, 0x21D2 },
    { 0x21D4, 0x21D4 }, { 0x21E7, 0x21E7 }, { 0x2200, 0x2200 },
    { 0x2202, 0x2203 }, { 0x2207, 0x2208 }, { 0x220B, 0x220B },
    { 0x220F, 0x220F }, { 0x2211, 0x2211 }, { 0x2215, 0x2215 },
    { 0x221A, 0x221A }, { 0x221D, 0x2220 }, { 0x2223, 0x2223 },
    { 0x2225, 0x2225 }, { 0x2227, 0x222C }, { 0x222E, 0x222E },
    { 0x2234, 0x2237 }, { 0x223C, 0x223D }, { 0x2248, 0x2248 },
    { 0x224C, 0x224C }, { 0x2252, 0x2252 }, { 0x2260, 0x2261 },
    { 0x2264, 0x2267 }, { 0x226A, 0x226B }, { 0x226E, 0x226F },
    { 0x2282, 0x2283 }, { 0x2286, 0x2287 }, { 0x2295, 0x2295 },
    { 0x2299, 0x2299 }, { 0x22A5, 0x22A5 }, { 0x22BF, 0x22BF },
    { 0x2312, 0x2312 }, { 0x2460, 0x24E9 }, { 0x24EB, 0x254B },
    { 0x2550, 0x2573 }, { 0x2580, 0x258F }, { 0x2592, 0x2595 },
    { 0x25A0, 0x25A1 }, { 0x25A3, 0x25A9 }, { 0x25B2, 0x25B3 },
    { 0x25B6, 0x25B7 }, { 0x25BC, 0x25BD }, { 0x25C0, 0x25C1 },
    { 0x25C6, 0x25C8 }, { 0x25CB, 0x25CB }, { 0x25CE, 0x25D1 },
    { 0x25E2, 0x25E5 }, { 0x25EF, 0x25EF }, { 0x2605, 0x2606 },
    { 0x2609, 0x2609 }, { 0x260E, 0x260F }, { 0x2614, 0x2615 },
    { 0x261C, 0x261C }, { 0x261E, 0x261E }, { 0x2640, 0x2640 },
    { 0x2642, 0x2642 }, { 0x2660, 0x2661 }, { 0x2663, 0x2665 },
    { 0x2667, 0x266A }, { 0x266C, 0x266D }, { 0x266F, 0x266F },
    { 0x273D, 0x273D }, { 0x2776, 0x277F }, { 0xE000, 0xF8FF },
    { 0xFFFD, 0xFFFD }, { 0xF0000, 0xFFFFD }, { 0x100000, 0x10FFFD }
  };

  /* binary search in table of non-spacing characters */
  if (bisearch(ucs, ambiguous,
	       sizeof(ambiguous) / sizeof(struct interval) - 1))
    return 2;

  return mk_wcwidth(ucs);
}


int mk_wcswidth_cjk(const wchar_t *pwcs, size_t n)
{
  int w, width = 0;

  for (;*pwcs && n-- > 0; pwcs++)
    if ((w = mk_wcwidth_cjk(*pwcs)) < 0)
      return -1;
    else
      width += w;

  return width;
}
#endif /* 0 */

/**/
#endif /* BROKEN_WCWIDTH && (__STDC_ISO_10646__ || __APPLE__) */

/**/
#if defined(__APPLE__) && defined(BROKEN_ISPRINT)

/**/
int
isprint_ascii(int c)
{
    if (!strcmp(nl_langinfo(CODESET), "UTF-8"))
	return (c >= 0x20 && c <= 0x7e);
    else
	return isprint(c);
}

/**/
#endif /* __APPLE__ && BROKEN_ISPRINT */
