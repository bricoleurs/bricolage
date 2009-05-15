package Bric::Test::PodTest;

=head1 Name

Bric::Test::Base - Bricolage Development Testing Base Class

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  make devtest

  perl inst/runtests.pl t/Bric/Test/PodTest.pm

=head1 Description

This test class uses Pod::Checker to parse the POD in all of the modules in
the F<lib>, F<bin>, and F<t/Bric/Test> directories to make sure that they
contain no POD errors. It is run by C<make devtest>, but can also be run
individually, as shown in the synopsis.

=cut

use strict;
use warnings;
use base qw(Bric::Test::Base);
use File::Find;
use File::Spec::Functions;
use Test::Pod;

##############################################################################
# Start by getting a list of the files we want to check.
my $files;
BEGIN {
    # Find the lib directory.
    die "Cannot find Bricolage lib directory"
      unless -d 'lib';

    # Find the test lib directory.
    die "Cannot fine Bricolage test lib directory"
      unless -d 't';

    # Find all the modules.
    find( sub {
              push @$files, $File::Find::name
                if $File::Find::dir !~ m{blib/} and (m{\.pm$} or m{\.pod$})
          },
          'lib', catdir('t', 'Bric', 'Test') );

    # Find the bin directory.
    die "Cannot find Bricolage lib directory"
      unless -d 'bin';

    # Find all the scripts.
    find( sub { push @$files, $File::Find::name if -f and -x }, 'bin' );
}

##############################################################################
# Now set up the test. We eval it in a BEGIN block so that Test::Harness can
# be told how many tests there are at compile time.
BEGIN {
    my $num_files = scalar @$files;

    eval qq[
sub test_pod : Test($num_files) {
    foreach my \$mod (\@\$files) {
        pod_file_ok(\$mod);
    }
}];
}

1;
__END__

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric::Test::Base|Bric::Test::Base>,L<Bric::Test::Runner|Bric::Test::Runner>,
L<Pod::Checker|Pod::Checker>
