package Bric::Test::PodTest;

=head1 NAME

Bric::Test::Base - Bricolage Development Testing Base Class

=head1 VERSION

$Revision: 1.8 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.8 $ )[-1];

=head1 DATE

$Date: 2003-02-18 19:15:20 $

=head1 SYNOPSIS

See L<Bric::Test::Runner|Bric::Test::Runner>.

=head1 DESCRIPTION

This test class uses Pod::Checker to parse the POD in all of the modules in
the F<lib>, F<bin>, and F<t/Bric/Test> directories to make sure that they
contain no POD errors.

=cut

use strict;
use warnings;
use base qw(Bric::Test::Base);
use File::Find;
use File::Spec::Functions;
use Pod::Checker;
use IO::Scalar;
use Test::More;

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
    my $test_dir = catdir 't', 'Bric';
    $test_dir = qr/^$test_dir/;
    my $mods = $self->{mods};
    foreach my $module (@$mods) {
        # Set up an error file handle and a POD checker object.
        my $errstr = '';
        my $errors = IO::Scalar->new(\$errstr);
        open my $fh, '<', $module or die "Cannot open '$module': $!\n";
        my $checker = Pod::Checker->new( -warnings => 1 );
        $checker->parse_from_filehandle($fh, $errors);
        ok( $checker->num_errors == 0, "Check ${module}'s POD" );
        if ($errstr =~ m/^\*\*\*/) {
            # There are warnings or errors. So print error string via diag.
            $errstr =~ s/\(unknown\)/$module/g;
            diag( $errstr )
        }
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
