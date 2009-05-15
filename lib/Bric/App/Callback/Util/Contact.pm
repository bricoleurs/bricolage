package Bric::App::Callback::Util::Contact;

use strict;
use Bric::App::Util qw(:aref);

use base qw(Exporter);
our @EXPORT_OK = qw(update_contacts);
our %EXPORT_TAGS = (all => \@EXPORT_OK);


sub update_contacts {
    my ($param, $obj) = @_;

    my ($cids, $values, $types) = 
        map { mk_aref($param->{$_}) } qw(contact_id value type);
    my %cids_seen = {};
    for (my $i = 0; $i < scalar @$values; $i++) {
        if (my $id = $cids->[$i]) {
            my ($c) = $obj->get_contacts($id);
            $c->set_value($values->[$i]);
            $c->set_type($types->[$i]);
            $cids_seen{$c} = 1;
        } else {
            next unless $values->[$i];
            my $c = $obj->new_contact($types->[$i], $values->[$i]);
        }
    }

    my @del;
    for my $contact ($obj->get_contacts()) {
        push @del, $contact unless $cids_seen{$contact};
    }
    $obj->del_contacts(@del) if @del;
}

1;

=head1 Name

Bric::App::Callback::Util::Contact - Contact utility functions for callbacks

=head1 Synopsis

  use Bric::App::Callback::Util::Contact qw(:all);
  update_contacts($params, $person);

=head1 Description

This module provides utility functions for managing contacts in callback
classes that manage Bric::Biz::Person objects.

=head1 Interface

=head2 Functions

=head3 update_contacts

  update_contacts($params, $person);

Updates the contacts for C<$person> by pulling the contact data from
C<$params>. See
L<Bric::App::Callback::Profile::User|Bric::App::Callback::Profile::User> for a
sample usage.

=head1 Author

Scott Lanning <lannings@who.int>

=head1 See Also

=over 4

=item L<Bric::App::Callback::Profile::User|Bric::App::Callback::Profile::User>

This callback class uses Bric::App::Callback::Util::Contact.

=item L<Bric::App::Callback|Bric::App::Callback>

This is the base class for all callback classes.

=back

=head1 Copyright and License

Copyright (c) 2003-2004 World Health Organization and Kineticode, Inc. See
L<Bric::License|Bric::License> for complete license terms and conditions.

=cut
