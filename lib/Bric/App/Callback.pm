package Bric::App::Callback;

use base qw(MasonX::CallbackHandler);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'Callback';

use strict;

use Bric::App::Cache;
use Bric::Config qw(:ui);
use Bric::Util::Language;

my $cache = Bric::App::Cache->new();
my $lang = Bric::Util::Language->get_handle(LANGUAGE);

sub lang { $lang }
sub cache { $cache }

1;
