package Bric::App::Callback::Profile;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'profile');
use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Callback::Util qw(parse_uri);
use Bric::App::Util qw(:all);


my $excl = { desk => 1, action => 1, server => 1 };


sub SOMENAMES : Callback {
    my $self = shift;

    my $type = (parse_uri($self->apache_req->uri))[2];

    # Get the class name.
    my $key = $type eq 'contrib' && ! defined $param->{contrib_id}
      ? 'person'
      : $type;

    my $class = get_package_name($key);
    $class = $param->{grp_type} || $class if $type eq 'grp';

    # Instantiate the object.
    my $id = defined $param->{$type . '_id'} && $param->{$type . '_id'} ne ''
      ? $param->{$type . '_id'} : undef;
    my $obj = defined $id ? $class->lookup({ id => $id }) : $class->new;

    # Check the permissions.
    unless ( $excl->{$type} || chk_authz($obj, (defined $id ? EDIT : CREATE), 1)
               || ($type eq 'user' && $obj->get_id == get_user_id()) ) {
        # If we're in here, the user doesn't have permission to do what
        # s/he's trying to do.
        add_msg("Changes not saved: permission denied.");
        set_redirect(last_page());
        return;
    }

    # Process its data
    # action, alert_type, category, contrib, desk, dest, element_data,
    # element_type, grp, job, media_type, output_channel, pref,
    # server, site, source, user, workflow
    $param->{obj} = $m->comp("$type.mc", %ARGS, obj => $obj, class => $class);
}




1;
