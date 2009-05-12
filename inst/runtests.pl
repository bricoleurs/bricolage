#!/usr/bin/perl -w

=head1 Name

runtests.pl - Runs Bricolage's Tests

=head1 Synopsis

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
  perl inst/runtests.pl Bric::TestClass Bric::TestClass2 ...
  perl inst/runtests.pl t/Bric/TestClass, t/Bric/TestClass2 ...
  perl inst/runtests.pl -V
  perl inst/runtests.pl -V Bric::TestClass Bric::TestClass2 ...
  perl inst/runtests.pl -V t/Bric/TestClass, t/Bric/TestClass2 ...
  perl inst/runtests.pl -d
  perl inst/runtests.pl -dV

=head1 Description

This script is called during "make test" and "make devtest" to run the
Bricolage test suite. Passing in the "-d" argument is what causes the script
to run I<all> of the tests, including developer tests, while no arguments
cause the script to only run the 'Test.pm' scripts.

If the environment variable C<TEST_VERBOSE> is set, or the C<-V> option is
passed in, then the tests will be run in verbose mode.

If a list of one or more test classes and/or test class files are passed in,
then only the tests in those files and/or classes will be run.

All tests are executed in the Bricolage distribution root directory. If you're
writing tests that need to output test files or something, please use
C<< File::Spec->tmpdir >> and clean up after yourself!

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Test::Class|Test::Class>, L<Test::More|Test::More>.

=cut

use strict;
use warnings;
use File::Spec;
use Test::Harness qw(runtests $verbose);
use Getopt::Std;

# Add the requisite library paths to @INC.
unshift @INC, 'lib', File::Spec->catdir('t');

# Get arguments.
my %opts;
getopts('dV', \%opts);

# Prepare for 'make devtest'. The test runner will check this environment
# variable.
$ENV{BRIC_DEV_TEST} ||= $opts{d} if $opts{d};

$ENV{BRIC_TEST_CLASSES} = join ',', @ARGV if @ARGV;

#Set option to enable test cache
#This only enables the code that checks if it should do test
#caching
$ENV{BRIC_CACHE_DEBUG_MODE} = 1;

# Set verbosity.
if ($opts{V}) {
    # This environment variable tells Test::Class to be verbose.
    $ENV{TEST_VERBOSE} = 1;
    # This variable tells Test::Harness to be verbose.
    $verbose = 1;
} else {
    # Tell Test::Harness to be verbose if the TEST_VERBOSE environment
    # variable is set.
    $verbose = 1 if $ENV{TEST_VERBOSE};
}

# Make sure that all tests are run with warnings enabled.
$ENV{HARNESS_PERL_SWITCHES} = '-w';

# Run the tests!
runtests(File::Spec->catfile(qw(t Bric Test Runner.pm)));


