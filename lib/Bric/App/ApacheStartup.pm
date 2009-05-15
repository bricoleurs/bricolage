package Bric::App::ApacheStartup;

=head1 Name

Bric::App::ApacheStartup - Bricolage httpd startup configuration

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  <Perl>
      use File::Spec::Functions qw(catdir);
      BEGIN {
        $ENV{BRICOLAGE_ROOT} ||= '/usr/local/bricolage';
        unshift(@INC, catdir($ENV{BRICOLAGE_ROOT}, 'lib'));
      };
  </Perl>
  PerlModule Bric::App::ApacheStartup

=head1 Description

This module takes care of all of Apache startup configuration necessary to get
Bricolage working. Putting it all in this module makes it easier for you to
add it to your own httpd.conf by using only a single line.

=cut

# switch scope
package Bric::App::ApacheConfig;
use strict;
use warnings;
use Bric::Config qw(:mod_perl);

# start Apache::DB if we're debugging.  This is done here so that
# modules loaded below will get debugging symbols.
our $DEBUGGING;
BEGIN {
    if (MOD_PERL_VERSION < 2) {
        if (eval{Apache->define('BRICOLAGE_DEBUG')}) {
            require Apache::DB;
            Apache::DB->init;
            $DEBUGGING = 1;
        }
    }
    else {
        require mod_perl2;
        require APR;
        require APR::Request;
        require APR::Request::Apache2;
        require APR::Table;
        require Apache2::Access;
        require Apache2::Connection;
        require Apache2::Log;
        require Apache2::Request;
        require Apache2::RequestRec;
        require Apache2::RequestUtil;
        require Apache2::Response;
        require Apache2::RequestIO;
        require Apache2::ServerUtil;
        require Apache2::SubRequest;
        require Apache2::Upload;
        if ( eval{ Apache2::ServerUtil->exists_config_define('BRICOLAGE_DEBUG') } ) {
            require Apache::DB;
            Apache::DB->init;
            $DEBUGGING = 1;
        }
    }
}

use Bric::Config qw(:conf :sys_user :qa :temp :profile :proc_size :ui);
use Bric::App::Handler;
use Bric::App::AccessHandler;
use Bric::App::CleanupHandler;
use Bric::App::Auth;

# booting XS here.
BEGIN {
    if (MOD_PERL_VERSION < 2) {
        require mod_perl;    mod_perl->import();
        require Apache::Log;
    }
}


if (CHECK_PROCESS_SIZE) {
    my $apsizepkg = (MOD_PERL_VERSION < 2) ? 'Apache::SizeLimit' : 'Apache2::SizeLimit';
    eval "require $apsizepkg";

    no strict 'refs';

    # apache child processes larger than this size will be killed
    ${"${apsizepkg}::MAX_PROCESS_SIZE"}    = MAX_PROCESS_SIZE;

    # requests handled per size check
    ${"${apsizepkg}::CHECK_EVERY_N_REQUESTS"}    = CHECK_FREQUENCY;

    ${"${apsizepkg}::MIN_SHARE_SIZE"}        = MIN_SHARE_SIZE
        if MIN_SHARE_SIZE > 0;

    ${"${apsizepkg}::MAX_UNSHARED_SIZE"}    = MAX_UNSHARED_SIZE
        if MAX_UNSHARED_SIZE > 0;
}

if (PREVIEW_LOCAL) {
    # This will slow down every request; thus we recommend that previews
    # not be local.
    require Bric::App::PreviewHandler;
}

1;

__END__

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>

=cut
