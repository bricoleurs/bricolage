
# Programatic dependancies
PERL = /usr/bin/perl
APACHE = /usr/sbin/apache-perl
POSTGRESHOME = /usr/lib/postgresql
POD2HTML = /usr/bin/pod2html
POD2TEXT = /usr/bin/pod2text
POD2MAN = /usr/bin/pod2man



# Installation related variables
BINDIR  = ${exec_prefix}/bin
DATADIR  = ${prefix}/share
EXEC_PREFIX  = ${prefix}
INCLUDEDIR  = ${prefix}/include
INFODIR  = ${prefix}/info
LIBDIR  = ${exec_prefix}/lib
LIBEXECDIR  = ${exec_prefix}/libexec
LOCALSTATEDIR  = ${prefix}/var
MANDIR  = ${prefix}/man
OLDINCLUDEDIR  = /usr/include
PREFIX  = /usr/local
SBINDIR  = ${exec_prefix}/sbin
SHAREDSTATEDIR  = ${prefix}/com
SYSCONFDIR  = ${prefix}/etc



# Bricolage configuration info
APACHE_USER = 
APACHE_GROUP = 

# A list of any missing modules
MISSING_MODULES = 
MODULE_COMMAND = $(foreach mod,${MISSING_MODULES},${PERL} -MCPAN -e "install ${mod}" ;)



all: dep README INSTALL TODO License

install:

dep: cpan

cpan:
	${INSTALL_MISSING}
	echo Installed ${MISSING_MODULES} >>install.log

INSTALL:
	${POD2TEXT} lib/Bric/Admin.pod >$@

TODO:
	${POD2TEXT} lib/Bric/ToDo.pod >$@

README:
	${POD2TEXT} lib/Bric/Changes.pod >$@

License:
	${POD2TEXT} lib/Bric/License.pod >$@


clean:
	${RM} -f README INSTALL TODO License



.PHONY : clean dep clean cpan
