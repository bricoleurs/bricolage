package Bric::Util::Language;

###############################################################################

=encoding utf8

=head1 Name

Bric::Util::Language - Bricolage Localization

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

To follow

=head1 Description

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
use Bric::Config qw(LOAD_LANGUAGES);
use Bric::Util::Fault qw(throw_mni);

BEGIN {
    foreach my $lang ( @{ LOAD_LANGUAGES() } ) {
        my $module = "Bric::Util::Language::$lang";
        eval "use $module";
        die $@ if $@;
    }
}

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw(Locale::Maketext);

my $INSTANCE;
sub get_handle { $INSTANCE = shift->SUPER::get_handle(@_) }
sub instance { $INSTANCE }

sub maketext { shift->SUPER::maketext(ref $_[0] ? @{$_[0]} : @_) }

sub key {
    my $self = shift;
    my $pkg = ref $self || $self;
    throw_mni "Method $pkg->key not implemented";
}


1;
__END__

=head1 Adding New Languages

=over

=item *

Add new Bric::Util::Language subclass, named for your language code with
dashes changed to underscores and all lowercase letters. For example, en-US
would be "en_us". This will be known as the "key" for your language. Add the
constant C<key> to your new subclass and have it return the key.

=item *

Copy the localization messages from Bric::Util::Language::de_de into your new
subclass and change the German translations of the English words and phrases
into your language. Be sure to use the UTF-8 character set.

=item *

Add your name to F<comp/widgets/help/translators.html> for your language.

=item *

Copy F<contrib/button_gen/bric_buttons.de_de.txt> to a new file named with
your language key substituted for "de_de". Translate the button labels in your
new text file. Make sure that the character set you use is supported by the
Gimp. Then run the scripts to generate the buttons (or ask someone on
bricolage-devel to do so) and put them into a new subdirectory in
F<comp/media/images> named for your language key.

=item *

Create a new subdirectory in F<comp/help> named for your language key. Copy
all of the subdirectories and files from the F<comp/help/en_us> directory to
your new language directory and translate them. Be sure to use the UTF-8
character set.

=item *

Copy F<comp/media/js/en_us_messages.js> to a new JavaScript file named with
your language key substituted for "en_us". Translate the JavaScript messages
in your new JavaScript file. Be sure to use the UTF-8 character set.

=item *

Copy F<comp/media/css/en_us.css> to a new CSS file named with your language
key substituted for "en_us". Add any CSS that your langauge requires, such as
special fonts, right-to-left text, font sizes, etc. Many languages will
require no special CSS, in which case you can leave your new CSS file empty.

=item *

Add an C<INSERT> statement to F<sql/Pg/Bric/Util/Pref.val>.

=item *

Write a migration script to add the new language key to the database. It
should go into a subdirectory of F<instup/upgrade> named for the expected next
version of Bricolage. Model it on F<inst/upgrade/1.10.2/add_ja.pl>; all you
need to is change all instances of "ja" to your new language key.

=back

=head1 Author

ClE<aacute>udio Valente <cvalente@co.sapo.pt>

=head1 See Also

