package Bric::App::Callback::Profile;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass('class_key' => 'profile');
use HTML::Mason::MethodMaker('read_write' => [qw(obj type class has_perms)]);
use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Callback::Util qw(parse_uri);
use Bric::App::Util qw(:all);

use Bric::App::Callback::Profile::Action.pm;
use Bric::App::Callback::Profile::AlertType.pm;
use Bric::App::Callback::Profile::Category.pm;
use Bric::App::Callback::Profile::Contrib.pm;
use Bric::App::Callback::Profile::Desk.pm;
use Bric::App::Callback::Profile::Dest.pm;
use Bric::App::Callback::Profile::ElementData.pm;
use Bric::App::Callback::Profile::ElementType.pm;
use Bric::App::Callback::Profile::FormBuilder.pm;
use Bric::App::Callback::Profile::Grp.pm;
use Bric::App::Callback::Profile::Job.pm;
use Bric::App::Callback::Profile::Media.pm;
use Bric::App::Callback::Profile::MediaType.pm;
use Bric::App::Callback::Profile::OutputChannel.pm;
use Bric::App::Callback::Profile::Pref.pm;
use Bric::App::Callback::Profile::Server.pm;
use Bric::App::Callback::Profile::Site.pm;
use Bric::App::Callback::Profile::Source.pm;
use Bric::App::Callback::Profile::Story.pm;
use Bric::App::Callback::Profile::Template.pm;
use Bric::App::Callback::Profile::User.pm;
use Bric::App::Callback::Profile::Workflow.pm;

my $excl = {'desk' => 1, 'action' => 1, 'server' => 1};


# each subclass of Profile inherits this constructor
# which I want to set up the common things (obj, type, class)
# and also whether the user has permission then each callback
# will just return unless $self->has_perms
sub new {
    my $pkg = shift;
    my $self = bless($pkg->SUPER::new(@_), $pkg);

    my $param = $self->request_args;

    $self->type((parse_uri($self->apache_req->uri))[2]);
    $self->class($get_class->($param, $self->type));

    # Instantiate the object.
    my $id = defined $param->{$self->type . '_id'} && $param->{$self->type . '_id'} ne ''
      ? $param->{$self->type . '_id'} : undef;
    my $obj = defined $id ? $self->class->lookup({ id => $id }) : $self->class->new;
    $self->obj($obj);

    # Check the permissions.
    unless ($excl->{$self->type}
              || chk_authz($self->obj, (defined $id ? EDIT : CREATE), 1)
              || ($self->type eq 'user' && $self->obj->get_id == get_user_id()))
    {
        # If we're in here, the user doesn't have permission to do what
        # s/he's trying to do.
        add_msg("Changes not saved: permission denied.");
        set_redirect(last_page());
        $self->has_perms(0);
    } else {
        $self->has_perms(1);
    }

    # Process its data - in a subclass:
    # action, alert_type, category, contrib, desk, dest, element_data,
    # element_type, grp, job, media_type, output_channel, pref,
    # server, site, source, user, workflow
}


###

my $get_class = sub {
    my ($param, $type) = @_;

    my $key = $type;
    if ($type eq 'contrib' && ! defined $param->{'contrib_id'}) {
        $key = 'person';
    }

    my $class = get_package_name($key);
    if ($type eq 'grp' && defined $param->{'grp_type'}) {
        $class = $param->{'grp_type'};
    }

    return $class;
};


1;
