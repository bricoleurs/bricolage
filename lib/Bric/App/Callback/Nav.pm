package Bric::App::Callback::Nav;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'nav');
use strict;


# XXX: unF, look at this later

my ($fullSection, $state ) = split /_/, $field;
my ($nav,$section) = split /\|/, $fullSection;
set_state_data('nav', $section, $param->{$field});


1;
