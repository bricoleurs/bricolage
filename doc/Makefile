# ****************************************************************
# * Settings                                                     *
# ****************************************************************

# dependencies
SHELL = /bin/sh
POD2HTML = /usr/bin/pod2html
POD2MAN = /usr/bin/pod2man
MKDIR = /bin/mkdir
MKDIRHIER = /usr/bin/X11/mkdirhier
GZIP = /bin/gzip

# ****************************************************************
# * Other Fields
# ****************************************************************

# directories
BIN = ../bin
COMP = ../comp
CONF = ../conf
DATA = ../data
LIB = ../lib

# ****************************************************************
# * some things we can figure out here, so we shouldn't 
# * have to mess with the settings all the time
# ****************************************************************

# the sourcefiles
PODFILES = $(shell find $(LIB) -name *.pod)
PMFILES = $(shell find $(LIB) -name *.pm)
SRCFILES = $(PODFILES)

# targets
HTML_TARGETS = $(shell echo $(SRCFILES) | sed -e 's:$(LIB):html:g' -e 's:\.pod:.html:g' -e 's:\.pm:.html:g')
MAN_TARGETS = $(shell echo $(SRCFILES) | sed -e 's:$(LIB):man:g' -e 's:\.pod:.gz:g' -e 's:\.pm:.gz:g')
ALL_TARGETS = $(HTML_TARGETS) $(MAN_TARGETS)

# suffixes:
.SUFFIXES:
.SUFFIXES: .pod .pl .html


# ****************************************************************
# *  RULES follow
# ****************************************************************

all: $(ALL_TARGETS)

html: 
	$(MKDIR) html

man:
	$(MKDIR) man

# ****************************************************************
# * This is a multiple target rule whose effect is to run 
# * pod2[whatever] recursively on the $(LIB) dir.  The whatever
# * is determined by the first prerequisite.
# ****************************************************************
$(HTML_TARGETS): DIR = $(shell echo $@ | sed -e "s:/[^/]*$$::")
$(HTML_TARGETS): BASE = $(shell echo $@ | sed -e "s:$<\(.*\)$<:\1:")
$(HTML_TARGETS): ORIG = $(shell echo $(SRCFILES) | sed -e "s:.*\($(LIB)$(BASE)[^ ]*\).*:\1:")
$(HTML_TARGETS): html
	$(MKDIRHIER) $(DIR)
	$(POD2HTML) --infile=$(ORIG) --outfile=$@
	$(RM) pod2htm*

$(MAN_TARGETS): DIR = $(shell echo $@ | sed -e "s:/[^/]*$$::")
$(MAN_TARGETS): BASE = $(shell echo $@ | sed -e "s:$<\(.*\)gz:\1:")
$(MAN_TARGETS): ORIG = $(shell echo $(SRCFILES) | sed -e "s:.*\($(LIB)$(BASE)[^ ]*\).*:\1:")
$(MAN_TARGETS): man
	$(MKDIRHIER) $(DIR)
	$(POD2MAN) $(ORIG) $(shell echo $@ | sed -e "s:\.gz::")
	$(GZIP) -f $(shell echo $@ | sed -e "s:\.gz::")
	$(RM) pod2ma*

clean: 
	$(RM) $(ALL_TARGETS)
	$(RM) -r man html

# historical
love:
	@echo "not war"


