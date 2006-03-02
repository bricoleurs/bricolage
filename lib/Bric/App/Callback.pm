package Bric::App::Callback;

use base qw(Params::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'Callback';

use strict;

use Bric::App::Cache;
use Bric::App::Util qw(get_pref);
use Bric::Util::Language;

my $cache = Bric::App::Cache->new();

sub lang { Bric::Util::Language->get_handle(get_pref('Language')) }
sub cache { $cache }
sub set_redirect { shift->redirect(shift, 1) }

1;

=head1 NAME

Bric::App::Callback - The Bricolage callback base class

=head1 SYNOPSIS

  use Bric::App::Callback::Foo;
  use Bric::App::Callback::Bar;

=head1 DESCRIPTION

This is the base class from which all Bricolage callback classes inherit.
Callback classes are created by simply subclassing Bric::App::Callback,
registering themselves, and then creating callback methods using the
C<Callback> attribute on methods:

  sub save : Callback {
      my $cb = shift;
      # ...do the saving.
  }

See the subclasses for examples.

=head1 CLASS INTERFACE

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

=head1 AUTHOR

Scott Lanning <lannings@who.int>

=head1 SEE ALSO

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

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2004 World Health Organization and Kineticode, Inc. See
L<Bric::License|Bric::License> for complete license terms and conditions.

=cut
