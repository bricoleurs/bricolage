package Bric::App::Callback;

use strict;
use base qw(Params::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'Callback';
use HTML::Entities;
use Bric::App::Cache;
use Bric::App::Util qw(get_pref add_msg);
use Bric::Util::ApacheConst qw(HTTP_CONFLICT HTTP_FORBIDDEN);
use Bric::Util::DBI qw(begin rollback);
use Bric::Util::Language;

my $cache = Bric::App::Cache->new();

sub lang { Bric::Util::Language->get_handle(get_pref('Language')) }
sub cache { $cache }
sub set_redirect { shift->redirect(shift, 1) }

sub add_message {
    shift;
    add_msg(@_);
}

sub raise_status {
    my ($self, $status) = (shift, shift);
    my $r = $self->apache_req or return $self->add_message(@_);

    # If it's not an Ajax request, it's just a message.
    return $self->add_message(@_)
        if ($r->headers_in->{'X-Requested-With'} || '') ne 'XMLHttpRequest';

    # Abort the database transaction.
    rollback(1);
    begin(1);

    # Prep the error message.
    my $txt = Bric::Util::Language->instance->maketext(@_);
    if ($txt =~ /(.*)<span class="l10n">(.*)<\/span>(.*)/) {
        $txt = encode_entities($1) . '<span class="l10n">'
          . encode_entities($2) . '</span>' . encode_entities($3);
    } else {
        $txt = encode_entities($txt);
    }

    # Send the status to the browser and abort.
    $r->status($status);
    $r->print(qq{<div class="errorMsg">$txt</div>});
    $self->abort;
}

sub raise_conflict  { shift->raise_status( HTTP_CONFLICT,  @_ ) }
sub raise_forbidden { shift->raise_status( HTTP_FORBIDDEN, @_ ) }

1;

=head1 Name

Bric::App::Callback - The Bricolage callback base class

=head1 Synopsis

  use Bric::App::Callback::Foo;
  use Bric::App::Callback::Bar;

=head1 Description

This is the base class from which all Bricolage callback classes inherit.
Callback classes are created by simply subclassing Bric::App::Callback,
registering themselves, and then creating callback methods using the
C<Callback> attribute on methods:

  sub save : Callback {
      my $cb = shift;
      # ...do the saving.
  }

See the subclasses for examples.

=head1 Class Interface

=head2 Class Methods

=head3 lang

  my $lang = Bric::App::Callback->lang;
  $lang = $cb->lang;

Returns the currently active L<Bric::Util::Language|Bric::Util::Language>
localization object. Can also be used as an instance method.

=head3 cache

  my $cache = Bric::App::Callback->cache;
  $cache = $cb->cache;

Returns the currently active L<Bric::App::Cache|Bric::App::Cache> object. Can
also be used as an instance method.

=head2 Instance Methods

=head3 set_redirect

  $cb->set_redirect($url);

Sets the URL to redirect to after all callbacks have finished executing, but
before the request is turned over to Mason for processing.

=head3 add_message

  $cb->add_message( 'Template "[_1]" deployed.', $template->get_uri );

Add a status message to be displayed to the user. Pass in a list of values
suitable for passing through C<< $lang->maketext >>.

=head3 raise_status

  $cb->raise_status( HTTP_FORBIDDEN, 'Ya canna do that, captain!' );

In a non-Ajax request, this method simply passes the error message on to
C<Bric::App::Util::add_msg()>. In an Ajax request, however, it rolls back the
current transaction sends the error message to the browser, along with the
status, and aborts the request. This is useful for situations where a
requested action cannot be carried out for one reason or another, such as the
user not having the appropriate permission.

=head3 raise_conflict

  $cb->raise_conflict( q{You cannot move a story from a desk it's not on.} );

A shortcut for calling C<raise_status()> and passing C<HTTP_CONFLICT> as the
furst argument.

=head3 raise_forbidden

  $cb->raise_forbidden( q{I can't let you do that, Dave.} );

A shortcut for calling C<raise_status()> and passing C<HTTP_FORBIDDEN> as the
furst argument.

=head1 Author

Scott Lanning <lannings@who.int>

=head1 See Also

=over 4

=item L<Params::CallbackRequest|Params::CallbackRequest>

This module provides a generalized parameter triggering callback architecture.
Bric::App::Callback inherits from its Params::Callback class.

=item L<MasonX::Interp::WithCallbacks|MasonX::Interp::WithCallbacks>

This module provides the interface for adding callback processing to Mason
requests.

=item L<Bricolage::App::Handler|Bricolage::App::Handler>

This module handles all Bricolage Apache requests, and loads all of the
callback modules.

=back

=head1 Copyright and License

Copyright (c) 2003-2004 World Health Organization and Kineticode, Inc. See
L<Bric::License|Bric::License> for complete license terms and conditions.

=cut
