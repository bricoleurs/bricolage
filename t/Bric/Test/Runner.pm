package Bric::Test::Runner;

=head1 Name

Bric::Test::Base - Bricolage Development Testing Base Class

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Test::Harness qw(runtests);
  runtests(File::Spec->catfile(qw(t Bric Test Runner.pm)));

=head1 Description

This class functions as the sole test script for Bricolage. It locates all of
the Bricolage test classes and executes them. See F<inst/runtests.pl> for
its complete usage.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric::Test::Base|Bric::Test::Base>, F<inst/runtests.pl>.

=cut

use strict;
use warnings;
use File::Find;
use File::Spec;
use Bric::Test::Base;
use Bric::Util::Grp; # Need to load now to prevent warnings later.

BEGIN {
    # XXX Delete Bric::Util::DBI::_disconnect() unless we're running dev
    # tests or arbitrary tests (in which case it's likely that database-
    # specific tests are being run). This is to prevent `make test` from
    # throwing an exception when it can't connect to the database in
    # _disconnect().
    unless ($ENV{BRIC_DEV_TEST} or ($ENV{BRIC_TEST_CLASSES} && $ENV{BRIC_TEST_CLASSES} =~ /DevTest\.pm\b/) ) {
        require Bric::Util::DBI;
        no warnings 'redefine';
        *Bric::Util::DBI::_disconnect = sub {};
    }
}

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

1;
__END__
