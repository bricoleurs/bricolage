dnl
dnl The Autoconf macros in this file are free software; you can
dnl redistribute it and/or modify it under the terms of the GNU
dnl General Public License as published by the Free Software
dnl Foundation; either version 2, or (at your option) any later
dnl version. 
dnl 
dnl They are distributed in the hope that they will be useful,
dnl but WITHOUT ANY WARRANTY; without even the implied warranty
dnl of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
dnl the GNU General Public License for more details. (You should
dnl have received a copy of the GNU General Public License along
dnl with this program; if not, write to the Free Software
dnl Foundation, Inc., 59 Temple Place -- Suite 330, Boston, MA
dnl 02111-1307, USA.) 
dnl 
dnl As a special exception, the Free Software Foundation gives
dnl unlimited permission to copy, distribute and modify the
dnl configure scripts that are the output of Autoconf. You need
dnl not follow the terms of the GNU General Public License when
dnl using or distributing such scripts, even though portions of
dnl the text of Autoconf appear in them. The GNU General Public
dnl License (GPL) does govern all other use of the material that
dnl constitutes the Autoconf program. 
dnl 
dnl Certain portions of the Autoconf source text are designed to
dnl be copied (in certain cases, depending on the input) into
dnl the output of Autoconf. We call these the "data" portions.
dnl The rest of the Autoconf source text consists of comments
dnl plus executable code that decides which of the data portions
dnl to output in any given case. We call these comments and
dnl executable code the "non-data" portions. Autoconf never
dnl copies any of the non-data portions into its output. 
dnl 
dnl This special exception to the GPL applies to versions of
dnl Autoconf released by the Free Software Foundation. When you
dnl make and distribute a modified version of Autoconf, you may
dnl extend this special exception to the GPL to apply to your
dnl modified version as well, *unless* your modified version has
dnl the potential to copy into its output some of the text that
dnl was the non-data portion of the version that you started
dnl with. (In other words, unless your change moves or copies
dnl text from the non-data portions to the data portions.) If
dnl your modification has such potential, you must delete any
dnl notice of this special exception to the GPL from your
dnl modified version. 


dnl @synopsis CHECK_CPAN_MODULE{Module::Name [,Version ][,PathToPerl]}
dnl
dnl This macro searches the installed base of CPAN modules
dnl determine the the requested module is installed.
dnl
dnl
dnl @version $Id: aclocal.m4,v 1.1 2001-12-11 10:00:58 markjaroski Exp $
dnl @author Mark Jaroski <mark@geekhive.net>
dnl
AC_DEFUN([CHECK_CPAN_MODULE],[
 AC_MSG_CHECKING(for CPAN module $1)
 dnl TODO:
 AC_MSG_RESULT(maaaaybeee...)
])

dnl @synopsis AC_PROG_POSTGRESQL{[version]}
dnl
dnl This macro searches for an installation of PostgreSQL
dnl
dnl
dnl @version $Id: aclocal.m4,v 1.1 2001-12-11 10:00:58 markjaroski Exp $
dnl @author Mark Jaroski <mark@geekhive.net>
dnl
AC_DEFUN([AC_PROG_POSTGRESQL],[
 AC_MSG_CHECKING(for PostgreSQL)
 dnl TODO:
 AC_MSG_RESULT(maaaaybeee...) 
])

dnl @author Loic Dachary <loic@senga.org> 
dnl modified by Mark Jaroski <mark@geekhive.net> to add
dnl support for Debian apache installs
AC_DEFUN([AC_PROG_APACHE],
#
# Handle user hints
#
[
 AC_MSG_CHECKING(if apache is wanted)
 AC_ARG_WITH(apache,
  [  --with-apache=PATH absolute path name of apache server (default is to search httpd in
    /usr/local/apache/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin),
    --without-apache to disable apache detection],
  [
    #
    # Run this if -with or -without was specified
    #
    if test "$withval" != no ; then
       AC_MSG_RESULT(yes)
       APACHE_WANTED=yes
       if test "$withval" != yes ; then
         APACHE="$withval"
       fi
    else
       APACHE_WANTED=no
       AC_MSG_RESULT(no)
    fi
  ], [
    #
    # Run this if nothing was said
    #
    APACHE_WANTED=yes
    AC_MSG_RESULT(yes)
  ])
  #
  # Now we know if we want apache or not, only go further if
  # it's wanted.
  #
  if test $APACHE_WANTED = yes ; then
    #
    # If not specified by caller, search in standard places
    #
    if test -z "$APACHE" ; then
      # added for Debian compatibility
      AC_PATH_PROG(APACHE, apache-perl, , /usr/local/apache/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin)
      AC_PATH_PROG(APACHE, apache, , /usr/local/apache/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin)
      # original for non-Debian systems
      AC_PATH_PROG(APACHE, httpd, , /usr/local/apache/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin)
    fi
    AC_SUBST(APACHE)
    if test -z "$APACHE" ; then
        AC_MSG_ERROR("apache server executable not found");
    fi
    #
    # Collect apache version number. If for nothing else, this
    # guaranties that httpd is a working apache executable.
    #
    changequote(<<, >>)dnl
    APACHE_READABLE_VERSION=`$APACHE -v | grep 'Server version' | sed -e 's;.*Apache/\([0-9\.][0-9\.]*\).*;\1;'`
    changequote([, ])dnl
    APACHE_VERSION=`echo $APACHE_READABLE_VERSION | sed -e 's/\.//g'`
    if test -z "$APACHE_VERSION" ; then
        AC_MSG_ERROR("could not determine apache version number");
    fi
    APACHE_MAJOR=`expr $APACHE_VERSION : '\(..\)'`
    APACHE_MINOR=`expr $APACHE_VERSION : '..\(.*\)'`
    #
    # Check that apache version matches requested version or above
    #
    if test -n "$1" ; then
      AC_MSG_CHECKING(apache version >= $1)
      APACHE_REQUEST=`echo $1 | sed -e 's/\.//g'`
      APACHE_REQUEST_MAJOR=`expr $APACHE_REQUEST : '\(..\)'`
      APACHE_REQUEST_MINOR=`expr $APACHE_REQUEST : '..\(.*\)'`
      if test "$APACHE_MAJOR" -lt "$APACHE_REQUEST_MAJOR" -o "$APACHE_MINOR" -lt "$APACHE_REQUEST_MINOR" ; then
        AC_MSG_RESULT(no)
        AC_MSG_ERROR(apache version is $APACHE_READABLE_VERSION)
      else
        AC_MSG_RESULT(yes)
      fi
    fi
    #
    # Find out if .so modules are in libexec/module.so or modules/module.so
    #
    HTTP_ROOT=`$APACHE -V | grep HTTPD_ROOT | sed -e 's/.*"\(.*\)"/\1/'`
    AC_MSG_CHECKING(apache modules)
    for dir in libexec modules
    do
      if test -f $HTTP_ROOT/$dir/mod_env.*
      then
        APACHE_MODULES=$dir
      fi
    done
    if test -z "$APACHE_MODULES"
    then
      AC_MSG_RESULT(not found)
    else
      AC_MSG_RESULT(in $HTTP_ROOT/$APACHE_MODULES)
    fi
    AC_SUBST(APACHE_MODULES)
  fi
])


dnl @author Mark Ethan Trostler <trostler@juniper.net> 
AC_DEFUN([CHECK_SSL],
[AC_MSG_CHECKING(if ssl is wanted)
AC_ARG_WITH(ssl,
[  --with-ssl enable ssl [will check /usr/local/ssl
                            /usr/lib/ssl /usr/ssl /usr/pkg /usr/local /usr ]
],
[   AC_MSG_RESULT(yes)
    for dir in $withval /usr/local/ssl /usr/lib/ssl /usr/ssl /usr/pkg /usr/local /usr; do
        ssldir="$dir"
        if test -f "$dir/include/openssl/ssl.h"; then
            found_ssl="yes";
            CFLAGS="$CFLAGS -I$ssldir/include/openssl -DHAVE_SSL";
            break;
        fi
        if test -f "$dir/include/ssl.h"; then
            found_ssl="yes";
            CFLAGS="$CFLAGS -I$ssldir/include/ -DHAVE_SSL";
            break
        fi
    done
    if test x_$found_ssl != x_yes; then
        AC_MSG_ERROR(Cannot find ssl libraries)
    else
        printf "OpenSSL found in $ssldir\n";
        LIBS="$LIBS -lssl -lcrypto";
        LDFLAGS="$LDFLAGS -L$ssldir/lib";
        HAVE_SSL=yes
    fi
    AC_SUBST(HAVE_SSL)
],
[
    AC_MSG_RESULT(no)
])
])


dnl John Darrington <j.darrington@elvis.murdoch.edu.au> 
AC_DEFUN(
        [CHECK_GNU_MAKE], [ AC_CACHE_CHECK( for GNU make,_cv_gnu_make_command,
                _cv_gnu_make_command='' ;
dnl Search all the common names for GNU make
                for a in "$MAKE" make gmake gnumake ; do
                        if  ( $a --version 2> /dev/null | grep  -q GNU  ) ;  then
                                _cv_gnu_make_command=$a ;
                                break;
                        fi
                done ;
        ) ;
dnl If there was a GNU version, then set @ifGNUmake@ to the empty string, '#' otherwise
        if test  "x$_cv_gnu_make_command" != "x"  ; then
                ifGNUmake='' ;
        else
                ifGNUmake='#' ;
        fi
        AC_SUBST(ifGNUmake)
] )

