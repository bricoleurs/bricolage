
# Process this file with autoconf to produce a configure script.
AC_INIT(Bricolage, 1.1.2, bugs@bricolage.sourceforge.net)
AC_PREFIX_DEFAULT(/usr/local/bricolage)

# Checks for programs
AC_PROG_APACHE(1.3.20)
AC_PROG_POSTGRES(PGHOME, 7.1.3)
AC_POSTGRES_ENCODING(UNICODE)
AC_PROG_PERL(PERL, 5.6.1)
AC_PATH_PROG(POD2HTML, pod2html)
AC_PATH_PROG(POD2TEXT, pod2text)
AC_PATH_PROG(POD2MAN, pod2man)
AC_PATH_PROG(GZIP, gzip)
AC_PATH_PROG(MKDIR, mkdir)
AC_PATH_PROG(FIND, find)
AC_PATH_PROG(CTAGS, ctags)

# Checks for libraries.
CHECK_SSL

# Checks for CPAN modules
# TODO: make sure CPAN works
CHECK_CPAN_MODULE(MISSING_MOD, Time::HiRes, 01.20)
CHECK_CPAN_MODULE(MISSING_MOD, Storable, 1.0.10)
CHECK_CPAN_MODULE(MISSING_MOD, Unix::Syslog, 0.95)
CHECK_CPAN_MODULE(MISSING_MOD, Data::Dumper, 1.0703)
CHECK_CPAN_MODULE(MISSING_MOD, Net::Cmd, 1.0703)
CHECK_CPAN_MODULE(MISSING_MOD, Devel::Symdump, 2.01)
CHECK_CPAN_MODULE(MISSING_MOD, DBI, 1.19)
CHECK_CPAN_MODULE(MISSING_MOD, Cache::Cache, 0.09)
CHECK_CPAN_MODULE(MISSING_MOD, Digest::MD5, 2.12)
CHECK_CPAN_MODULE(MISSING_MOD, MD5, 2.02)
CHECK_CPAN_MODULE(MISSING_MOD, URI, 1.12)
CHECK_CPAN_MODULE(MISSING_MOD, HTML::Tagset, 3.03)
CHECK_CPAN_MODULE(MISSING_MOD, HTML::Parser, 3.23)
CHECK_CPAN_MODULE(MISSING_MOD, MIME::Base64, 2.12)
CHECK_CPAN_MODULE(MISSING_MOD, XML::Writer, 0.4)
CHECK_CPAN_MODULE(MISSING_MOD, LWP, 5.50)
CHECK_CPAN_MODULE(MISSING_MOD, Image::Info, 1.07)
CHECK_CPAN_MODULE(MISSING_MOD, Text::Iconv, 1.1)
CHECK_CPAN_MODULE(MISSING_MOD, MLDBM, 2.00)
CHECK_CPAN_MODULE(MISSING_MOD, Params::Validate, 0.04)
CHECK_CPAN_MODULE(MISSING_MOD, HTML::Mason, 1.03)
CHECK_CPAN_MODULE(MISSING_MOD, DBD::Pg, 1.00)
CHECK_CPAN_MODULE(MISSING_MOD, Apache::Session, 1.53)
CHECK_CPAN_MODULE(MISSING_MOD, Apache::libapreq, 0.31_03)

# Accept configuration details on the command line
AC_ARG_VAR_DEFAULT(APACHE_USER, nobody)
AC_ARG_VAR_DEFAULT(APACHE_GROUP, nogroup)
AC_ARG_VAR_DEFAULT(DB_NAME, www-data)
AC_ARG_VAR_DEFAULT(DBI_USER, nobody)
AC_ARG_VAR_DEFAULT(DBI_PASS, c@st3l!@n)
AC_ARG_VAR_DEFAULT(POSTGRES_ROOT_USER, postgres)
AC_ARG_VAR_DEFAULT(PG_SYSTEM_USER, postgres)
AC_ARG_VAR(PG_ROOT_PASS)


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
  AC_MSG_ERROR([You must define PG_ROOT_PASS
    -or- use the flag --with-no-pgroot-pass
])
fi


# write out the makefiles
AC_CONFIG_FILES([Makefile doc/Makefile install/bric.sql])
AC_OUTPUT
