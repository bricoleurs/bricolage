#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

my ($name) = row_array("SELECT name FROM element WHERE key_name = ''");
exit unless defined $name;

my $key_name = lc $name;
$key_name =~ y/a-z0-9/_/cs;

print "######################################################################

    Due to a bug in Bricolage 1.7.1, element '$name' has the
    empty string ('') for its key name. To address this problem,
    this upgrade script has given it the name '$key_name'. If this
    is incorrect, you'll need to update the element table in the
    database to change it to the key name you require. Apologies
    for the inconvenience.

######################################################################\n";

my $set_key_name = prepare("UPDATE element SET key_name = ? WHERE key_name = ''");
execute($set_key_name, $key_name);

__END__
