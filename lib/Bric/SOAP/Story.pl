#!/usr/bin/perl -w

=head1 NAME

Story.pl - a test script for Bric::SOAP::Story

=head1 SYNOPSIS

  $ ./Story.pl
  ok 1 ...

=head1 DESCRIPTION

This is a Test::More test script for the Bric::SOAP::Story module.  It
requires a mix of stories in the running Bricolage instance to work
properly.  The requirements are:

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

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=cut

use strict;
use constant DEBUG => 0;

use Test::More qw(no_plan);
use SOAP::Lite (DEBUG ? (trace => [qw(debug)]) : ());
import SOAP::Data 'name';
use Data::Dumper;
use XML::Simple;
use Carp;
use Carp::Heavy; # for some reason if I remove this I can't get syntax
                 # errors, I just get Carp errors.

use Bric::Biz::Asset::Business::Story;
use Bric::Biz::AssetType;
use Bric::Biz::Workflow;

# setup soap object
my $soap = new SOAP::Lite
    uri => 'http://bricolage.sourceforge.net/Bric/SOAP/Story',
    proxy => 'http://localhost/soap',
    readable => DEBUG;
isa_ok($soap, 'SOAP::Lite');

# try selecting every story
my $response = $soap->list_ids();
ok(!$response->fault, 'fault check');

my $story_ids = $response->result;
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

# select every story
$response = $soap->list_ids();
ok(!$response->fault, 'SOAP result is not a fault');

$story_ids = $response->result;
isa_ok($story_ids, 'ARRAY');
ok(@$story_ids, 'list_ids() returned some story_ids');

# try exporting a story
my $story_id = $story_ids->[0];
$response = $soap->export(name(story_id => $story_id));
if ($response->fault) {
  fail('SOAP export() response fault check');
} else {
  pass('SOAP export() response fault check');  

  my $document = $response->result;
  ok($document, 'Recieved export document');
  check_doc($document, "first story");
}

# this will be replaced by a schema validator as soon as I can get
# one working!
sub check_doc {
  my ($doc, $name) = @_;
  my $x = XMLin($doc, 
		forcearray => [ 'story' ],
		keyattr    => [],
		keeproot   => 1);

  print "$name :\n$doc\n" if DEBUG;
  print Data::Dumper->Dump([$x], ['doc']) if DEBUG;

  # check basic structure
  ok(exists $x->{assets}, "$name has assets");
  ok(exists $x->{assets}{story}, "$name has at least one story");

  # check that all required elements are present
  foreach my $s (@{$x->{assets}{story}}) {
      my @missing = grep { not exists $s->{$_} } 
	  (qw(name description slug primary_uri priority publish_status active 
	      source cover_date categories keywords elements));
      ok(!@missing, "has required elements");
  }
}
