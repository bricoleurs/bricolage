use ExtUtils::MakeMaker;
use File::Find;
use File::Spec;
use strict;

# load $CONFIG if it exists
our $CONFIG = {};
eval { require "../config.db" };

# find all .pm and .pod files below this directory. I assume that, once we get
# rid of all the .pl files, this will no longer be necessary? Because
# MakeMaker will find all the .pm files on its own. Is this correct?
my %PM;
find({no_chdir => 1,
      wanted   => sub {
          return unless /\.pm$/ or /\.pod$/;
          return if m!/blib/!;
          # This strips off the './' nonsense from the beginning of
          # each file name. Required for MakeMaker changes in Perl 5.8.0.
          $_ = File::Spec->canonpath($_);
          $PM{$_} = File::Spec->catfile('${INST_LIB}', $_)
            unless /\.pod$/;
          # Um, so, are we ignoring .pod files after all?
      }},
     File::Spec->curdir);

# Write out the Makefile
WriteMakefile(NAME           => 'Bric',
              PM             => \%PM,
	      ( exists $CONFIG->{MODULE_DIR} ?
		( INSTALLSITELIB => $CONFIG->{MODULE_DIR} ) :
		()),
	      ( exists $CONFIG->{MAN_DIR} ?
		( INSTALLMAN3DIR => "$CONFIG->{MAN_DIR}/man3" ) :
		()));
