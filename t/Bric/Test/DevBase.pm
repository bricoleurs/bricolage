package Bric::Test::DevBase;

=head1 NAME

Bric::Test::Base - Bricolage Development Testing Base Class

=head1 VERSION

$Revision: 1.1 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.1 $ )[-1];

=head1 DATE

$Date: 2003-01-17 01:37:30 $

=head1 SYNOPSIS

  package Bric::Biz::Person::DevTest;

  use strict;
  use warnings;
  use base qw(Bric::Test::DevBase);
  use Test::More;
  use Bric::Biz::Person;
  use Bric::Util::Grp::Person;

  sub table { 'person' }

  # Write some tests.
  sub test_me : Test(4) {
      my $self = shift;
      ok( my $p = Bric::Biz::Person->new, "create" );
      ok( $p->save, "save" );
      $self->add_del_ids([$p->get_id]);
      ok( my $grp = Bric::Util::Grp::Person->new, "create grp" );
      ok( $grp->save, "Save grp" );
      $self->add_del_ids([$grp->get_id], 'grp' );
  }

=head1 DESCRIPTION

This class is the base class for all of the Bricolage development testing
classes. It uses the L<Bric::Test::Base|Bric::Test::Base> module as I<its>
base class, and thus all of its subclasses get all of its benefits. It also
has a number of methods of its own that are designed to be used in classes
inherited from this class. They help keep the database cleaned up and such.

=cut

use strict;
use warnings;
require 5.006;
use base qw(Bric::Test::Base);

=head1 INTERFACE

Bric::Test::Base inherits from L<Bric::Test::Base|Bric::Test::Base>, and
therefore the entire interface of that class is available to
Bric::Test::DevBase and its subclasses. The following additional methods have
been added to its interface.

=over 4

=item C<add_del_ids>

  $test->add_del_ids([@ids]);
  $test->add_del_ids([@ids], $table);

This method takes an array reference of object IDs and schedules them for
deletion when a test method finishes executing, even if the method died before
completion. It uses a private cleanup method to handle the actual deletion of
rows from the database. It also needs to know the name of the table from which
to delete the rows. This name can either be passed in explicitly via a second
argument, or it can be set on a class-bases by adding a C<table()> method that
returns the name of the relevant table.

=cut

sub add_del_ids {
    my ($self, $ids, $table) = @_;
    $table ||= $self->table;
    push @{ $self->{_to_delete}{$table} }, @$ids;
}

=item C<get_del_ids>

  my $del_ids_hash = $test->get_del_ids;

Returns the hash reference used by C<add_del_ids> and C<del_ids> to store the
list of IDs to be deleted. The hash keys are the tables, and the values are
array references of the IDs to be deleted.

=cut

sub get_del_ids { $_[0]->{_to_delete} }

=item C<del_ids>

This method is automatically called by Test::Class after every test method has
executed. It's a tear-down method. It goes through the list of IDs that have
been added via C<add_del_ids()> and executes a C<DELETE> statement against the
appropriate table in the database.

It can be useful to override this method in order to delete related IDs. For
example, Bri::Biz::Asset::DevTest overrides C<del_ids()> to delete instances
of assets as well as the assets themselves. If you plan to override
C<del_ids()> but still wish it to run, be aware that when it does run, it
deletes the hash returned by C<get_del_ids()>. So if you need to get the list
of IDs to delete, be sure to do so before you call the C<del_ids()> method in
the super class:

  sub del_ids : Test(teardown => 0) {
      my $self = shift;
      my $to_delete = $self->get_del_ids;
      $self->SUPER::del_ids(@_);
      # Now do what you like with $to_delete.
  }

=cut

sub del_ids : Test(teardown => 0) {
    my $self = shift;
    my $to_delete = delete $self->{_to_delete} or return;

    while (my ($table, $ids) = each %$to_delete) {
        $ids = join ', ', @$ids;
        Bric::Util::DBI::prepare(qq{
            DELETE FROM $table
            WHERE  id IN ($ids)
        })->execute;
    }
}

1;
__END__

=back

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric::Test::Base|Bric::Test::Base>, L<Test::Class|Test::Class>,
L<Test::More|Test::More>, L<Test::Simple|Test::Simple>.
