package Bric::App::Session;
###############################################################################

=head1 NAME

Bric::App::Session - A class to handle user sessions

=head1 VERSION

$Revision: 1.17 $

=cut

our $VERSION = (qw$Revision: 1.17 $ )[-1];

=head1 DATE

$Date: 2002-12-06 07:43:55 $

=head1 SYNOPSIS

  use Bric::App::Session;

  #- Methods called from the apache perl handler -#

  setup_user_session($r);

  sync_user_session();

  handle_callbacks($interp);

  #- Methods called from widgets -#

  [$new_state_name, $new_state_data] = init_state($widget, $state, $data);

  $state_name = state_name($widget, $name);

  $state_data = state_data($widget, ($data_hash || $name, $value));

  [$state_name, $state_data] = state($widget, $state_name, $state_data);

=head1 DESCRIPTION

This module provides all the necessary functions for maintaining state within
widgets. This includes setting a global state variable $session as well as
accessor methods for setting the state name of a widget and state data of a
widget.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies

use strict;

#--------------------------------------#
# Programmatic Dependencies
use Bric::Util::Fault::Exception::GEN;
use Bric::Util::Fault::Exception::AP;
use Bric::Config qw(:sys_user :admin :temp :cookies);
use Apache::Session::File;
use Bric::Util::Trans::FS;

use File::Path qw(mkpath);
use Apache::Cookie;

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw( Exporter );

our @EXPORT_OK = qw(clear_state
                    init_state
                    init_state_name
                    init_state_data
                    reset_state
                    get_state
                    get_state_data
                    get_state_name
                    get_user_login
                    get_user_id
                    set_state
                    set_state_data
                    set_state_name
                    set_user
                    get_user_login
                    get_user_id
                    get_user_object
                    user_is_admin);

our %EXPORT_TAGS = (state => [qw(clear_state
                                 init_state
                                 init_state_name
                                 init_state_data
                                 reset_state
                                 get_state
                                 get_state_data
                                 get_state_name
                                 set_state
                                 set_state_data
                                 set_state_name)],
                    user => [qw(set_user
                                user_is_admin
                                get_user_login
                                get_user_id
                                get_user_object)],
                   );

#=============================================================================#
# Function Prototypes                  #
#======================================#



#==============================================================================#
# Constants                            #
#======================================#

use constant MAX_HISTORY => 10;

use constant SESS_DIR =>
  Bric::Util::Trans::FS->cat_dir(TEMP_DIR, 'bricolage', 'session');

use constant LOCK_DIR =>
  Bric::Util::Trans::FS->cat_dir(TEMP_DIR, 'bricolage', 'lock');

use constant OPTS     => { Directory     => SESS_DIR,
                           LockDirectory => LOCK_DIR,
                           Transaction   => 1 };

# Whether to cache the user object or not.
#use constant CACHE_USER  => 1;

# Create the session and lock directories if they do not exist.
unless (-d SESS_DIR && -d LOCK_DIR) {
    my $tmp_dir = Bric::Util::Trans::FS->cat_dir(TEMP_DIR, 'bricolage');
    mkpath($tmp_dir, 0, 0777);
    mkpath(SESS_DIR, 0, 0777);
    mkpath(LOCK_DIR, 0, 0777);
    chown SYS_USER, SYS_GROUP, $tmp_dir, SESS_DIR, LOCK_DIR;
}

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields
{
    package HTML::Mason::Commands;
    # The persistent user session variable.
    our %session;
}

#--------------------------------------#
# Private Class Fields

my $ap = 'Bric::Util::Fault::Exception::AP';
my $gen = 'Bric::Util::Fault::Exception::GEN';
my $secret = 'd0 a3rQ#R9JR34$(#ffE*38fhj3#$98jfeER9\'a35T(fgn[*;|ife=ef*R#,{%@';

#------------------------------------------------------------------------------#

=head1 INTERFACE

=head2 Functions

=item setup_user_session($r)

This function takes an Apache request object and sets up the persistent user 
session hash.  This hash is tied to an Apache::Session::File object.

B<Throws:>

=over

=item *

Difficulties tie'ing the session hash.

=back

B<Side Effects:>

=over

=item *

Sends a cookie to the users browser.

=item *

Creates a session file on the file system.

=item *

Sets global variable '%session' in package 'HTML::Mason::Commands'.

=back

B<Notes:>

NONE

=cut

sub setup_user_session {
    my ($r, $new) = @_;
    return if !$new && tied %HTML::Mason::Commands::session;
    # Grab the existing cookie.
    my %cookies = Apache::Cookie->fetch;
    my $cookie = $cookies{&COOKIE} unless $new;

    # Try to tie the session variable to a session file.
    eval { tie %HTML::Mason::Commands::session,
             'Apache::Session::File', ($cookie ? $cookie->value : undef), OPTS; };

    # Test to see if the tie succeeded.
    if ($@) {
        # Tie did not succeed, but we can recover if it was this error...
        if ($@ =~ /^Object does not exist in the data store/) {
            tie %HTML::Mason::Commands::session,
                'Apache::Session::File', undef, OPTS;
            undef $cookie;
        }
        # We can't recover so throw an exception.
        else {
            die $gen->new({ msg => "Difficulties tie'ing the session hash to " .
                            "file '".OPTS->{Directory}."'\n", payload => $@});
        }
    }

    # Create a new cookie if one doesn't exist.
    unless ($cookie) {
        my $cookie = Apache::Cookie->new($r,
                         -name    => COOKIE,
                         -value   => $HTML::Mason::Commands::session{_session_id},
                         -path    => '/');

        # Send this cookie out with the headers.
        $cookie->bake;
    }
}

#------------------------------------------------------------------------------#

=item sync_user_session()

Synchronizes changes to the user session back to the file system.

B<Throws:>

=over 4

=item *

Unable to synchronize user session.

=back

B<Side Effects:>

=over 4

=item *

Unties the global variable %HTML::Mason::Commands::session.

=back

B<Notes:>

NONE

=cut

sub sync_user_session {
    untie %HTML::Mason::Commands::session ||
      die $gen->new({ msg => 'Unable to synchronize user session.',
                      payload => $@ });
}

=item expire_session()

Expires the user session, deleting it from the disk.

B<Throws:>

=over 4

=item *

Unable to expire user session.

=back

B<Side Effects:>

=over 4

=item *

Deletes the global %HTML::Mason::Commands::session session object.

=back

B<Notes:>

NONE

=cut

sub expire_session {
    my $r = shift;
    eval { tied(%HTML::Mason::Commands::session)->delete };
    die $gen->new({ msg => 'Unable to expire user session.',
                    payload => $@ }) if $@;

    # Expire the session cookie.
    my $cookie = Apache::Cookie->new($r,
                     -name    => COOKIE,
                     -expires => "-1d",
                     -value   => 'Expired',
                     -path    => '/');

    # Send this cookie out with the headers.
    $cookie->bake;
    return 1;
}

#------------------------------------------------------------------------------#

=item handle_callbacks($interp, $parameter_hash)

This function takes an HTML::Mason::Request ($m) object and an anonymous hash of
GET and/or POST data as its arguments. It scans anonymous hash looking for
specially marked up field names. If it finds them, it executes the proper Mason
callback element. Ideally, it should be called from an autohandler, so that it
executes before any dhandlers:

  <%perl>;
  unless ($ARGS{__CB_DONE}) {
      # Setup the global session variable.
      Bric::App::Session::setup_user_session($r);

      # Execute an callbacks set for this request.
      Bric::App::Session::handle_callbacks($m, \%ARGS);
  }
  $m->call_next(%ARGS);
  </%perl>

The handle_callbacks() function adds the __CB_DONE key to %ARGS so that when it
calls callback element, the autohandler can avoid calling handle_callbacks()
again.

B<Throws:>

=over 4

=item *

Error handling callbacks.

=back

B<Side Effects:> Executes one or more callback mason elements.

B<Notes:> The format for field names that will be handled by this function is:

  <widget_name>|<field_name>_cb

If any request sends a field element of this format, this callback function will
look in the widget directory, within the folder named <widget_name> and look for
a mason element called 'callback.mc'. This element will be called with the
widget name, the field name that cause the callback and the query string (and/or
form field) parameters:

  $m->comp($callback_comp, widget => $widget_name,
           field => $field_name, param => $parameter_hash);

=cut

sub handle_callbacks {
    my ($m, $param) = @_;
    my $w_dir = $HTML::Mason::Commands::widget_dir;
    my (@delay_cb, @priority);

    eval {
        foreach my $field (keys %$param) {
            # Strip off the '.x' that an input type="image" tag creates. Yes,
            # the RegEx is actually faster than using substr(), even when the
            # $field doesn't have '.x' on its end -- I benchmarked it!
            (my $key = $field) =~ s/\.x$//;
            # Determine whether this is a priority callback or a regular one.
            my $ext = substr($key, -3);

            # Delay execution of regular callbacks.
            if ($ext eq '_cb') {
                if ($key ne $field) {
                    # Some browsers (notably Mozilla) will submit $key as
                    # well as $key.x and $key.y. So skip it if that's true
                    # here.
                    next if exists $param->{$key};
                    # Otherwise, add the unadorned key to $param.
                    $param->{$key} = $param->{$field}
                }

                # Skip callbacks that aren't given a value.
                next if $param->{$key} eq '';

                my $widget = substr($key, 0, index($key, '|'));
                my $cb = "/$w_dir/$widget/callback.mc";

                if ($m->comp_exists($cb)) {
                    # Save the callbacks as sub refs in an array to call later
                    push @delay_cb, sub {
                        $m->comp($cb, 'widget' => $widget, 'field'  => $key,
                                 'param'  => $param, __CB_DONE => 1);
                    };
                }
            }
            # Call priority callbacks first.
            elsif ($ext eq '_pc' || $ext eq '_p0') {
                my $stack = $ext eq '_pc' ? \@delay_cb : \@priority;
                $param->{$key} = $param->{$field} unless $key eq $field;
                # Skip callbacks that aren't given a value.
                next if $param->{$key} eq '';

                my $widget = substr($key, 0, index($key, '|'));
                my $cb = "/$w_dir/$widget/callback.mc";
                if ($m->comp_exists($cb)) {
                    # Save these callbacks, first - ensures that all the '_cb.x'
                    # fields will be properly named '_cb' instead.
                    unshift @$stack, sub {
                        $m->comp($cb, 'widget' => $widget, 'field'  => $key,
                                 'param'  => $param, __CB_DONE => 1);
                    };
                }
            }
        }

        # Execute the callbacks.
        foreach my $cb (@priority, @delay_cb) { &$cb }
    };

    # Do error processing, if necessary.
    if (my $err = $@) {
        die $err if ref $err;
        # Create an exception object unless we already have one.
        die $ap->new({msg => "Error handling callbacks.", payload => $err});
    }
    return 1;
}

#------------------------------------------------------------------------------#

=item [$new_state_name, $new_state_data] = init_state($widget, $state, $data)

=item $cur_name = init_state_name($widget, $name);

=item $cur_val  = init_state_data($widget, $name, $value);

=item $key_val  = reset_state($widget, $reset_key);

If a widget has not yet been called and this function is called, it will set 
some default values for that widgets state name and state data.

B<Throws:>

NONE

B<Side Effects:>

=over 4

=item *

Sets the global variable %HTML::Mason::Commands::session

=back

B<Notes:>

NONE

=cut

sub init_state {
    my ($widget, $state, $data) = @_;

    return if exists $HTML::Mason::Commands::session{$widget};

    set_state($widget, $state, $data);
}

sub init_state_name {
    my ($widget, $name) = @_;

    unless (defined get_state_name($widget)) {
        return set_state_name($widget, $name);
    }

    return;
}

sub init_state_data {
    my ($widget, $name, $value) = @_;

    unless (defined get_state_data($widget, $name)) {
        return set_state_data($widget, $name, $value);
    }

    return;
}

sub reset_state {
    my ($widget, $key) = @_;

    $key = '' unless defined $key;
    my $reset = get_state_data($widget, '_reset_key') || '';
    if ($key ne $reset) {
        return set_state($widget, undef, {'_reset_key' => $key});
    }

    return;
}

#------------------------------------------------------------------------------#

=item $state_name = set_state_name($widget, $name)

=item $state_name = get_state_name($widget)

Set or get the current widget state name.  A state name cannot be set to undef
since it is bad style to rely on a state that you do not set explicitly.  If you
want to clear the state entirely, use clear_state.

B<Throws:>

NONE

B<Side Effects:>

=over 4

=item *

Sets the global variable %HTML::Mason::Commands::session

=back

B<Notes:>

NONE

=cut

sub set_state_name {
    my ($widget, $name) = @_;

    # Don't do anything if a widget name is not passed.
    return unless $widget and $name;

    # Load this in to a temporary hash first to make sure the tie funcs are hit.
    my $s = $HTML::Mason::Commands::session{$widget};
    $s->{'state'} = $name;

    $HTML::Mason::Commands::session{$widget} = $s;

    return $name;
}

sub get_state_name {
    my ($widget) = @_;

    # Don't do anything if a widget name is not passed.
    return unless $widget;

    # Don't do anything if there is not data for this widget.
    return unless defined $HTML::Mason::Commands::session{$widget};

    return $HTML::Mason::Commands::session{$widget}->{'state'};
}

#------------------------------------------------------------------------------#

=item $state_data = set_state_data($widget, ($data_hash || $name, $value))

=item $state_data = get_state_data($widget, $name)

Get or set the state data.  The set function takes either a hash or a key/value.
Given a hash the set function will overwrite the state data.  Given a key/value
pair, it will set that key in the state data to that value.

The get function will return the whole state data hash if given just a widget.
If passed a name it will return the value for the state data with that name.

B<Throws:>

NONE

B<Side Effects:>

=over 4

=item *

Sets the global variable %HTML::Mason::Commands::session

=back

B<Notes:>

NONE

=cut

sub set_state_data {
    my ($widget, $data, $value) = @_;

    return unless $widget and $data;

    if (ref $data) {
        my $s = $HTML::Mason::Commands::session{$widget};
        $s->{'data'} = $data;

        $HTML::Mason::Commands::session{$widget} = $s;

        return $HTML::Mason::Commands::session{$widget}->{'data'};
    } else {
        my $s = $HTML::Mason::Commands::session{$widget};
        $s->{'data'}->{$data} = $value;

        $HTML::Mason::Commands::session{$widget} = $s;

        return $HTML::Mason::Commands::session{$widget}->{'data'}->{$data};
    }
}

sub get_state_data {
    my ($widget, $key) = @_;

    return unless $widget;

    if (defined $key) {
        return $HTML::Mason::Commands::session{$widget}->{'data'}->{$key};
    } else {
        return $HTML::Mason::Commands::session{$widget}->{'data'};
    }
}

#------------------------------------------------------------------------------#

=item [$state_name, $state_data] = set_state($widget, $state_name, $state_data)

=item [$state_name, $state_data] = get_state($widget)

The set function takes a widget name, $widget, a state name, $state_name, and a 
hash ref, $state_data,  containing state data.  Both $state_name and $state_data
are optional.  If $state_name is undef, the state name will not be set, but if 
it does have a value it will be used to update the widget $widget state name.
The same holds true for $state_data;  undef will leave the state data untouched
while a hash value will be used to overwrite the state data.

The get function returns both the state name and the state data..

B<Throws:>

NONE

B<Side Effects:>

=over 4

=item *

Sets the global variable %HTML::Mason::Commands::session

=back

B<Notes:>

NONE

=cut

sub set_state {
    my ($widget, $state, $data) = @_;

    return unless $widget;

    set_state_name($widget, $state) if $state;

    set_state_data($widget, $data) if $data;

    return [$HTML::Mason::Commands::session{$widget}->{'state'},
            $HTML::Mason::Commands::session{$widget}->{'data'}];
}

sub get_state {
    my ($widget) = @_;

    return unless $widget;

    return [$HTML::Mason::Commands::session{$widget}->{'state'},
            $HTML::Mason::Commands::session{$widget}->{'data'}];
}

#------------------------------------------------------------------------------#

=item clear_state($widget)

Completely clears the state information for the given widget.

B<Throws:>

NONE

B<Side Effects:>

=over 4

=item *

Sets the global variable %HTML::Mason::Commands::session

=back

B<Notes:>

NONE

=cut

sub clear_state {
    my ($widget) = @_;

    delete $HTML::Mason::Commands::session{$widget};
}

#------------------------------------------------------------------------------#

=item (0 || 1) = set_user($user);

=item ($login || undef) = get_user_login;

=item ($uid || undef) = get_user_id;

=item ($user || undef) = get_user_object;

Get/set logged in user information.

B<Throws:> NONE

B<Side Effects:>

=over 4

=item *

Uses Bric::App::Util::get_pref() and Bric::App::Util::set_pref().

=back

B<Notes:> NONE

=cut

sub set_user {
    my ($r, $user) = @_;
    my $uid = $user->get_id;
    my $curr_id =  get_user_id();
    # Create a new session if the user has changed.
    setup_user_session($r, 1) if defined $curr_id && $uid != $curr_id;
    my $bric_user = { login  => $user->get_login,
                    id     => $uid,
                    object => $user
                  };
    $HTML::Mason::Commands::session{_bric_user} = $bric_user;
    return 1;
}

sub get_user_login { $HTML::Mason::Commands::session{_bric_user}->{login} }

sub get_user_id { $HTML::Mason::Commands::session{_bric_user}->{id} }

sub get_user_object { $HTML::Mason::Commands::session{_bric_user}->{object} }

sub user_is_admin {
    my $bric_user = $HTML::Mason::Commands::session{_bric_user};
    return $bric_user->{admin} if exists $bric_user->{admin};
    $bric_user->{admin} = grep { $_ eq ADMIN_GRP_ID }
      $bric_user->{object}->get_grp_ids;
    return $bric_user->{admin};
}


#--------------------------------------#
# Private Class Fields



#--------------------------------------#
# Instance Fields



#==============================================================================#

=head1 INTERFACE

=head2 Constructors

NONE.

=cut


#--------------------------------------#

=head2 Destructors

NONE.

=cut

#--------------------------------------#

=head2 Public Class Methods

NONE.

=cut


#--------------------------------------#

=head2 Public Instance Methods

NONE.

=cut

#==============================================================================#

=head2 Private Methods

NONE.

=cut

#--------------------------------------#

=head2 Private Class Methods

NONE

=cut

#--------------------------------------#

=head2 Private Instance Methods

NONE

=cut

1;
__END__

=head1 NOTES

NONE

=head1 AUTHOR

Garth Webb <garth@perijove.com>

=head1 SEE ALSO

L<perl>, L<Bric>, L<Apache::Session::File>

=cut
