package Bric::Test::Base;

=head1 NAME

Bric::Test::Base - Bricolage Testing Base Class

=head1 VERSION

$Revision: 1.2 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.2 $ )[-1];

=head1 DATE

$Date: 2003-01-09 01:51:13 $

=head1 SYNOPSIS

  package Bric::Biz::Person::Test;

  use strict;
  use warnings;
  use base qw(Bric::Test::Base);
  use Test::More;

  # Register this class for testing.
  BEGIN { __PACKAGE__->test_class }

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

Bric::Test::Base offers a single class method, C<test_class()> that none of
its subclasses should override, but that they all should call in a BEGIN
block, B<after> all other classes and modules have been loaded. This approach
allows each test class to run as a single Perl script, and thus work very
nicely with L<Test::Harness|Test::Harness>.

=head1 INTERFACE

Bric::Test::Base inherits from L<Test::Class|Test::Class>, and therefore the
entire interface of that class is available to Bric::Test::Base and its
subclasses. Only one class method has been added.

=over 4

=item C<test_class>

  BEGIN { __PACKAGE__->test_class }

This method must be called in a C<BEGIN> block by all Bric::Test::Base
subclasses so that they can be run as independent scripts. It must be called
only after all other classes have been C<use>d, so that the proper package
name is registered.

=back

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

my $class;
sub test_class { $class = shift }

# Defer execution until everything else has compiled and run.
END { Test::Class->runtests($class) if $class }

1;
