use ExtUtils::MakeMaker;
use Bric;
use File::Find;
use strict;

# This will be a hash containing the list of .pm files
# which will be installed.
my %pmfiles;

# for the convenience of &wanted calls, including -eval statements:
use vars qw/*name *dir *prune/;
*name   = *File::Find::name;
*dir    = *File::Find::dir;
*prune  = *File::Find::prune;


# Traverse filesystem starting at this directory
File::Find::find({wanted => \&wanted, no_chdir => 1}, '.', );

# Write out the Makefile
WriteMakefile(  NAME        => 'Bric',
                VERSION     => $Bric::VERSION,
                PM          => \%pmfiles);


# add each file found to the hash reference for PM
sub wanted {
    my $orig = $_;
    if (/^.*\.pm\z/ || /^.*\.pod\z/) {
        s/^\.\///;
        $pmfiles{$orig} = '${INST_LIBDIR}/' . $_;
    }
}

