package Bric::Dist::Action::Mover;

=head1 NAME

Bric::Dist::Action::Mover - Actions that actually move resources.

=head1 VERSION

$Revision: 1.3 $

=cut

# Grab the Version Number.
our $VERSION = substr(q$Revision: 1.3 $, 10, -1);

=head1 DATE

$Date: 2001-10-11 00:34:54 $

=head1 SYNOPSIS

  use Bric::Dist::Action::Mover;

=head1 DESCRIPTION



=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::App::Event qw(log_event);
use Bric::Util::Fault::Exception::GEN;

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Dist::Action);

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
my $gen = 'Bric::Util::Fault::Exception::GEN';

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

=head1 INTERFACE

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

These methods documented are in addition to those inherited from
Bric::Dist::Action.

=over 4

=item $act->undo_it($job, $resources, $server_type)

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
    eval "require $class";
    die $gen->new({ msg => "Unable to load $class mover class.",
		    payload => $@ }) if $@;
    $class->put_res($res, $st);
    # Log the move.
    my $move_meth = $st->get_move_method;
    grep { log_event('resource_move', $_, { Via => $move_meth } ) }
      @$res;
    return $self;
}

################################################################################

=item $act->undo_it($job, $resources, $server_type)

Undes $action via the method specified for the Bric::Dist::ServerType of which
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
    eval "require $class";
    die $gen->new({ msg => "Unable to load $class mover class.",
		    payload => $@ }) if $@;
    $class->del_res($res, $st);
    # Log the remove.
    my $move_meth = $st->get_move_method;
    grep { log_event('resource_remove', $_, { Via => $move_meth } ) }
      @$res;
    return $self;
}

################################################################################

=back 4

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

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

perl(1),
Bric (2),
Bric::Dist::Action(3)

=cut
