package Bric::App::ApacheConfig;

=head1 NAME

Bric::App::ApacheConfig - Bricolage httpd.conf configuration

=head1 VERSION

$Revision$

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision$ )[-1];

=head1 DATE

$Date$

=head1 SYNOPSIS

  <Perl>
      use File::Spec::Functions qw(catdir);
      BEGIN {
        $ENV{BRICOLAGE_ROOT} ||= '/usr/local/bricolage';
        unshift(@INC, catdir($ENV{BRICOLAGE_ROOT}, 'lib'));
      };
  </Perl>
  PerlModule Bric::App::ApacheConfig

=head1 DESCRIPTION

This module takes care of all of Apache configuration necessary to get Bricolage
working. Putting it all in this module makes it easier for you to add it to your
own httpd.conf by using only a single line.

=begin comment

Right now, of course, the <Perl> section shown in the synopsis above in order to
make sure that the path to the Bric libraries is in Perl's @INC path. But maybe
we ought to start putting them into the default @INC rather than adding their
directory to @INC by using Makefile.PL. Just a thought.

=end comment

=cut

use strict;
use Bric::App::ApacheStartup;
use Bric::Config qw(:char);
use constant DEBUGGING => 0;

do {
    my @names = ('NameVirtualHost ' . NAME_VHOST . ':' . LISTEN_PORT);
    # Set up the basic configuration.
    my @config = (
        'DocumentRoot        ' . MASON_COMP_ROOT->[0][1],
        'ServerName          ' . VHOST_SERVER_NAME,
        'DefaultType         "text/html; charset=' . lc CHAR_SET . '"',
        'AddDefaultCharset   ' . lc CHAR_SET,
        'SetHandler          perl-script',
        'PerlHandler         Bric::App::Handler',
        'PerlAccessHandler   Bric::App::AccessHandler',
        'PerlCleanupHandler  Bric::App::CleanupHandler',
        'RedirectMatch       '.
          'permanent .*\/favicon\.ico$ /media/images/favicon.ico',
    );

    # Setup Apache::DB handler if debugging
    push @config, 'PerlFixupHandler    Apache::DB' if DEBUGGING;

    # see Apache::SizeLimit manpage
    push @config, 'PerlFixupHandler    Apache::SizeLimit'
      if CHECK_PROCESS_SIZE;

    # This will slow down every request; thus we recommend that previews
    # not be local.
    push @config,
      'PerlTransHandler    Bric::App::PreviewHandler::uri_handler'
      if PREVIEW_LOCAL;

    # This URI will handle logging users out.
    my @locs = (<<"    EOF");
      <Location /logout>
        PerlAccessHandler  Bric::App::AccessHandler::logout_handler
        PerlCleanupHandler Bric::App::CleanupHandler
      </Location>
    EOF

    # Mask off Apache::DB handler if debugging - the debugger
    # seems to cause problems for login for some reason.  With the
    # Apache::DB handler in place the output from the first screen
    # after login goes to the debugger's STDOUT instead of the
    # browser!
    my $fix = DEBUGGING
      ? "\n        PerlFixupHandler Apache::OK"
      : '';

    # This URI will handle logging users in.
    push @locs, <<"    EOF";
      <Location /login>
        SetHandler         perl-script
        PerlAccessHandler  Bric::App::AccessHandler::okay
        PerlHandler        Bric::App::Handler
        PerlCleanupHandler Bric::App::CleanupHandler$fix
      </Location>
    EOF

    # We might need this for SSL configuration.
    my $loginref = \$locs[-1];

    # This URI will handle all non-Mason stuff that we server (graphics, etc.).
    push @locs, <<"    EOF";
      <Location /media>
        SetHandler         default-handler
        PerlAccessHandler  Apache::OK
        PerlCleanupHandler Apache::OK$fix
      </Location>
    EOF

    # Force JavaScript to the proper MIME type and always use Unicode.
    push @locs, <<"    EOF";
      <Location /media/js>
        ForceType          "application/x-javascript; charset=utf-8"
      </Location>
    EOF

    # This will serve media assets and previews.
    push @locs, <<"    EOF";
      <Location /data>
        SetHandler         default-handler
      </Location>
    EOF

    # This will run the SOAP server.
    push @locs, <<"    EOF";
      <Location /soap>
        SetHandler         perl-script
        PerlHandler        Bric::SOAP::Handler
        PerlAccessHandler  Apache::OK
      </Location>
    EOF

    if (ENABLE_DIST) {
        push @locs, <<"        EOF";
          <Location /dist>
            SetHandler         perl-script
            PerlHandler        Bric::Dist::Handler
          </Location>
        EOF
    }

    if (QA_MODE) {
        # Turn on Perl warnings and run Apache::Status.
        push @config, 'PerlWarn            On';
        push @locs, <<"        EOF";
          <Location /dist>
            SetHandler         perl-script
            PerlHandler        Apache::Status
            PerlAccessHandler  Apache::OK
            PerlCleanupHandler Apache::OK$fix
          </Location>
        EOF
    }

    if (PREVIEW_LOCAL) {
        my $prev_loc = "/" . join('/', PREVIEW_LOCAL);
        if (PREVIEW_MASON) {
            # We need to take some special steps to ensure that Mason properly
            # handles the request.
            push @locs, <<"            EOF";
              <Location $prev_loc>
                SetHandler       perl-script
                PerlFixupHandler Bric::App::PreviewHandler::fixup_handler
                PerlHandler      Bric::App::Handler
              </Location>
            EOF
        } else {
            # This will ensure that the documents are not cached by the browser, so
            # that the preview will always serve the most recently burned file.
            push @locs, <<"            EOF";
              <Location $prev_loc>
                PerlFixupHandler "sub { \$_[0]->no_cache(1); return Apache::OK; }"
              </Location>
            EOF
        }
    }

    my @sections = (
        "<VirtualHost "
          . NAME_VHOST . ':' . LISTEN_PORT . ">",
        @config, @locs,
        '</VirtualHost>'
    );

    if (SSL_ENABLE) {
        push @names, 'NameVirtualHost ' . NAME_VHOST . ':' . SSL_PORT;
        push @config,
            'SSLCertificateFile     ' . SSL_CERTIFICATE_FILE,
            'SSLCertificateKeyFile  ' . SSL_CERTIFICATE_KEY_FILE;

        # Replace the login location.
        $loginref = <<"        EOF";
          <Location /login>
            SetHandler         perl-script
            PerlAccessHandler  Bric::App::AccessHandler::okay
            PerlHandler        Bric::App::Handler
            PerlCleanupHandler Bric::App::CleanupHandler
          </Location>
        EOF

        # Apache::ReadConfig does not handle <IfModule>
        if (MANUAL_APACHE) {
            if (SSL_ENABLE eq 'apache_ssl') {
                push @config,
                  'SSLEnable',
                  'SSLRequireSSL',
                  'SSLVerifyClient   0',
                  'SSLVerifyDepth    10';
            } else {
                # is mod_ssl
                push @config, 'SSLEngine      On';
            }
        } else {
            push @config, <<"            EOF";
              <IfModule mod_ssl.c>
                SSLEngine On
              </IfModule>
              <IfModule apache_ssl.c>
                SSLEnable
                SSLVerifyClient 0,
                SSLVerifyDepth  10,
                SSLRequireSSL
              </IfModule>
            EOF
        }

        push @sections, "<VirtualHost " . NAME_VHOST . ':' . SSL_PORT . ">",
          @config, @locs,
      '</VirtualHost>';
    }

    if (MANUAL_APACHE) {
        # Write out a configuration file and include it.
        use Bric::Util::Trans::FS;
        my $conffile = Bric::Util::Trans::FS->cat_dir(TEMP_DIR, 'bricolage',
                                                      'bric_httpd.conf');
        open CONF, ">$conffile" or die "Cannot open $conffile for output: $!\n";
        print CONF $_, $/ for (@names, @sections);
        close CONF;

        # Place Include directive in Apache's scope
        package Apache::ReadConfig;
        our $Include = $conffile;
    } else {
        # place VirtualHost stuff in Apache's scope
        package Apache::ReadConfig;
        our $PerlConfig = join "\n", @names, @sections;
    }
};

1;

__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric|Bric>

=cut
