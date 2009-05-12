package Bric::SOAP::Category::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::SOAP::Category');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w

=head1 Name

Category.pl - a test script for Bric::SOAP::Category

=head1 Synopsis

  $ ./Category.pl
  ok 1 ...

=head1 Description

This is a Test::More test script for the Bric::SOAP::Category module.  It
requires a mix of categories in the running Bricolage instance to work
properly.

Bricolage requirements are:

=over 4

=item *

Multiple category objects.

=back

Also, to get the most out of the tests you'll need to install the
Xerces C++ library.  See:

    http://xml.apache.org/xerces-c/index.html

for details.  You need a later version than 1.6.0 which currently
means the CVS version.  Also, you need to install the sample program
DOMCount into your path.

You can still run the tests without Xerces C++ installed but the
schema validation tests will be skipped.

=head1 Constants

=over 4

=item USER

Set this to a working login.

=item PASSWORD

Set this to the password for the USER account.

=item DEBUG

Set this to 1 to see debugging text including the full XML for every
SOAP method call and response.  Highly educational.  Defaults to the
value of the DEBUG environment variable or 0.

=item DELETE_TEST_CATEGORIES

The test script will create new category to test create() and update().
If you set this constant to 0 then you'll be able to examine them in
the GUI after the test.

=back

=head1 Author

Sam Tregar <stregar@about-inc.com>

=cut

use strict;
use constant DEBUG => $ENV{DEBUG} || 0;
use constant DELETE_TEST_CATEGORIES => 1;

use constant USER     => 'admin';
use constant PASSWORD => 'change me now!';

use Test::More qw(no_plan);
use SOAP::Lite (DEBUG ? (trace => [qw(debug)]) : ());
import SOAP::Data 'name';
use Data::Dumper;
use XML::Simple;
use File::Temp qw(tempfile);

use Bric::Biz::Asset::Template;
use Bric::Biz::ElementType;
use Bric::Biz::Workflow;
use Bric::Biz::OutputChannel;
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

my ($response, $category_ids);

# login
$response = $soap->login(name(username => USER), 
             name(password => PASSWORD));
ok(!$response->fault, 'fault check');
exit 1 if $response->fault;

my $success = $response->result;
ok($success, "login success");

# set uri for Category module
$soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Category');

# try selecting every category
$response = $soap->list_ids();
ok(!$response->fault, 'fault check');
exit 1 if $response->fault;

$category_ids = $response->result;
isa_ok($category_ids, 'ARRAY');
ok(@$category_ids, 'list_ids() returned some category_ids');

# try a query returning an empty list
my $response2 = $soap->list_ids(name(name => 'FOO' . rand() . 'BAR'));
ok(!$response2->fault, "SOAP result is not a fault");
exit 1 if $response2->fault;
my $category_ids2 = $response2->result;
isa_ok($category_ids2, 'ARRAY');
is(@$category_ids2, 0, 'list_ids() returned 0 category_ids');


# get schema ready for checking documents
my $xsd = extract_schema();
ok($xsd, "Extracted XSD from Bric::SOAP: $xsd");

# try exporting and importing every category object
foreach my $category_id (@$category_ids) {
    $response = $soap->export(name(category_id => $category_id));
    if ($response->fault) {
     fail('SOAP export() response fault check');
     exit 1;
    } else {
     pass('SOAP export() response fault check');  
    
     my $document = $response->result;
     ok($document, "recieved document for category $category_id");
     check_doc($document, $xsd, "category $category_id");    

      # add (/copy$time) to path and try to create copy
     my $time = time();
      $document =~ s!<path>(.*?)</path>!
        "<path>" . ($1 eq '/' ? "/copy$time" : "$1/copy$time") . "</path>"!e;
    #print STDERR $document;
      $response = $soap->create(name(document => $document)->type('base64'));
      ok(!$response->fault, 'SOAP create() result is not a fault');
      exit 1 if $response->fault;
      my $ids = $response->result;
      isa_ok($ids, 'ARRAY');

      # modify copy with update to add to description of first item
      $document =~ s!<description>(.*?)</description>!<description>$1 (description updated)</description>!;
      $document =~ s!id=".*?"!id="$ids->[0]"!;
      $response = $soap->update(name(document => $document)->type('base64'),
                    name(update_ids => [ name(category_id => 
                                  $ids->[0]) ]));
      ok(!$response->fault, 'SOAP update() result is not a fault');
      exit 1 if $response->fault;
      my $updated_ids = $response->result;
      isa_ok($ids, 'ARRAY');
      is($updated_ids->[0], $ids->[0], "update() worked in place");

      # delete copies unless debugging 
     if (DELETE_TEST_CATEGORIES) {        
          my %to_delete = map { $_ => 1 } (@$ids, @$updated_ids);
          $response = $soap->delete(name(category_ids => [ map { name(category_id => $_) } keys %to_delete ]));
          ok(!$response->fault, 'SOAP delete() result is not a fault');
          exit 1 if $response->fault;
          ok($response->result, "SOAP delete() result check");
      }
    }
}

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
    exit if $results =~ /Error/;
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
