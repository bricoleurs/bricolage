package Bric::App::Callback::Test;

use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::App::Callback;
use File::Spec::Functions qw(catfile);

##############################################################################
# Start by getting a list of the callback classes we want to load. Grab them
# from Bric::App::Handler.
my @cb_classes;
BEGIN {
    my $handler = catfile qw(lib Bric App Handler.pm);
    open AH, $handler or die "Cannot open '$handler' : $!\n";
    while (<AH>) {
        next unless /use (Bric::App::Callback::[^;]*)/;
        push @cb_classes, $1;
    }
}

##############################################################################
# Now set up the test. We eval it in a BEGIN block so that Test::Harness can
# be told how many tests there are at compile time.
BEGIN {
    my $num_classes = @cb_classes;

    eval qq[
sub test_load_cb_classes : Test($num_classes) {
    foreach my \$class (\@cb_classes) {
        use_ok(\$class);
    }
}];

}

1;
__END__
