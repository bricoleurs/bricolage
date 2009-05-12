package Bric::App::Util;

###############################################################################

=head1 Name

Bric::App::Util - A class to house general application functions.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::App::Util;

=head1 Description

Utility functions.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programmatic Dependencies
#use CGI::Cookie;
#use Bric::Config qw(:qa :cookies);
use Bric::App::Cache;
use Bric::App::Session qw(:state :user);
use Bric::Config qw(:cookies :mod_perl);
use Bric::Util::Class;
use Bric::Util::Pref;
use Bric::Util::ApacheReq;
use HTML::Mason::Request;
use Bric::Util::ApacheUtil qw(escape_uri);
use HTML::Entities;
use Bric::Util::Language;
use Bric::Util::Fault qw(throw_gen);
use Bric::App::Authz qw(:all);
use Bric::Util::Priv::Parts::Const qw(:all);
use URI;
use URI::Escape;

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw( Exporter );

our @EXPORT_OK = qw(
                    add_msg
                    get_msg
                    next_msg
                    num_msg
                    clear_msg

                    get_pref

                    get_package_name
                    get_class_info
                    get_disp_name
                    get_class_description

                    set_redirect
                    get_redirect
                    del_redirect
                    do_queued_redirect
                    redirect
                    redirect_onload

                    log_history
                    last_page
                    pop_page

                    mk_aref

                    detect_agent
                    parse_uri
                    status_msg
                    severe_status_msg

                    find_workflow
                    find_desk
                    site_list

                    eval_codeselect
                   );

our %EXPORT_TAGS = (all     => \@EXPORT_OK,
                    msg     => [qw(add_msg
                                   get_msg
                                   next_msg
                                   num_msg
                                   clear_msg)],
                    redir   => [qw(set_redirect
                                   get_redirect
                                   del_redirect
                                   do_queued_redirect
                                   redirect
                                   redirect_onload)],
                    history => [qw(log_history
                                   last_page
                                   pop_page)],
                    pref    => ['get_pref'],
                    pkg     => [qw(get_package_name
                                   get_disp_name
                                   get_class_description
                                   get_class_info)],
                    aref    => ['mk_aref'],
                    browser => [qw(parse_uri
                                   status_msg
                                   severe_status_msg)],
                    wf      => [qw(find_workflow
                                   find_desk)],
                    sites   => [qw(site_list)],
                    elem    => [qw(eval_codeselect)],
                   );

#=============================================================================#
# Function Prototypes                  #
#======================================#

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;
use constant DEBUG_COOKIE => 'BRICOLAGE_DEBUG';

use constant MAX_HISTORY => 10;

#==============================================================================#
# FIELDS                               #
#======================================#

#--------------------------------------#
# Public Class Fields

#--------------------------------------#
# Private Class Fields
my $login_marker = LOGIN_MARKER .'='. LOGIN_MARKER;

#------------------------------------------------------------------------------#

#--------------------------------------#
# Instance Fields

#==============================================================================#

=head1 Interface

=head2 Constructors

NONE

=cut

#--------------------------------------#

=head2 Destructors

=cut

#--------------------------------------#

=head2 Public Class Methods

=over 4

=item (1 || undef) = add_msg($txt)

Add a new warning message to the current list of messages.

B<Throws:>

NONE

B<Side Effects:> Adds the message to the session.

B<Notes:>

NONE

=cut

sub add_msg {
    return unless @_;
    my $session = Bric::App::Session->instance;
    my $msg = $session->{_msg} ||= [];
    my $lang = Bric::Util::Language->instance;
    push @$msg, $lang->maketext(@_);
    $session->{timestamp} = time; # Force serialization.
}

#------------------------------------------------------------------------------#

=item $txt = get_msg($num)

=item (@txt_list || $txt_list) = get_msg()

Return warning message number '$num' or if $num is not given return all error
messages.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_msg {
    my ($num) = @_;
    my $msg = Bric::App::Session->instance->{'_msg'};

    if (defined $num) {
        return $msg->[$num];
    } else {
        return wantarray ? @$msg : $msg;
    }
}

#------------------------------------------------------------------------------#

=item ($txt || undef) = next_msg

Returns the next warning message in the list.  If there are no more messages,
it will return undef.

B<Throws:>

NONE

B<Side Effects:>

=over

=item *

Sets global variable %HTML::Mason::Commands::session

=back

B<Notes:>

NONE

=cut

sub next_msg {
    my $session = Bric::App::Session->instance();
    my $msg = $session->{'_msg'};
    my $txt = shift @$msg;
    $session->{'_msg'} = $msg;
    return $txt;
}

#------------------------------------------------------------------------------#

=item $num = num_msg

Returns the current number of warning messages.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub num_msg {
    my $msg = Bric::App::Session->instance->{'_msg'};
    return scalar @$msg;
}

#------------------------------------------------------------------------------#

=item clear_msg

Clears out all the error messages remaining.  This should be called after all
messages have been processed.

B<Throws:>

NONE

B<Side Effects:>

=over

=item *

Sets global variable %HTML::Mason::Commands::session

=back

B<Notes:>

NONE

=cut

sub clear_msg {
    Bric::App::Session->instance->{'_msg'} = [];
}

#------------------------------------------------------------------------------#

=item my $aref = mk_aref($arg)

Returns an array reference. If $arg is an anonymous array, it is simply
returned. If it's a defined scalar, it's returned as the single value in an
anonymous array. If it's undef, an empty anonymous array will be returned.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub mk_aref { ref $_[0] ? $_[0] : defined $_[0] ? [$_[0]] : [] }

#------------------------------------------------------------------------------#

=item my $value = get_pref($pref_name)

Returns a preference value.

B<Throws:>

=over 4

=item *

Unable to instantiate preference cache.

=item *

Unable to populate preference cache.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Unable to get cache value.

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Pref->lookup_val() internally.

=cut

sub get_pref {
    my $pref_name = shift;

    my $user = get_user_object;

    if ($user) {
        return $user->get_pref($pref_name);
    } else {
        my $pref = Bric::Util::Pref->lookup({ name => $pref_name });
        return $pref->get_value();
    }
}

#------------------------------------------------------------------------------#

=item my $pkg = get_package_name

Returns the package name given a short name.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_disp_name { get_class_info($_[0])->get_disp_name }

sub get_package_name { get_class_info($_[0])->get_pkg_name }

sub get_class_description { get_class_info($_[0])->get_description }

sub get_class_info {
    my $key = shift;
    my $class = Bric::Util::Class->lookup({ id => $key, key_name => $key,
                                          pkg_name => $key })
      || throw_gen(error => "No such class key '$key'.");
    return $class;
}


#------------------------------------------------------------------------------#

=item (1 || 0) = set_redirect($loc)

=item $loc     = get_redirect

=item $loc     = del_redirect

Get/Set/Delete a redirect to happen during the next page load that includes the
'header.mc' header element.

B<Throws:>

NONE

B<Side Effects:>

=over

=item *

Sets global variable %HTML::Mason::Commands::session

=back

B<Notes:>

This only works with pages that use the 'header.mc' element.

=cut

sub set_redirect {
    Bric::App::Session->instance->{_redirect} = shift;
}

# Unused as of 1.2.2
sub get_redirect {
    Bric::App::Session->instance->{_redirect};
}

sub del_redirect {
    my $session = Bric::App::Session->instance();
    my $rv = delete $session->{_redirect};
    # Behave normally if not login
    return $rv unless defined $rv and $rv =~ /$login_marker/o;

    # Work-around to allow multi port http / https operation by propagating
    # cookies to 2nd server build hash of cookies from blessed reference into
    # Apache::Tables
    my %cookies;
    my $r = Bric::Util::ApacheReq->instance;
    $r->err_headers_out->do(sub {
        my($k,$v) = @_;     # foreach key matching Set-Cookie
        ($k,$v) = split('=',$v,2);
        $cookies{$k} = $v;
        1;
    }, 'Set-Cookie');

    # get the current authorization cookie
    return $rv unless $cookies{&AUTH_COOKIE};
    my $qsv = AUTH_COOKIE .'='. escape_uri($cookies{&AUTH_COOKIE});
    # Add current session ID which should not need to be escaped. For now, the
    # path is always "/", since that's what AccessHandler sets it to. If that
    # changes in the future, we'll need to change it here, too, by adding code
    # to attach the proper query string to the URI.
    $qsv .= '&'. COOKIE .'='. $session->{_session_id} . escape_uri('; path=/');
    $rv =~ s/$login_marker/$qsv/;
    return $rv;
}

#------------------------------------------------------------------------------#

=item (1 || 0) = do_queued_redirect

If there is a redirected set, then redirect the browser, otherwise return.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub do_queued_redirect {
    my $loc = del_redirect() || return;
    redirect($loc);
}


#------------------------------------------------------------------------------#

=item (1 || 0) = redirect

Redirect to a different location.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub redirect {
    my $loc = shift or return;
    HTML::Mason::Request->instance->redirect($loc);
}


#------------------------------------------------------------------------------#

=item (1 || 0) = redirect_onload()

  redirect('/');
  redirect('/', $cbh);

Uses a JavaScript function call to redirect the browser to a different
location. Will not clear out the buffer first, so stuff sent ahead will still
draw in the browser. If a Params::Callback object is passed in as the second
argument, the Apache request object will be used to send the JavaScript to the
Browser and the callback handler object will be used to abort the request.
Otherwise, the Mason request object will be used to send the JavaScript to the
browser and to abort the request.

B<Throws:> NONE.

B<Side Effects:> Because C<redirect_onload()> executes immediately, if it is
called from a callback, note that no further callbacks will be executed, not
even post-callback request callbacks.

B<Notes:> NONE.

=cut

sub redirect_onload {
    my $loc = shift or return;

    # escape the path+query part if necessary
    my $uri = URI->new($loc);
    my $pq = $uri->path_query;
    $uri->path_query($pq);

    my $js  = sprintf q{<script>location.href='%s';</script>\n},
                      $uri;

    if (my $m = HTML::Mason::Request->instance) {
        # Use the Mason request object.
        $m->clear_buffer;
        $m->print($js);
        $m->abort;
    } elsif (my $cbh = shift) {
        # Use the callback handler object.
        my $r = $cbh->apache_req;
        if (MOD_PERL_VERSION < 2) {
            $r->send_http_header unless $r->headers_out->{'Content-type'};
        }
        $r->print($js);
        $cbh->abort;
    } else {
        throw_gen "No way to send redirect to browser";
    }
}

=item status_msg($msg)

=item severe_status_msg($msg)

Sometimes there's a long process executing, and you want to send status
messages to the browser so that the user knows what's happening. These
functions will do this for you. Call C<status_msg()> each time you want to
send a status messages, and it'll take care of the rest for you. The
C<severe_status_msg()> will do the same, but convert the message into a red,
bold-fased message before sending it to the browser. When you're done sending
status messages, you can either redirect to another page, or simply finish
drawing the current page. It will draw in below the status messages. This
function will work both in callbacks and in Mason UI code.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub status_msg {
    if (MOD_PERL) {
        _send_msg(encode_entities(Bric::Util::Language->instance->maketext(@_)));
    } else {
        print STDERR Bric::Util::Language->instance->maketext(@_);
    }
 }

sub severe_status_msg {
    if (MOD_PERL) {
    _send_msg('<span style="font-weight: bold; font-color: red;">' .
              encode_entities(Bric::Util::Language->instance->maketext(@_)) .
              "</span>");
    } else {
        print STDERR "##################################################\n\n";
        print STDERR Bric::Util::Language->instance->maketext(@_), "\n";
        print STDERR "##################################################\n\n";
    }
}

sub _send_msg {
    my $msg = shift;
    my $key = '_status_msg_';

    if (my $m = HTML::Mason::Request->instance) {
        my $r = $m->apache_req;
        my $old_autoflush = $m->autoflush;   # autoflush is restored below
        $m->autoflush(1);

        $m->print(qq{<p class="statusMsg" style="margin-left: 40px;">});

        unless ( $r->pnotes($key) ) {
            # We haven't called this thing yet. Throw up some initial information.
            $m->print("<br />\n" x 2);
            $r->pnotes($key, 1);
        }

        $m->print(qq{$msg</p>\n});

        $m->flush_buffer;
        $m->autoflush($old_autoflush);
    }
}

#------------------------------------------------------------------------------#

=item log_history($args)

Log the current URL for historical purposes.

B<Throws:>

NONE

B<Side Effects:>

Populates the history key of the session data.

B<Notes:>

NONE

=cut

sub log_history {
    my $session = Bric::App::Session->instance();
    my $history = $session->{'_history'};

    my $r = Bric::Util::ApacheReq->instance;
    my $curr = $r->uri;

    # Only push this URI onto the stack if it is different than the top value
    if (!$history->[0] || $curr ne $history->[0]) {
        # Push the current URI onto the stack.
        unshift @$history, $curr;

        # Pop the last item off the list if we've grown beyond our max.
        pop @$history if scalar(@$history) > MAX_HISTORY;

        # Save the history back.
        $session->{'_history'} = $history;
    }
}

#------------------------------------------------------------------------------#

=item $uri = last_page($n);

Grab the $n-th page visited.  Argument $n defaults to 1, or the very last page
(A $n value of 0 is the current page).  Only MAX_HISTORY pages are saved.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub last_page {
    my ($n) = @_;

    # Default to one page prior (index 0 contains the current page).
    $n = 1 unless defined $n;

    return Bric::App::Session->instance->{'_history'}->[$n];
}

#------------------------------------------------------------------------------#

=item $uri = pop_page;

Pops the last page visited off of the page history and returns it.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub pop_page {
    my $sess = Bric::App::Session->instance;
    my $hist = $sess->{_history};
    my $ret = shift @$hist;
    $sess->{_history} = $hist;
    return $ret;
}

#------------------------------------------------------------------------------#

=item ($section, $mode, $type, ...) = parse_uri($uri);

Returns $section (e.g. admin), $mode (e.g. manager, profile)
and $type (e.g. user, media, etc). This is centralized here in case
it becomes a complicated thing to do. And, centralizing is nice.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

Was comp/lib/util/parseUri.mc.

=cut

sub parse_uri {
    my $uri = shift;
    return split /\//, substr($uri, 1);
}

#--------------------------------------#

=item my $wf = find_workflow($site_id, $type, $perm);

Returns a workflow of a particular type in a given site for which the user has
a given permission to the documents and/or templates in that workflow. Returns
C<undef> if no workflow is found.

=cut

# XXX Could this be optimized to use the cache that sideNav.mc uses?

sub find_workflow {
    my ($site_id, $type, $perm) = @_;
    for my $wf (Bric::Biz::Workflow->list({ type    => $type,
                                            site_id => $site_id })) {
        return $wf if chk_authz(0, $perm, 1, $wf->get_asset_grp_id,
                                $wf->get_grp_ids);
    }
    return undef;
}

#--------------------------------------#

=item my $desk = find_desk($wf, $doc_perm)

Returns the desk in the given workflow for which the user has the permission
to access its documents and/or templates. Returns C<undef> if no desk is
found.

=cut

# Could this be optimized to use the cache that sideNav.mc uses?

sub find_desk {
    my ($wf, $perm) = @_;
    return unless $wf;
    if (chk_authz(undef, $perm, 1, $wf->get_asset_grp_id)) {
        # They have the permission for the whole workflow.
        # Just return the start desk unless they're interested
        # in a publish desk.
        return $wf->get_start_desk unless $perm == PUBLISH;
        # So find a publish desk. It's likely to be the last one returned,
        # so optimize for that.
        for my $d (reverse $wf->allowed_desks) {
            return $d if $d->can_publish;
        }
    }

    # Okay, so find a desk.
    for my $d ($wf->allowed_desks) {
        return $d if chk_authz(undef, $perm, 1, $d->get_asset_grp);
    }

    # Failure.
    return undef;
}

#--------------------------------------#

=item my @sites = site_list($perm)

Returns a list or array reference of sites to which the user has the specified
permission.

=cut

sub site_list {
    my $perm = shift;
    my $cache = Bric::App::Cache->new;
    my $sites = $cache->get('__SITES__');

    unless ($sites) {
        $sites = Bric::Biz::Site->list({ active => 1 });
        $cache->set('__SITES__', $sites);
    }

    return wantarray
      ? grep { chk_authz($_, $perm, 1) } @$sites
      : [ grep { chk_authz($_, $perm, 1) } @$sites ];
}

#--------------------------------------#

=item my $select_options = eval_codeselect($code, $field)

Returns a hash reference or reference to an array of arrays as returned by the
code in C<$code>. If the code just returns a list, it will be converted to a
reference of array references, unless it has an odd number of items, in which
case an error message will be displayed.

=cut

sub eval_codeselect {
    my ($code, $field) = @_;
    # XXX: This is very unsafe, but they need to be able
    # to do things like DBI queries; would that work with Safe?
    local $_;
    my $res = eval $code;

    my $ref = ref $res;
    # Return a hashref.
    return $res if $ref eq 'HASH';

    if ($ref eq 'ARRAY') {
        # Return an array of arrays.
        return $res if ref $res->[0] eq 'ARRAY';

        unless (@{ $res } % 2) {
            # It's just a simple array. Convert it to an array of arrays.
            my $vals = [];
            for (my $i = 0; $i < @{ $res }; $i += 2) {
                push @$vals, [ $res->[$i], $res->[$i+1] ];
            }
            return $vals;
        }
    }

    # If we get here, it ain't right.
    add_msg(
        'Invalid codeselect code: it did not return a hash reference, '
      . 'an array reference of array references, or an array reference '
      . 'of even size'
    );
    return;
}

=back

=head2 Public Instance Methods

NONE

=cut

#==============================================================================#

=head2 Private Methods

NONE

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

=head1 Notes

NONE

=head1 Author

Garth Webb <garth@perijove.com>
David Wheeler <david@justatheory.com>

=head1 See Also

L<perl>, L<Bric>

=cut
