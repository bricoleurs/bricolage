package Bric::Util::Language;
###############################################################################

=head1 NAME

Bric::Util::Language - Bricolage Localization

=head1 VERSION

$Revision: 1.9 $

=cut

our $VERSION = (qw$Revision: 1.9 $ )[-1];

=head1 DATE

$Date: 2003-02-12 15:52:58 $

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

#sub maketext {
#    my $self = shift(@_);
#    my $value = $self->SUPER::maketext(@_);
#    return $value;
#}

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

