package Bric::App::Callback::Util;

use strict;

use base qw(Exporter);
our @EXPORT_OK = qw(parse_uri);
our %EXPORT_TAGS = (all => \@EXPORT_OK);


# replaces comp/lib/util/parseUri.mc

sub parse_uri {
    my $uri = shift;
    return split /\//, substr($uri, 1);
}


1;
