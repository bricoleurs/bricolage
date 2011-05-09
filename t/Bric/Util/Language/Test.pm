package Bric::Util::Language::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use File::Spec;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(17) {
    use_ok('Bric::Util::Language');
    my $dir = File::Spec->catdir(qw(lib Bric Util Language), '');
    opendir LANGS, $dir or die "Cannot open directory '$dir': $!\n";
    while (my $lang = readdir LANGS) {
        next unless $lang =~ s/\.pm$//;
        use_ok("Bric::Util::Language::$lang");
    }
    closedir LANGS;
}

##############################################################################
# Test escaped special characters
##############################################################################
sub test_localize : Test(3) {
    use_ok('Bric::Util::Language');
    ok(my $lang = Bric::Util::Language->get_handle("de_de"),
       'Get German translation');
    is($lang->maketext('Me, ~~myself~~, and ~[I~] ~,'),
       'Me, ~myself~, and [I] ~,',
       "Special characters are unescaped properly");
}

1;
__END__
