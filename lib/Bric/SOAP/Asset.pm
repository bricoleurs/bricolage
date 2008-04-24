package Bric::SOAP::Asset;

# $Id $
###############################################################################

use strict;
use warnings;

use Bric::Config qw(:l10n);
use Bric::App::Authz  qw(chk_authz CREATE);
use Bric::Util::Fault qw(throw_ap throw_mni);
use Bric::App::Event  qw(log_event);
use Bric::App::Util   qw(get_package_name);
use Bric::SOAP::Util  qw(site_to_id output_channel_name_to_id);
use Bric::Util::Priv::Parts::Const qw(:all);

use IO::Scalar;

BEGIN {
    # XXX Turn off warnings so that we don't get XML::Writer's
    # Parameterless "use IO" deprecated warning.
    local $^W;
    require XML::Writer;
}

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 NAME

Bric::SOAP::Asset - base class for SOAP "asset" classes

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 AUTHOR

Scott Lanning <slanning@theworld.com>

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut


1;
