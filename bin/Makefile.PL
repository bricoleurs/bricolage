use ExtUtils::MakeMaker;
use File::Find;
use File::Spec;
use strict;

# load $CONFIG if it exists
our $CONFIG = {};
eval { require "../config.db" }; 

# find all files in this directory
my @EXE;
File::Find::find({no_chdir => 1,
		  wanted   => sub { 
		      return unless -f and m!bric_\w+$!;
		      push @EXE, $_;
		  }},
		 File::Spec->curdir);

# Write out the Makefile
WriteMakefile(NAME           => 'bric_bin',
	      EXE_FILES      => \@EXE,
	      ( exists $CONFIG->{MODULE_DIR} ? 
		( INSTALLSITELIB => $CONFIG->{MODULE_DIR} ) : 
		()),
	      ( exists $CONFIG->{BIN_DIR} ? 
		( INSTALLSCRIPT => $CONFIG->{BIN_DIR} ) : 
		()),
	      ( exists $CONFIG->{MAN_DIR} ? 
		( INSTALLMAN1DIR => "$CONFIG->{MAN_DIR}/man1" ) : 
		()));

