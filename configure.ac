# assuming we have perl we can get the version number
# if not, we know right off that something wrong
VERSION=`perl -MBric -e 'print $Bric::VERSION'`

# Process this file with autoconf to produce a configure script.
AC_INIT(Bricolage,${VERSION}, http://bricolage-bugzilla.thepirtgroup.com)
AC_PREFIX_DEFAULT(/usr/local/bricolage)
# Installation directory overrides
# bricolage has historically used a slightly
# different directory scheme from the GNU standard
# we'll roll with it
# Use braces instead of parens because sh, perl, etc. also accept them.
datadir='${prefix}/data'
sysconfdir='${prefix}/conf'

# Additional --with-switches
# SYNTAX: AC_VAR_WITH(VARNAME,switchname,default)
AC_VAR_WITH(compdir,compdir,'${prefix}/comp')
AC_VAR_WITH(htmldir,htmldir,'${prefix}/doc/html')
AC_VAR_WITH(blibdir,blibdir,'${prefix}/blib')
AC_VAR_WITH(APACHE_USER,apache-user,nobody)
AC_VAR_WITH(APACHE_GROUP,apache-group,nobody)
AC_VAR_WITH(HOSTNAME,hostname,`hostname --fqdn || true`)
AC_VAR_WITH(ADMINISTRATOR,administrator,root)
AC_VAR_WITH(DB_NAME,db-name,wwwdata)
AC_VAR_WITH(DBI_USER,dbi-user,nobody)
AC_VAR_WITH(DBI_PASS,dbi-pass,c@st3l!@n)
AC_VAR_WITH(POSTGRES_ROOT_USER,pgroot-user,postgres)
AC_VAR_WITH(POSTGRES_SYSTEM_USER,pgsystem-user,postgres)
# TODO: System defaults for these can be determined from $APACHE -V
AC_VAR_WITH(SERVER_ROOT,server_root,/usr/local/apache)
AC_VAR_WITH(APACHE_CONF,apache-conf,'${prefix}/conf')
AC_VAR_WITH(LOGDIR,lod_dir,${SERVER_ROOT}/logs)
AC_VAR_WITH(ERROR_LOG,error_log,${LOGDIR}/error.log)
AC_VAR_WITH(ACCESS_LOG,access_log,${LOGDIR}/access.log)
AC_VAR_WITH(SSL_LOG,ssl_log,${LOGDIR}/ssl_engine_log)
AC_VAR_WITH(PID_FILE,pid_file,${LOGDIR}/httpd.pid)

AC_CHECK_SYS_USER(ISUSERHERE,${APACHE_USER})
if test "$ISUSERHERE" = "no" ;then
	AC_MSG_ERROR([

  There is no such user "${APACHE_USER}" in the system
  database.  Please add this user or run 
  	
  	./configure --with-apache-user=USER

  Where the user exists.

])
fi

AC_CHECK_SYS_GROUP(ISGROUPHERE,${APACHE_GROUP})
if test "$ISGROUPHERE" = "no" ;then
	AC_MSG_ERROR([

  There is no such group "${APACHE_GROUP}" in the system
  database.  Please add this group or run 
  	
  	./configure --with-apache-group=GROUP

  Where the group exists.

])
fi

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
AC_CACHE_SAVE


# Checks for libraries.
CHECK_SSL
SSL_COMMENT=
if test "${HAVE_SSL}" != "yes" ;then
	SSL_COMMENT='# '
fi
AC_SUBST(SSL_COMMENT)
AC_CACHE_SAVE

# Checks for CPAN modules
# TODO: make sure CPAN itself works
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
AC_CACHE_SAVE

# Accept configuration details by environmental variable
# on the command line or otherwise
AC_ARG_VAR(PG_ROOT_PASS)
AC_CACHE_SAVE
CHECK_FOR_PGPASS

# predefined
AC_SUBST(VERSION)

# write out the makefiles
# TODO: The files here that aren't makefiles should eventually
# 		be handled by make, this is cheating in a way
AC_CONFIG_FILES([Makefile doc/Makefile install/bric.sql conf/bricolage.tmp.conf])
AC_OUTPUT
