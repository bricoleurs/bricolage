package Bric::Test::Base;

=head1 NAME

Bric::Test::Base - Bricolage Testing Base Class

=head1 VERSION

$Revision: 1.6 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.6 $ )[-1];

=head1 DATE

$Date: 2003-01-24 06:50:15 $

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This class is the base class for all of the Bricolage testing classes. It uses
the L<Test::Class|Test::Class> module as I<its> base class, and thus all of
its subclasses get all of its benefits.

=head1 INTERFACE

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

# Set up the temporary directory. This must be readable and writable
# by the person running the tests, and so must be different from the
# default in bricolage.conf, since there may be data owned by another
# user in that directory.
BEGIN {
    $ENV{BRIC_TEMP_DIR} = File::Spec->catdir
      (File::Spec->tmpdir, 'bricolage-test');
    File::Path::mkpath($ENV{BRIC_TEMP_DIR}, 0, 0777);
}

# Remove the temp directory. END blocks run in LIFO, so this block will run
# after the one below that actually runs the tests.
END { File::Path::rmtree($ENV{BRIC_TEMP_DIR}) }

=head1 INTERFACE

=head2 Class Methods

=over 4

=item C<user_id>

  my $user_id = Bric::Test::Base->user_id;

Returns a user ID that can be used throughout the tests. Just don't delete
this user when you construct it!

=cut

sub user_id { 0 }

1;
__END__

=back

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric::Test::DevBase|Bric::Test::DevBase>, L<Test::Class|Test::Class>,
L<Test::More|Test::More>, L<Test::Simple|Test::Simple>.

=cut

