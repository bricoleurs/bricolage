
# Programatic dependancies
PERL = /usr/bin/perl
APACHE = /usr/sbin/apache-perl
POSTGRESHOME = /usr/lib/postgresql

# Standard
MAKE = @MAKE@
RM = @RM@

# A list of any missing modules
MISSING_MODULES = 

all: dep

install:

dep: cpan

cpan:
ifdef ${MISSING_MODULES}
	for M in ${MISSING_MODULES} ;do \
		${PERL} -MCPAN -e "install $$M"	;\
	done
	echo "Installed: ${MISSING_MODULES}" >$@
else
	echo "No new modules installed" >$@
endif

clean:


.PHONY : clean dep clean
