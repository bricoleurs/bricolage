package Bric::Test::PodTest;

=head1 NAME

Bric::Test::Base - Bricolage Development Testing Base Class

=head1 VERSION

$Revision: 1.11 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.11 $ )[-1];

=head1 DATE

$Date: 2003-03-04 16:07:52 $

=head1 SYNOPSIS

  make devtest

  perl inst/runtests.pl t/Bric/Test/PodTest.pm

  perl inst/runtests.pl t/Bric/Test/PodTest.pm | grep '***'

=head1 DESCRIPTION

This test class uses Pod::Checker to parse the POD in all of the modules in
the F<lib>, F<bin>, and F<t/Bric/Test> directories to make sure that they
contain no POD errors. It is run by C<make devtest>, but can also be run
individually, as shown in the synopsis. To just see output of errors and
warnings, pipe the test through C<grep>, as shown in the synopsis.

=cut

use strict;
use warnings;
use base qw(Bric::Test::Base);
use File::Find;
use File::Spec::Functions;
use Test::Pod;

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
    foreach my $mod (@{ $self->{mods} }) {
        pod_file_ok($mod);
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
    find( sub { push @mods, $File::Find::name if m/\.pm$/ }, 'lib',
          catdir('t', 'Bric', 'Test') );

    # Find the bin directory.
    die "Cannot find Bricolage lib directory"
      unless -d 'bin';

    # Find all the scripts.
    find( sub { push @mods, $File::Find::name if -f and -x }, 'bin' );
    return \@mods;
}

1;
__END__

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric::Test::Base|Bric::Test::Base>,L<Bric::Test::Runner|Bric::Test::Runner>,
L<Pod::Checker|Pod::Checker>
