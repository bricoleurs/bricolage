package Bric::App::Handler;

=head1 NAME

Bric::App::Handler - The center of the application, as far as Apache is concerned.

=head1 VERSION

$Revision: 1.21 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.21 $ )[-1];

=head1 DATE

$Date: 2002-11-13 22:58:52 $

=head1 SYNOPSIS

  <Perl>
  use lib '/usr/local/bricolage/lib';
  </Perl>
  PerlModule Bric::App::Handler
  PerlFreshRestart    On
  DocumentRoot "/usr/local/bricolage/comp"
  <Directory "/usr/local/bricolage/comp">
      Options Indexes FollowSymLinks MultiViews
      AllowOverride None
      Order allow,deny
      Allow from all
      SetHandler perl-script
      PerlAccessHandler Bric::App::AccessHandler
      PerlHandler Bric::App::Handler
      PerlCleanupHandler Bric::App::CleanupHandler
  </Directory>

=head1 DESCRIPTION

This package is the main package used by Apache for managing the Bricolage
application. It loads all the necessary Mason and Bricolage libraries and sets
everything up for use in Apache. It is one function is handler(), which is
called by mod_perl for every request.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Config qw(:mason :char :sys_user :err);
use Bric::Util::Fault::Exception::AP;
use Bric::Util::Fault::Exception::DP;
use Bric::Util::DBI qw(:trans);
use Bric::Util::CharTrans;
use Bric::App::Event qw(clear_events);
use Apache::Log;
use HTML::Mason;
use Carp qw(croak);

# Bring in ApacheHandler. Install Apache::Request and have it parse arguments.
use HTML::Mason::ApacheHandler (args_method => MASON_ARGS_METHOD);

{
    # Now let's set up our Mason space.
    package HTML::Mason::Commands;

    # Load all modules to be used from elements.
    use Apache::Util qw(escape_html escape_uri);
    use Bric::Config qw(:auth_len :admin :time :dist :ui :prev :ssl :qa
                        :search);
    use Bric::Biz::Asset::Business::Media;
    use Bric::Biz::Asset::Business::Media::Audio;
    use Bric::Biz::Asset::Business::Media::Image;
    use Bric::Biz::Asset::Business::Media::Video;
    use Bric::Biz::Asset::Business::Parts::Tile::Container;
    use Bric::Biz::Asset::Business::Story;
    use Bric::Biz::Asset::Formatting;
    use Bric::Biz::AssetType;
    use Bric::Biz::Category;
    use Bric::Biz::Contact;
    use Bric::Biz::Keyword;
    use Bric::Biz::Org::Person;
    use Bric::Biz::Org::Source;
    use Bric::Biz::OutputChannel;
    use Bric::Biz::Person;
    use Bric::Biz::Person::User;
    use Bric::Biz::Workflow qw(:wf_const);
    use Bric::Biz::Workflow::Parts::Desk;

    use Bric::App::Auth qw(:all);
    use Bric::App::Authz qw(:all);
    use Bric::App::Cache;
    use Bric::App::ReqCache;
    use Bric::App::Event qw(log_event);
    use Bric::App::Session qw(:state :user);
    use Bric::App::Util qw(:msg
                        :redir
			:pkg
			:history
			mk_aref
                        get_pref);

    use Bric::Dist::Job;
    use Bric::Dist::Resource;

    use Bric::Util::AlertType;
    use Bric::Util::Burner;
    use Bric::Util::Burner::Mason;
    use Bric::Util::Burner::Template;
    use Bric::Util::Class;
    use Bric::Util::Pref;
    use Bric::Util::Priv;
    use Bric::Util::Priv::Parts::Const qw(:all);
    use Bric::Util::Time qw(strfdate);
    use Bric::Util::Trans::FS;

    use Bric::SOAP;

    use vars qw($c $rc $widget_dir);

    # Where our widgets live under the element root.
    $widget_dir = 'widgets';

    # A global that makes the cache available everywhere.
    $c = Bric::App::Cache->new;

    # A global that maes the request cache available everywhere.
    $rc = Bric::App::ReqCache->new;
}

################################################################################
# Inheritance
################################################################################
use base qw( Exporter );
our @EXPORT_OK = qw(handle_err);
our %EXPORT_TAGS = (err => [qw(handle_err)]);

################################################################################
# Function and Closure Prototypes
################################################################################

################################################################################
# Constants
################################################################################

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $dp = 'Bric::Util::Fault::Exception::DP';
my $ap = 'Bric::Util::Fault::Exception::AP';
#my $defset = 'iso-8859-1';
my $ct = Bric::Util::CharTrans->new(CHAR_SET);
my $no_trans = 0;

# Create Mason parser object.
my $parser = HTML::Mason::Parser->new;

# Create the interpreter. Options we may want to add for the shipping product
# include:
# * use_reload_file => 1 - This forces Mason to use object files only, without
#   checking element files to see if they've changed. 'Corse, we'll need
#   to pre-compile all of our elements upon installation by using
#   the Parser/make_element method.
# * out_mode => 'stream' = This should make the serving of pages appear to
#   be faster, as Mason will output data as it goes, rather than computing
#   the entire page in memory (in a scalar) and then serving it all at once,
#   which is what 'batch' mode (the default) does.
my $interp = HTML::Mason::Interp->new(parser            => $parser,
                                      comp_root         => MASON_COMP_ROOT,
                                      data_dir          => MASON_DATA_ROOT,
				      system_log_events => 'ALL',
				      out_method => \&filter,
				      use_reload_file => 0,
				      die_handler => sub { $_ },
				      out_mode => 'batch');

my $ah = HTML::Mason::ApacheHandler->new(interp       => $interp,
					 error_mode   => 'fatal',
					 decline_dirs => 0);

# Install our own ARGS handler.
$HTML::Mason::ApacheHandler::ARGS_METHOD = \&load_args;

# Reset ownership of all files created by Mason at startup.
chown SYS_USER, SYS_GROUP, $interp->files_written;

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

NONE.

=head2 Public Class Methods

NONE.

=head2 Public Functions

=over 4

=item my $status = handler()

Handles the apache request.

B<Throws:> None - the buck stops here!

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub handler {
    my ($r) = @_;
    # Handle the request.
    my $status;
    eval {
	# Start the database transactions.
	begin(1);
	# Handle the request.
	$status = $ah->handle_request($r);
	# Commit the database transactions.
	commit(1);
    };

    # Do error processing, if necessary.
    return $@ ? handle_err($r, $@) : $status;
}

################################################################################

=item $status = handle_err($r, $@)

  $status = handle_err($r, $@) if $@;

Handles errors when they're thrown by a main handler. Logs the error to the
Apache error log and formats the error screen for the browser.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub handle_err {
    my ($r, $err) = @_;
    # Create an exception object unless we already have one.
    $err = Bric::Util::Fault::Exception::AP->new(
       { msg => "Error processing Mason elements.", payload => $err })
       unless ref $err;

    # Rollback the database transactions.
    eval { rollback(1) };
    my $more_err = $@ ? "In addition, the database rollback failed: $@" : undef;

    # Clear out events to that they won't be logged.
    clear_events();

    # Send the error to the apache error log.
    $r->log->error($err->get_msg . ': ' . $err->get_payload . ($more_err ?
		   "\n\n$more_err" : '') . "\nStack Trace:\n" .
                   join("\n", map { ref $_ ? join(' - ', @{$_}[1,2,3]) : $_ }
                        @{$err->get_stack}) . "\n\n");

    # Make sure we go back to translating character sets, or we'll be
    # screwed on the next request.
    $no_trans = 0;

    # Process the exception for the user.
    return $interp->exec(ERROR_URI, fault => $err,
			 __CB_DONE => 1, more_err => $more_err);
}
################################################################################

=item my $args = load_args($ah, $rref, $m)

Overrides the HTML::Mason::ApacheHandler::ARGS_METHOD method to process GET and
POST data. By overriding it, we are able to do a couple of extra things, such as
translate the characters to Unicode and to turn empty strings into undefs.

B<Throws:>

=over 4

=item *

Error setting Bric::Util::CharTrans character set.

=item *

Error translating to Unicode.

=back

B<Side Effects:> NONE.

B<Notes:> Most of this code was copied from
HTML::Mason::ApacheRequest::_mod_perl_args(). We will have to change the Mason
settings for triggering this in future versions of Mason, where Jonathan
promises,

  In the long term (1.2-ish), we are planning to split out
  ApacheHandler::handle_request into several API functions, one of which will
  be "determine the hash of args from $r". So you will be able to do your own
  thing instead of calling the standard ApacheHandler method for this.

One thing that is commented out here is callbacks. I have not been able to get
them to work properly here yet, so they remain in /autohandler. But they are
the Only thing left there!

=cut

sub load_args {
    my ($ah, $rref, $m) = @_;

    my $apr = $$rref;
    # Switch to an Apache::Request object, if necessary.
    unless (UNIVERSAL::isa($apr, 'Apache::Request')) {
	$apr = Apache::Request->new($apr);
	$$rref = $apr;
    }

    # We need to apply preferences for the character set.
    # Commented out because we're using the setting in Bric::Config, instead, and
    # that's set only once, at server startup time.
#    eval { $ct->charset(Bric::App::Default::get_pref("Character Set") || $defset)};
#    die ref $@ ? $@ : $dp->new({
#      msg => "Error setting Bric::Util::CharTrans character set.",
#      payload => $@ }) if $@;

    return unless $apr->param;

    # We'll be checking to see if the data is already Unicode below.
    my $utf = $ct->charset eq 'UTF-8';
    my %args;
    foreach my $key ($apr->param) {
	my @values = $apr->param($key);

	# Translate value to Unicode, unless it's already Unicode
        eval { $ct->to_utf8(\@values) } unless $utf;

        if ($@) {
            my $msg = 'Error translating from '.$ct->charset.' to UTF-8.';
            die ref $@ ? $@
                       : Bric::Util::Fault::Exception::DP->new({msg     => $msg,
                                                                payload => $@});
        }

        # Build up our own argument hash of converted values.
        $args{$key} = scalar @values == 1 ? $values[0] : \@values;
    }

    # Execute any callbacks set for this request.
    # Commented out because it doesn't work right now. Jonathan says,
    #   ...without taking a closer look I'd say you cannot depend on having
    #   access to a full request object in the argument handler. Again, this API
    #   is due for a revamp.
#    Bric::App::Session::handle_callbacks($m, \%args);
    return %args;
}

################################################################################

=item filter($output)

This function translates data going out from Mason from Unicode into the users
preferred character set.

B<Throws:>

=over 4

=item *

Error translating from UTF-8.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub filter {
    # Just get it over with if we're not supposed to do translation.
    if ($no_trans or $ct->charset eq 'UTF-8') {
	print STDOUT $_[0];
	return;
    }

    # Do the translation.
    my $ret;
    eval { $ret = $ct->from_utf8($_[0]) };
    
    # Do error processing, if necessary.
    if (my $err = $@) {
        $no_trans = 1; # So we don't translate error.html.
        my $msg = 'Error translating from UTF-8 to '.$ct->charset;
        die ref $@ ? $@ : $dp->new({msg     => $msg,
                                    payload => $@ }) if $@;
    }

    # Dump the data.
    print STDOUT $ret;
}

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

L<Bric|Bric>

=cut
