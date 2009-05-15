package Bric::Test::Base;

=head1 Name

Bric::Test::Base - Bricolage Testing Base Class

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  package Bric::Biz::Person::Test;

  use strict;
  use warnings;
  use base qw(Bric::Test::Base);
  use Test::More;

  # Write some tests.
  sub test_me : Test(3) {
      my $self = shift;
      ok( 2 * 2 == 4, "Check multiplication" )
        or diag "Houston, we have a problem";
      is('shoe' . 'box' , 'shoebox', "Check concatenation" );
      isa_ok($self, 'Bric::Test::Base');
  }

=head1 Description

This class is the base class for all of the Bricolage testing classes. It uses
the L<Test::Class|Test::Class> module as I<its> base class, and thus all of
its subclasses get all of its benefits.

=head1 Interface

Bric::Test::Base inherits from L<Test::Class|Test::Class>, and therefore the
entire interface of that class is available to Bric::Test::Base and its
subclasses. It offers methods generally useful throughout the testing classes.

This class also sets the C<BRIC_TEMP_DIR> environment variable. This variable
overrides the setting in the F<bricolage.conf> file to provide a temporary
temp directory just for testing. The reason for this is that the temp
directory must be readable and writable by the person running the tests, and
so must be different from the default in bricolage.conf, since there may be
data owned by another user in that directory. Thus Bric::Test::Base creates
the temporary directory, and then deletes it and all of its contents between
tests. This also provents prior tests from affecting later tests by leaving
older stuff in the temp directory.

=cut

use strict;
use warnings;
require 5.006;
use base qw(Test::Class);
use File::Spec;
use File::Path;
use Bric::Test::TieOut;

# Set up the temporary directory. This must be readable and writable
# by the person running the tests, and so must be different from the
# default in bricolage.conf, since there may be data owned by another
# user in that directory.
BEGIN {
    my $tmp = $ENV{BRIC_TEMP_DIR} = File::Spec->catdir(
        File::Spec->tmpdir, 'bricolage-test'
    );
    File::Path::mkpath($ENV{BRIC_TEMP_DIR}, 0, 0777);
    $ENV{BRIC_BURN_ROOT} = File::Spec->catdir($tmp, 'burn');
    $ENV{MEDIA_FILE_ROOT} = File::Spec->catdir($tmp, 'media');
}

# Remove the temp directory. END blocks run in LIFO, so this block will run
# after the one below that actually runs the tests.
END { File::Path::rmtree($ENV{BRIC_TEMP_DIR}) }

# Tie off STDERR and STDOUT so that we don't output anything, but then can
# read from them in our tests. Also tie off STDIN so we can print stuff to
# it.
open REALOUT, ">&STDOUT" or die "Can't dup STDOUT: $!";
my $stdout = tie *STDOUT, 'Bric::Test::TieOut', \*REALOUT
  or die "Cannot tie STDOUT: $!\n";

open REALERR, ">&STDERR"  or die "Can't dup STDERR: $!";
my $stderr = tie *STDERR, 'Bric::Test::TieOut', \*REALERR
  or die "Cannot tie STDERR: $!\n";

open REALIN, ">&STDIN"  or die "Can't dup STDIN: $!";
my $stdin = tie *STDIN, 'Bric::Test::TieOut', \*REALIN
  or die "Cannot tie STDIN: $!\n";

=head1 Interface

=head2 Class Methods

=head3 user_id

  my $user_id = Bric::Test::Base->user_id;

Returns a user ID that can be used throughout the tests. Just don't delete
this user when you construct it!

=cut

sub user_id { 0 }

##############################################################################

=head3 trap_stdout

=head3 trap_stderr

  $test->trap_stdout;
  Bric::Test::Base->trap_stdout;

  $test->trap_stderr;
  Bric::Test::Base->trap_stderr;

Traps output printed to C<STDOUT> or C<STDERR> so that it can be retreived by
a call to C<read_stdout()> or C<read_stderr()>. The trapping will last only
for the lifetime of a test, and any output not retreived from C<read_stdout()>
or C<read_stderr()> will be output in the default fashion at during the test
teardown phase.

=cut

sub trap_stdout { $stdout->autoflush(0) }
sub trap_stderr { $stderr->autoflush(0) }

sub zzuntrap : Test(teardown) {
    $stdout->autoflush(1);
    $stdout->printit;
    $stderr->autoflush(1);
    $stderr->printit;
}

##############################################################################

=head3 read_stdout

=head3 read_stderr

  my $stdout = Bric::Test::Base->read_stdout;
  $stdout = $test->read_stdout;

  my $stderr = Bric::Test::Base->read_stderr;
  $stderr = $test->read_stderr;

Returns everything printed to C<STDOUT> or C<STDERR> since the last time it
was read from. Bric::Test::Base ties C<STDOUT> and C<STDERR> off to
Bric::Test::TieOut in order to prevent any code that prints to these file
handles from messing with the output the Test::Harness expects to read. But
it's also useful for checking what your Bricolage output in your tests, too.
They can also be used as instance methods.

=cut

sub read_stdout { $stdout->read }
sub read_stderr { $stderr->read }

##############################################################################

=head3 print_stdin

  Bric::Test::Base->print_stdin(@msgs);
  $test->print_stdin(@msgs);

Sends C<@msgs> to C<STDIN> as if a user had input data. Any code that read
from C<STDIN> will of course read in what you've input.

=cut

sub print_stdin {
    shift;
    print STDIN @_;
}

1;
__END__

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric::Test::DevBase|Bric::Test::DevBase>, L<Test::Class|Test::Class>,
L<Test::More|Test::More>, L<Test::Simple|Test::Simple>.

=cut

