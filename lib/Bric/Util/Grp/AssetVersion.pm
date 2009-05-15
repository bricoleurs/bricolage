package Bric::Util::Grp::AssetVersion;

use strict;
use base qw(Bric::Util::Grp);
use constant CLASS_ID => 25;
sub get_secret { Bric::Util::Grp::SECRET_GRP }
sub get_class_id { CLASS_ID }

1;
__END__

=head1 Name

Bric::Util::Grp::AssetVersion - Legacy Group Class

=head1 Description


This is a dummy class to keep upgraded installations from breaking when
Bric::Util::Grp loads classes based on the contents of the contents of the
Class table. Unfortunately trying to delete from the Class table triggeres a
cascading delete of dangerous proportions. If we find a way around that then
we can remove this file.

=cut
