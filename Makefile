#
# Bricolage Makefile
#
# Supports the following targets:
#
#   all       - default target checks requirements and builds source
#   install   - installs the bricolage system
#   upgrade   - upgrades an existing installation
#   clean     - delete intermediate files
#   dist      - prepare a distrubution from a CVS checkout
#   clone     - create a distribution based on an existing system
#   test      - run non-database changing test suite
#   devtest   - run all tests, including those that change the database
#
# See INSTALL for details.
#

# Set the location of Perl.
PERL = /usr/bin/perl

#########################
# build rules           #
#########################

all 		: required.db modules.db apache.db postgres.db config.db \
                  build_done

required.db	: inst/required.pl
	$(PERL) inst/required.pl

modules.db 	: inst/modules.pl lib/Bric/Admin.pod
	$(PERL) inst/modules.pl

apache.db	: inst/apache.pl required.db
	$(PERL) inst/apache.pl

postgres.db 	: inst/postgres.pl required.db
	$(PERL) inst/postgres.pl

config.db	: inst/config.pl required.db apache.db postgres.db
	$(PERL) inst/config.pl

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
	@touch build_done

.PHONY 		: all


###########################
# dist rules              #
###########################

dist            : check_dist distclean inst/bricolage.sql dist_dir rm_sql \
                  rm_tst rm_use rm_CVS rm_tmp dist/INSTALL dist/Changes \
                  dist/License dist_tar

# can't load Bric since it loads Bric::Config which has dependencies
# that won't be solved till make install.
BRIC_VERSION = `$(PERL) -ne '/VERSION.*?([\d\.]+)/ and print $$1 and exit' < lib/Bric.pm`

check_dist      :
	$(PERL) inst/check_dist.pl $(BRIC_VERSION)

distclean	: clean
	-rm -rf bricolage-$(BRIC_VERSION)
	-rm -f  bricolage-$(BRIC_VERSION).tar.gz
	-rm -rf dist

dist_dir	:
	-rm -rf dist
	mkdir dist
	ls | grep -v dist | $(PERL) -lne 'system("cp -pR $$_ dist")'

rm_sql		:
	find dist/lib/ -name '*.sql' -o -name '*.val' -o -name '*.con' \
        | xargs rm -rf

rm_use          :
	find dist/lib/ -name '*.use'   | xargs rm -rf

rm_tst          :
	find dist/lib/ -name '*.tst'   | xargs rm -rf

rm_CVS		:
	find dist/ -type d -name 'CVS' | xargs rm -rf
	find dist/ -name '.cvsignore'  | xargs rm -rf

rm_tmp		:
	find dist/ -name '#*#' -o -name '*~' | xargs rm -rf

dist/INSTALL	: lib/Bric/Admin.pod
	pod2text lib/Bric/Admin.pod   > dist/INSTALL

dist/Changes	: lib/Bric/Changes.pod
	pod2text lib/Bric/Changes.pod > dist/Changes

dist/License	: lib/Bric/License.pod
	pod2text lib/Bric/License.pod > dist/License

dist_tar	:
	mv dist bricolage-$(BRIC_VERSION)
	tar cvf bricolage-$(BRIC_VERSION).tar bricolage-$(BRIC_VERSION)
	gzip --best bricolage-$(BRIC_VERSION).tar

SQL_FILES := $(shell find lib -name '*.sql' -o -name '*.val' -o -name '*.con')

inst/bricolage.sql : $(SQL_FILES)
	find lib -name '*.sql' -exec grep -v '^--' '{}' ';' >  inst/bricolage.sql
	find lib -name '*.val' -exec grep -v '^--' '{}' ';' >> inst/bricolage.sql
	find lib -name '*.con' -exec grep -v '^--' '{}' ';' >> inst/bricolage.sql

.PHONY 		: distclean inst/bricolage.sql dist_dir rm_sql rm_use rm_CVS \
                  dist_tar check_dist

##########################
# clone rules            #
##########################

clone           : distclean clone.db clone_dist_dir clone_files clone_sql \
		  rm_sql rm_use rm_CVS rm_tmp \
                  dist/INSTALL dist/Changes dist/License \
		  clone_tar 

clone.db	:
	$(PERL) inst/clone.pl

clone_dist_dir  : 
	-rm -rf dist
	mkdir dist

clone_files     :
	$(PERL) inst/clone_files.pl

clone_sql       : 
	$(PERL) inst/clone_sql.pl

clone_tar	:
	$(PERL) inst/clone_tar.pl

.PHONY 		: clone_dist_dir clone_files clone_sql clone_tar

##########################
# installation rules     #
##########################

install 	: all cpan lib bin files db conf done

cpan 		: modules.db postgres.db inst/cpan.pl
	$(PERL) inst/cpan.pl

lib 		: 
	-rm -f lib/Makefile
	cd lib; $(PERL) Makefile.PL; $(MAKE) install

bin 		:
	-rm -f bin/Makefile
	cd bin; $(PERL) Makefile.PL; $(MAKE) install

files 		: config.db
	$(PERL) inst/files.pl

db    		: inst/db.pl postgres.db
	$(PERL) inst/db.pl

conf		: inst/conf.pl files required.db config.db postgres.db \
                  apache.db
	$(PERL) inst/conf.pl

done		: conf db files bin lib cpan
	$(PERL) inst/done.pl

.PHONY 		: install lib bin files db conf done


##########################
# upgrade rules          #
##########################

upgrade		: upgrade.db required.db cpan stop lib bin db_upgrade \
	          upgrade_files upgrade_conf upgrade_done

upgrade.db	:
	$(PERL) inst/upgrade.pl

db_upgrade	: upgrade.db
	$(PERL) inst/db_upgrade.pl

stop		:
	$(PERL) inst/stop.pl

upgrade_files   :
	$(PERL) inst/files.pl UPGRADE

upgrade_conf    :
	$(PERL) inst/conf.pl UPGRADE

upgrade_done    :
	@echo
	@echo ===========================================================
	@echo ===========================================================
	@echo 
	@echo Bricolage Upgrade Complete.  You may now start your
	@echo servers to start using the new version of Bricolage.
	@echo 
	@echo ===========================================================
	@echo ===========================================================
	@echo

.PHONY		: db_upgrade upgrade_files stop upgrade_done

##########################
# test rules             #
##########################
TEST_VERBOSE=0

test		:
	PERL_DL_NONLAZY=1 $(PERL) inst/runtests.pl

devtest         :
	PERL_DL_NONLAZY=1 $(PERL) inst/runtests.pl -d

##########################
# clean rules            #
##########################

clean 		: 
	-rm -rf *.db
	-rm -rf build_done
	cd lib ; $(PERL) Makefile.PL ; $(MAKE) clean
	-rm -rf lib/Makefile.old
	cd bin ; $(PERL) Makefile.PL ; $(MAKE) clean
	-rm -rf bin/Makefile.old

.PHONY 		: clean
