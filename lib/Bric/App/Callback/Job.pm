package Bric::App::Callback::Job;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'job');
use strict;


my $type = 'job';
my $class = get_package_name($type);


1;
