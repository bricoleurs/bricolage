# settings
SHELL = /bin/sh

# Programatic dependancies
PERL = /usr/local/bin/perl
APACHE = /usr/local/apache/bin/httpd
POSTGRESHOME = --enable-multibyte=UNICODE
POD2HTML = /usr/local/bin/pod2html
POD2TEXT = /usr/local/bin/pod2text
POD2MAN = /usr/local/bin/pod2man
GZIP = /bin/gzip
MKDIR = /bin/mkdir
FIND = /usr/bin/find
CTAGS = /usr/bin/ctags

# directories
BIN = bin
COMP = comp
CONF = conf
DATA = data
LIB = lib
DOC = doc
INST = install

# Installation related variables
NORMAL_INSTALL = :
PRE_INSTALL = :
POST_INSTALL = :
NORMAL_UNINSTALL = :
PRE_UNINSTALL = :
POST_UNINSTALL = :
prefix  = /usr/local/bricolage
exec_prefix  = ${prefix}
bindir  = ${exec_prefix}/bin
datadir  = ${prefix}/share
sysconfdir  = ${prefix}/etc
libdir  = ${exec_prefix}/lib
libexecdir  = ${exec_prefix}/libexec
includedir  = ${prefix}/include
oldincludedir  = /usr/include
mandir  = ${prefix}/man
infodir  = ${prefix}/info
sbindir  = ${exec_prefix}/sbin
localstatedir  = ${prefix}/var
sharedstatedir  = ${prefix}/com


# Bricolage configuration info
APACHE_USER = 
APACHE_GROUP = 

# A list of any missing modules
<<<<<<< Makefile
MISSING_MODULES = XML::Writer
=======
MISSING_MODULES = Devel::Symdump Apache::libapreq
>>>>>>> 1.12
MODULE_COMMAND = $(foreach mod,${MISSING_MODULES},${PERL} -MCPAN -e "install ${mod}" ;)



all:  doc

install: dep installdirs install-bin install-comp \
		 install-conf install-data install-lib install-doc \
		 install-man install-html
installdirs:
	${INST}/mkinstalldirs 	${prefix} ${exec_prefix} \
							${bindir} ${datadir} \
							${sysconfdir} ${libdir} \
							${libexecdir} ${includedir} \
							${oldincludedir} ${mandir} \
							${infodir} ${sbindir} \
							${localstatedir} ${sharedstatedir} \
							${compdir} ${docdir} \
							${htmldir} ${mandir}
install-bin:
	cp -r ${BIN}/* ${bindir}/	
	chmod -R a+x ${bindir}/*
install-comp:
	cp -r ${COMP}/* ${comp}/
	chmod -R a+r ${comp}
ifdef APACHE_USER
	chown -R ${APACHE_USER} ${localstatedir}
endif
ifdef APACHE_GROUP
	chgrp -R ${APACHE_GROUP} ${localstatedir}
endif
install-conf:
	cp -r ${CONF}/* ${sysconfdir}/
ifdef APACHE_USER
	chown -R ${APACHE_USER} ${sysconfdir}
endif
install-data:
	cp -r ${DATA}/* ${data}/
	chmod -R a+r ${data}
ifdef APACHE_USER
	chown -R ${APACHE_USER} ${data}
endif
ifdef APACHE_GROUP
	chgrp -R ${APACHE_GROUP} ${data}
endif
install-lib:
	cp -r ${LIB} ${libdir}
install-doc: install-man install-html
install-man:
	cp -r ${DOC}/man/* ${mandir}
install-html:
	cp -r ${DOC}/html/* ${htmldir}



dep: cpan

cpan:
	${INSTALL_MISSING}
	echo Installed ${MISSING_MODULES} >>install.log



doc: README INSTALL TODO License
	cd ${DOC} && ${MAKE} -e

INSTALL:
	${POD2TEXT} lib/Bric/Admin.pod >$@

TODO:
	${POD2TEXT} lib/Bric/ToDo.pod >$@

README:
	${POD2TEXT} lib/Bric/Changes.pod >$@

License:
	${POD2TEXT} lib/Bric/License.pod >$@



# TODO: Make this recursively generate tags files in all directories
tags:
ifdef CTAGS
	${CTAGS} -R
endif



clean: docclean
	${RM} -f README INSTALL TODO License tags


docclean:
	cd $(DOC) && ${MAKE} -e clean


.PHONY : clean dep clean cpan doc install installdirs \
		 install-bin install-comp install-conf install-data \
		 install-lib install-doc install-html install-man
