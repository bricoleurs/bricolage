use ExtUtils::MakeMaker;
use Bric;
use File::Find;
use File::Spec;
use strict;
# find all .pm and .pod files below this directory
my %PM;
File::Find::find({no_chdir => 1,
		  wanted   => sub { 
		    return unless /\.pm$/ or /\.pod$/;
		    $PM{$_} = File::Spec->catfile('${INST_LIBDIR}', $_);
		  }},
		 File::Spec->curdir);
		 
# Write out the Makefile
WriteMakefile(NAME        => 'Bric',
	      VERSION     => $Bric::VERSION,
	      PM          => \%PM);
