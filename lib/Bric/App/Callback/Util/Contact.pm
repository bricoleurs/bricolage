package Bric::App::Callback::Util::Contact;

use strict;
use Bric::App::Util qw(:aref);

use base qw(Exporter);
our @EXPORT_OK = qw(update_contacts);
our %EXPORT_TAGS = (all => \@EXPORT_OK);


sub update_contacts {
    my ($param, $obj) = @_;

    my $cids = mk_aref($param->{contact_id});
    for (my $i = 0; $i < @{$param->{value}}; $i++) {
	if (my $id = $cids->[$i]) {
	    my ($c) = $obj->get_contacts($id);
	    $c->set_value($param->{value}[$i]);
	    $c->set_type($param->{type}[$i])
	} else {
	    next unless $param->{value}[$i];
	    my $c = $obj->new_contact($param->{type}[$i],
				       $param->{value}[$i]);
	}
    }

    $obj->del_contacts(@{ mk_aref($param->{del_contact}) })
      if $param->{del_contact};
}

1;

=head1 NAME

Bric::App::Callback::Util::Contact - Contact utility functions for callbacks

=head1 SYNOPSIS

  use Bric::App::Callback::Util::Contact qw(:all);
  update_contacts($params, $person);

=head1 DESCRIPTION

This module provides utility functions for managing contacts in callback
classes that manage Bric::Biz::Person objects.

=head1 INTERFACE

=head2 Functions

=head3 update_contacts

  update_contacts($params, $person);

Updates the contacts for C<$person> by pulling the contact data from
C<$params>. See
L<Bric::App::Callback::Profile::User|Bric::App::Callback::Profile::User> for a
sample usage.

=head1 AUTHOR

Scott Lanning <lannings@who.int>

=head1 SEE ALSO

=over 4

=item L<Bric::App::Callback::Profile::User|Bric::App::Callback::Profile::User>

This callback class uses Bric::App::Callback::Util::Contact.

=item L<Bric::App::Callback|Bric::App::Callback>

This is the base class for all callback classes.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2004 World Health Organization and Kineticode, Inc. See
L<Bric::License|Bric::License> for complete license terms and conditions.

=cut
