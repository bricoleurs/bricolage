package Bric::App::Handler;

=head1 Name

Bric::App::Handler - The center of the application, as far as Apache is concerned.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  <Perl>
  use lib '/usr/local/bricolage/lib';
  </Perl>
  PerlModule Bric::App::Handler
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

=head1 Description

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
use Bric::Config qw(:mason :sys_user :err :l10n);
use Bric::Util::Fault qw(:all);
use Bric::Util::DBI qw(:trans);
use Bric::Util::Trans::FS;
use Bric::App::Event qw(clear_events);
use Bric::App::Util qw(del_redirect add_msg get_pref);
use Bric::Util::ApacheConst qw(OK);
use HTML::Mason '1.16';
use HTML::Mason::ApacheHandler;

use Bric::App::Callback::Alert;
use Bric::App::Callback::Alias;
use Bric::App::Callback::AssetMeta;
use Bric::App::Callback::BulkPublish;
# Only load CharTrans if we have Perl 5.8 or later.
BEGIN { require Bric::App::Callback::CharTrans if ENCODE_OK }
use Bric::App::Callback::ContainerProf;
use Bric::App::Callback::Desk;
use Bric::App::Callback::Event;
use Bric::App::Callback::ListManager;
use Bric::App::Callback::Login;
use Bric::App::Callback::Perm;
use Bric::App::Callback::Profile;
use Bric::App::Callback::Publish;
use Bric::App::Callback::Request;
use Bric::App::Callback::Search;
use Bric::App::Callback::SelectObject;
use Bric::App::Callback::SelectTime;
use Bric::App::Callback::SiteContext;

use Bric::App::Callback::Profile::Action;
use Bric::App::Callback::Profile::AlertType;
use Bric::App::Callback::Profile::Category;
use Bric::App::Callback::Profile::Contrib;
use Bric::App::Callback::Profile::Desk;
use Bric::App::Callback::Profile::Dest;
use Bric::App::Callback::Profile::ElementType;
use Bric::App::Callback::Profile::FieldType;
use Bric::App::Callback::Profile::FormBuilder;
use Bric::App::Callback::Profile::Grp;
use Bric::App::Callback::Profile::Job;
use Bric::App::Callback::Profile::Keyword;
use Bric::App::Callback::Profile::Media;
use Bric::App::Callback::Profile::MediaType;
use Bric::App::Callback::Profile::OutputChannel;
use Bric::App::Callback::Profile::Pref;
use Bric::App::Callback::Profile::Server;
use Bric::App::Callback::Profile::Site;
use Bric::App::Callback::Profile::Source;
use Bric::App::Callback::Profile::Story;
use Bric::App::Callback::Profile::Template;
use Bric::App::Callback::Profile::User;
use Bric::App::Callback::Profile::UserPref;
use Bric::App::Callback::Profile::Workflow;
use MasonX::Interp::WithCallbacks;

{
    # Now let's set up our Mason space.
    package HTML::Mason::Commands;

    # Load all modules to be used from elements.
    use Bric::Util::Cookie;
    use Bric::Util::ApacheConst qw(HTTP_INTERNAL_SERVER_ERROR HTTP_FORBIDDEN HTTP_NOT_FOUND);
    # xxx: is escape_uri actually used anywhere under comp/ ?
    use Bric::Util::ApacheUtil qw(escape_uri);
    use HTML::Entities (); *escape_html = \&HTML::Entities::encode_entities;
    use Bric::Config qw(:auth_len :admin :time :dist :ui :prev :ssl :qa :thumb :oc);
    use Bric::Biz::Asset::Business::Media;
    use Bric::Biz::Asset::Business::Media::Audio;
    use Bric::Biz::Asset::Business::Media::Image;
    use Bric::Biz::Asset::Business::Media::Video;
    use Bric::Biz::Asset::Business::Parts::Tile::Container;
    use Bric::Biz::Element::Container;
    use Bric::Biz::Asset::Business::Story;
    use Bric::Biz::Asset::Formatting;
    use Bric::Biz::Asset::Template;
    use Bric::Biz::Site;
    use Bric::Biz::AssetType;
    use Bric::Biz::ElementType;
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
                           :pref
                           :aref
                           :browser
                           :wf
                           :sites
                           :elem
                         );

    use Bric::Dist::Action;
    use Bric::Dist::Action::Mover;
    use Bric::Dist::Action::Email;
    use Bric::Dist::Action::DTDValidate;
    use Bric::Util::Job::Dist;
    use Bric::Util::Job::Pub;
    use Bric::Dist::Resource;

    use Bric::Util::AlertType;
    use Bric::Util::Burner;
    use Bric::Util::Burner::Mason;
    use Bric::Util::Class;
    use Bric::Util::DBI qw(:junction);
    use Bric::Util::Fault qw(:all);
    use Bric::Util::Language;
    use Bric::Util::Pref;
    use Bric::Util::Priv;
    use Bric::Util::Priv::Parts::Const qw(:all);
    use Bric::Util::Time qw(:all);
    use Bric::Util::Trans::FS;
    use Bric::Util::UserPref;
    use Text::Diff::HTML;
    use Text::WordDiff ();

    use Bric::SOAP;

    use vars qw($c $widget_dir $lang $lang_key $ct);

    # Where our widgets live under the element root.
    $widget_dir = 'widgets';

    # A global that makes the cache available everywhere.
    $c = Bric::App::Cache->new;
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
use constant ERROR_FILE => Bric::Util::Trans::FS->cat_dir(
    MASON_COMP_ROOT->[0][1],
    Bric::Util::Trans::FS->split_uri(ERROR_URI),
);

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields

my ($ah);
{
    my %args = ( comp_root            => MASON_COMP_ROOT,
                 data_dir             => MASON_DATA_ROOT,
                 static_source        => MASON_STATIC_SOURCE,
                 autoflush            => 0,
                 error_mode           => 'fatal',
                 cb_classes           => 'ALL',
                 cb_exception_handler => \&cb_exception_handler,
                 ignore_nulls         => 1,
                 interp_class         => 'MasonX::Interp::WithCallbacks',
                 decline_dirs         => 0,
                 args_method          => MASON_ARGS_METHOD,
                 preamble             => "use utf8;\n",
               );

    $ah = HTML::Mason::ApacheHandler->new(%args);
}

# This ApacheHandler object will only be used to serve components
# that handle errors.
my $gah = HTML::Mason::ApacheHandler->new(comp_root    => MASON_COMP_ROOT,
                                          data_dir     => MASON_DATA_ROOT,
                                          decline_dirs => 0,
                                          args_method  => MASON_ARGS_METHOD);

################################################################################

################################################################################
# Instance Fields

# NONE.

################################################################################
# Class Methods
################################################################################

=head1 Interface

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
    my $r = shift;

    # Handle the request.
    my $status;
    my $lang_name = get_pref('Language');

    # A global for localization purposes
    local $HTML::Mason::Commands::lang =
        Bric::Util::Language->get_handle($lang_name);
    local $HTML::Mason::Commands::lang_key = $HTML::Mason::Commands::lang->key;
    my $char_set = get_pref('Character Set');

    eval {
        # Prevent browsers from caching pages.
        $r->no_cache(1);
        # Set up the language and content type headers.
        $r->content_languages([$lang_name]);
        $r->content_type('text/html; charset=' . lc $char_set);
        Bric::Util::Pref->use_user_prefs(1);

        # Start the database transactions.
        begin(1);
        # Handle the request.
        $status = $ah->handle_request($r);
        # Commit the database transactions.
        commit(1);

        Bric::Util::Pref->use_user_prefs(0);
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

    $err = Bric::Util::Fault::Exception::AP->new(
        error   => "Error processing Mason elements.",
        payload => $err,
    ) unless isa_exception($err);

    # Rollback the database transactions.
    eval { rollback(1) };
    my $more_err = $@ ? "In addition, the database rollback failed: $@" : undef;

    # Clear out events so that they won't be logged.
    clear_events();

    # Clear out redirects so that they won't be triggered.
    del_redirect();

    # Send the error(s) to the apache error log.
    $r->log->error($err->full_message);
    $r->log->error($more_err) if $more_err;

    # Exception::Class::Base provides trace->as_string, but trace_as_text is
    # not guaranteed. Use print STDERR to avoid escaping newlines.
    print STDERR $err->can('trace_as_text')
      ? $err->trace_as_text
      : join (
          "\n",
          map { sprintf '  [%s:%d]', $_->filename, $_->line } $err->trace->frames
      ), "\n";

    # Process the exception for the user.
    # Instead of using $interp->exec we start over a la PreviewHandler.
    # The 'BRIC_*' args are used in errors/500.mc
    $r->uri(ERROR_URI);
    $r->filename(ERROR_FILE);
    $r->pnotes('BRIC_EXCEPTION' => $err);
    $r->pnotes('BRIC_MORE_ERR' => $more_err);

    $gah->handle_request($r);
    return OK;
}

##############################################################################

sub cb_exception_handler {
    my $err = shift;
    rethrow_exception $err unless isa_bric_exception($err, 'Error');
    # Rollback any changes.
    rollback(1);
    begin(1);
    add_msg($err->maketext);
}

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

=cut

1;
__END__

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>

=cut
