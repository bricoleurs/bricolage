package Bric::Test::Base;

=head1 NAME

Bric::Test::Base - Bricolage Testing Base Class

=head1 VERSION

$Revision: 1.3 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.3 $ )[-1];

=head1 DATE

$Date: 2003-01-13 03:10:28 $

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
subclasses. No methods have been added, but they might be later -- the soft of
thing that might be desireable to do with every test class.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Test::Class|Test::Class>, L<Test::More|Test::More>,
L<Test::Simple|Test::Simple>.

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
      (File::Spec->tmpdir, 'bricolage', 'test');
    File::Path::mkpath($ENV{BRIC_TEMP_DIR}, 0, 0777);
}

# Remove the temp directory. END blocks run in LIFO, so this block will run
# after the one below that actually runs the tests.
END { File::Path::rmtree($ENV{BRIC_TEMP_DIR}) }


1;
__END__
