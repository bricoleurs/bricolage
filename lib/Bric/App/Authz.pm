package Bric::App::Authz;

=head1 Name

Bric::App::Authz - Exports functions for checking user authorization.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::App::Authz qw(:all);

  chk_authz($obj, READ);
  # If we get here, we can read $obj.

  chk_authz($obj, EDIT);
  # If we get here, we can edit $obj.

  chk_authz($obj, CREATE);
  # If we get here, we can create $obj.

=head1 Description

This package exports the function chk_authz(), which will return true if the
current user has permission to perform a given activity to $obj, and redirect to
an error page if the user does not have the permission. The permissions
available are also exported. They are READ, EDIT, and CREATE. CREATE includes
READ and CREATE permissions while EDIT includes READ permission.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::App::Session qw(:user user_is_admin);
use Bric::Util::ApacheReq;
use Bric::App::Util ();
use Bric::Util::Fault qw(throw_forbidden);
use Bric::Util::Priv;

################################################################################
# Inheritance
################################################################################
use base qw(Exporter);

# READ, EDIT, and CREATE are re-exported from Bric::Util::Priv::Parts::Const.
our @EXPORT_OK = qw(chk_authz clear_authz_cache READ EDIT CREATE);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

################################################################################
# Function and Closure Prototypes
################################################################################

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields

################################################################################

################################################################################
# Instance Fields


################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

NONE.

=head2 Destructors

=over 4

=item $p->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

NONE.

=head2 Public Functions

=over 4

=item my $bool = chk_authz($obj, $permission, $no_redir, @gids)

Returns true if the current user has the given $permission on $obj, and sends an
error page to the browser if the current user does not have $permission on $obj.
If $no_redir is true, then the browser won't be redirected, but chk_authz() will
return undef. If any group IDs are passed in via @gids, they will be checked as
if $obj was a member of those groups.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub chk_authz {
    my ($obj, $chk_perm, $no_redir, @gids) = @_;
    my $perm;
    if (my $ref = ref $obj) {
        my $id = $obj->get_id;
        $id = '' unless defined $id;
        my $key = "_AUTHZ_:$ref:$id";
        my $r = Bric::Util::ApacheReq->instance;
        unless (defined ($perm = $r->pnotes($key))) {
            $perm = get_user_object()->what_can($obj, @gids);
            $r->pnotes($key, $perm);
        }
    } else {
        $perm = get_user_object()->what_can($obj, @gids);
    }
    return 1 if $perm >= $chk_perm && $perm != DENY;

    # If we get here, then authorization has failed.
    return undef if $no_redir;
    if (my $m = $HTML::Mason::Commands::m) {
        $m->comp(
            '/errors/403.mc',
            perm => $chk_perm,
            obj  => $obj,
        );
    } else {
        my $pname = Bric::Util::Priv->vals_href->{$perm};
        my $name = ref $obj ? $obj->get_name : '';
        my $class = Bric::App::Util::get_disp_name(ref $obj || $obj);
        throw_forbidden(
            error => qq{You have not been granted $pname access to the "$name" $class},
            maketext => [
                'You have not been granted [_1] access to the "[_2]" [_3]',
                $pname,
                $name,
                $class,
            ],
            perm => $chk_perm,
            obj  => $obj,
        );
    }
}

##############################################################################

=item clear_authz_cache( $obj )

Clears the authz cache for an object as set by a call to C<chk_authz>. The
cache is generally useful, as it lasts for the duration of a request, but
sometimes group memberships change during the lifetime of a request. In such
cases, the authorzation cache for that object should be cleared before the
next call to C<chk_authz>.

=cut

sub clear_authz_cache {
    my $obj = shift;
    my $ref = ref $obj or return;
    my $id = $obj->get_id;
    $id = '' unless defined $id;
    my $key = "_AUTHZ_:$ref:$id";
    my $r = Bric::Util::ApacheReq->instance;
    $r->pnotes( $key, undef );
    return $obj;
}

################################################################################

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

=cut

1;
__END__

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Biz::Person::User|Bric::Biz::Person::User>

=cut
