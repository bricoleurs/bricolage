package Bric::SOAP::Template;
###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Formatting;
use Bric::Biz::AssetType;
use Bric::Biz::Category;
use Bric::Biz::Workflow qw(TEMPLATE_WORKFLOW);
use Bric::App::Session  qw(get_user_id);
use Bric::App::Authz    qw(chk_authz READ EDIT CREATE);
use XML::Writer;
use Carp qw(croak);

use Bric::SOAP::Util qw(category_path_to_id 
			xs_date_to_pg_date pg_date_to_xs_date
			parse_asset_document
		       );
use Bric::SOAP::Media;

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 1;
require Data::Dumper if DEBUG;

=head1 NAME

Bric::SOAP::Template - SOAP interface to Bricolage templates.

=head1 VERSION

$Revision: 1.1 $

=cut

our $VERSION = (qw$Revision: 1.1 $ )[-1];

=head1 DATE

$Date: 2002-02-13 00:51:57 $

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

  # set uri for Template module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Template');

  # get a list of template_ids in the root category
  my $template_ids = $soap->list_ids(name(category => '/'))->result;
  
=head1 DESCRIPTION

This module provides a SOAP interface to manipulating Bricolage templates.

B<IMPLEMENTATION INCOMPLETE>

=cut

=head1 INTERFACE

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the story database for matching templates and
returns a list of ids.  If no templates are found an empty list will be
returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item element (M)

The template's element name.

=item file_name (M)

The template's file_name.

=item output_channel

The output channel for the template.

=item category

A category containing the story, given as the complete category path
from the root.  Example: "/news/linux".

=item workflow

The name of the workflow containing the template.

=item simple (M)

a single OR search that hits element and filename.

=item priority

The priority of the template.

=item publish_status

Stories that have been published have a publish_status of "1",
otherwise "0".

=item deploy_date_start

Lower bound on deploy date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item deploy_date_end

Upper bound on deploy date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item expire_date_start

Lower bound on expire date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=item expire_date_end

Upper bound on expire date.  Given in XML Schema dateTime format
(CCYY-MM-DDThh:mm:ssTZ).

=back 4

Throws: NONE

Side Effects: NONE

Notes: SQL tweaking paramters (Order, Limit, etc.) as in Bric::SOAP::Story
are not available here. We should add them to
Bric::Biz::Asset::Formatting->list() and then support them here too.

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(element file_name output_channel
				 category workflow simple
				 priority publish_status element
				 deploy_date_start deploy_date_end
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

    # element is name for templates
    $args->{name} = delete $args->{element}
      if exists $args->{element};
    
    my @list = Bric::Biz::Asset::Formatting->list_ids($args);
    
    print STDERR "Bric::Biz::Asset::Formatting->list_ids() called : ",
	"returned : ", Data::Dumper->Dump([\@list],['list'])
	    if DEBUG;
    
    # name the results
    my @result = map { name(template_id => $_) } @list;
    
    # name the array and return
    return name(template_ids => \@result);
}
}

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

1;
