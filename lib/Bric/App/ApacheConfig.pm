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

# start Apache::DB if we're debugging.  This is done here so that
# modules loaded below will get debugging symbols.
our $DEBUGGING;
BEGIN { 
  if(Apache->define('BRICOLAGE_DEBUG')) {
    require Apache::DB;
    Apache::DB->init;
    $DEBUGGING = 1;
  }
}

package Apache::ReadConfig;
use strict;
use warnings;
use Bric::Config qw(:conf :sys_user :qa :temp :profile);
use Bric::App::Handler;
use Bric::App::AccessHandler;
use Bric::App::CleanupHandler;
use Bric::App::Auth;
use mod_perl;
our %VirtualHost;

our @NameVirtualHost = ([ NAME_VHOST . ':' . LISTEN_PORT ]);

do {
    # Set up the basic configuration.
    my %config = ( DocumentRoot       => MASON_COMP_ROOT->[0][1],
		   ServerName         => VHOST_SERVER_NAME,
		   DefaultType        => 'text/html',
		   SetHandler         => 'perl-script',
		   PerlHandler        => 'Bric::App::Handler',
		   PerlAccessHandler  => 'Bric::App::AccessHandler',
		   PerlCleanupHandler => 'Bric::App::CleanupHandler',
		   RedirectMatch      =>
		     'permanent .*\/favicon\.ico$ /media/images/favicon.ico',

		   # setup Apache::DB handler if debugging
		   ($DEBUGGING ?  
		    (PerlFixupHandler => 'Apache::DB') : ()), 
		 );

    # set up profiling with Devel::Profiler - this installs a
    # ChildInitHandler
    require Devel::Profiler::Apache if PROFILE;

    if (PREVIEW_LOCAL) {
	# This will slow down every request; thus we recommend that previews
	# not be local.
	require Bric::App::PreviewHandler;
	$config{PerlTransHandler} = 'Bric::App::PreviewHandler::uri_handler';
    }

    # This URI will handle logging users out.
    my %locs = ("/logout"  => {
        PerlAccessHandler  => 'Bric::App::AccessHandler::logout_handler',
        PerlCleanupHandler => 'Bric::App::CleanupHandler',
    });

    # This URI will handle logging users in.
    $locs{"/login"} = {
        SetHandler         => 'perl-script',
        PerlAccessHandler  => 'Bric::App::AccessHandler::okay',
        PerlHandler        => 'Bric::App::Handler',
        PerlCleanupHandler => 'Bric::App::CleanupHandler',

	# mask off Apache::DB handler if debugging - the debugger
	# seems to cause problems for login for some reason.  With the
	# Apache::DB handler in place the output from the first screen
	# after login goes to the debugger's STDOUT instead of the
	# browser!
       ($DEBUGGING ?  
        (PerlFixupHandler  => 'Apache::OK') : ()), 
    };

    # This URI will handle all non-Mason stuff that we server (graphics, etc.).
    $locs{"/media"} = {
        SetHandler         => 'default-handler',
        PerlAccessHandler  => 'Apache::OK',
        PerlCleanupHandler => 'Apache::OK',

	# mask off Apache::DB handler if debugging
       ($DEBUGGING ?  
        (PerlFixupHandler  => 'Apache::OK') : ()), 
    };

    # This will serve media assets and previews.
    $locs{"/data"} = { SetHandler => 'default-handler' };

    # This will run the SOAP server.
    $locs{'/soap'} = {
        SetHandler         => 'perl-script',
        PerlHandler        => 'Bric::SOAP::Handler',
        PerlAccessHandler  => 'Apache::OK'
    };

    if (ENABLE_DIST) {
	# This URI will run the distribution server.
	$locs{"/dist"} = {
            SetHandler  => 'perl-script',
            PerlHandler => 'Bric::Dist::Handler'
        };
    }

    if (QA_MODE) {
	# Turn on Perl warnings and run Apache::Status.
	$config{PerlWarn} = 'On';
	$locs{"/perl-status"} = {
            SetHandler         => 'perl-script',
            PerlHandler        => 'Apache::Status',
            PerlAccessHandler  => 'Apache::OK',
            PerlCleanupHandler => 'Apache::OK',

            # mask off Apache::DB handler if debugging 
	   ($DEBUGGING ?  
            (PerlFixupHandler  => 'Apache::OK') : ()), 
        };
    }

    if (PREVIEW_LOCAL) {
	my $prev_loc = "/" . join('/', PREVIEW_LOCAL);
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
	$ssl_locs{"/login"} = {
            SetHandler         => 'perl-script',
            PerlAccessHandler  => 'Bric::App::AccessHandler::okay',
            PerlHandler        => 'Bric::App::Handler',
            PerlCleanupHandler => 'Bric::App::CleanupHandler'
        };
	$ssl_config{Location} = \%ssl_locs;
	$VirtualHost{NAME_VHOST . ':443'} = \%ssl_config;
    }

    unless ($mod_perl::VERSION > 1.26) {

	# If we get here, then <Perl> sections are broken. See the discussion here:
	# http://mathforum.org/epigone/modperl/rorphaltwin. As a quick and dirty
	# fix, let's dump the config to a temp file and just use the include
	# directive.
	use Bric::Util::Trans::FS;
	my $conffile = Bric::Util::Trans::FS->cat_dir(TEMP_DIR, 'bricolage',
						      'bric_httpd.conf');
	open CONF, ">$conffile" or die "Cannot open $conffile for output: $!\n";
	select CONF;

	# Output the NameVirtualHost directives.
	print "NameVirtualHost $_->[0]\n" for @NameVirtualHost;
	@NameVirtualHost = ();

	# Output the rest.
	while (my ($k, $v) = each %VirtualHost) {
	    print "<VirtualHost $k>\n";
	    print_bric_directive(undef, $v, 2);
	    print "</VirtualHost>\n";
	}
	%VirtualHost = ();
	close CONF;
	select STDOUT;
	our $Include = $conffile;
    }
};


# This function is required for outputting a configuration file from mod_perl
# version 1.26 and earlier.
sub print_bric_directive {
    my ($directive, $value, $i) = @_;
    my $indent = ' ' x $i;
    if ($directive) {
	if ($directive eq 'Location') {
	    while (my ($k, $v) = each %$value) {
		print "$indent<Location $k>\n";
		print_bric_directive(undef, $v, $i + 2);
		print "$indent</Location>\n";
	    }
	} else {
	    if (ref $value) {
		print "$indent<$directive>\n";
		print_bric_directive(undef, $value, $i + 2);
		print "$indent</$directive>\n";
	    }
	    else {
		print "$indent$directive $value\n";
	    }
	}
    } else {
	while (my ($k, $v) = each %$value) {
	    print_bric_directive($k, $v, $i + 2);
	}
    }
}

1;

__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric|Bric>

=cut
