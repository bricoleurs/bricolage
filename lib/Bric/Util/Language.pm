package Bric::Util::Language;
###############################################################################

=head1 NAME

Bric::Util::Language - Bricolage Localization

=head1 VERSION

$Revision: 1.10 $

=cut

our $VERSION = (qw$Revision: 1.10 $ )[-1];

=head1 DATE

$Date: 2003-03-12 03:25:57 $

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

=head1 ADDING NEW LANGUAGES

=over

=item *

Add new Bric::Util::Language subclass, named for your language code with
dashes changed to underscores and all lowercase letters. For example, en-US
would be "en_us". This will be known as the "key" for your language. Add the
constant C<key> to your new subclass and have it return the key.

=item *

Copy the localization messages from Bric::Util::Language into your new
subclass and change the Portuguese translations of the English words and
phrases into your languages. Make sure to use the UTF-8 character set.

=item *

Document your new language key in Bric::Admin.

=item *

Create a new subdirectory in F<comp/media/images> named for your language.
Copy all of the files from the F<comp/media/images/en_us> directory to your
new language directlry and sipmly recreate them in your language.

=back

=head1 AUTHOR

ClE<aacute>udio Valente <cvalente@co.sapo.pt>

=head1 SEE ALSO

