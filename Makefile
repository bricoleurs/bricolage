
# Programatic dependancies
PERL = /usr/bin/perl
APACHE = /usr/sbin/apache-perl
POSTGRESHOME = /usr/lib/postgresql

# Standard
MAKE = @MAKE@
RM = @RM@

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
