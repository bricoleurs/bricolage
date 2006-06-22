#
# Bricolage Makefile
#
# Supports the following targets:
#
#   all       - default target checks requirements and builds source
#   install   - installs the bricolage system
#   upgrade   - upgrades an existing installation
#   uninstall - uninstalls an existing installation
#   clean     - delete intermediate files
#   dist      - prepare a distrubution from a Subversion checkout
#   clone     - create a distribution based on an existing system
#   devclone  - As clone above, only no pre-previewed / compiled files
#   test      - run non-database changing test suite
#   devtest   - run all tests, including those that change the database
#   dev       - installs directly from a Subversion checkout (for development)
#
# See INSTALL for details.
#

# Set the location of Perl.
PERL = /usr/bin/perl

# Blank by default, but set to QUIET to ask essential questions only
INSTALL_VERBOSITY?= STANDARD

# can't load Bric since it loads Bric::Config which has dependencies
# that won't be solved till make install.
BRIC_VERSION = `$(PERL) -ne '/VERSION.*?([\d\.]+)/ and print $$1 and exit' < lib/Bric.pm`

#########################
# build rules           #
#########################

all 		: required.db modules.db apache.db database.db config.db \
                  bconf/bricolage.conf build_done

required.db	: inst/required.pl
	$(PERL) inst/required.pl $(INSTALL_VERBOSITY)

modules.db 	: inst/modules.pl lib/Bric/Admin.pod
	$(PERL) inst/modules.pl $(INSTALL_VERBOSITY)

apache.db	: inst/apache.pl required.db
	$(PERL) inst/apache.pl $(INSTALL_VERBOSITY)

# This should be updated to something more database-independent. In fact,
# what should happen is that a script should present a list of supported
# databases, the user picks which one (each with a key name for the DBD
# driver, e.g., "Pg", "mysql", "Oracle", etc.), and then the rest of the
# work should just assume that database and do the work for that database.
DATABASE_PROBES := $(shell find inst -name 'dbprobe_*.pl')

database.db 	: inst/database.pl  required.db $(DATABASE_PROBES)
	$(PERL) inst/database.pl $(INSTALL_VERBOSITY) $(DATABASE_PROBES)

config.db	: inst/config.pl required.db apache.db database.db
	$(PERL) inst/config.pl $(INSTALL_VERBOSITY)

bconf/bricolage.conf	:  required.db inst/conf.pl
	$(PERL) inst/conf.pl INSTALL $(BRIC_VERSION)

build_done	: required.db modules.db apache.db database.db config.db \
                  bconf/bricolage.conf
	@echo
	@echo ===========================================================
	@echo ===========================================================
	@echo 
	@echo Bricolage Build Complete. You may now proceed to
	@echo \"make cpan\", which must be run as root, to install any
	@echo needed Perl modules\; then to
	@echo \"make test\" to run some basic tests of the API\; then to
	@echo \"make install\", which must be run as root.
	@echo 
	@echo ===========================================================
	@echo ===========================================================
	@echo
	@touch build_done

.PHONY 		: all


###########################
# dist rules              #
###########################

dist            : check_dist distclean inst/Pg.sql inst/mysql.sql dist_dir \
                  rm_svn rm_tmp dist/INSTALL dist/Changes \
                  dist/License dist_tar

check_dist      :
	$(PERL) inst/check_dist.pl $(BRIC_VERSION)

distclean	: clean
	-rm -rf bricolage-$(BRIC_VERSION)
	-rm -f  bricolage-$(BRIC_VERSION).tar.gz
	-rm -f inst/*.sql
	-rm -rf dist

dist_dir	:
	-rm -rf dist
	mkdir dist
	ls | grep -v dist | grep -v sql | $(PERL) -lne 'system("cp -pR $$_ dist")'

rm_svn		:
	find dist/ -type d -name '.svn' | xargs rm -rf

rm_tmp		:
	find dist/ -name '#*#' -o -name '*~' -o -name '.#*' | xargs rm -rf

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

# Update this later to be database-independent.
inst/Pg.sql : $(SQL_FILES)
	grep -vh '^--' `find sql/Pg -name '*.sql' | env LANG= LANGUAGE= LC_ALL=POSIX sort` >  $@;
	grep -vh '^--' `find sql/Pg -name '*.val' | env LANG= LANGUAGE= LC_ALL=POSIX sort` >>  $@;
	grep -vh '^--' `find sql/Pg -name '*.con' | env LANG= LANGUAGE= LC_ALL=POSIX sort` >>  $@;

inst/mysql.sql : $(SQL_FILES)
	grep -vh '^--' `find sql/mysql -name '*.sql' | env LANG= LANGUAGE= LC_ALL=POSIX sort` >  $@;
	grep -vh '^--' `find sql/mysql -name '*.val' | env LANG= LANGUAGE= LC_ALL=POSIX sort` >>  $@;
	grep -vh '^--' `find sql/mysql -name '*.con' | env LANG= LANGUAGE= LC_ALL=POSIX sort` >>  $@;

.PHONY 		: distclean inst/Pg.sql inst/mysql.sql dist_dir rm_svn dist_tar check_dist

##########################
# clone rules            #
##########################


clone           : distclean clone.db clone_dist_dir clone_sql clone_files \
		  rm_svn rm_tmp \
                  dist/INSTALL dist/Changes dist/License \
		  clone_tar 
devclone  : distclean clone.db clone_dist_dir clone_sql clone_files \
    rm_svn rm_tmp \
    dist/INSTALL dist/Changes dist/License \
    clone_lightweight \
    clone_tar 

clone.db	:
	$(PERL) inst/clone.pl

clone_dist_dir  : 
	-rm -rf dist
	mkdir dist

clone_files     :
	$(PERL) inst/clone_files.pl

clone_lightweight     :
	$(PERL) inst/clone_lightweight.pl

CLONE_SQL_FILES := $(shell find inst -name 'clone_sql_*.pl')

clone_sql       : $(CLONE_SQL_FILES)
	$(PERL) inst/clone_sql.pl

clone_tar	:
	$(PERL) inst/clone_tar.pl

.PHONY 		: clone_dist_dir clone_files clone_sql clone_tar

##########################
# installation rules     #
##########################

install 	: install_files install_db done

install_files	: all is_root cpan lib bin files

install_db	: db db_grant

is_root         : inst/is_root.pl
	$(PERL) inst/is_root.pl

cpan 		: modules.db database.db inst/cpan.pl
	$(PERL) inst/cpan.pl

lib 		: 
	-rm -f lib/Makefile
	cd lib; $(PERL) Makefile.PL; $(MAKE) install

bin 		:
	-rm -f bin/Makefile
	cd bin; $(PERL) Makefile.PL; $(MAKE) install

files 		: config.db bconf/bricolage.conf
	$(PERL) inst/files.pl

DBLOAD_FILES := $(shell find inst -name 'dbload_*.sql')

db    		: inst/db.pl database.db $(DBLOAD_FILES)
	$(PERL) inst/db.pl

db_grant	: inst/db.pl database.db
	$(PERL) inst/db_grant.pl

done		: bconf/bricolage.conf db files bin lib cpan
	$(PERL) inst/done.pl

.PHONY 		: install is_root lib bin files db done



##########################
# upgrade rules          #
##########################

upgrade		: upgrade.db required.db database.db bconf/bricolage.conf \
	          is_root cpan stop db_upgrade lib bin  \
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

	$(PERL) inst/conf.pl UPGRADE $(BRIC_VERSION)

upgrade_done    :
	@echo
	@echo ===========================================================
	@echo ===========================================================
	@echo 
	@echo Bricolage Upgrade Complete. You may now start your
	@echo server and start using the new version of Bricolage.
	@echo 
	@echo ===========================================================
	@echo ===========================================================
	@echo

.PHONY		: db_upgrade upgrade_files stop upgrade_done

##########################
# uninstall rules        #
##########################

uninstall 	: is_root prep_uninstall stop db_uninstall rm_files clean

prep_uninstall	:
	$(PERL) inst/uninstall.pl

db_uninstall	:
	$(PERL) inst/db_uninstall.pl

rm_files	:
	$(PERL) inst/rm_files.pl

.PHONY 		: uninstall prep_uninstall db_uninstall rm_files


##########################
# development rules      #
##########################

dev_symlink :
	$(PERL) inst/dev.pl

dev			: inst/Pg.sql inst/My.sql install dev_symlink clean
	

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
	-rm -rf bconf
	cd lib ; $(PERL) Makefile.PL ; $(MAKE) clean
	-rm -rf lib/Makefile.old
	-rm -rf lib/auto
	-rm -rf inst/db_tmp

.PHONY 		: clean
