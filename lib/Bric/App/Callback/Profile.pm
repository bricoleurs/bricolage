package Bric::App::Callback::Profile;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'profile';

use HTML::Mason::MethodMaker('read_write' => [qw(obj type class has_perms)]);
use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Util qw(:all);

use Bric::App::Callback::Profile::Action;
use Bric::App::Callback::Profile::AlertType;
use Bric::App::Callback::Profile::Category;
use Bric::App::Callback::Profile::Contrib;
use Bric::App::Callback::Profile::Desk;
use Bric::App::Callback::Profile::Dest;
use Bric::App::Callback::Profile::ElementData;
use Bric::App::Callback::Profile::ElementType;
use Bric::App::Callback::Profile::FormBuilder;
use Bric::App::Callback::Profile::Grp;
use Bric::App::Callback::Profile::Job;
use Bric::App::Callback::Profile::Media;
use Bric::App::Callback::Profile::MediaType;
use Bric::App::Callback::Profile::OutputChannel;
use Bric::App::Callback::Profile::Pref;
use Bric::App::Callback::Profile::Server;
use Bric::App::Callback::Profile::Site;
use Bric::App::Callback::Profile::Source;
use Bric::App::Callback::Profile::Story;
use Bric::App::Callback::Profile::Template;
use Bric::App::Callback::Profile::User;
use Bric::App::Callback::Profile::Workflow;

my $excl = {'desk' => 1, 'action' => 1, 'server' => 1};

my ($get_class);


# each subclass of Profile inherits this constructor,
# which I want to set up the common things (obj, type, class)
# and also whether the user has permission, then each callback
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

    return $self;
}


###

$get_class = sub {
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
