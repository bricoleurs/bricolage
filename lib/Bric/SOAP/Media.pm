package Bric::SOAP::Media;
###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Business::Media;
use Bric::Biz::AssetType;
use Bric::Biz::Category;
use Bric::Util::Grp::Parts::Member::Contrib;
use Bric::Biz::Workflow qw(MEDIA_WORKFLOW);
use Bric::App::Session  qw(get_user_id);
use Bric::App::Authz    qw(chk_authz READ EDIT CREATE);
use XML::Writer;
use IO::Scalar;
use Carp qw(croak);

use Bric::SOAP::Util qw(category_path_to_id 
			xs_date_to_pg_date pg_date_to_xs_date
			parse_asset_document
		       );

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 NAME

Bric::SOAP::Media - SOAP interface to Bricolage media.

=head1 VERSION

$Revision: 1.1 $

=cut

our $VERSION = (qw$Revision: 1.1 $ )[-1];

=head1 DATE

$Date: 2002-02-05 23:43:37 $

=head1 SYNOPSIS

  use SOAP::Lite;
  import SOAP::Data 'name';

  # setup soap object to login with
  my $soap = new SOAP::Lite
    uri      => 'http://bricolage.sourceforge.net/Bric/SOAP/Auth',
    readable => DEBUG;
  $soap->proxy('http://localhost/soap',
               cookie_jar => HTTP::Cookies->new(ignore_discard => 1));
  # login
  $soap->login(name(username => USER), 
	       name(password => PASSWORD));

  # set uri for Media module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Media');

  # get a list of media_ids for all Illustrations (a Media Type)
  my $media_ids = $soap->list_ids(name(element => 'Illustration'));
  
=head1 DESCRIPTION

This module provides a SOAP interface to manipulating Bricolage media.

=cut

=head1 INTERFACE

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching media and returns a list
of ids.  If no media is found an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item title (M)

The media title.

=item description (M)

The media description.

=item uri (M)

The media uri.

=item simple (M)

A single OR search that hits title, description and uri.

=item workflow

The name of the workflow containing the media.  (ex. Media)

=item priority

The priority of the media object.

=item element

The name of the top-level element for the media.  Also know as the
"Media Type".  This value corresponds to the element attribute on the
media element in the asset schema.

=item publish_date_start

Lower bound on publishing date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item publish_date_end

Upper bound on publishing date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item cover_date_start

Lower bound on cover date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item cover_date_end

Upper bound on cover date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item expire_date_start

Lower bound on cover date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item expire_date_end

Upper bound on cover date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=back 4

Throws: NONE

Side Effects: NONE

Notes: Some obvious options are missing - category, file_name and the
SQL tweaking paramters (Order, Limit, etc.) in Bric::SOAP::Story most
obviously.  We should add them to
Bric::Biz::Asset::Business::Media->list() and then support them here
too.

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(title description
				 simple uri priority
				 workflow element
				 publish_date_start publish_date_end
				 cover_date_start cover_date_end
				 expire_date_start expire_date_end);
sub list_ids {
    my $self = shift;
    my $env = pop;
    my $args = $env->method || {};    
    
    print STDERR __PACKAGE__ . "->list_ids() called : args : ", 
	Data::Dumper->Dump([$args],['args']) if DEBUG;
    
    # check for bad parameters
    for (keys %$args) {
	die __PACKAGE__ . "::list_ids : unknown parameter \"$_\".\n"
	    unless exists $allowed{$_};
    }
    
    # handle workflow => workflow__id mapping
    if (exists $args->{workflow}) {
	my ($workflow_id) = Bric::Biz::Workflow->list_ids(
			        { name => $args->{workflow} });
	die __PACKAGE__ . "::list_ids : no workflow found matching " .
	    "(workflow => \"$args->{workflow}\")\n"
		unless defined $workflow_id;
	$args->{workflow__id} = $workflow_id;
	delete $args->{workflow};
    }
    
    # handle element => element__id conversion
    if (exists $args->{element}) {
	my ($element_id) = Bric::Biz::AssetType->list_ids(
			      { name => $args->{element} });
	die __PACKAGE__ . "::list_ids : no element found matching " .
	    "(element => \"$args->{element}\")\n"
		unless defined $element_id;
	$args->{element__id} = $element_id;
	delete $args->{element};
    }
    
    # handle category => category_id conversion
    if (exists $args->{category}) {
	my $category_id = category_path_to_id($args->{category});
	die __PACKAGE__ . "::list_ids : no category found matching " .
	    "(category => \"$args->{category}\")\n"
		unless defined $category_id;
	$args->{category_id} = $category_id;
	delete $args->{category};      
    }
    
    # translate dates into proper format
    for my $name (grep { /_date_/ } keys %$args) {
	my $date = xs_date_to_pg_date($args->{$name});
	die __PACKAGE__ . "::list_ids : bad date format for $name parameter " .
	    "\"$args->{$name}\" : must be proper XML Schema dateTime format.\n"
		unless defined $date;
	$args->{$name} = $date;
    }
    
    my @list = Bric::Biz::Asset::Business::Media->list_ids($args);
    
    print STDERR "Bric::Biz::Asset::Business::Media->list_ids() called : ",
	"returned : ", Data::Dumper->Dump([\@list],['list'])
	    if DEBUG;
    
    # name the results
    my @result = map { name(media_id => $_) } @list;
    
    # name the array and return
    return name(media_ids => \@result);
}
}


=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

1;
