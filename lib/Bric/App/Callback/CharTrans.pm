package Bric::App::Callback::CharTrans;

use strict;
use base qw(Bric::App::Callback);
use Bric::App::Util qw(get_pref);
use Bric::Util::Fault qw(:all);
use Bric::Config qw(:l10n);

__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'char_trans';

BEGIN {
    foreach my $char_set ( @{ LOAD_CHAR_SETS() } ) {
        if ($char_set !~ /utf-8/i) {
            require Bric::Util::CharTrans;
            # This seems to be the only way to force Encode to pre-load
            # various character sets.
            my $string = 'foo';
            Encode::encode($char_set, $string);
        }
    }
}

use constant CHAR_TRANS_LOADED => $Bric::Util::CharTrans::VERSION;

sub to_utf8 : PreCallback {
    my $self = shift;

    my $char_set = get_pref('Character Set');
    return if $char_set eq 'UTF-8';

    # Make sure that CharTrans is loaded.
    require Bric::Util::CharTrans unless CHAR_TRANS_LOADED;

    my $ct = Bric::Util::CharTrans->new($char_set);
    $ct->to_utf8($self->params);
}

# This method isn't a callback, but it called from the root-level autohandler
# to convert the outgoing page from UTF-8.
sub from_utf8 {
    my $self = shift;
    my $char_set = get_pref('Character Set');
    return if $char_set eq 'UTF-8';

    # Make sure that CharTrans is loaded.
    require Bric::Util::CharTrans unless CHAR_TRANS_LOADED;

    my $ct = Bric::Util::CharTrans->new($char_set);
    $ct->from_utf8(shift);
}
