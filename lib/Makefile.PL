use ExtUtils::MakeMaker;
use Bric;
use File::Find;
use File::Spec;
use strict;

# load $CONFIG if it exists
our $CONFIG = {};
eval { require "../config.db" }; 

# find all .pm and .pod files below this directory
my %PM;
File::Find::find({no_chdir => 1,
		  wanted   => sub { 
		    return unless /\.pm$/ or /\.pod$/;
		    return if m!/blib/!;
		    $PM{$_} = File::Spec->catfile('${INST_LIB}', $_) 
		      unless /\.pod$/;
		  }},
		 File::Spec->curdir);

# Write out the Makefile
WriteMakefile(NAME           => 'Bric',
              VERSION        => $Bric::VERSION,
              PM             => \%PM,
	      ( exists $CONFIG->{MODULE_DIR} ? 
		( INSTALLSITELIB => $CONFIG->{MODULE_DIR} ) : 
		()),
	      ( exists $CONFIG->{MAN_DIR} ? 
		( INSTALLMAN3DIR => "$CONFIG->{MAN_DIR}/man3" ) : 
		()));
