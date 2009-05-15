package Bric::App::Callback::Profile;

=head1 Name

Bric::App::Callback::Profile - The Bricolage profile callback base class

=head1 Synopsis

  use base 'Bric::App::Callback::Profile';

=head1 Description

This is the base class from which all Bricolage profile callback classes
inherit. It provides a number of base and utility methods that are useful to
the profile classes, and that handle common functionality between the classes.

=cut

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'profile';

use HTML::Mason::MethodMaker('read_write' => [qw(obj type class has_perms)]);
use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Authz qw(:all);
use Bric::App::Util qw(:aref :history :pkg :browser);
use Bric::App::Session qw(:user);

my $excl = {
    desk       => 1,
    action     => 1,
    server     => 1,
    field_type => 1,
};

my ($get_class, $chk_grp_perms);

##############################################################################

=head1 Class Interface

=head2 Constructors

=head3 new

Bric::App::Callback::Profile overrids the parent C<new()> constructor so
handle a number of tasks common to all profile callback classes. These
include:

=over 4

=item *

Constructing the object on which the callback methods will be operating.

=item *

Setting the class of object that the callback will be executing against.

=item *

Checking permissions on the object to be operated on.

=back

=cut

# each subclass of Profile inherits this constructor,
# which I want to set up the common things (obj, type, class)
# and also whether the user has permission, then each callback
# will just return unless $self->has_perms
sub new {
    my $pkg = shift;
    my $self = bless($pkg->SUPER::new(@_), $pkg);

    my $param = $self->params;

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
        $self->raise_forbidden('Changes not saved: permission denied.');
        $self->set_redirect(last_page());
        $self->has_perms(0);
    } else {
        $self->has_perms(1);
    }

    return $self;
}

##############################################################################

=head1 Instance Interface

=head2 Instance Attributes

=head3 obj

  my $obj = $cb->obj;

The object on which operations are to be performed by callback methods.

=head3 type

  my $type = $cb->type;

The type of object on which operations will be performed. This is generally a
string such as "user" or "story".

=head3 class

  my $class = $cb->class;

The class of object on which operations will be performed.

=head3 has_perms

  unless ($cb->has_perms)
      die "Oh-oh!";
  }

Returns true if the current user has permission to the object to be operated
on. The required permission is CREATE for new objects and EDIT for existing
objects.

=cut

##############################################################################

=head2 Instance Methods

=head3 manage_grps

  $cb->manage_grps;

This method manages group memberships for the object. Since many profiles have
group membership association built in to the UI, this method can handle
updating the memberships for any and all types of objects with profiles.

=cut

# Group membership is handled the same way through all callbacks,
# so this method gets inherited to all profiles.

sub manage_grps : Callback( priority => 7 ) {
    my $self   = shift;
    my $obj    = shift || $self->obj;
    my $param  = $self->params;
    return unless $param->{add_grp} or $param->{rem_grp};

    my @add_grps = map { Bric::Util::Grp->lookup({ id => $_ }) }
                       @{mk_aref($param->{add_grp})};

    my @del_grps = map { Bric::Util::Grp->lookup({ id => $_ }) }
                       @{mk_aref($param->{rem_grp})};

    my $is_user = ref $obj eq 'Bric::Biz::Person::User';
    my $return = 1;

    # It could be an array of objects -- See Profile::Category.
    for my $o (ref $obj eq 'ARRAY' ? @$obj : ($obj)) {
        my $all_grp_id = $o->INSTANCE_GROUP_ID;
        # Assemble the new member information.
        foreach my $grp (@add_grps) {
            # Check permissions.
            next unless $chk_grp_perms->($self, $grp, $all_grp_id, $is_user);

            # Add the object to the group.
            $grp->add_members([{ obj => $o }]);
            $grp->save;
            log_event('grp_save', $grp);
        }

        foreach my $grp (@del_grps) {
            # Check permissions.
            next unless $chk_grp_perms->($self, $grp, $all_grp_id, $is_user);

            # Deactivate the object's group membership.
            foreach my $mem ($grp->has_member({ obj => $o })) {
                $mem->deactivate;
                $mem->save;
            }

            $grp->save;
            log_event('grp_save', $grp);
        }
    }
}

$chk_grp_perms = sub {
    my ($cb, $grp, $all_grp_id, $is_user) = @_;
    # If it's a user group, disallow access unless the current user is the
    # global admin or a member of the group. If it's not a user group,
    # disallow access unless the current user has EDIT access to the members
    # of the group.
    unless (
        $grp->get_id != $all_grp_id
        && chk_authz($grp, EDIT, 1)
        && ((
                $is_user
                && (user_is_admin || $grp->has_member({ obj => get_user_object }))
                || chk_authz(0, EDIT, 1, $grp->get_id)
            ))
    ) {
        cb->raise_forbidden(
            'Permission to manage "[_1]" group membership denied',
            $grp->get_name,
        );
        return;
    }
    return 1;
};

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

=head1 Author

Scott Lanning <lannings@who.int>

=head1 See Also

=over 4

=item L<Bric::App::Callback|Bric::App::Callback>

The Bricolage base callback class, from which Bric::App::Callback::Profile
inherits.

=item L<Bric::App::Callback::Profile|Bric::App::Callback::Profile::User>

The user profile callback class, which inherits from
Bric::App::Callback::Profile.

=back

=head1 Copyright and License

Copyright (c) 2003-2004 World Health Organization and Kineticode, Inc. See
L<Bric::License|Bric::License> for complete license terms and conditions.

=cut
