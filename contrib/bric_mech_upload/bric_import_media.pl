#!/usr/bin/perl -w -s
# This script imports Media files in a directory hierarchy.
# The hierarchy should begin with $BASEDIR.
# Put your media files under that directory.
# The directory should end with $l (language code),
# for example: /entity/media/en . Then the files will be put
# in the /entity/media category (I'll fix that some day).
#
# Use -x to exec bric_soap (after creating the XML files).
# But first, run it without -x, to create the XML files
# (be sure to set $type to the right Element: PDF Document, Word Document, HTML).
#
# Use -l=es or -l=fr to do Spanish or French files.
#
# Use -d=32 to put (for example) a 32 second delay between each file import.
#
# Use -t='PDF Document' to create PDFs.
#
# Example usage (from one above $BASEDIR directory):
#
# $ ./bric_import_media.pl -l=fr -t='Photograph'
# $ ./bric_import_media.pl -l=fr -t='Photograph' -d=30 -x

use strict;

use POSIX;
use MIME::Base64;

our ($x, $l, $d, $t);

####### BEGIN CONFIGURATION ######

my $bricroot = '/usr/local/bricolage';
my $bricsoap = "$bricroot/bin/bric_soap";
#my $server = 'http://webit.who.int/';
my $server = 'http://localhost';
my $username = 'admin';
my $password = 'change me now!';

#my $BASEDIR = 'features/';
my $BASEDIR = 'entity/';
#my $BASEDIR = 'country/';

#my $BRIC_VERSION = '1.8';
my $BRIC_VERSION = '1.6';

my $briccmd = qq{$bricsoap --timeout 10000 --server $server --username $username --password='$password' media create };  # note: we add filename below

my %TYPEMAP = (
    'Illustration'  => 'pdf',
    'Word Document' => 'doc',
    'HTML'          => 'htm|html',
#    'Illustration'  => 'gif|jpg|jpeg',
    'Photograph'    => 'gif|jpg|jpeg',
    'Excel'         => 'xls',
);
my $source = 'Internal';

###### END CONFIGURATION ######

my $type = defined($t) ? $t : 'PDF Document';
my $typekeys = join('|', keys(%TYPEMAP));
die "invalid type: '$type'\n" unless $type =~ /^($typekeys)$/;

$l = 'en' unless defined($l) && $l =~ /^(fr|es)$/;   # en, fr, es
$d = 0    unless defined($d) && $d =~ /^\d+$/;

my @files = `find . -type f -path './$BASEDIR*$l/*'`;
chomp @files;

foreach my $file (@files) {
    next unless $file =~ m{$BASEDIR};

    my $uri = $file;
    $uri =~ s/^\.//;

    my $xmlfile = $file;
    $xmlfile =~ s{\.\w+$}{.xml};

    if (defined $x) {
        next unless $file =~ /\.xml$/;

        my $res = `$briccmd $xmlfile 2>&1`;
        if ($res =~ /media_\d+/) {
            chomp $res;
            print "$file\t$res\n";   # map file to media ID
        } else {
            die "\nERROR: $res\n";
        }

        sleep $d;
    } else {
        my $ext = $TYPEMAP{$type};
        next unless $file =~ m{\.($ext)$}i;

        my $name = $file;
        $name =~ s{^\./$BASEDIR}{};
        my $date = strftime('%Y-%m-%dT%H:%M:%SZ', localtime(time()));

        my $cat = $file;
        $cat =~ s/^\.//;
        $cat =~ s{/[^/]+$}{};
        $cat =~ s{/$l$}{};

        my $size = (stat($file))[7];

        my $filename = $file;
        $filename =~ s{^.+/}{};

        open(FILE, $file) || die "open '$file': $!";
        my $blob = join('', <FILE>);
        my $data = encode_base64($blob, '');
        close(FILE);

        my $siteelement = ($BRIC_VERSION =~ /^1\.8/)
          ? '<site>Default Site</site>'
          : '';

        my $xml = <<"EOS";
<?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>
<assets xmlns="http://bricolage.sourceforge.net/assets.xsd">
 <media id="" element="$type">
  $siteelement
  <name>$name</name>
  <description></description>
  <uri>$uri</uri>
  <priority>3</priority>
  <publish_status>0</publish_status>
  <active>1</active>
  <source>$source</source>
  <cover_date>$date</cover_date>
  <publish_date></publish_date>
  <category>/</category>
  <contributors></contributors>
  <elements></elements>
  <file>
   <name>$filename</name>
   <size>$size</size>
   <data>$data</data>
  </file>
 </media>
</assets>
EOS

        open(OUT, ">$xmlfile") || die "out '$xmlfile': $!";
        print OUT $xml;
        close(OUT);

        print "$xmlfile\n";
    }
}
