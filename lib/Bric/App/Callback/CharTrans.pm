package Bric::App::Callback::CharTrans;

use strict;
use base qw(Bric::App::Callback);
use Bric::Config qw(:char);
use Bric::Util::Fault qw(:all);

__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'char_trans';

BEGIN {
    # Load everything up in a BEGIN block so that it actually only compiles and
    # Loads if the character set isn't UTF-8.
    if (CHAR_SET ne 'UTF-8') {
        eval q{
            require Bric::Util::CharTrans;
            $ct = Bric::Util::CharTrans->new(CHAR_SET);
            sub char_trans : PreCallback {
                my $self = shift;

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
        };
    }
}

