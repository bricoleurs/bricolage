package Bric::App::Handler;

=head1 NAME

Bric::App::Handler - The center of the application, as far as Apache is concerned.

=head1 VERSION

$Revision: 1.32.2.1 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.32.2.1 $ )[-1];

=head1 DATE

$Date: 2003-03-04 06:45:46 $

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
use Bric::Util::Fault qw(:all);
use Bric::Util::DBI qw(:trans);
use Bric::Util::CharTrans;
use Bric::App::Event qw(clear_events);
use Apache::Log;
use HTML::Mason '1.16';
use HTML::Mason::ApacheHandler;
use HTML::Mason::Exceptions;
use Carp qw(croak);

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
    use Bric::Biz::Site;
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
    use Bric::Util::Fault qw(:all);
    use Bric::Util::Language;
    use Bric::Util::Pref;
    use Bric::Util::Priv;
    use Bric::Util::Priv::Parts::Const qw(:all);
    use Bric::Util::Time qw(strfdate);
    use Bric::Util::Trans::FS;

    use Bric::SOAP;

    use HTML::Mason::Exceptions;
    eval { require Text::Levenshtein };
    require Text::Soundex if $@;

    use vars qw($c $widget_dir $lang);

    # Where our widgets live under the element root.
    $widget_dir = 'widgets';

    # A global that makes the cache available everywhere.
    $c = Bric::App::Cache->new;

    # A global for localization purposes
    $lang = Bric::Util::Language->get_handle(LANGUAGE);
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
my $ct;
my $no_trans = 0;

my %interp_args =
  ( comp_root     => MASON_COMP_ROOT,
    data_dir      => MASON_DATA_ROOT,
    static_source => 0,
    autoflush     => 0,
    error_mode    => 'fatal',
  );

my $interp = HTML::Mason::Interp->new(%interp_args);
my $ah;
if (CHAR_SET ne 'UTF-8') {
    require Bric::App::ApacheHandler;
    $ah = Bric::App::ApacheHandler->new(%interp_args,
                                        decline_dirs => 0,
                                        out_method   => \&filter,
                                        args_method  => MASON_ARGS_METHOD
                                       );
    $ct = Bric::Util::CharTrans->new(CHAR_SET);
} else {
    $ah = HTML::Mason::ApacheHandler->new(%interp_args,
                                        decline_dirs => 0,
                                        args_method  => MASON_ARGS_METHOD
                                       );
}

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
    $err = _make_fault($err);

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

##############################################################################

sub _make_fault {
    my $err = shift;

    # Just return bricolage exceptions.
    return $err if isa_bric_exception($err);

    # Otherwise, create a new exception object.
    my $payload = '';
    if (isa_mason_exception($err)) {
        if (QA_MODE) {
            # Make sure we're not stealing away Mason's internal exceptions.
            die $err if isa_mason_exception($err, 'Abort') or
              isa_mason_exception($err, 'Compilation::IncompatibleCompiler');
        }
        my $brief = $err->as_brief;
        return $brief if isa_bric_exception($brief);
        $payload = $brief;
    } else {
        $payload = $err;
    }

    return Bric::Util::Fault::Exception::AP->new
      ( error   => "Error processing Mason elements.",
        payload => $payload );
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
    if ($no_trans) {
	print STDOUT $_[0];
	return;
    }

    # Do the translation.
    my $ret;
    eval { $ret = $ct->from_utf8($_[0]) };

    # Do error processing, if necessary.
    if (my $err = $@) {
        $no_trans = 1; # So we don't translate error.html.
        my $msg = 'Error translating from UTF-8 to ' . $ct->charset;
        die $err if ref $err;
        throw_dp error => $msg, payload => $err;
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
