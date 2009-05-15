use ExtUtils::MakeMaker;
use File::Find;
use File::Spec;
use strict;

# load $CONFIG if it exists
our $CONFIG = {};
eval { require "../config.db" };

# find all files in this directory
my @EXE;
File::Find::find({
    no_chdir => 1,
    wanted   => sub {
        return if m!/blib/!;
        return unless -f and m!bric_\w+$!;
        push @EXE, $_;
    }}, File::Spec->curdir);

# skip manifying PODs if '!' is given as MAN_DIR
sub MY::manifypods {
    if (exists $CONFIG->{MAN_DIR} && $CONFIG->{MAN_DIR} eq '!') {
        return '
manifypods:
	@$(NOOP)
';
    } else {
        package MY;
        return shift->SUPER::manifypods(@_);
    }
}

# Write out the Makefile
WriteMakefile(
    NAME           => 'bric_bin',
    EXE_FILES      => \@EXE,
    ( exists $CONFIG->{BRICOLAGE_ROOT} ?
        ( PREFIX => $CONFIG->{BRICOLAGE_ROOT} ) :
        ()
    ),
    ( exists $CONFIG->{MODULE_DIR} ?
        ( INSTALLSITELIB => $CONFIG->{MODULE_DIR} ) :
        ()
    ),
    ( exists $CONFIG->{BIN_DIR} ? (
        INSTALLSCRIPT => $CONFIG->{BIN_DIR},
        INSTALLSITESCRIPT => $CONFIG->{BIN_DIR},
        INSTALLSITEBIN => $CONFIG->{BIN_DIR}
    ) : ()),
    ( exists $CONFIG->{MAN_DIR} ? (
        INSTALLMAN1DIR => "$CONFIG->{MAN_DIR}/man1",
        INSTALLSITEMAN1DIR => "$CONFIG->{MAN_DIR}/man1"
    ) : ())
);
