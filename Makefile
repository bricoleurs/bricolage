#
# Bricolage Makefile
#
# Supports the following targets:
#
#   all       - default target checks requirements and builds source
#   install   - installs the bricolage system
#   clean     - delete intermediate files
#   dist      - prepare a distrubution from a CVS checkout
#
# See INSTALL for details.
#

SQL_FILES := $(shell find lib -name '*.sql' -o -name '*.val' -o -name '*.con')

#########################
# build rules           #
#########################

all 		: required.db modules.db apache.db postgres.db config.db \
                  build_done

required.db	: inst/required.pl
	perl inst/required.pl

modules.db 	:  inst/modules.pl lib/Bric/Admin.pod
	perl inst/modules.pl

apache.db	: inst/apache.pl required.db
	perl inst/apache.pl

postgres.db 	:  inst/postgres.pl required.db
	perl inst/postgres.pl

config.db	: inst/config.pl required.db apache.db postgres.db
	perl inst/config.pl

build_done	: required.db modules.db apache.db postgres.db config.db
	@echo
	@echo ===========================================================
	@echo ===========================================================
	@echo 
	@echo Bricolage Build Complete.  You may now proceed to
	@echo \"make install\" which must be run as root.
	@echo 
	@echo ===========================================================
	@echo ===========================================================
	@echo
	touch build_done


###########################
# dist rules              #
###########################

dist            : clean inst/bricolage.sql dist_dir rm_sql rm_use rm_CVS \
                  INSTALL Changes License dist_tar

dist_dir	:
	-rm -rf dist
	mkdir dist
	ls | grep -v dist | xargs cp -a --target-directory=dist

rm_sql		:
	find dist/lib/ -name '*.sql' -o -name '*.val' -o -name '*.con' \
        | xargs rm -rf

rm_pl           :
	find dist/lib/ -name '*.pl'    | xargs rm -rf

rm_use          :
	find dist/lib/ -name '*.use'   | xargs rm -rf

rm_CVS		:
	find dist/ -type d -name 'CVS' | xargs rm -rf
	find dist/ -name '.cvsignore'  | xargs rm -rf

rm_empty	:
	find dist/ -type d 

dist/INSTALL		: lib/Bric/Admin.pod
	pod2text --loose lib/Bric/Admin.pod   > dist/INSTALL

dist/Changes		: lib/Bric/Changes.pod
	pod2text --loose lib/Bric/Changes.pod > dist/Changes

dist/License		: lib/Bric/License.pod
	pod2text --loose lib/Bric/License.pod > dist/License

BRIC_VERSION := $(shell perl -Ilib -MBric -e 'print $$Bric::VERSION')

dist_tar		:
	-rm -rf bricolage-$(BRIC_VERSION)
	mv dist bricolage-$(BRIC_VERSION)
	tar cvf bricolage-$(BRIC_VERSION).tar bricolage-$(BRIC_VERSION)
	gzip --best bricolage-$(BRIC_VERSION).tar


##########################
# installation rules     #
##########################
install 	: all cpan lib bin files db conf done

cpan 		: modules.db config.db inst/cpan.pl
	perl inst/cpan.pl

lib 	: 
	-rm -f lib/Makefile
	cd lib; perl Makefile.PL; $(MAKE) install

bin 	:
	-rm -f bin/Makefile
	cd bin; perl Makefile.PL; $(MAKE) install

files 		: config.db
	perl inst/files.pl

db    		: inst/db.pl postgres.db inst/bricolage.sql
	perl inst/db.pl

inst/bricolage.sql : $(SQL_FILES)	
	find lib/ -name '*.sql' -exec cat '{}' ';' >  inst/bricolage.sql
	find lib/ -name '*.val' -exec cat '{}' ';' >> inst/bricolage.sql
	find lib/ -name '*.con' -exec cat '{}' ';' >> inst/bricolage.sql

conf		: inst/conf.pl files required.db config.db postgres.db \
                  apache.db
	perl inst/conf.pl

done		: 
	perl inst/done.pl

# remove working files
clean : 
	-rm -rf *.db
	-rm -rf build_done
	cd lib ; perl Makefile.PL ; $(MAKE) clean
	-rm -rf lib/Makefile.old
	cd bin ; perl Makefile.PL ; $(MAKE) clean
	-rm -rf bin/Makefile.old

# list of all phony targets
.PHONY 		: all install lib bin clean uninstall dist db conf done \
                  cpan files
