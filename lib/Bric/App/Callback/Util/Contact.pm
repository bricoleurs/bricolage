package Bric::App::Callback::Util::Contact;

use strict;
use Bric::App::Util qw(:all);

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
