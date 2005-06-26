use strict;
require 5.006001;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    code => q{
        # ./Build uitest
        # same as `./Build test` but with the test files in t/UI
        sub ACTION_uitest {
            my $self = shift;
            $self->test_files('t/UI/*.t');
            $self->SUPER::ACTION_test;
        }
    },
);

my $build = $class->new(
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
