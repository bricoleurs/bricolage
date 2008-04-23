package Bric::App::ApacheConfig;

=head1 NAME

Bric::App::ApacheConfig - Bricolage httpd.conf configuration

=head1 VERSION

$Revision$

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

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
use Bric::Config qw(:ui :ssl :mod_perl);
use constant DEBUGGING => 0;


BEGIN {

    ### mod_perl 1.x ###

    if (MOD_PERL_VERSION < 2) {
        my $names = 'NameVirtualHost ' . NAME_VHOST . ':' . LISTEN_PORT . "\n";
        my $hostname = VHOST_SERVER_NAME;
        if ($hostname eq '_default_') {
            # Do our best to find the host name.
            require Sys::Hostname;
            $hostname = Sys::Hostname::hostname();
        }

        # Set up the basic configuration. Default to UTF-8 (it can be overridden
        # on a per-request basis in Bric::App::Handler.
        my @config = (
            '  DocumentRoot           ' . MASON_COMP_ROOT->[0][1],
            "  ServerName             $hostname",
            "  DefaultType            \"text/html; charset=utf-8\"",
            "  AddDefaultCharset      utf-8",
            '  SetHandler             perl-script',
            '  PerlHandler            Bric::App::Handler',
            '  PerlAccessHandler      Bric::App::AccessHandler',
            '  PerlCleanupHandler     Bric::App::CleanupHandler',
            '  RedirectMatch          '.
                    'permanent .*\/favicon\.ico$ /media/images/bricicon.ico',
        );

        # Setup Apache::DB handler if debugging
        push @config, '  PerlFixupHandler       Apache::DB' if DEBUGGING;

        # see Apache::SizeLimit manpage
        push @config, '  PerlFixupHandler       Apache::SizeLimit'
          if CHECK_PROCESS_SIZE;

        # This will slow down every request; thus we recommend that previews
        # not be local.
        push @config,
          '  PerlTransHandler       Bric::App::PreviewHandler::uri_handler'
          if PREVIEW_LOCAL;

        # Enable mod_gzip page compression
        if (ENABLE_GZIP) {
          push @config,
            "<IfModule mod_gzip.c>\n" .
            "  mod_gzip_on                   Yes\n" .
            "  mod_gzip_can_negotiate        Yes\n" .
            "  mod_gzip_static_suffix        .gz\n" .
            "  AddEncoding gzip              .gz\n" .
            "  mod_gzip_update_static        No\n" .
            "  mod_gzip_keep_workfiles       No\n" .
            "  mod_gzip_minimum_file_size    500\n" .
            "  mod_gzip_maximum_file_size    500000\n" .
            "  mod_gzip_maximum_inmem_size   60000\n" .
            "  mod_gzip_min_http             1000\n" .
            "  mod_gzip_handle_methods       GET POST\n" .
            "  mod_gzip_dechunk              Yes\n" .
            "  mod_gzip_add_header_count     Yes\n" .
            "  mod_gzip_send_vary            Yes\n" .
            "  mod_gzip_item_include         file \\.html\$\n" .
            "  mod_gzip_item_include         file \\.htm\$\n" .
            "  mod_gzip_item_include         file \\.shtml\$\n" .
            "  mod_gzip_item_include         file \\.shtm\$\n" .
            "  mod_gzip_item_include         file \\.pl\$\n" .
            "  mod_gzip_item_include         mime ^text/.*\n" .
            "  mod_gzip_item_include         mime ^httpd/unix-directory\$\n" .
            "  mod_gzip_item_include         handler ^perl-script\$\n" .
            "  mod_gzip_item_exclude         file \\.css\$\n" .
            "  mod_gzip_item_exclude         file \\.js\$\n" .
            "  mod_gzip_item_exclude         mime ^image/.*\n" .
            "</IfModule>";

        }

        # This URI will handle logging users out.
        my @locs = (
            "  <Location /logout>\n" .
            "    PerlAccessHandler   Bric::App::AccessHandler::logout_handler\n" .
            "    PerlCleanupHandler  Bric::App::CleanupHandler\n" .
            "  </Location>"
        );

        # Mask off Apache::DB handler if debugging - the debugger
        # seems to cause problems for login for some reason.  With the
        # Apache::DB handler in place the output from the first screen
        # after login goes to the debugger's STDOUT instead of the
        # browser!
        my $fix = DEBUGGING
          ? "\n    PerlFixupHandler    Apache::OK"
          : '';

        # This URI will handle logging users in.
        push @locs,
          "  <Location /login>\n" .
          "    SetHandler          perl-script\n" .
          "    PerlAccessHandler   Bric::App::AccessHandler::okay\n" .
          "    PerlHandler         Bric::App::Handler\n" .
          "    PerlCleanupHandler  Bric::App::CleanupHandler$fix\n" .
          "  </Location>";

        # We might need to change this for SSL configuration.
        my $loginref = \$locs[-1];

        # This URI will handle all non-Mason stuff that we serve (graphics, etc.).
        push @locs,
          "  <Location /media>\n" .
          "    SetHandler          default-handler\n" .
          "    PerlAccessHandler   Apache::OK\n" .
          "    PerlCleanupHandler  Apache::OK$fix\n" .
          "  </Location>";

        # Force JavaScript to the proper MIME type and always use Unicode.
        push @locs,
          "  <Location /media/js>\n" .
          "    ForceType           \"text/javascript; charset=utf-8\"\n" .
          "  </Location>";

        # Force CSS to the proper MIME type.
        push @locs,
          "  <Location /media/css>\n" .
          "    ForceType           \"text/css\"\n" .
          "  </Location>";

        # Enable CGI for spellchecker.
        if (ENABLE_WYSIWYG){
            push @locs,
              "  <Location /media/wysiwyg/htmlarea/plugins/SpellChecker>\n" .
              "    SetHandler None\n" .
              "    AddHandler perl-script .cgi\n" .
              "    PerlHandler Apache::Registry\n" .
              "  </Location>" if lc WYSIWYG_EDITOR eq 'htmlarea';
            push @locs,
              "  <Location /media/wysiwyg/xinha/plugins/SpellChecker>\n" .
              "    SetHandler None\n" .
              "    AddHandler perl-script .cgi\n" .
              "    PerlHandler Apache::Registry\n" .
              "  </Location>" if lc WYSIWYG_EDITOR eq 'xinha';
            push @locs,
              "  <Location /media/wysiwyg/fckeditor/editor/dialog/fck_spellerpages/spellerpages/server-scripts>\n" .
              "    SetHandler None\n" .
              "    AddHandler perl-script .pl\n" .
              "    PerlHandler Apache::Registry\n" .
              "  </Location>" if lc WYSIWYG_EDITOR eq 'fckeditor';
        }

        # This will serve media assets and previews.
        push @locs,
          "  <Location /data>\n" .
          "    SetHandler          default-handler\n" .
          "  </Location>";

        # This will run the SOAP server.
        push @locs,
          "  <Location /soap>\n" .
          "    SetHandler          perl-script\n" .
          "    PerlHandler         Bric::SOAP::Handler\n" .
          "    PerlAccessHandler   Apache::OK\n" .
          "  </Location>";

        if (ENABLE_DIST) {
            require Bric::Dist::Handler;
            push @locs,
              "  <Location /dist>\n" .
              "    SetHandler          perl-script\n" .
              "    PerlHandler         Bric::Dist::Handler\n" .
              "  </Location>";
        }

        if (QA_MODE) {
            # Turn on Perl warnings and run Apache::Status.
            push @config, '  PerlWarn               On';
            push @locs,
              "  <Location /perl-status>\n" .
              "    SetHandler          perl-script\n" .
              "    PerlHandler         Apache::Status\n" .
              "    PerlAccessHandler   Apache::OK\n" .
              "    PerlCleanupHandler  Apache::OK$fix\n" .
              "  </Location>";
        }

        if (PREVIEW_LOCAL) {
            my $prev_loc = "/" . join('/', PREVIEW_LOCAL);
            if (PREVIEW_MASON) {
                # We need to take some special steps to ensure that Mason properly
                # handles the request.
                push @locs,
                  "  <Location $prev_loc>\n" .
                  "    SetHandler          perl-script\n" .
                  "    PerlFixupHandler    Bric::App::PreviewHandler::fixup_handler\n" .
                  "    PerlHandler         Bric::App::Handler\n" .
                  "  </Location>";
            } else {
                # This will ensure that the documents are not cached by the browser, so
                # that the preview will always serve the most recently burned file.
                push @locs,
                  "  <Location $prev_loc>\n" .
                  "    PerlFixupHandler    " .
                       qq{"sub { \$_[0]->no_cache(1); return Apache::OK; }"\n} .
                  "  </Location>";
            }
        }

        my $config;
        if (SSL_ENABLE && ALWAYS_USE_SSL) {
            my $ssl_url = "https://$hostname"
                . (SSL_PORT == 443 ? '' : ':' . SSL_PORT). '/';
            $config = join "\n",
                "<VirtualHost " . NAME_VHOST . ':' . LISTEN_PORT . ">",
                '  ServerName             ' . VHOST_SERVER_NAME,
                "RedirectPermanent / $ssl_url",
                '</VirtualHost>';
        }
        else {
            $config = join "\n",
                "<VirtualHost " . NAME_VHOST . ':' . LISTEN_PORT . ">",
                    @config, @locs,
                '</VirtualHost>';
        }

        if (SSL_ENABLE) {
            $names .=  'NameVirtualHost ' . NAME_VHOST . ':' . SSL_PORT . "\n";
            push @config,
                '  SSLCertificateFile     ' . SSL_CERTIFICATE_FILE,
                '  SSLCertificateKeyFile  ' . SSL_CERTIFICATE_KEY_FILE;

            # Replace the login location.
            $loginref =
              "<Location /login>\n" .
              "    SetHandler         perl-script\n" .
              "    PerlAccessHandler  Bric::App::AccessHandler::okay\n" .
              "    PerlHandler        Bric::App::Handler\n" .
              "    PerlCleanupHandler Bric::App::CleanupHandler\n" .
              "  </Location>";

            # Apache::ReadConfig does not handle <IfModule>
            if (MANUAL_APACHE) {
                if (SSL_ENABLE eq 'apache_ssl') {
                    push @config,
                      '  SSLEnable',
                      '  SSLRequireSSL',
                      '  SSLVerifyClient        0',
                      '  SSLVerifyDepth         10';
                } else {
                    # is mod_ssl
                    push @config, '  SSLEngine              On';
                }
            } else {
                push @config,
                  "  <IfModule mod_ssl.c>\n" .
                  "    SSLEngine           On\n" .
                  "  </IfModule>\n" .
                  "  <IfModule apache_ssl.c>\n" .
                  "    SSLEnable\n" .
                  "    SSLVerifyClient     0\n" .
                  "    SSLVerifyDepth      10\n" .
                  "    SSLRequireSSL\n" .
                  "  </IfModule>";
            }

            $config .= join "\n", '',
              "<VirtualHost " . NAME_VHOST . ':' . SSL_PORT . ">",
                @config, @locs,
              '</VirtualHost>';
        }

        if (MANUAL_APACHE) {
            # Write out a configuration file and include it.
            require Bric::Util::Trans::FS;
            my $conffile = Bric::Util::Trans::FS->cat_dir(TEMP_DIR, 'bricolage',
                                                          'bric_httpd.conf');
            open CONF, ">$conffile" or die "Cannot open $conffile for output: $!\n";
            print CONF $names, $config;
            close CONF;

            # Place Include directive in Apache's scope
            package Apache::ReadConfig;
            our $Include = $conffile;
        } else {
            # place VirtualHost stuff in Apache's scope
            package Apache::ReadConfig;
            our $PerlConfig = $names . $config;
        }
    }

    ### mod_perl 2 ###
    else {
        my @names = ( 'NameVirtualHost ' . NAME_VHOST . ':' . LISTEN_PORT );
        my $hostname = VHOST_SERVER_NAME;
        if ($hostname eq '_default_') {
            # Do our best to find the host name.
            require Sys::Hostname;
            $hostname = Sys::Hostname::hostname();
        }

        # Mask off Apache::DB handler if debugging - the debugger
        # seems to cause problems for login for some reason.  With the
        # Apache::DB handler in place the output from the first screen
        # after login goes to the debugger's STDOUT instead of the browser!
        my $fix = DEBUGGING
          ? "\n    PerlFixupHandler    Apache2::Const::OK"
          : '';


        # Set up the basic configuration. Default to UTF-8 (it can be overridden
        # on a per-request basis in Bric::App::Handler).
        my @config = (
            '  DocumentRoot           ' . MASON_COMP_ROOT->[0][1],
            "  ServerName             $hostname",
            '  DefaultType            "text/html; charset=utf-8"',
            '  AddDefaultCharset      utf-8',
            '  SetHandler             perl-script',
            '  PerlResponseHandler    Bric::App::Handler',
            '  PerlAccessHandler      Bric::App::AccessHandler',
            '  PerlCleanupHandler     Bric::App::CleanupHandler',
            '  RedirectMatch          ' .
              'permanent .*\/favicon\.ico$ /media/images/bricicon.ico',
        );

        # Setup Apache::DB handler if debugging
        push @config, '  PerlFixupHandler       Apache::DB' if DEBUGGING;

        # see Apache::SizeLimit manpage (xxx: actually that says PerlCleanupHandler...)
        if (CHECK_PROCESS_SIZE) {
            push @config, '  PerlFixupHandler       Apache2::SizeLimit';
        }

        # This will slow down every request; thus we recommend that previews
        # not be local.
        use Apache2::Const -compile => 'DECLINED';
        push @config,
          '  PerlTransHandler       Bric::App::PreviewHandler::uri_handler'
          if PREVIEW_LOCAL;

        # Enable mod_gzip page compression
        if (ENABLE_GZIP) {
            # XXX Come back to this. It's mod_deflate.
            push @config,
              "<IfModule mod_gzip.c>\n" .
              "  mod_gzip_on                   Yes\n" .
              "  mod_gzip_can_negotiate        Yes\n" .
              "  mod_gzip_static_suffix        .gz\n" .
              "  AddEncoding gzip              .gz\n" .
              "  mod_gzip_update_static        No\n" .
              "  mod_gzip_keep_workfiles       No\n" .
              "  mod_gzip_minimum_file_size    500\n" .
              "  mod_gzip_maximum_file_size    500000\n" .
              "  mod_gzip_maximum_inmem_size   60000\n" .
              "  mod_gzip_min_http             1000\n" .
              "  mod_gzip_handle_methods       GET POST\n" .
              "  mod_gzip_dechunk              Yes\n" .
              "  mod_gzip_add_header_count     Yes\n" .
              "  mod_gzip_send_vary            Yes\n" .
              "  mod_gzip_item_include         file \\.html\$\n" .
              "  mod_gzip_item_include         file \\.htm\$\n" .
              "  mod_gzip_item_include         file \\.shtml\$\n" .
              "  mod_gzip_item_include         file \\.shtm\$\n" .
              "  mod_gzip_item_include         file \\.pl\$\n" .
              "  mod_gzip_item_include         mime ^text/.*\n" .
              "  mod_gzip_item_include         mime ^httpd/unix-directory\$\n" .
              "  mod_gzip_item_include         handler ^perl-script\$\n" .
              "  mod_gzip_item_exclude         file \\.css\$\n" .
              "  mod_gzip_item_exclude         file \\.js\$\n" .
              "  mod_gzip_item_exclude         mime ^image/.*\n" .
              "</IfModule>";
        }

        # This URI will handle logging users out.
        my @locs = (
            '  <Location /logout>',
            '    PerlAccessHandler   Bric::App::AccessHandler::logout_handler',
            '    PerlCleanupHandler  Bric::App::CleanupHandler',
            '  </Location>'
        );

        # This URI will handle logging users in.
        push @locs,
          '  <Location /login>',
          '    SetHandler          perl-script',
          '    PerlAccessHandler   Bric::App::AccessHandler::okay',
          '    PerlResponseHandler Bric::App::Handler',
          "    PerlCleanupHandler  Bric::App::CleanupHandler$fix",
          '  </Location>';

        # We might need to change this for SSL configuration.
        my $loginref = \$locs[-1];

        # This URI will handle all non-Mason stuff that we serve (graphics, etc.).
        push @locs,
          '  <Location /media>',
          '    SetHandler          default-handler',
          '    PerlAccessHandler   Apache2::Const::OK',
          "    PerlCleanupHandler  Apache2::Const::OK$fix",
          '  </Location>';

        # Force JavaScript to the proper MIME type and always use Unicode.
        push @locs,
          '  <Location /media/js>',
          '    ForceType           "text/javascript; charset=utf-8"',
          '  </Location>';

        # Force CSS to the proper MIME type.
        push @locs,
          '  <Location /media/css>',
          '    ForceType           "text/css"',
          '  </Location>';

        # Enable CGI for spellchecker.
        if (ENABLE_WYSIWYG){
            push @locs,
              '  <Location /media/wysiwyg/htmlarea/plugins/SpellChecker>',
              '    SetHandler None',
              '    AddHandler perl-script,cgi',
              '    PerlResponseHandler ModPerl::Registry',
              '  </Location>' if lc WYSIWYG_EDITOR eq 'htmlarea';
            push @locs,
              '  <Location /media/wysiwyg/xinha/plugins/SpellChecker>',
              '    SetHandler None',
              '    AddHandler perl-script,cgi',
              '    PerlResponseHandler ModPerl::Registry',
              '  </Location>' if lc WYSIWYG_EDITOR eq 'xinha';
            push @locs,
              '  <Location /media/wysiwyg/fckeditor/editor/dialog/fck_spellerpages/spellerpages/server-scripts>',
              '    SetHandler None',
              '    AddHandler perl-script,pl',
              '    PerlResponseHandler ModPerl::Registry',
              '  </Location>' if lc WYSIWYG_EDITOR eq 'fckeditor';
        }

        # This will serve media assets and previews.
        push @locs,
          '  <Location /data>',
          '    SetHandler          default-handler',
          '  </Location>';

        # This will run the SOAP server.
        push @locs,
          '  <Location /soap>',
          '    SetHandler          perl-script',
          '    PerlResponseHandler Bric::SOAP::Handler',
          '    PerlAccessHandler   Apache2::Const::OK',
          '  </Location>';

        if (ENABLE_DIST) {
            require Bric::Dist::Handler;
            push @locs,
              '  <Location /dist>',
              '    SetHandler          perl-script',
              '    PerlResponseHandler Bric::Dist::Handler',
              '  </Location>';
        }

        if (QA_MODE) {
            # Turn on Perl warnings and run Apache::Status.
            push @config, '  PerlWarn               On';
            push @locs,
              '  <Location /perl-status>',
              '    SetHandler          perl-script',
              '    PerlResponseHandler Apache2::Status',
              '    PerlAccessHandler   Apache2::Const::OK',
              "    PerlCleanupHandler  Apache2::Const::OK$fix",
              '  </Location>';
        }

        if (PREVIEW_LOCAL) {
            my $prev_loc = "/" . join('/', PREVIEW_LOCAL);
            if (PREVIEW_MASON) {
                # We need to take some special steps to ensure that Mason properly
                # handles the request.
                push @locs,
                  "  <Location $prev_loc>",
                  '    SetHandler          perl-script',
                  '    PerlFixupHandler    Bric::App::PreviewHandler::fixup_handler',
                  '    PerlResponseHandler Bric::App::Handler',
                  '  </Location>';
            } else {
                # This will ensure that the documents are not cached by the browser, so
                # that the preview will always serve the most recently burned file.
                push @locs,
                  "  <Location $prev_loc>",
                  '    ExpiresActive       On',
                  '    ExpiresDefault      "now plus 0 seconds"',
                  '    PerlFixupHandler    Apache2::Const::OK',
                  '  </Location>';
            }
        }

        my @vhosts;
        if (SSL_ENABLE && ALWAYS_USE_SSL) {
            my $ssl_url = "https://$hostname"
              . (SSL_PORT == 443 ? '' : ':' . SSL_PORT). '/';
            push @vhosts,
              '<VirtualHost ' . NAME_VHOST . ':' . LISTEN_PORT . '>',
              '  ServerName             ' . VHOST_SERVER_NAME,
              "RedirectPermanent / $ssl_url",
              '</VirtualHost>';
        } else {
            push @vhosts,
              '<VirtualHost ' . NAME_VHOST . ':' . LISTEN_PORT . '>',
              @config, @locs,
              '</VirtualHost>';
        }

        if (SSL_ENABLE) {
            push @names, 'NameVirtualHost ' . NAME_VHOST . ':' . SSL_PORT;
            push @config,
              '  SSLCertificateFile     ' . SSL_CERTIFICATE_FILE,
              '  SSLCertificateKeyFile  ' . SSL_CERTIFICATE_KEY_FILE;

            # Replace the login location.
            $loginref =
              "<Location /login>\n" .
              "    SetHandler          perl-script\n" .
              "    PerlAccessHandler   Bric::App::AccessHandler::okay\n" .
              "    PerlResponseHandler Bric::App::Handler\n" .
              "    PerlCleanupHandler  Bric::App::CleanupHandler\n" .
              "  </Location>\n";

            # Apache::ReadConfig does not handle <IfModule>
            if (MANUAL_APACHE) {
                # is mod_ssl
                push @config, '  SSLEngine              On';
            } else {
                push @config,
                  '  <IfModule mod_ssl.c>',
                  '    SSLEngine           On',
                  '  </IfModule>';
            }

            push @vhosts, "\n",
              "<VirtualHost " . NAME_VHOST . ':' . SSL_PORT . ">\n",
              @config, @locs,
              "</VirtualHost>\n";
        }

        require Apache2::ServerUtil;
        my $s = Apache2::ServerUtil->server;

#        XXX For now we have to write out a file and let httpd.conf include it
#        This is because I can't get mod_perl to load a configuration with a
#        VirtualHost directive without it crashing. Watch this thread for
#        details: http://marc.info/?t=120889389400011

#        if (MANUAL_APACHE) {
            # Write out a configuration file and include it.
            require Bric::Util::Trans::FS;
            my $conffile = Bric::Util::Trans::FS->cat_dir(
                TEMP_DIR,
                'bricolage',
                'bric_httpd.conf'
            );
            open my $cfh, ">$conffile"
                or die "Cannot open $conffile for output: $!";
            print $cfh map { $_, $/ } @names, @vhosts;
            close $cfh;

#            $s->add_config([ "Include $conffile" ]);
#        } else {
#            $s->add_config([ @names, @vhosts ]);
#        }
    }
}   # BEGIN


1;

__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@justatheory.com>

apache 2 changes by Scott Lanning <slanning@cpan.org>, Chris Heiland

=head1 SEE ALSO

L<Bric|Bric>

=cut
