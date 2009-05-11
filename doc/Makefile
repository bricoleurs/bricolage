# ****************************************************************
# * Settings                                                     *
# ****************************************************************

# dependencies
SHELL = /bin/sh
POD2HTML = /usr/local/bin/pod2html
POD2MAN = /usr/local/bin/pod2man
MKDIR = /bin/mkdir
GZIP = /bin/gzip
PERL = /usr/local/bin/perl
FIND = /usr/bin/find

# ****************************************************************
# * Other Fields
# ****************************************************************

# directories
LIB = lib
BRIC = ../${LIB}/Bric

# ****************************************************************
# * some things we can figure out here, so we shouldn't 
# * have to mess with the settings all the time
# ****************************************************************

# the sourcefiles
PODFILES = $(shell ${FIND} ${BRIC} -name *.pod 2>/dev/null)
SRCFILES = $(PODFILES)

# suffixes:
.SUFFIXES:
.SUFFIXES: .pod .pl .html .man .man.gz

HTML_TARGETS = $(addprefix html/,$(addsuffix .html,$(basename $(notdir ${SRCFILES}))))

define generate-manpage
${POD2MAN} $^ >/tmp/$(notdir $^).man
${GZIP} /tmp/$(notdir $^).man >$@
endef

# ****************************************************************
# *  RULES follow
# ****************************************************************

all: doc
doc: ${HTML_TARGETS} man-targets


# ****************************************************************
# * This is a multiple target rule whose effect is to run 
# * pod2[whatever] recursively on the $(LIB) dir.  The whatever
# * is determined by the first prerequisite.
# ****************************************************************
html: 
    $(MKDIR) -p html
$(HTML_TARGETS): BASE = $(basename $(notdir $@))
$(HTML_TARGETS): ORIG = $(filter %/${BASE}.pod,${SRCFILES})
$(HTML_TARGETS): html
ifdef PERL2HTML
    ${PERL2HTML} --bgcolor '#ffffff' --verbosity 1 ${BRIC} html
else
    $(POD2HTML) --podpath=Bric --podroot=../${LIB} --verbose \
    --flush --htmldir=html --recurse --index --infile=$(ORIG) \
    --outfile=$@ --libpods=$(shell echo ${SRCFILES} | tr ' ' ':')
endif
    chmod a+r $@
    ${RM} pod2htm*

man-targets: man man/bricolage.8.gz man/bricolage-dba.8.gz \
     man/bricolage-security.8.gz man/bricolage-templates.3.gz \
     man/bricolage-advTemplages.3.gz man/bricolage-assetEditing.1.gz \
     man/bricolage-elementAdmin.1.gz man/bricolage-htmlTemplate.3.gz
man:
    $(MKDIR) -p man
man/bricolage.8.gz: ${BRIC}/Admin.pod
    ${generate-manpage}
man/bricolage-dba.8.gz: ${BRIC}/DBA.pod
    ${generate-manpage}
man/bricolage-security.8.gz: ${BRIC}/Security.pod
    ${generate-manpage}
man/bricolage-templates.3.gz: ${BRIC}/Templates.pod
    ${generate-manpage}
man/bricolage-advTemplages.3.gz: ${BRIC}/AdvTemplates.pod
    ${generate-manpage}
man/bricolage-assetEditing.1.gz: ${BRIC}/AssetEditing.pod
    ${generate-manpage}
man/bricolage-elementAdmin.1.gz: ${BRIC}/ElementAdmin.pod
    ${generate-manpage}
man/bricolage-htmlTemplate.3.gz: ${BRIC}/HTMLTemplate.pod
    ${generate-manpage}

clean: 
    $(RM) -r man html

