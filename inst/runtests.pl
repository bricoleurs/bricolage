#!/usr/bin/perl -w

=head1 NAME

runtests.pl - Runs Bricolage's Tests

=head1 VERSION

$Revision: 1.3 $

=head1 DATE

$Date: 2002-09-19 00:03:28 $

=head1 SYNOPSIS

  # In Makefile:
  TEST_VERBOSE=0

  test          :
          PERL_DL_NONLAZY=1 $(PERL) inst/runtests.pl

  devtest         :
          PERL_DL_NONLAZY=1 $(PERL) inst/runtests.pl -d


  # Run standard tests from the shell.
  make test
  make test TEST_VERBOSE=1

  # Do the same with all tests.
  make devtest
  make devtest TEST_VERBOSE=1

  # Or simply execute this script.
  perl inst/runtests.pl
  perl inst/runtests.pl t/test_file, t/test_file ...
  perl inst/runtests.pl -V
  perl inst/runtests.pl -V t/test_file, t/test_file ...
  perl inst/runtests.pl -d
  perl inst/runtests.pl -dV

=head1 DESCRIPTION

This script is called during "make test" and "make devtest" to run the
Bricolage test suite. Passing in the "-d" argument is what causes the script
to run I<all> of the tests, including developer tests, while no arguments
cause the script to only run the 'Test.pm' scripts.

If the environment variable C<TEST_VERBOSE> is set, or the C<-V> option is
passed in, then the tests will be run in verbose mode.

If a list of one or more test class files are passed in, then only those tests
will be run.

All tests are executed in the Bricolage distribution root directory. If you're
writing tests that need to output test files or something, please use
C<< File::Spec->tmpdir >> and clean up after yourself!

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Test::Class|Test::Class>, L<Test::More|Test::More>.

=cut

use strict;
use warnings;
use File::Find;
use File::Spec;
use Test::Harness qw(runtests $verbose);
use Getopt::Std;

# Add the requisite library paths to @INC.
unshift @INC, 'lib', File::Spec->catdir('t', 'lib');

# Get arguments.
my %opts;
getopts('dV', \%opts);

# Set up how to check the test names.
my $chk = $opts{d} ? sub { m/Test.pm$/ } : sub { $_ eq 'Test.pm' };

# Find the tests.
my @tests = @ARGV;
find(sub { push @tests, $File::Find::name if $chk->() }, 'lib')
  unless @tests;

# Set verbosity.
if ($opts{V}) {
    # This environment variable tells Test::Class to be verbose.
    $ENV{TEST_VERBOSE} = 1;
    # This varible tells Test::Harness to be verbose.
    $verbose = 1;
} else {
    # Tell Test::Harness to be verbose if the TEST_VERBOSE environment
    # variable is set.
    $verbose = 1 if $ENV{TEST_VERBOSE};
}

# Run the tests!
runtests(@tests);


