package Bric::App::Util;
###############################################################################

=head1 NAME

Bric::App::Util - A class to house general application functions.

=head1 VERSION

$Revision: 1.2.2.5 $

=cut

our $VERSION = (qw$Revision: 1.2.2.5 $ )[-1];

=head1 DATE

$Date: 2001-12-10 21:59:47 $

=head1 SYNOPSIS

  use Bric::App::Util;

=head1 DESCRIPTION



=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies
#use CGI::Cookie;
#use Bric::Config qw(:qa);
use Bric::Util::Class;
use Bric::Util::Pref;

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
		    aref    => ['mk_aref']
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
my $gen = 'Bric::Util::Fault::Exception::GEN';

#--------------------------------------#
# Instance Fields                       


#==============================================================================#

=head1 INTERFACE

=head2 Constructors

=over 4

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

B<Side Effects:>

=over

=item *

Sets global variable %HTML::Mason::Commands::session

=back

B<Notes:>

NONE

=cut

sub add_msg {
    my ($txt) = @_;
    my $msg = $HTML::Mason::Commands::session{'_msg'};
    
    push @$msg, $txt;

    $HTML::Mason::Commands::session{'_msg'} = $msg;

    return 1;
}

#------------------------------------------------------------------------------#

=item $txt = get_msg($num)

=item (@txt_list || $txt_list) = get_msg()

Return warning message number '$num' or if $num is not given return all error
messages.

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

sub get_msg {
    my ($num) = @_;
    my $msg = $HTML::Mason::Commands::session{'_msg'};

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
    my $msg = $HTML::Mason::Commands::session{'_msg'};
    my $txt = shift @$msg;
    $HTML::Mason::Commands::session{'_msg'} = $msg;
    return $txt;
}

#------------------------------------------------------------------------------#

=item $num = num_msg

Returns the current number of warning messages.

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

sub num_msg {
    my $msg = $HTML::Mason::Commands::session{'_msg'};
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
    $HTML::Mason::Commands::session{'_msg'} = [];
}

#------------------------------------------------------------------------------#

=item my $aref = mk_aref($arg)

Returns an array reference. If $arg is an anonymous array, it is simply
returned. If it's a defined scalar, it's returned as the single value in an
anonymous array. If it's undef, an ampty anonymous array will be returned.

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

sub get_pref { Bric::Util::Pref->lookup_val(shift) }

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
      || die $gen->new({ msg => "No such class key '$key'." });
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

sub set_redirect { $HTML::Mason::Commands::session{_redirect} = shift }

sub get_redirect { $HTML::Mason::Commands::session{_redirect} }

sub del_redirect { delete $HTML::Mason::Commands::session{_redirect} }

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
    my $loc = delete $HTML::Mason::Commands::session{'_redirect'} || return;
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
    my $loc = shift || return;
    $HTML::Mason::Commands::m->clear_buffer;
    # The next two lines are necessary to stop Apache from re-reading
    # POSTed data.
    $HTML::Mason::Commands::r->method('GET');
    $HTML::Mason::Commands::r->headers_in->unset('Content-length');
    $HTML::Mason::Commands::r->content_type('text/html');
    $HTML::Mason::Commands::r->header_out(Location => $loc);
    $HTML::Mason::Commands::m->abort(302);
}


#------------------------------------------------------------------------------#

=item (1 || 0) = redirect_onload()

Uses a JavaScript function call to redirect the browser to a different location.
Will not clear out the buffer, first, so stuff sent ahead will still draw in the
browser.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub redirect_onload {
    my $loc = shift || return;

    $HTML::Mason::Commands::m->out(qq{<script>
            location.href='$loc';
        </script>
    });
    $HTML::Mason::Commands::m->abort;
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
    my $history = $HTML::Mason::Commands::session{'_history'};

    my $curr = $HTML::Mason::Commands::r->uri;

    # Only push this URI onto the stack if it is different than the top value
    if (!$history->[0] || $curr ne $history->[0]) {
	# Push the current URI onto the stack.
	unshift @$history, $curr;

	# Pop the last item off the list if we've grown beyond our max.
	pop @$history if scalar(@$history) > MAX_HISTORY;

	# Save the history back.
	$HTML::Mason::Commands::session{'_history'} = $history;
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

    return $HTML::Mason::Commands::session{'_history'}->[$n];
}

#------------------------------------------------------------------------------#

=item $uri = pop_page;

Grab the $n-th page visited.  Argument $n defaults to 1, or the very last page
(A $n value of 0 is the current page).  Only MAX_HISTORY pages are saved.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub pop_page {
    return shift @{$HTML::Mason::Commands::session{'_history'}}
}

#--------------------------------------#

=head2 Public Instance Methods

=cut


#==============================================================================#

=head2 Private Methods

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

=back

=head1 NOTES

NONE

=head1 AUTHOR

"Garth Webb" <garth@perijove.com>
"David Wheeler" <david@wheeler.net>
Bricolage Engineering

=head1 SEE ALSO

L<perl>, L<Bric>

=cut
