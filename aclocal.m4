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

dnl @synopsis AC_ARG_VAR_DEFAULT(VAR, DEFAULT_VALUE)
dnl 
dnl Places a default value into an environmental variable which is then
dnl "blessed" by AC_ARG_VAR
dnl
dnl @author Mark Jaroski <mark@geekhive.net>
AC_DEFUN([AC_ARG_VAR_DEFAULT],[
	AC_HELP_STRING($1,[Defaults to: $2])
	AC_ARG_VAR($1)
	if test -z "${$1}" ;then
		$1=$2 ;
	fi
])

dnl @synopsis AC_PROG_PERL(VAR[, VERSION]])
dnl 
dnl A cheap quickie version of a perl macro.  
dnl
dnl @author Mark Jaroski <mark@geekhive.net>
AC_DEFUN([AC_PROG_PERL],[
  AC_PATH_PROG($1, perl)  
  #
  # Collect perl version number. If for nothing else, this
  # guaranties that perl is a working perl executable.
  #
  changequote(<<, >>)dnl
  PERL_VERSION=`${$1} -v | grep 'This is perl' | sed -e 's;.* v\([0-9\.][0-9\.]*\).*;\1;'`
  changequote([, ])dnl
  if test -z "$PERL_VERSION" ; then
      AC_MSG_ERROR("could not determine perl version number");
  fi
  changequote(<<, >>)dnl
  PERL_MAJOR=`expr $PERL_VERSION : '\([0-9]*\)'`
  PERL_MINOR=`expr $PERL_VERSION : "$PERL_MAJOR.\([0-9]*\)"`
  PERL_SUBMINOR=`expr $PERL_VERSION : "$PERL_MAJOR.$PERL_MINOR.\([0-9]*\)"`
  changequote([, ])dnl
  #
  # Check that perl version matches requested version or above
  #
  if test -n "$2" ; then
    AC_MSG_CHECKING(perl version >= $2)
    changequote(<<, >>)dnl
    PERL_REQUEST_MAJOR=`expr $2 : '\([0-9]*\)'`
    PERL_REQUEST_MINOR=`expr $2 : "$PERL_REQUEST_MAJOR.\([0-9]*\)"`
    PERL_REQUEST_SUBMINOR=`expr $2 : "$PERL_REQUEST_MAJOR.$PERL_REQUEST_MINOR.\([0-9]*\)"`
    changequote([, ])dnl
    if test "$PERL_MAJOR" -lt "$PERL_REQUEST_MAJOR" -o "$PERL_MINOR" -lt "$PERL_REQUEST_MINOR" -o "$PERL_SUBMINOR" -lt "$PERL_REQUEST_SUBMINOR" ; then
      AC_MSG_RESULT(no)
      AC_MSG_ERROR(perl version is $PERL_VERSION)
    else
      AC_MSG_RESULT(yes)
    fi
  fi
])



dnl @synopsis CHECK_CPAN_MODULE{VARIABLE, Module::Name [,Version [,PathToPerl]]}
dnl
dnl This macro searches the installed base of CPAN modules
dnl determine the the requested module is installed.
dnl
dnl The first argument is the name of a variable which is to
dnl contain a space-delimited list of missing modules.
dnl
dnl @version $Id: aclocal.m4,v 1.11.2.6 2002-02-01 17:51:31 markjaroski Exp $
dnl @author Mark Jaroski <mark@geekhive.net>
dnl
AC_DEFUN([CHECK_CPAN_MODULE],[
 AC_MSG_CHECKING(for CPAN module $2 $3)
 #
 # use perl itself to check for the module
 #
 if perl -e "use $2 $3" 2>/dev/null ;then
    AC_MSG_RESULT(yes)
 else
    AC_MSG_RESULT(no)
    if test -z "${$1}" ; then
        NEW_LIST="$2" ;
    else
        NEW_LIST="${$1} $2";
    fi
    AC_SUBST($1, $NEW_LIST)
 fi
])


dnl @synopsis AC_PROG_POSTGRES{VARIABLE, [version]}
dnl
dnl This macro searches for an installation of PostgreSQL
dnl
dnl After the test the variable name will hold the 
dnl path to PostgreSQL home
dnl
dnl @version $Id: aclocal.m4,v 1.11.2.6 2002-02-01 17:51:31 markjaroski Exp $
dnl @author Mark Jaroski <mark@geekhive.net>
dnl
AC_DEFUN([AC_PROG_POSTGRES],[
 #
 # If the user specifies a pg_config location things get
 # a bit easier, might as well ask for that first
 # 
 AC_ARG_WITH(pg_config,
  [
  --with-pg_config=PATH   absolute path name of the wonderful pg_config
                          script which can tell us so much about your 
                          postgres installation (default is to search 
                          for pg_config in: 
                            /usr/local/postgresql/bin:
                            /usr/local/bin:
                            /usr/local/sbin:
                            /usr/bin:
                            /usr/sbin)],
  [
    #
    # Run this if -with or specified
    #
    if test "$withval" != no ; then
       PG_CONFIG="$withval"
    fi
  ])
 #
 # Or we can just take the postgres home location
 # 
 AC_ARG_WITH(pghome,
  [
  --with-pghome=PATH      absolute path name of the postgres binary
                          (default is /usr/local/pgsql)],
  [
    #
    # Run this if -with or specified
    #
    if test "x$withval" != "x" ; then
       PGHOME="$withval"
    fi
  ])
 #
 # If pg_config not specified by caller, search in standard places
 #
 if test -z "$PG_CONFIG" ; then
   AC_PATH_PROG(PG_CONFIG, pg_config, , $PGHOME/bin:/usr/local/pgsql/bin:/opt/pgsql/bin:/usr/local/postgres/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin)
 fi
 AC_SUBST(PG_CONFIG)
 if test -z "$PG_CONFIG" ; then
     AC_MSG_ERROR("pg_config executable not found");
 fi
 #
 # If we don't have a pghome yet it from pg_config
 #
 if test -z "$PGHOME" ;then
   changequote(<<, >>)dnl
   PGHOME=`$PG_CONFIG --configure |sed -e 's/.*--prefix=\([^ ]*\).*/\1/'` ;
   changequote([, ])dnl
 fi
 #
 # Collect postgres version number. If for nothing else, this
 # guaranties that postgres is a working postgres executable.
 #
 changequote(<<, >>)dnl
 POSTGRES_VERSION=`$PG_CONFIG --version | grep 'PostgreSQL' | sed -e 's;.*PostgreSQL \([0-9\.][0-9\.]*\).*;\1;'`
 changequote([, ])dnl
 if test -z "$POSTGRES_VERSION" ; then
     AC_MSG_ERROR("could not determine postgres version number");
 fi
 changequote(<<, >>)dnl
 POSTGRES_MAJOR=`expr $POSTGRES_VERSION : '\([0-9]*\)'`
 POSTGRES_MINOR=`expr $POSTGRES_VERSION : "$POSTGRES_MAJOR.\([0-9]*\)"`
 POSTGRES_SUBMINOR=`expr $POSTGRES_VERSION : "$POSTGRES_MAJOR.$POSTGRES_MINOR.\([0-9]*\)"`
 changequote([, ])dnl
 #
 # Check that postgres version matches requested version or above
 #
 if test -n "$2" ; then
   AC_MSG_CHECKING(postgres version >= $2)
   changequote(<<, >>)dnl
   POSTGRES_REQUEST_MAJOR=`expr $2 : '\([0-9]*\)'`
   POSTGRES_REQUEST_MINOR=`expr $2 : "$POSTGRES_REQUEST_MAJOR.\([0-9]*\)"`
   POSTGRES_REQUEST_SUBMINOR=`expr $2 : "$POSTGRES_REQUEST_MAJOR.$POSTGRES_REQUEST_MINOR.\([0-9]*\)"`
   changequote([, ])dnl
   if test "$POSTGRES_MAJOR" -lt "$POSTGRES_REQUEST_MAJOR" -o "$POSTGRES_MINOR" -lt "$POSTGRES_REQUEST_MINOR" -o "$POSTGRES_SUBMINOR" -lt "$POSTGRES_REQUEST_SUBMINOR" ; then
     AC_MSG_RESULT(no)
     AC_MSG_ERROR(postgres version is $POSTGRES_VERSION)
   else
     AC_MSG_RESULT(yes)
   fi
 fi
 #
 # set user specified variable to our $PGHOME
 #
 AC_SUBST($1,$PGHOME) 
])

dnl @synopsis AC_POSTGRES_ENCODING(ENCODING[,PATH_TO_PGCONFIG])
dnl
dnl This macro checks to see that postgres has been 
dnl compiled to allow the desired encoding
dnl
dnl @version $Id: aclocal.m4,v 1.11.2.6 2002-02-01 17:51:31 markjaroski Exp $
dnl @author Mark Jaroski <mark@geekhive.net>
dnl
AC_DEFUN([AC_POSTGRES_ENCODING], [
	AC_MSG_CHECKING(if postgres was compiled with $1 support)
	if test "$2" ; then
		PG_CONFIG=$2
	elif test -z "$PG_CONFIG" ;then
  	AC_PATH_PROG(PG_CONFIG, pg_config, , $PGHOME/bin:/usr/local/pgsql/bin:/opt/pgsql/bin:/usr/local/postgres/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin)
	fi
	if $PG_CONFIG --configure | grep multibyte >/dev/null ;then
		AC_MSG_RESULT(yes)
	else
		AC_MSG_RESULT(no)
		AC_MSG_ERROR(Bricolage requires that Postgres be compiled with multibyte charager support)
	fi
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
  [
  --with-apache=PATH      absolute path name of apache server (default is 
                          to search httpd in:
                             /usr/local/apache/bin:
                             /usr/local/bin:
                             /usr/local/sbin:
                             /usr/bin:/usr/sbin),

  --without-apache        to disable apache detection],
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
      # original for non-Debian systems
      AC_PATH_PROG(APACHE, httpd, , /usr/local/apache/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin)
      # added for Debian compatibility
      AC_PATH_PROG(APACHE, apache-perl, , /usr/local/apache/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin)
      AC_PATH_PROG(APACHE, apache, , /usr/local/apache/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin)
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
AC_ARG_WITH(ssl,[
  --with-ssl              enable ssl [will check /usr/local/ssl
                            /usr/lib/ssl /usr/ssl /usr/pkg 
                            /usr/local /usr ]
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

dnl @synopsis AC_PROMPT_USER(VARIABLENAME,QUESTION,[DEFAULT])
dnl
dnl Asks a QUESTION and puts the results in VARIABLENAME with an optional
dnl DEFAULT value if the user merely hits return.  Also calls
dnl AC_DEFINE_UNQUOTED() on the VARIABLENAME for VARIABLENAMEs that should
dnl be entered into the config.h file as well.
dnl
dnl @version $Id: aclocal.m4,v 1.11.2.6 2002-02-01 17:51:31 markjaroski Exp $
dnl @author Wes Hardaker <wjhardaker@ucdavis.edu>
dnl
AC_DEFUN([AC_PROMPT_USER],
[
MSG_CHECK=`echo "$2" | tail -1`
AC_CACHE_CHECK($MSG_CHECK, ac_cv_user_prompt_$1,
[echo "" >&AC_FD_MSG
AC_PROMPT_USER_NO_DEFINE($1,[$2],$3)
eval ac_cv_user_prompt_$1=\$$1
echo $ac_n "setting $MSG_CHECK to...  $ac_c" >&AC_FD_MSG
])
if test "$ac_cv_user_prompt_$1" != "none"; then
  if test "$4" != ""; then
    AC_DEFINE_UNQUOTED($1,"$ac_cv_user_prompt_$1")
  else
    AC_DEFINE_UNQUOTED($1,$ac_cv_user_prompt_$1)
  fi
fi
]) dnl

dnl @synopsis CHECK_FOR_PGPASS
dnl
dnl when installing a PostgreSQL db we'll need to know if 
dnl there is a password, and if so what it is.
dnl
dnl @version $Id: aclocal.m4,v 1.11.2.6 2002-02-01 17:51:31 markjaroski Exp $
dnl @author Mark Jaroski <mark@geekhive.net>
dnl
AC_DEFUN([CHECK_FOR_PGPASS],[
  AC_MSG_CHECKING([whether we will wave the PG_ROOT_PASS requirement])
  AC_ARG_WITH(no-pgroot-pass,[
  --with-no-pgroot-pass   Use this flag to specify that you want 
                          the db installer to su $PG_SYSTEM_USER and
                          try to log into psql with no password.
                          (Some systems are set up this way for security)],[
      if test "$withval" = "yes" ;then
		PG_NO_PASS="true"
		AC_MSG_RESULT(yes)
	  else 
		PG_NO_PASS="false"
		AC_MSG_RESULT(no)
	  fi
	],[
	  PG_NO_PASS="false"
	  AC_MSG_RESULT(no)
	])

  if test "${PG_NO_PASS}" = "false" ;then
	AC_MSG_ERROR([

    You must define PG_ROOT_PASS

    -or- 

    use the switch --with-no-pgroot-pass
  ])
  fi
])

dnl @synopsis AC_VAR_WITH(VAR,with,default)
dnl
dnl when installing a PostgreSQL db we'll need to know if 
dnl
dnl @version $Id: aclocal.m4,v 1.11.2.6 2002-02-01 17:51:31 markjaroski Exp $
dnl @author Mark Jaroski <mark@geekhive.net>
dnl
AC_DEFUN([AC_VAR_WITH],[
AC_ARG_WITH($2,AC_HELP_STRING([
  --with-$2],[defaults to $3]),
  $1=${withval},
  $1=$3)
AC_SUBST($1)

])

dnl @synopsis AC_CHECK_SYS_USER(VAR,username)
dnl
dnl Check to see if a user exists.  VAR will be set
dnl to "yes" on success, "no" on failure.
dnl
dnl @version $Id: aclocal.m4,v 1.11.2.6 2002-02-01 17:51:31 markjaroski Exp $
dnl @author Mark Jaroski <mark@geekhive.net>
dnl
AC_DEFUN([AC_CHECK_SYS_USER],[
	AC_MSG_CHECKING(for user "$2")
	if finger $2 >/dev/null ; then
		$1='yes'
		AC_MSG_RESULT(yes)
	else
		$1='no'
    AC_MSG_RESULT(no)
	fi
])


dnl @synopsis AC_CHECK_SYS_GROUP(VAR,group)
dnl
dnl Check to see if a group exists.  VAR will be set
dnl to "yes" on success, "no" on failure.
dnl
dnl @version $Id: aclocal.m4,v 1.11.2.6 2002-02-01 17:51:31 markjaroski Exp $
dnl @author Mark Jaroski <mark@geekhive.net>
dnl
AC_DEFUN([AC_CHECK_SYS_GROUP],[
	AC_MSG_CHECKING(for group "$2")
	touch /tmp/ac_group_test
	if chgrp $2 /tmp/ac_group_test 2>&1 >/dev/null ; then
		$1='yes'
		AC_MSG_RESULT(yes)
	elif chgrp $2 /tmp/ac_group_test 2>&1 | grep 'invalid' >/dev/null 
		$1='no'
    	AC_MSG_RESULT(no)
	else
		$1='yes'
		AC_MSG_RESULT(yes)
	fi
])

dnl @synopsis AC_POD2HTML(VAR)
dnl
dnl Try to figure out which pod2html we're working with
dnl the variable will be set to Christiansen, McDougall, 
dnl or none, depending on which pod2html is found.
dnl
dnl @version $Id: aclocal.m4,v 1.11.2.6 2002-02-01 17:51:31 markjaroski Exp $
dnl @author Mark Jaroski <mark@geekhive.net>
dnl
AC_DEFUN([AC_POD2HTML],[
	AC_MSG_CHECKING(which pod2html we have)
	if pod2html --help | grep '--libpods' ; then
		$1='Christiansen'
	elif pod2html --help | grep 'Unknown option: help' 
		$1='McDougall'
	else 
		$1='none'
	fi
	AC_SUBST($1)
])




