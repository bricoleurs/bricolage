package Bric::Util::CharTrans::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Util::CharTrans;
use File::Spec::Functions qw(catfile);
use File::Basename;
use Storable qw(dclone);
use Bric::Config qw(:char);

# Borrowed these files from the Encode test suite, but renamed them and
# truncated each of them to 100 lines. I figure if we demonstrate that
# Encode is working, then Encode's own tests can be the comprehensive ones!
my %test_files =
  ('euc-cn'    => [ catfile(dirname(__FILE__), 'euc-cn.enc'),
                    catfile(dirname(__FILE__), 'euc-cn.utf') ],
   'euc-jp'    => [ catfile(dirname(__FILE__), 'euc-jp.enc'),
                    catfile(dirname(__FILE__), 'euc-jp.utf') ],
   'euc-kr'    => [ catfile(dirname(__FILE__), 'euc-kr.enc'),
                    catfile(dirname(__FILE__), 'euc-kr.utf') ],
   'big5-eten' => [ catfile(dirname(__FILE__), 'big5-eten.enc'),
                    catfile(dirname(__FILE__), 'big5-eten.utf') ]
  );

##############################################################################
# Simple string conversion tests.
##############################################################################
sub test_strings : Test(1612) {
    my $self = shift;

    # Failing constructors.
    eval { Bric::Util::CharTrans->new };
    ok( my $err = $@, "Got no charset exception" );
    isa_ok($err, 'Bric::Util::Fault::Exception::GEN');

    eval { Bric::Util::CharTrans->new('flintstone_runes') };
    ok( $err = $@, "Got bogus charset exception" );
    isa_ok($err, 'Bric::Util::Fault::Exception::GEN');

    while (my ($charset, $files) = each %test_files) {
        ok( my $ct = Bric::Util::CharTrans->new($charset),
            "Create new CT for '$charset' charset" );
        isa_ok($ct, 'Bric::Util::CharTrans');
        open ENC, $files->[0] or die "Unable to open $files->[0]: $!\n";
        open UTF, $files->[1] or die "Unable to open $files->[1]: $!\n";
        my $i;
        while (my $enc_line = <ENC>) {
            my $utf_line = <UTF>;
            ++$i;
            my $cp = $enc_line;
            ok( $ct->to_utf8($cp), "Convert $charset line $i to UTF-8" );
            is( $cp, $utf_line, "Compare to UTF-8");
            $cp = $utf_line;
            ok( $ct->from_utf8($cp), "Convert line $i to $charset" );
            is( $cp, $enc_line, "Compare to $charset");
        }
    }
}

##############################################################################
# Test conversion of complex structures.
##############################################################################
sub test_structs : Test(24) {
    my $self = shift;
    while (my ($charset, $files) = each %test_files) {
        ok( my $ct = Bric::Util::CharTrans->new($charset),
            "Create new CT for '$charset' charset" );
        isa_ok($ct, 'Bric::Util::CharTrans');
        open ENC, $files->[0] or die "Unable to open $files->[0]: $!\n";
        open UTF, $files->[1] or die "Unable to open $files->[1]: $!\n";

        # Create a hash of arrays of hashes, with a scalarref for good
        # measure.
        my $enc_struct = { one => [ scalar <ENC>, scalar <ENC>, scalar <ENC>,
                                    { two   => scalar <ENC>,
                                      three => scalar <ENC>,
                                      four  => scalar <ENC>,
                                    },
                                    \scalar <ENC>
                                  ]
                         };

        # Do the same with some UTF-8 data.
        my $utf_struct = { one => [ scalar <UTF>, scalar <UTF>, scalar <UTF>,
                                    { two   => scalar <UTF>,
                                      three => scalar <UTF>,
                                      four  => scalar <UTF>,
                                    },
                                    \scalar <UTF>
                                  ]
                         };

        # Close the files.
        close ENC;
        close UTF;

        # Now clone (deep copy) those data structures.
        my $enc_struct_clone = dclone $enc_struct;
        my $utf_struct_clone = dclone $utf_struct;

        # Now try to convert the encoded string to UTF-8.
        ok( $ct->to_utf8($enc_struct_clone),
            "Convert $charset structure to UTF-8" );
        # It should be UTF-8 now!
        is_deeply($enc_struct_clone, $utf_struct,
                  "$charset structure converted to UTF-8 structure");

        # Now try to convert the UTF-8 string the encoding.
        ok( $ct->from_utf8($utf_struct_clone),
            "Convert UTF-8 structure to $charset" );
        # It should be UTF-8 now!
        is_deeply($utf_struct_clone, $enc_struct,
                  "UTF-8 structure converted to $charset structure");

    }
}

1;
