package Bric::App::ApacheConfig;

=head1 NAME

Bric::App::ApacheConf - Bricolage httpd.conf configuration

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
  PerlModule Bric::App::ApacheConf

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

1;

package Apache::ReadConfig;
use strict;
use warnings;
use Bric::Config qw(:conf :sys_user :qa);
use Bric::App::Handler;
use Bric::App::AccessHandler;
use Bric::App::CleanupHandler;
use Bric::App::Auth;
use mod_perl;
our %VirtualHost;

our @NameVirtualHost = ([ NAME_VHOST . ':' . LISTEN_PORT ]);

do {
    # Set up string matching for mod_perl pre-1.27 bug. Perhaps after a while we
    # can require 1.27 or later and remove this crap.
    my $match = $mod_perl::VERSION < 1.27 ? '^' : '';

    # Set up the basic configuration.
    my %config = ( DocumentRoot       => MASON_COMP_ROOT->[0][1],
		   ServerName         => VHOST_SERVER_NAME,
		   DefaultType        => 'text/html',
		   SetHandler         => 'perl-script',
		   PerlHandler        => 'Bric::App::Handler',
		   PerlAccessHandler  => 'Bric::App::AccessHandler',
		   PerlCleanupHandler => 'Bric::App::CleanupHandler',
		   RedirectMatch      =>
		     'permanent .*\/favicon\.ico$ /media/images/favicon.ico'
    );

    if (PREVIEW_LOCAL) {
	# This will slow down every request; thus we recommend that previews
	# not be local.
	require Bric::App::PreviewHandler;
	$config{PerlTransHandler} = 'Bric::App::PreviewHandler::uri_handler';
    }

    # This URI will handle logging users out.
    my %locs = ("$match/logout"  => {
        PerlAccessHandler  => 'Bric::App::AccessHandler::logout_handler',
        PerlCleanupHandler => 'Bric::App::CleanupHandler'
    });

    # This URI will handle logging users in.
    $locs{"$match/login"} = {
        SetHandler         => 'perl-script',
        PerlAccessHandler  => 'Bric::App::AccessHandler::okay',
        PerlHandler        => 'Bric::App::Handler',
        PerlCleanupHandler => 'Bric::App::CleanupHandler'
    };

    # This URI will handle all non-Mason stuff that we server (graphics, etc.).
    $locs{"$match/media"} = {
        SetHandler         => 'default-handler',
        PerlAccessHandler  => 'Apache::OK',
        PerlCleanupHandler => 'Apache::OK'
    };

    # This will serve media assets and previews.
    $locs{"$match/data"} = { SetHandler => 'default-handler' };

    # This will run the SOAP server.
    $locs{'/soap'} = {
        SetHandler         => 'perl-script',
        PerlHandler        => 'Bric::SOAP::Handler',
        PerlAccessHandler  => 'Apache::OK'
    };

    if (ENABLE_DIST) {
	# This URI will run the distribution server.
	$locs{"$match/dist"} = {
            SetHandler  => 'perl-script',
            PerlHandler => 'Bric::Dist::Handler'
        };
    }

    if (QA_MODE) {
	# Turn on Perl warnings and run Apache::Status.
	$config{PerlWarn} = 'On';
	$locs{"$match/perl-status"} = {
            SetHandler         => 'perl-script',
            PerlHandler        => 'Apache::Status',
            PerlAccessHandler  => 'Apache::OK',
            PerlCleanupHandler => 'Apache::OK'
        };
    }

    if (PREVIEW_LOCAL) {
	my $prev_loc = "$match/" . join('/', PREVIEW_LOCAL);
	if (PREVIEW_MASON) {
	    # We need to take some special steps to ensure that Mason properly
	    # handles the request.
	    $locs{$prev_loc} = {
                SetHandler       => 'perl-script',
                PerlFixupHandler => 'Bric::App::PreviewHandler::fixup_handler',
                PerlHandler      => 'Bric::App::Handler'
	    };
	} else {
	    # This will ensure that the documents are not cached by the browser, so
	    # that the preview will always serve the most recently burned file.
	    $locs{$prev_loc} =
	      { PerlFixupHandler =>
		'"sub { $_[0]->no_cache(1); return Apache::OK; }"' };
	}
    }
    $config{Location} = \%locs;
    $VirtualHost{NAME_VHOST . ':' . LISTEN_PORT} = \%config;

    if (SSL_ENABLE) {
	push @NameVirtualHost, [ NAME_VHOST . ':443' ];
	my %ssl_config = (%config, SSLEngine => 'on');
	my %ssl_locs = %locs;
	$ssl_locs{"$match/login"} = {
            SetHandler         => 'perl-script',
            PerlAccessHandler  => 'Bric::App::AccessHandler::okay',
            PerlHandler        => 'Bric::App::Handler',
            PerlCleanupHandler => 'Bric::App::CleanupHandler'
        };
	$ssl_config{Location} = \%ssl_locs;
	$VirtualHost{NAME_VHOST . ':443'} = \%ssl_config;
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
