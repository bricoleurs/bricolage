#!/usr/bin/perl -w

=head1 NAME

Story.pl - a test script for Bric::SOAP::Story

=head1 SYNOPSIS

  $ ./Story.pl
  ok 1 ...

=head1 DESCRIPTION

This is a Test::More test script for the Bric::SOAP::Story module.  It
requires a mix of stories in the running Bricolage instance to work
properly.

Bricolage requirements are:

=over 4

=item *

Multiple stories in different categories.

=item *

Some stories that have been published and some that haven't.

=item *

Some stories of the 'Story' story type.

=item *

A workflow named 'Story' with stories in it.

=back

Also, to get the most out of the tests you'll need to install the
Xerces C++ library.  See:

    http://xml.apache.org/xerces-c/index.html

for details.  You need a later version than 1.6.0 which currently
means the CVS version.  Also, you need to install the sample program
DOMCount into your path.

You can still run the tests without Xerces C++ installed but the
schema validation tests will be skipped.

=head1 CONSTANTS

=over 4

=item USER

Set this to a working login.

=item PASSWORD

Set this to the password for the USER account.

=item DEBUG

Set this to 1 to see debugging text including the full XML for every
SOAP method call and response.  Highly educational.

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=cut

use strict;
use constant DEBUG => 0;

use constant USER     => 'admin';
use constant PASSWORD => 'bric';

use Test::More qw(no_plan);
use SOAP::Lite (DEBUG ? (trace => [qw(debug)]) : ());
import SOAP::Data 'name';
use Data::Dumper;
use XML::Simple;
use File::Temp qw(tempfile);
use Carp;
use Carp::Heavy; # for some reason if I remove this I can't get syntax
                 # errors, I just get Carp errors.

use Bric::Biz::Asset::Business::Story;
use Bric::Biz::AssetType;
use Bric::Biz::Workflow;
use HTTP::Cookies;

# check to see if we have Xerces C++ to use for Schema validation
our $has_xerces = 0;
my $test;
eval { $test = `DOMCount -? 2>&1`;    };
$has_xerces = 1 if $test =~ /This program invokes the DOM parser/;

# setup soap object to login with
my $soap = new SOAP::Lite
    uri      => 'http://bricolage.sourceforge.net/Bric/SOAP/Auth',
    readable => DEBUG;
$soap->proxy('http://localhost/soap',
	     cookie_jar => HTTP::Cookies->new(ignore_discard => 1));
isa_ok($soap, 'SOAP::Lite');

my ($response, $story_ids);

# login
$response = $soap->login(name(username => USER), 
			 name(password => PASSWORD));
ok(!$response->fault, 'fault check');

my $success = $response->result;
ok($success, "login success");

# set uri for Story module
$soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Story');

# if (0) {

# try selecting every story
$response = $soap->list_ids();
ok(!$response->fault, 'fault check');

$story_ids = $response->result;
isa_ok($story_ids, 'ARRAY');
ok(@$story_ids, 'list_ids() returned some story_ids');

# try a query returning an empty list
my $response2 = $soap->list_ids(name(title => 'FOO' . rand() . 'BAR'));
ok(!$response2->fault, "SOAP result is not a fault");
my $story_ids2 = $response2->result;
isa_ok($story_ids2, 'ARRAY');
is(@$story_ids2, 0, 'list_ids() returned 0 story_ids');

# try a set of queries and make sure we get the same result using the
# SOAP interface and Bric::Biz::Asset::Business::Story

# get element_id for 'Story' element for use in tests
my ($story_element_id) = Bric::Biz::AssetType->list_ids({name => 'Story'});
ok($story_element_id, "Got element id for story");

# get workflow_id for use in tests
my ($workflow_id) = Bric::Biz::Workflow->list_ids({ name => 'Story' });
ok($workflow_id, "Got workflow id for Story");

# pairs of list_ids() and normal list_ids() arg hashes that must return
# the same list of stories.
my @queries = (
	       [ { }, { } ],
	       [ { publish_status => 1 }, { publish_status => 1 } ],
	       [ { element => 'Story' },
		 { element__id => $story_element_id } ],
	       [ { category => '/', },
		 { category_id => 0 }, ],
	       [ { workflow => 'Story' },
		 { workflow__id => $workflow_id } ],
	      );

foreach my $queries (@queries) {
  my ($soap_query, $query) = @$queries;

  # try Bric::SOAP::Story
  my $response = $soap->list_ids(map { name($_, $soap_query->{$_}) } 
			      keys %$soap_query);
  ok(!$response->fault, 'SOAP result is not a fault');
  my $soap_story_ids = $response->result;
  isa_ok($soap_story_ids, 'ARRAY');

  # try Bric::Biz::Asset::Business::Story
  my @bric_story_ids = Bric::Biz::Asset::Business::Story->list_ids($query);

  # compare the lists, truely, madly, deeply.
  @$soap_story_ids = sort @$soap_story_ids;
  @bric_story_ids  = sort @bric_story_ids;
  print STDERR "Bric: ", join(', ', @bric_story_ids), "\n"  if DEBUG;
  print STDERR "SOAP: ", join(', ', @$soap_story_ids), "\n" if DEBUG;

  is_deeply(\@bric_story_ids, $soap_story_ids, 
	    "Comparing SOAP to non-SOAP query : (" . 
	    join(', ', map { "$_ => $soap_query->{$_}" } keys %$soap_query) . 
	    ")");
}

# }

# select every story
$response = $soap->list_ids();
ok(!$response->fault, 'SOAP result is not a fault');

$story_ids = $response->result;
isa_ok($story_ids, 'ARRAY');
ok(@$story_ids, 'list_ids() returned some story_ids');

# get schema ready for checking documents
my $xsd = extract_schema();
ok($xsd, "Extracted XSD from Bric::SOAP: $xsd");

# if (0) {

# try exporting every story
foreach my $story_id (@$story_ids) {
  $response = $soap->export(name(story_id => $story_id));
  if ($response->fault) {
    fail('SOAP export() response fault check');
  } else {
    pass('SOAP export() response fault check');  
    
    my $document = $response->result;
    ok($document, "recieved document for story $story_id");
    check_doc($document, $xsd, "story $story_id");
  }
}

# }

# try importing a story
$response = $soap->export(name(story_id => $story_ids->[0]),
			  name(export_related_stories => 1));
ok(!$response->fault, 'SOAP result is not a fault');
my $document = $response->result;

$response = $soap->create(name(document => $document));
ok(!$response->fault, 'SOAP create result is not a fault');
my $ids = $response->result;
isa_ok($ids, 'ARRAY');

# done with schema
unlink $xsd;


###############################################################################
#
# utility routines
#
###############################################################################

# check a document against an xsd schema
sub check_doc {
  my ($doc, $xsd, $name) = @_;
  print "$name :\n$doc\n" if DEBUG;

  SKIP: {
      skip "need Xerces C++ for schema validation", 1 unless $has_xerces;

      # hocus pocus!  The document needs some extra attributes on the root
      # element to get validation to happen right.
      $doc =~ s!<assets!<assets xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://bricolage.sourceforge.net/assets.xsd $xsd" !;
      
      # output into a tempfile
      my ($fh, $filename) = tempfile("doc_XXXX", SUFFIX => '.xml');
      print $fh $doc;
      close $fh;
      
      # call DOMCount and look for error lines
      my $results = `DOMCount -n -s -f -v=always $filename 2>&1`;
      print "Schema Validation Results: $results\n" if DEBUG;
      ok($results !~ /Error/, "$name schema validation");
      
      unlink $filename;
  };
}

# extracts the assets schema from the Bric::SOAP POD, writes it to the
# filesystem and returns the filename
sub extract_schema {
    my $bric_root = $ENV{BRICOLAGE_ROOT} || "/usr/local/bricolage";

    # suck in spec
    open SPEC, "$bric_root/lib/Bric/SOAP.pm" 
	or die "Unable to open $bric_root/lib/Bric/SOAP.pm : $!";
    my $text = join('', <SPEC>);
    close(SPEC);

    # find the xsd
    my ($xsd) = $text =~ m!(<\?xml\sversion="1\.0"\sencoding="UTF-8"\?>
                           .*?
                           <xs:schema
                           .*?
                           </xs:schema>)!xs;
    die "Unable to extract XSD" unless $xsd;
    
    # output xsd into a tempfile and return name
    my ($fh, $filename) = tempfile("asset_XXXX", SUFFIX => '.xsd');
    print $fh $xsd;
    close $fh;
    return $filename;
}
