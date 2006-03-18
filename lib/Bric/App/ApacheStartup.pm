package Bric::App::ApacheStartup;

=head1 NAME

Bric::App::ApacheStartup - Bricolage httpd startup configuration

=head1 VERSION

$LastChangedRevision$

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

  <Perl>
      use File::Spec::Functions qw(catdir);
      BEGIN {
        $ENV{BRICOLAGE_ROOT} ||= '/usr/local/bricolage';
        unshift(@INC, catdir($ENV{BRICOLAGE_ROOT}, 'lib'));
      };
  </Perl>
  PerlModule Bric::App::ApacheStartup

=head1 DESCRIPTION

This module takes care of all of Apache startup configuration necessary to get
Bricolage working. Putting it all in this module makes it easier for you to
add it to your own httpd.conf by using only a single line.

=cut

# switch scope
package Bric::App::ApacheConfig;
use strict;
use warnings;

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

BEGIN {
    # Set up profiling with Devel::Profiler - this installs a
    # ChildInitHandler. It needs to be setup as early as possible to enable
    # the CORE::GLOBAL::caller override to be used by the profiled modules.
    use Bric::Config qw(PROFILE QA_MODE);
    if (PROFILE) {
        # Exclude upper-case subs, which are mostly constants in Bric anyway
        my $sub_filter = sub {
            return 0 if $_[1] =~ /^[A-Z_]+$/;
            return 1;
        };

        # Exclude Bric::Util::Fault and some misbehavin' packages used by Bric
        my $pkg_filter = sub {
            return 0 if ($_[0] =~ /^Bric::Util::Fault/ or
                         $_[0] =~ /^XML::Parser/       or
                         $_[0] =~ /^SOAP/);
            return 1;
        };

        require Devel::Profiler::Apache;
        Devel::Profiler::Apache->import(sub_filter     => $sub_filter,
                                        package_filter => $pkg_filter);

        # Profiling with QA_MODE on is inadvisable
        print STDERR "WARNING: Both PROFILE and QA_MODE options activated.\n",
                     "         PROFILE results will be skewed.\n\n"
            if QA_MODE;
    }
}

use Bric::Config qw(:conf :sys_user :qa :temp :profile :proc_size :ui);
use Bric::App::Handler;
use Bric::App::AccessHandler;
use Bric::App::CleanupHandler;
use Bric::App::Auth;
use mod_perl;

if (CHECK_PROCESS_SIZE) {
    # see Apache::SizeLimit manpage
    require Apache::SizeLimit;

    # apache child processes larger than this size will be killed
    $Apache::SizeLimit::MAX_PROCESS_SIZE	= MAX_PROCESS_SIZE;

    # requests handled per size check
    $Apache::SizeLimit::CHECK_EVERY_N_REQUESTS	= CHECK_FREQUENCY;

    $Apache::SizeLimit::MIN_SHARE_SIZE		= MIN_SHARE_SIZE
	if MIN_SHARE_SIZE > 0;

    $Apache::SizeLimit::MAX_UNSHARED_SIZE	= MAX_UNSHARED_SIZE
	if MAX_UNSHARED_SIZE > 0;
    }

if (PREVIEW_LOCAL) {
    # This will slow down every request; thus we recommend that previews
    # not be local.
    require Bric::App::PreviewHandler;
}

1;

__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@justatheory.com>

=head1 SEE ALSO

L<Bric|Bric>

=cut
