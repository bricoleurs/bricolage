package Bric::Util::Language::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(no_plan) {
    use_ok('Bric::Util::Language');
    # XXX Do we need t make this OS-sensitive?
    (my $dir = $INC{'Bric/Util/Language.pm'}) =~ s/\.pm$//;
    opendir LANGS, $dir or die "Cannot open directory '$dir': $!\n";
    while (my $lang = readdir LANGS) {
        next unless $lang =~ s/\.pm$//;
        use_ok("Bric::Util::Language::$lang");
    }
    closedir LANGS;
}

1;
__END__
