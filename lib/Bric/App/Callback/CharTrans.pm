package Bric::App::Callback::CharTrans;

use strict;
use base qw(Bric::App::Callback);
use Bric::App::Util qw(get_pref);
use Bric::Util::CharTrans;
use Bric::Util::Fault qw(:all);

__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'char_trans';

sub char_trans : PreCallback {
    my $self = shift;

    my $char_set = get_pref('Character Set');
    if ($char_set ne 'UTF-8') {
        my $ct = Bric::Util::CharTrans->new($char_set);

        # Translate chars if non-UTF8 (see also Handler.pm)
        eval { $ct->to_utf8($self->params) };
        if ($@) {
            if (isa_bric_exception($@)) {
                rethrow_exception($@);
            } else {
                throw_dp error => 'Error translating from ' .
                    $ct->charset . ' to UTF-8.',
                        payload    => $@;
            }
        }
    }
}

