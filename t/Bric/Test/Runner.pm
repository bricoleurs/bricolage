package Bric::Test::Runner;

use strict;
use warnings;
use File::Find;
use File::Spec;
use Bric::Test::Base;
use Bric::Util::Grp; # Need to load now to prevent warnings later.

# Find the tests classes.
my @classes;
BEGIN {
    # We'll use this code reference to convert file names to class names.
    my $convert = sub {
        # Get all of the directories in the file name except 't', and then
        # join them all up into proper package names.
         my ($t, @dirs) = File::Spec->splitdir(substr shift, 0, -3);
         join '::', @dirs;
    };

    if ($ENV{BRIC_TEST_CLASSES}) {
        # Only specific tests need running.
        foreach my $arg (split /,/, $ENV{BRIC_TEST_CLASSES}) {
            if ($arg =~ /^t/ and -f $arg) {
                # It's a file name. Convert it to a class name.
                push @classes, $convert->($arg);
            } elsif ($arg =~ /^Bric::/) {
                # It's a class name. Just add it to the list.
                push @classes, $arg;
            } else {
                die "Unknown argument: '$arg'\n";
            }
        }
    } else {
        # We need to find all of the tests classes. If $ENV{BRIC_DEV_TEST}
        # is set, we'll want all classes ending in "Test.pm". Otherwise,
        # we'll want only those explicityly named "Test.pm".
        my $regex = $ENV{BRIC_DEV_TEST} ? qr/Test\.pm$/ : qr/^Test\.pm$/;

        my $find_classes = sub {
            return unless /$regex/;
            return if /#/; # Ignore old backup files.
            unshift @classes, $convert->($File::Find::name);
        };

        find($find_classes, 't');
    }

    # Make sure that all of the classes are loaded.
    foreach my $c (@classes) {
        eval "require $c";
        die "Error loading $c: $@" if $@;
    }
}

# Run the tests.
Bric::Test::Base->runtests(@classes);
