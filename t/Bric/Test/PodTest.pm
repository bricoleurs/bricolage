package Bric::Test::PodTest;

use strict;
use warnings;
use base qw(Bric::Test::Base);
use File::Find;
use File::Spec;
use Pod::Checker;
use IO::Scalar;
use Test::More;

BEGIN {__PACKAGE__->test_class }

sub new {
    my $self = shift->SUPER::new(@_);
    # Find all the modules and scripts.
    my $mods = $self->find_mods;
    # Set the number of tests in the test_mods method.
    $self->num_method_tests('test_mods', scalar @$mods);
    # Cache the modules and scripts.
    $self->{mods} = $mods;
    return $self;
}

sub test_mods : Test(no_plan) {
    my $self = shift;
    my $mods = $self->{mods};
    foreach my $module (@$mods) {
        # Set up an error file handle and a POD checker object.
        my $errstr = '';
        my $errors = new IO::Scalar \$errstr;
        my $checker = Pod::Checker->new( -warnings => 1 );
        $checker->parse_from_file($module, $errors);
        # Delete this next statement once all errors are fixed!
        local $TODO = 'POD repairs in progress...'
          unless $checker->num_errors == 0;
        # Fail the test if the file's POD contains errors.
        ok($checker->num_errors == 0, "Check ${module}'s POD" )
          or diag($errstr);
    }
}

sub find_mods {
    # Find the lib directory.
    die "Cannot find Bricolage lib directory"
      unless -d 'lib';

    # Find the test lib directory.
    die "Cannot fine Bricolage test lib directory"
      unless -d 't';

    # Find all the modules.
    my @mods;
    find( sub { push @mods, $File::Find::name if m/\.pm$/ }, 'lib', 't' );

    # Find the bin directory.
    die "Cannot find Bricolage lib directory"
      unless -d 'bin';

    # Find all the scripts.
    find( sub { push @mods, $File::Find::name if -f and -x }, 'bin' );
    return \@mods;
}
