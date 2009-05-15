package Bric::Dist::Action::DTDValidate;

=head1 Name

Bric::Dist::Action::DTDValidate - Validates XML against a DTD

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Dist::Action::DTDValidate;

  my $id = 5; # Assume that this is an validate against DTD action.
  # This line will automatically instantiate the correct subclass.
  my $action = Bric::Dist::Action->lookup({ id => $id });

  # Perform the action on a list of resources.
  $action = $action->do_it($resources_href);

  # Undo is a no-op.
  $action = $action->undo_it($resources_href);

=head1 Description

This subclass of Bric::Dist::Action can be used to validate XML or XHTML
against a DTD. Note that it requires XML::LibXML, and since it downloads the
DTD over via the Internet for every resource, it can be quite slow. Set your
DOCTYPE tag to point to a a copy of the DTD on your LAN to make things faster.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::Fault qw(throw_dp isa_exception);
use Bric::App::Util qw(:browser);
use constant HAVE_LIB_XML => eval { require XML::LibXML };

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Dist::Action);

################################################################################
# Private Class variables
################################################################################
my $parser;
if (HAVE_LIB_XML) {
    $parser = XML::LibXML->new;
    $parser->validation(1);
    __PACKAGE__->_register_action('DTD Validation');
}


################################################################################
# Fields
################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({ });
}

##############################################################################
# Constructors.
##############################################################################

=head1 Class Interface

=head2 Constructors

See Bric::Dist::Action.

=head2 Class Methods

The following class method is in addition to those provided by
Bric::Dist::Action, and overrides the same method in that class.

=head3 has_more

  if (Bric::Dist::Action::DTDValidate->has_more) {
      print "It has more attributes than Bric::Dist::Action\n";
  }

Returns true to indicate that this action has more properties than does the
base class (Bric::Dist::Action).

=cut

sub has_more { return 0 }

##############################################################################

=head1 Instance Interface

=head2 Other Instance Methods

=head3 do_it

 $action = $action->do_it($job, $server_type);

Validates the resources (files) against a DTD for a given job and server type.

B<Thows:>

=over 4

=item Exception::DP

=back

=cut

sub do_it {
    my ($self, $resources) = @_;
    # Optimize the code away if we don't have XML::LibXML installed.
    if (HAVE_LIB_XML) {
        my $types = $self->get_media_href;
        foreach my $res (@$resources) {
            # Skip media types we're not interested in.
            next unless $types->{$res->get_media_type};

            # Get the resource path.
            my $path = $res->get_tmp_path || $res->get_path;

            # Get the resource URI sans output channel ID.
            (my $uri = $res->get_uri) =~ s|^/\d+||;

            # Let 'em know what we're doing.
            status_msg "Validating $uri";

            # Parse the file.
            eval { $parser->parse_file($path)->validate };

            # Handle any parsing or validation exceptions.
            handle_err($@, 'Error parsing XML', $path, $uri, 1) if $@;
        }
    }
    return $self;
}

sub handle_err {
    my ($err, $msg, $path, $uri, $clean) = @_;
    # Mason sets $SIG{__DIE__}, so we need to get the message from its
    # exception object.
    $err = $err->error if isa_exception($err);

    # Use the URI in the error payload, since that will have more  meaning for
    # the user.
    $err =~ s/$path/$uri/g;

    if ($clean) {
        # Clean up the error message of its line number and quotation marks.
        $err =~ s/^'//;
        $err =~ s/'\s+at.*$//;
    }

    # Throw the exception, but remove this function from the stack trace.
    @_ = (error => $msg, payload => $err);
    goto &throw_dp;
}

##############################################################################

1;
__END__

=pod

=head1 Author

David Wheeler <david@kineticode.com>

=head1 See Also

=over 4

=item L<Bric::Dist::Action|Bric::Dist::Action>

Base class from which Bric::Dist::Action::DTDValidate inherits much of its
interface.

=item L<Bric::Dist::ActionType|Bric::Dist::ActionType>

Defines the types of actions that the Bricolage distribution supports,
including validating resources.

=item L<Bric::Dist::ServerType|Bric::Dist::ServerType>

Defines the interface for Bricolage distribution destinations, including a
list of actions to be performed before distributing to a given destination, as
well as a list of servers for that destination.

=item L<Bric::Util::Job::Dist|Bric::Util::Job::Dist>

Manages distribution jobs, including processing all the actions required for
each destination for which resources are to be distributed.

=back

=head1 Copyright and License

Copyright (c) 2003 Kineticode, Inc. See L<Bric::License|Bric::License> for
complete license terms and conditions.

=cut
