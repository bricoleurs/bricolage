
# Programatic dependancies
PERL = /usr/bin/perl
APACHE = /usr/sbin/apache-perl
POSTGRESHOME = /usr/lib/postgresql


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



all: dep

install:

dep: cpan

cpan:
	${INSTALL_MISSING}
	echo "Installed: ${MISSING_MODULES}" >$@

clean:


.PHONY : clean dep clean
