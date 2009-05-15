use ExtUtils::MakeMaker;
use File::Find;
use File::Spec;
use strict;

# load $CONFIG if it exists
our $CONFIG = {};
eval { require "../config.db" };

# Find all .pm and .pod files below this directory. Once we get rid of all the
# .pl files, this will no longer be necessary.
my %PM;
find({no_chdir => 1,
      wanted   => sub {
          return unless /\.pm$/ or /\.pod$/;
          return if m!/blib/!;
          # This strips off the './' nonsense from the beginning of
          # each file name. Required for MakeMaker changes in Perl 5.8.0.
          $_ = File::Spec->canonpath($_);
          $PM{$_} = File::Spec->catfile('${INST_LIB}', $_);
      }},
     File::Spec->curdir);

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
WriteMakefile(NAME           => 'Bric',
              PM             => \%PM,
              ( exists $CONFIG->{BRICOLAGE_ROOT} ?
                ( PREFIX => $CONFIG->{BRICOLAGE_ROOT} ) :
                ()),
              ( exists $CONFIG->{MODULE_DIR} ?
                ( INSTALLSITELIB => $CONFIG->{MODULE_DIR} ) :
                ()),
              ( exists $CONFIG->{MAN_DIR} ?
                ( INSTALLMAN3DIR => "$CONFIG->{MAN_DIR}/man3",
                  INSTALLSITEMAN3DIR => "$CONFIG->{MAN_DIR}/man3") :
                ()));
