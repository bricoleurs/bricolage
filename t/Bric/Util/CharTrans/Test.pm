package Bric::Util::CharTrans::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }

##############################################################################
# Test class loading.
##############################################################################
sub test_load : Test(1) {
    use_ok('Bric::Util::CharTrans');
}


__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use strict;
use Test;

BEGIN { plan tests => 55}

use lib qw(../..);

use Bric::Util::CharTrans;

my $from_or_to = shift;
my $charset = shift;

if ($charset) {
   # skip tests, do a file conversion..
   my $text;
   while (<>) {
	$text .= $_;
   }
   my $ct = new Bric::Util::CharTrans($charset);

   die "$!" unless ($ct);

   my $out;
   if ($from_or_to eq 'from') {
     print $ct->to_utf8($text);
   } else {
     print $ct->from_utf8($text);
   }

   exit;
}

#############################################################
print <<EOF

Verify Module Loads
EOF
;

ok(1);



#############################################################
print <<EOF

Create broken object, flintstone_runes
EOF
;
my $chartrans;

eval { $chartrans = new Bric::Util::CharTrans('flintstone_runes');};

ok($@);


#############################################################
print <<EOF

Create bogus empty object, no args at all..
EOF
;

eval { $chartrans = new Bric::Util::CharTrans()};

ok($@);

#############################################################
print <<EOF

Create new object, iso8859-1
EOF
;

eval { $chartrans = new Bric::Util::CharTrans('iso-8859-1');};
ok(!$@ && defined($chartrans));
print "$@" if ($@);
######################################################################

die "can't continue" unless ($chartrans);  # can't continue without it..

# Test proper behavior for conversions

my $ascii_utf8 = {
    '' => '',
    'abcdefghijklmnopqrstuvwxyz' => 'abcdefghijklmnopqrstuvwxyz',
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ' => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    '0123456789!@#$%^&*()_-+=[]{}:;,.<>/?\|\'"`~' =>     '0123456789!@#$%^&*()_-+=[]{}:;,.<>/?\|\'"`~',
    "\n\t\r" => "\n\t\r"
    };

test_set('ASCII', $ascii_utf8);

my $latin1_utf8 = {
   'áàäâãÁÀÄÂÃ ç éèëêÉÈËÊ  íìïîÍÌÏÎ óòöôõÓÒÖÔÕ ñÑ úùüûÚÙÜÛ' =>

'Ã¡Ã Ã¤Ã¢Ã£ÃÃ€Ã„Ã‚Ãƒ Ã§ Ã©Ã¨Ã«ÃªÃ‰ÃˆÃ‹ÃŠ  Ã­Ã¬Ã¯Ã®ÃÃŒÃÃŽ Ã³Ã²Ã¶Ã´ÃµÃ“Ã’Ã–Ã”Ã• Ã±Ã‘ ÃºÃ¹Ã¼Ã»ÃšÃ™ÃœÃ›',
   'åÅ øØ æÆ ýÿÝ ¡ðþß«»' => 'Ã¥Ã… Ã¸Ã˜ Ã¦Ã† Ã½Ã¿Ã Â¡Ã°Ã¾ÃŸÂ«Â»',
   };


test_set('ISO-8859-1', $latin1_utf8);

#####################################################################
my $latin2_utf8 = {
  'mù¾e být pou¾ito za pou¾ití Mo¿na ju¿ zamieniæ zawarto¶æ' => 
  'mÅ¯Å¾e bÃ½t pouÅ¾ito za pouÅ¾itÃ­ MoÅ¼na juÅ¼ zamieniÄ‡ zawartoÅ›Ä‡'
   };

eval { $chartrans = new Bric::Util::CharTrans('iso-8859-2');};
ok(!$@ && defined($chartrans));
print "$@" if ($@);
test_set('ISO-8859-2', $latin2_utf8);

#####################################################################
my $jis_utf8 = {
     '$B%W%m%@%/%H(BOK' => 'ãƒ—ãƒ­ãƒ€ã‚¯ãƒˆOK',
     '$B%l%C%I%O%C%H$N;qK\(BOK' => 'ãƒ¬ãƒƒãƒ‰ãƒãƒƒãƒˆã®è³‡æœ¬OK',
     'test ascii' => 'test ascii'
   };

eval { $chartrans = new Bric::Util::CharTrans('ISO-2022-JP');};
ok(!$@ && defined($chartrans));
print "$@" if ($@);
test_set('ISO-2022-JP', $jis_utf8);

######################################################################
my $sjis_utf8 = {
	'' => '',
};

eval { $chartrans = new Bric::Util::CharTrans('ISO-2022-JP');};
ok(!$@ && defined($chartrans));
print "$@" if ($@);
test_set('ISO-2022-JP', $sjis_utf8);

######################################################################
# Test a set of translations
#
# First test scalar, then test ref..

sub test_set {
  my ($name, $set) = @_;
  print "*** Testing set $name\n";
  foreach my $t (sort(keys(%{$set}))) {
    my $as_utf8 = $set->{$t};

    my $result = $chartrans->to_utf8($t);
    
    print "Testing '$t'\n";
    ok($result, $as_utf8);
    my $storage = $t;

    $chartrans->to_utf8(\$storage);
    ok($storage, $as_utf8);

    print "...reversed\n";
    $result = $chartrans->from_utf8($as_utf8);
    ok ($result, $t);

    $storage = $as_utf8;
    $chartrans->from_utf8(\$storage);
    ok($storage, $t); 
  }
  if  ($name eq 'iso-8859-1') {
  my $texts = ['abcdefg','áàäâãÁÀÄÂÃ', ['bbb', 'ccc'], {a=>"Ã111222", b=>'2222'}];
  print "Testing multilevel data structure fixing\n";
  use Data::Dumper;
  print Dumper($texts);
  $chartrans->to_utf8($texts);
  print "Recursive conversion...\n";
  use Data::Dumper;
  print Dumper($texts), "\n";
  }
}

