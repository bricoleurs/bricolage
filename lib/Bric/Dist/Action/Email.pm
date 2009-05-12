package Bric::Dist::Action::Email;

=head1 Name

Bric::Dist::Action::Email - Class to email distribution resources

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Dist::Action::Email;

  my $id = 1; # Assume that this is an Email action.
  # This line will automatically instantiate the correct subclass.
  my $action = Bric::Dist::Action->lookup({ id => $id });

  # Set up the action.
  $action->set_from('me@example.com');
  $action->set_to('you@example.net');

  # Perform the action on a list of resources.
  $action = $action->do_it($resources_href);

  # Undo is a no-op.
  $action = $action->undo_it($resources_href);

=head1 Description

This subclass of Bric::Dist::Action can be used to email distribution
resources to one or more email addresses.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::Trans::Mail;
use Mail::Address;
use Bric::Util::Fault qw(throw_undef);

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Dist::Action);
__PACKAGE__->_register_action('Email');

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_attr, $parse_addrs);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant INLINE => 1;
use constant ATTACH => 2;
use constant IGNORE => 3;

################################################################################
# Fields
################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
        # Public Fields.
        from         => Bric::FIELD_READ,
        to           => Bric::FIELD_READ,
        cc           => Bric::FIELD_READ,
        bcc          => Bric::FIELD_READ,
        subject      => Bric::FIELD_READ,
        message      => Bric::FIELD_READ,
        content_type => Bric::FIELD_READ,
        handle_text  => Bric::FIELD_READ,
        handle_other => Bric::FIELD_READ,
    });
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

  if (Bric::Dist::Action::Email->has_more) {
      print "It has more attributes than Bric::Dist::Action\n";
  }

Returns true to indicate that this action has more properties than does the
base class (Bric::Dist::Action).

=cut

sub has_more { return 1 }

=head3 my_meths

  my $meths = Bric::Dist::Action::Email->my_meths
  my @meths = Bric::Dist::Action::Email->my_meths(1);
  my $meths_aref = Bric::Dist::Action::Email->my_meths(1);
  @meths = Bric::Dist::Action::Email->my_meths(0, 1);
  $meths_aref = Bric::Dist::Action::Email->my_meths(0, 1);

Returns Bric::Dist::Action::Email attribute accessor introspection data. See
L<Bric|Bric> for complete documentation of the format of that data. Returns
accessor introspection data for the following attributes:

=over

=item from

Address from whom email will be sent.

=item to

Addresses to whom email will be sent.

=item cc

Addresses to whom email will be Cc'd.

=item bcc

Addresses to whom email will be Bcc'd.

=item subject

Subject of the email to be sent.

=item content_type

The content type the email will be sent as.

=item handle_text

Determines how text resources are to be handled.

=item handle_other

Determines how non-text resources are to be handled.

=back

=cut

{

    # We don't got 'em. So get 'em!
    my ($meths, @ord);
    foreach my $meth (__PACKAGE__->SUPER::my_meths(1)) {
        $meths->{$meth->{name}} = $meth;
        push @ord, $meth->{name};
    }

    push @ord, qw(from to cc bcc subject content_type handle_text
                  handle_other), pop @ord;

    $meths->{from} = { get_meth => sub { shift->get_from(@_) },
                       get_args => [],
                       set_meth => sub { shift->set_from(@_) },
                       set_args => [],
                       name     => 'from',
                       disp     => 'From',
                       len      => 256,
                       req      => 0,
                       type     => 'short',
                       props    => { type      => 'text',
                                     length    => 64,
                                     maxlength => 256
                                   }
                     };

    $meths->{to} = { get_meth => sub { shift->get_to(@_) },
                     get_args => [],
                     set_meth => sub { shift->set_to(@_) },
                     set_args => [],
                     name     => 'to',
                     disp     => 'To',
                     len      => 256,
                     req      => 0,
                     type     => 'short',
                     props    => { type => 'textarea',
                                   cols => 40,
                                   rows => 4
                                 }
                   };

    $meths->{cc} = { get_meth => sub { shift->get_cc(@_) },
                     get_args => [],
                     set_meth => sub { shift->set_cc(@_) },
                     set_args => [],
                     name     => 'cc',
                     disp     => 'Cc',
                     len      => 256,
                     req      => 0,
                     type     => 'short',
                     props    => { type => 'textarea',
                                   cols => 40,
                                   rows => 4
                                 }
                   };

    $meths->{bcc} = { get_meth => sub { shift->get_bcc(@_) },
                      get_args => [],
                      set_meth => sub { shift->set_bcc(@_) },
                      set_args => [],
                      name     => 'bcc',
                      disp     => 'Bcc',
                      len      => 256,
                      req      => 0,
                      type     => 'short',
                      props    => { type => 'textarea',
                                    cols => 40,
                                    rows => 4
                                  }
                    };

    $meths->{subject} = { get_meth => sub { shift->get_subject(@_) },
                          get_args => [],
                          set_meth => sub { shift->set_subject(@_) },
                          set_args => [],
                          name     => 'subject',
                          disp     => 'Subject',
                          len      => 256,
                          req      => 0,
                          type     => 'short',
                          props    => { type      => 'text',
                                        length    => 64,
                                        maxlength => 256
                                      }
                        };

    $meths->{content_type} = { get_meth => sub { shift->get_content_type(@_) },
                               get_args => [],
                               set_meth => sub { shift->set_content_type(@_) },
                               set_args => [],
                               name     => 'content_type',
                               disp     => 'Content Type',
                               len      => 256,
                               req      => 0,
                               type     => 'short',
                               props    => { type      => 'text',
                                             length    => 32,
                                             maxlength => 256
                                           }
                        };

    $meths->{handle_text} = { get_meth => sub { shift->get_handle_text(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_handle_text(@_) },
                              set_args => [],
                              name     => 'handle_text',
                              disp     => 'Handle Text Files',
                              len      => 256,
                              req      => 1,
                              type     => 'short',
                  props    => { type => 'select',
                        vals => [[INLINE, 'Inline'],
                             [ATTACH, 'Attach'],
                             [IGNORE, 'Ignore']],
                      }
                            };

    $meths->{handle_other} = { get_meth => sub { shift->get_handle_other(@_) },
                               get_args => [],
                               set_meth => sub { shift->set_handle_other(@_) },
                               set_args => [],
                               name     => 'handle_other',
                               disp     => 'Handle Other Files',
                               len      => 256,
                               req      => 1,
                               type     => 'short',
                               props    => { type => 'select',
                                             vals => [[IGNORE, 'Ignore'],
                                                      [ATTACH, 'Attach']],
                                           }
                             };

    sub my_meths {
        my ($pkg, $ord, $ident) = @_;
        return if $ident;
        return !$ord ? $meths :
          wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
    }
}

##############################################################################

=head1 Instance Interface

=head2 Accessors

The following accessors are in addition to those provided by
Bric::Dist::Action.

=head3 from

  my $from = $action->get_from;
  $action = $action->set_from($from);

Get and set the address from which email will be sent. Optional. The setter
converts non-Unix line endings.

=head3 to

  my $to = $action->get_to;
  $action = $action->set_to($to);

Get and set the address or addresses to which email will be sent. Multiple
addresses should be separated by commas. Either C<to> or C<bcc> or both are
required. The setter converts non-Unix line endings.

=head3 cc

  my $cc = $action->get_cc;
  $action = $action->set_cc($cc);

Get and set the address or addresses to which email will be Cc'd. Multiple
addresses should be separated by commas. Optional. The setter converts
non-Unix line endings.

=head3 bcc

  my $bcc = $action->get_bcc;
  $action = $action->set_bcc($bcc);

Get and set the address or addresses to which email will be Bcc'd. Multiple
addresses should be separated by commas. Either C<to> or C<bcc> or both are
required. The setter converts non-Unix line endings.

=head3 subject

  my $subject = $action->get_subject;
  $action = $action->set_subject($subject);

Get and set the subject to be used when emails are sent. Optional. The setter
converts non-Unix line endings.

=head3 content_type

  my $content_type = $action->get_content_type;
  $action = $action->set_content_type($content_type);

Get and set the content type to be used when emails are sent. If not
specified, Bric::Dist::Action::Email will use the media type of the first text
file it uses for the email message. The setter converts non-Unix line endings.

=head3 handle_text

  my $handle_text = $action->get_handle_text;
  $action = $action->set_handle_text($handle_text);

Get and set the constant value that determines how text resources are
handled. All files with a media type starting with "text/" are considered text
files. The possible values for this attribute are available via the constants
defined for this class:

=over 4

=item C<INLINE>

Concatenate the contents of all text resources and include the resulting
string inlinex as the email message. The default value.

=item C<ATTACH>

Attach all text files to the email message.

=item C<IGNORE>

Ignore text resources.

=back

The setter converts non-Unix line endings.

=head3 handle_other

  my $handle_other = $action->get_handle_other;
  $action = $action->set_handle_other($handle_other);

Get and set the contant value that deterimines how non-text resources, such as
image files, are handled. All files with a media type that does not start with
"text/" are considered non-text files. The possible values for this attribute
are available via the constants defined for this class:

=over 4

=item C<IGNORE>

Ignore text resources. The default value.

=item C<ATTACH>

Attach all text files to the email message.

=back

The setter converts non-Unix line endings.

=cut

foreach my $attr (qw(from to cc bcc subject content_type handle_text
                     handle_other)) {
    no strict 'refs';
    *{"get_$attr"} = sub { shift->$get_attr($attr) };
    *{"set_$attr"} = sub { shift->$get_attr($attr, @_) };
}

##############################################################################

=head2 Other Instance Methods

=head3 do_it

 $action = $action->do_it($job, $server_type);

Emails the resources (files) for a given job and server type.

B<Thows:>

=over 4

=item Exception::DA

=back

=cut

sub do_it {
    my ($self, $resources) = @_;
    my $handle_txt = $self->$get_attr('handle_text');
    my $handle_oth = $self->$get_attr('handle_other');
    my $content_type = $self->$get_attr('content_type');
    my (@attach);
    my $msg = '';

    foreach my $res (@$resources) {
        if ($res->get_media_type =~ /^text\//) {
            # It's a text file. Grab the content type if it hasn't been set
            # explicitly. First one in wins.
            $content_type ||= $res->get_media_type;
            if ($handle_txt == INLINE) {
                # Make it part of the message.
                $msg .= $res->get_contents;
            } elsif ($handle_txt == ATTACH) {
                # We'll attach it.
                push @attach, $res;
            } else {
                # Ignore it.
                next;
            }
        } else {
            # It's something other than a text file.
            push @attach, $res if $handle_oth == ATTACH;
        }
    }

    # Just bail if there's nothing to send.
    return $self unless $msg || @attach;
    my $mailer = Bric::Util::Trans::Mail->new({
        to           => [ $self->$get_attr('to') ],
        from         => $self->$get_attr('from'),
        cc           => [ $self->$get_attr('cc') ],
        bcc          => [ $self->$get_attr('bcc') ],
        content_type => $content_type,
        subject      => $self->$get_attr('subject'),
        message      => $msg,
        resources    => \@attach,
    });

    $mailer->send;
    return $self;
}

################################################################################

=head3 save

  $action = $action->save;

Saves the action for the server type and job, along with all of its attributes.

B<Thows:>

=over 4

=item Exception::DA

=back

=cut

sub save {
    my $self = shift;

    # Make sure we have one or more addresses to send it to. Might want
    # to add validation here.
    throw_undef
      error    => "Must provide either a 'To' address or a 'Bcc' address'",
      maketext => ["Must provide either a 'To' address or a 'Bcc' address'"]
      unless $self->$get_attr('to') or $self->$get_attr('bcc');

    # Carry on.
    $self->SUPER::save;
}

##############################################################################

=begin private

=head2 Private Methods

=head3 _rebless

  $action->_rebless;

Reblesses the action object into the Bric::Dist::Action::Email class, and sets
default values for the C<handle_text> and C<handle_other> attributes.

=cut

sub _rebless {
    my $class = shift;
    my $self = $class->SUPER::_rebless(shift);
    $self->$get_attr('handle_text', INLINE);
    return $self->$get_attr('handle_other', IGNORE);
}

=head3 $get_attr

  $action->$get_attr($key, $value);

Gets or sets attribute values. Used internally by the accessor methods.

=cut

$get_attr = sub {
    my ($self, $key) = (shift, shift);
    my $attr = $self->_get_attr;
    if (@_) {
        my $val = shift;
        $val =~ s/\r\n?/\n/g if defined $val;
        $attr->set_attr({
            name     => $key,
            subsys   => 'EmailAction',
            sql_type => 'blob',
            value    => $val,
        });
    } else {
        return $attr->get_attr({
            name   => $key,
            subsys => 'EmailAction',
        });
    }
    return $self;
};

##############################################################################

1;
__END__

=pod

=end private

=head1 Author

David Wheeler <david@kineticode.com>

=head1 See Also

=over 4

=item L<Bric::Dist::Action|Bric::Dist::Action>

Base class from which Bric::Dist::Action::Email inherits much of its
interface.

=item L<Bric::Dist::ActionType|Bric::Dist::ActionType>

Defines the types of actions that the Bricolage distribution supports,
including emailing resources.

=item L<Bric::Dist::ServerType|Bric::Dist::ServerType>

Defines the interface for Bricolage distribution destinations, including a
list of actions to be performed before distributing to a given destination, as
well as a list of servers for that destination.

=item L<Bric::Util::Job::Dist|Bric::Util::Job::Dist>

Manages distribution jobs, including processing all the actions required for
each destination for which resources are to be distributed.

=back

=cut
