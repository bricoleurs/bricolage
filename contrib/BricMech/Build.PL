use strict;
require 5.006001;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Bric::Mech',
    dist_author => 'Scott Lanning <lannings@who.int>',
    requires => {
        'WWW::Mechanize' => '1.10',
        'HTML::TokeParser::Simple' => '0',  # XXX: not sure
        perl => '5.6.1',
    },
    create_makefile_pl => 'passthrough',
#    script_files       => [ 'bin/noneyet' ],
    license            => 'perl',
);
$build->create_build_script;
