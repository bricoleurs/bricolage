package Bric::Util::Language;
###############################################################################

=head1 NAME

Bric::Util::Language - Bricolage Localization

=head1 VERSION

$Revision: 1.9.2.1 $

=cut

our $VERSION = (qw$Revision: 1.9.2.1 $ )[-1];

=head1 DATE

$Date: 2003-03-07 07:42:20 $

=head1 SYNOPSIS

To follow

=head1 DESCRIPTION

To follow

=cut


#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies
use Bric::Util::Fault::Exception::MNI;

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw(Locale::Maketext);
#use Bric::Config qw(:char);

sub maketext { shift->SUPER::maketext(ref $_[0] ? @{$_[0]} : @_) }

sub key {
    my $self = shift;
    my $pkg = ref $self || $self;
    die Bric::Util::Fault::Exception::MNI->new
      ({ msg => "Method $pkg->key not implemented" })
}

1;
__END__

=head1 AUTHOR

ClE<aacute>udio Valente <cvalente@co.sapo.pt>

=head1 SEE ALSO

