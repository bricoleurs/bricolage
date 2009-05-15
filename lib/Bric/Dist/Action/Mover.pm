package Bric::Dist::Action::Mover;

=head1 Name

Bric::Dist::Action::Mover - Actions that actually move resources.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Dist::Action::Mover;

=head1 Description

This subclass of Bric::Dist::Action handles distribution. All ServerTypes must
have a mover_class selected, and a "Move" action specified. When Bricolage
triggers the Move action, this class determines what the mover method is, and
invokes the put_res() (or del_res()) method of the appropriate mover class. See
below for information on how to create your own mover.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::App::Event qw(log_event);
use Bric::Util::Fault qw(throw_ap);
use Bric::Util::Trans::FS;
use Bric::Util::Trans::FTP;
use Bric::Config qw(:dist);
if (ENABLE_SFTP_MOVER) {
    require Bric::Util::Trans::SFTP;
}

if (ENABLE_WEBDAV_MOVER) {
    require Bric::Util::Trans::WebDAV;
}

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Dist::Action);
__PACKAGE__->_register_action('Move');

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
BEGIN {
    Bric::register_fields({
             # Public Fields

             # Private Fields
            });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

Inherited from Bric::Dist::Action.

=head2 Destructors

=over 4

=item $mover->DESTROY

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

=head2 Public Instance Methods

The methods documented here are in addition to those inherited from
Bric::Dist::Action.

=over 4

=item $act->do_it($job, $resources, $server_type)

Executes $action via the method specified for the Bric::Dist::ServerType of which
this action is a part.

B<Throws:>

=over 4

=item *

Unable to load mover class.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub do_it {
    my ($self, $res, $st) = @_;
    my $class = $st->_get_mover_class;

    unless (ENABLE_SFTP_MOVER or $class !~ /::SFTP$/) {
        throw_ap(error => "Output channel is associated with SFTP " .
                 "but SFTP Mover is disabled.");
    }

    unless (ENABLE_WEBDAV_MOVER or $class !~ /::WebDAV$/) {
        throw_ap(error => "Output channel is associated with WebDAV" .
                   "but WebDAV Mover is disabled.");
    }

    $class->put_res($res, $st);
    # Log the move.
    my $move_meth = $st->get_move_method;
    grep { log_event('resource_move', $_, { Via => $move_meth } ) }
      @$res;
    return $self;
}

################################################################################

=item $act->undo_it($job, $resources, $server_type)

Undoes $action via the method specified for the Bric::Dist::ServerType of which
this action is a part.

B<Throws:>

=over 4

=item *

Unable to load mover class.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub undo_it {
    my ($self, $res, $st) = @_;
    my $class = $st->_get_mover_class;
    $class->del_res($res, $st);
    # Log the remove.
    my $move_meth = $st->get_move_method;
    grep { log_event('resource_remove', $_, { Via => $move_meth } ) }
      @$res;
    return $self;
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

=head2 How to Add New Distribution Movers.

If you're interested in adding new methods of distribution, or movers, to
Bricolage, here's how to do it.

=over 4

=item *

Create a mover class in Bric::Util::Trans, e.g., Bric::Util::Trans::MyMover. Use
Bric::Util::Trans::FS and Bric::Util::Trans::FTP as examples.

=item *

In your new mover class, implement a put_res() method and a del_res() method.
These methods take an array ref of Bric::Dist::Resource objects to be moved and
a Bric::Dist::ServerType object as arguments. Use the Bric::Dist::Server objects
in the Brci::Dist::ServerType object to put (or delete, in the case of del_res)
the files represented by each of the resource objects. Again, see Use
Bric::Util::Trans::FS and Bric::Util::Trans::FTP for examples.

=item *

Add an INSERT statement to F<lib/Bric/Util/Class.val> to create a new
representation for your mover class. Be sure to set the value of the
"distributor" column to 1. Use the records for Bric::Util::Trans::FS and
Bric::Util::Trans::FTP as examples.

=item *

Add an upgrade script to inst/upgrade/<version>, where the "version" is the
version number of the Bricolage release in which your transport will first be
included. This script is necessary for users who are upgrading existing versions
of Bricolage. Use inst/upgrade/1.3.1/mover.pl as an example.

=item *

Add C<use Bric::Util::Trans::MyMover;> to Bric::Dist::Action::Mover, so that your
mover loads on startup.

=item *

Update the class table of your Bricolage database, and then restart your
Bricolage server. Look at a Destination, and make sure that your mover is
listed in the "Move Method" select list.

=item *

Test your mover thoroughly. Make sure that it successfully distributes files and
deletes files.

=back

And that's all there is to it! Good luck!

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Dist::Action|Bric::Dist::Action>

=cut
