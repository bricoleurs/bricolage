#!/usr/bin/perl -w

=head1 NAME

bin.pl - moves bin/ to bbin/ before installing to keep the originals intact

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate: $

=head1 DESCRIPTION

MakeMaker modifies shebang of the files in bin/ during "make install," but we
need to keep the originals intact, so we copy them to bbin/ and install from
there.

=head1 AUTHOR

Marshall Roch <marshall@exclupen.com>

=cut


use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Path qw(mkpath);

mkpath 'bbin';
system("cp", "-R", "./bin/*", "./bbin");

exit 0;
