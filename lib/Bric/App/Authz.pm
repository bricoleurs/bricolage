package Bric::App::Authz;

=head1 NAME

Bric::App::Authz - Exports functions for checking user authorization.

=head1 VERSION

$Revision: 1.2.2.2 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.2.2.2 $ )[-1];

=head1 DATE

$Date: 2001-11-06 23:18:32 $

=head1 SYNOPSIS

  use Bric::App::Authz qw(:all);

  chk_authz($obj, READ);
  # If we get here, we can read $obj.

  chk_authz($obj, EDIT);
  # If we get here, we can edit $obj.

  chk_authz($obj, CREATE);
  # If we get here, we can create $obj.

=head1 DESCRIPTION

This package exporst the function chk_authz(), which will return true if the
current user has permission to perform a given activity to $obj, and redirect to
an error page if the user does not have the permission. The permissions
available are also exported. They are READ, EDIT, and CREATE. CREATE includes
READ and CREATE permissions while EDIT includes READ persmision.

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
use Bric::App::ReqCache;

################################################################################
# Inheritance
################################################################################
use base qw(Exporter);

# READ, EDIT, and CREATE are re-exported from Bric::Util::Priv::Parts::Const.
our @EXPORT_OK = qw(chk_authz READ EDIT CREATE);
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
my $rc;

################################################################################

################################################################################
# Instance Fields


################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

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

B<Notes:> Will use the Bric::Biz::Person::User object's can_do() method internally
once Permissions have been implemented. Meanwhile, it ignores $obj and
$permission and just returns true if the current user is a member of the
Administrators group.

=cut

sub chk_authz {
    my ($obj, $chk_perm, $no_redir, @gids) = @_;
    my $perm;
    if (my $ref = ref $obj) {
	$rc ||= Bric::App::ReqCache->new;
	my $id = $obj->get_id;
	$id = '' unless defined $id;
	my $key = "_AUTHZ_:$ref:$id";
	unless (defined ($perm = $rc->get($key))) {
	    $perm = get_user_object()->what_can($obj, @gids);
	    $rc->set($key, $perm);
	}
    } else {
	$perm = get_user_object()->what_can($obj, @gids);
    }

    return 1 if $perm >= $chk_perm && $perm != DENY;

    # If we get here, then authorization has failed.
    return undef if $no_redir;
    $HTML::Mason::Commands::m->comp('/errors/403.mc',
                                    perm => $chk_perm,
                                    obj => $obj);
}

################################################################################

=back

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

=cut

1;
__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

perl(1),
Bric (2),
Bric::Biz::Person::User

=cut
