package Bric::App::Callback;

use base qw(Params::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'Callback';

use strict;

use Bric::App::Cache;
use Bric::Config qw(:ui);
use Bric::App::Util qw(get_pref);
use Bric::Util::Language;

my $cache = Bric::App::Cache->new();

sub lang { Bric::Util::Language->get_handle(get_pref('Language')) }
sub cache { $cache }
sub set_redirect { shift->redirect(shift, 1) }

1;
