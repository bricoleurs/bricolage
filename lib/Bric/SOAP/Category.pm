package Bric::SOAP::Category;
###############################################################################

use strict;
use warnings;

use Bric::Biz::Category;
use Bric::Biz::Keyword;
use Bric::App::Session  qw(get_user_id);
use Bric::App::Authz    qw(chk_authz READ EDIT CREATE);
use Bric::App::Event    qw(log_event);
use IO::Scalar;
use XML::Writer;

use Bric::SOAP::Util qw(parse_asset_document);

use SOAP::Lite;
import SOAP::Data 'name';

# needed to get envelope on method calls
our @ISA = qw(SOAP::Server::Parameters);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 NAME

Bric::SOAP::Element - SOAP interface to Bricolage element definitions.

=head1 VERSION

$Revision: 1.9.2.3 $

=cut

our $VERSION = (qw$Revision: 1.9.2.3 $ )[-1];

=head1 DATE

$Date: 2003-01-03 23:21:34 $

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

  # set uri for Category module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Category');

  # get a list of all categories
  my $category_ids = $soap->list_ids()->result;

=head1 DESCRIPTION

This module provides a SOAP interface to manipulating Bricolage categories.

=cut

=head1 INTERFACE

=head2 Public Class Methods

=over 4

=item list_ids

This method queries the database for matching categories and returns a
list of ids.  If no categories are found an empty list will be returned.

This method can accept the following named parameters to specify the
search.  Some fields support matching and are marked with an (M).  The
value for these fields will be interpreted as an SQL match expression
and will be matched case-insensitively.  Other fields must specify an
exact string to match.  Match fields combine to narrow the search
results (via ANDs in an SQL WHERE clause).

=over 4

=item name (M)

The category's name.

=item directory (M)

The category's directory, the last element in the path.

=item uri (M)

The URI path of the category.

=item path

The category's complete path from the root.

=item parent

The category's parent, complete path from the root.

=item active

Set false to return deleted categories.

=back

Throws: NONE

Side Effects: NONE

Notes: Neither parent searches nor path searches may be combined with
other searches.  This is because the underlying list() method does not
support them directly.  Instead they are emulated at the SOAP level
and as such do not benefit from SQL's OR of search parameters.  This
should be fixed by adding them to the underlying list().

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(name directory path uri parent active);

sub list_ids {
    my $self = shift;
    my $env = pop;
    my $args = $env->method || {};
    my @cat_ids;

    print STDERR __PACKAGE__ . "->list_ids() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        die __PACKAGE__ . "::list_ids : unknown parameter \"$_\".\n"
            unless exists $allowed{$_};
    }

    # check for path or parent combined with other searches
    die __PACKAGE__ . "::list_ids : illegal combination of parent search ".
        "with other search terms.\n"
            if $args->{parent} and keys(%$args) > 1;
    die __PACKAGE__ . "::list_ids : illegal combination of path search ".
        "with other search terms.\n"
            if $args->{path} and keys(%$args) > 1;

    # perform emulated searches
    if ($args->{parent} or $args->{path}) {
        my $to_find = $args->{parent} ? $args->{parent} : $args->{path};
        my $return_children = exists $args->{parent};

        my @list = Bric::Biz::Category->list();
        foreach my $cat (@list) {
            if ($cat->ancestry_path eq $to_find) {
                if ($return_children) {
                    push(@cat_ids, map { $_->get_id } $cat->children);
                } else {
                    push(@cat_ids, $cat->get_id);
                }
            }
        }

    } else {
        # normal searches pass through to list
        @cat_ids = Bric::Biz::Category->list_ids($args);
    }

    # name the results
    my @result = map { name(category_id => $_) } @cat_ids;

    # name the array and return
    return name(category_ids => \@result);
}
}

=item export

The export method retrieves a set of categories from the database,
serializes them and returns them as a single XML document.  See
L<Bric::SOAP|Bric::SOAP> for the schema of the returned
document.

Accepted paramters are:

=over 4

=item category_id

Specifies a single category_id to be retrieved.

=item category_ids

Specifies a list of category_ids.  The value for this option should be an
array of interger "category_id" categories.

=back

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

{
# hash of allowed parameters
my %allowed = map { $_ => 1 } qw(category_id category_ids);

sub export {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};

    print STDERR __PACKAGE__ . "->export() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        die __PACKAGE__ . "::export : unknown parameter \"$_\".\n"
            unless exists $allowed{$_};
    }

    # category_id is sugar for a one-category category_ids arg
    $args->{category_ids} = [ $args->{category_id} ] 
      if exists $args->{category_id};

    # make sure category_ids is an array
    die __PACKAGE__ . "::export : missing required category_id(s) setting.\n"
        unless defined $args->{category_ids};
    die __PACKAGE__ . "::export : malformed category_id(s) setting.\n"
        unless ref $args->{category_ids} and 
            ref $args->{category_ids} eq 'ARRAY';

    # setup XML::Writer
    my $document        = "";
    my $document_handle = new IO::Scalar \$document;
    my $writer          = XML::Writer->new(OUTPUT      => $document_handle,
                                           DATA_MODE   => 1,
                                           DATA_INDENT => 1);

    # open up an assets document, specifying the schema namespace
    $writer->xmlDecl("UTF-8", 1);
    $writer->startTag("assets", 
                      xmlns => 'http://bricolage.sourceforge.net/assets.xsd');

    # iterate through category_ids, serializing category objects as we go
    foreach my $category_id (@{$args->{category_ids}}) {
      $pkg->_serialize_category(writer      => $writer, 
                                category_id  => $category_id,
                                args        => $args);
  }

    # end the assets category and end the document
    $writer->endTag("assets");
    $writer->end();
    $document_handle->close();

    # name, type and return
    return name(document => $document)->type('base64');
}
}

=item create

The create method creates new objects using the data contained in an
XML document of the format created by export().

Returns a list of new ids created in the order of the assets in the
document.

Available options:

=over 4

=item document (required)

The XML document containing objects to be created.  The document must
contain at least one category object.

=back

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

# hash of allowed parameters
{
my %allowed = map { $_ => 1 } qw(document);

sub create {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};

    print STDERR __PACKAGE__ . "->create() called : args : ",
      Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        die __PACKAGE__ . "::create : unknown parameter \"$_\".\n"
            unless exists $allowed{$_};
    }

    # make sure we have a document
    die __PACKAGE__ . "::create : missing required document parameter.\n"
      unless $args->{document};

    # setup empty update_ids arg to indicate create state
    $args->{update_ids} = [];

    # call _load_category
    return $pkg->_load_category($args);
}
}

=item update

The update method updates category using the data in an XML document of
the format created by export().  A common use of update() is to
export() a selected category object, make changes to one or more fields
and then submit the changes with update().

Returns a list of new ids created in the order of the assets in the
document.

Takes the following options:

=over 4

=item document (required)

The XML document where the objects to be updated can be found.  The
document must contain at least one category and may contain any number of
related category objects.

=item update_ids (required)

A list of "category_id" integers for the assets to be updated.  These
must match id attributes on category elements in the document.  If you
include objects in the document that are not listed in update_ids then
they will be treated as in create().  For that reason an update() with
an empty update_ids list is equivalent to a create().

=back

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

# hash of allowed parameters
{
my %allowed = map { $_ => 1 } qw(document update_ids);

sub update {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};

    print STDERR __PACKAGE__ . "->update() called : args : ",
      Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        die __PACKAGE__ . "::update : unknown parameter \"$_\".\n"
            unless exists $allowed{$_};
    }

    # make sure we have a document
    die __PACKAGE__ . "::update : missing required document parameter.\n"
      unless $args->{document};

    # make sure we have an update_ids array
    die __PACKAGE__ . "::update : missing required update_ids parameter.\n"
      unless $args->{update_ids};
    die __PACKAGE__ . 
        "::update : malformed update_ids parameter - must be an array.\n"
            unless ref $args->{update_ids} and 
                   ref $args->{update_ids} eq 'ARRAY';

    # call _load_category
    return $pkg->_load_category($args);
}
}

=item delete

The delete() method deletes categories.  It takes the following options:

=over 4

=item category_id

Specifies a single category_id to be deleted.

=item category_ids

Specifies a list of category_ids to delete.

=back

Throws: NONE

Side Effects: NONE

Notes: NONE

=cut

# hash of allowed parameters
{
my %allowed = map { $_ => 1 } qw(category_id category_ids);

sub delete {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};

    print STDERR __PACKAGE__ . "->delete() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        die __PACKAGE__ . "::delete : unknown parameter \"$_\".\n"
            unless exists $allowed{$_};
    }

    # category_id is sugar for a one-element category_ids arg
    $args->{category_ids} = [ $args->{category_id} ] 
        if exists $args->{category_id};

    # make sure category_ids is an array
    die __PACKAGE__ . "::delete : missing required category_id(s) setting.\n"
        unless defined $args->{category_ids};
    die __PACKAGE__ . "::delete : malformed category_id(s) setting.\n"
        unless ref $args->{category_ids} and 
               ref $args->{category_ids} eq 'ARRAY';

    # delete the category
    foreach my $category_id (@{$args->{category_ids}}) {
        print STDERR __PACKAGE__ . 
            "->delete() : deleting category_id $category_id\n"
                if DEBUG;

        # lookup category
        my $category = Bric::Biz::Category->lookup({ id => $category_id });
        die __PACKAGE__ . 
            "::delete : no category found for id \"$category_id\"\n"
                unless $category;
        die __PACKAGE__ . 
            "::delete : access denied for category \"$category_id\".\n"
                unless chk_authz($category, CREATE, 1);

        # make sure we're not trying to delete the root category
        die __PACKAGE__ . "::delete : cannot delete root category: ".
            "\"$category_id\"\n"
                if $category->get_id == Bric::Biz::Category::ROOT_CATEGORY_ID;

        # delete the category
        $category->deactivate;
        $category->save;
        log_event('category_deact', $category);
    }
    return name(result => 1);
}
}

=back

=head2 Private Class Methods

=over 4

=item $pkg->_load_category($args)

This method provides the meat of both create() and update().  The only
difference between the two methods is that update_ids will be empty on
create().

=cut

sub _load_category {
    my ($pkg, $args) = @_;
    my $document     = $args->{document};
    my $data         = $args->{data};
    my %to_update    = map { $_ => 1 } @{$args->{update_ids}};

    # parse and catch erros
    unless ($data) {
        eval { $data = parse_asset_document($document) };
        die __PACKAGE__ . " : problem parsing asset document : $@\n"
            if $@;
        die __PACKAGE__ .
            " : problem parsing asset document : no category found!\n"
                unless ref $data and ref $data eq 'HASH'
                    and exists $data->{category};
        print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # sort categories on path length.  This is a simple way to ensure
    # that I always have a valid, saved parent category when creating
    # a child (or the parent can't possibly exist).  My first pass
    # tried to use a fixup hash like the Element code but as it turns
    # out half-creating categories is a really bad thing resulting in
    # insane infinite loops.  Hence, this workaround.
    @{$data->{category}} = sort {(exists $a->{path} ? length($a->{path}) : 0)
                                 <=>
                                 (exists $b->{path} ? length($b->{path}) : 0) }
        @{$data->{category}};

    # loop over category, filling @category_ids
    my (@category_ids, %paths);
    foreach my $cdata (@{$data->{category}}) {
        my $id = $cdata->{id};

        # are we updating?
        my $update = exists $to_update{$id};

        # get category object
        my $category;
        unless ($update) {
            # create empty category
            $category = Bric::Biz::Category->new;
            die __PACKAGE__ . " : failed to create empty category object.\n"
                unless $category;
            print STDERR __PACKAGE__ . " : created empty category object\n"
                if DEBUG;
            die __PACKAGE__ . " : access denied.\n"
                unless chk_authz($category, CREATE, 1);
        } else {
            # updating - first look for a checked out version
            $category = Bric::Biz::Category->lookup({ id => $id });
            die __PACKAGE__ . "::update : no category found for \"$id\"\n"
                unless $category;
            die __PACKAGE__ . " : access denied.\n"
                unless chk_authz($category, CREATE, 1);
        }

        # set simple fields
        $category->set_name($cdata->{name});
        $category->set_description($cdata->{description});
        $category->set_ad_string($cdata->{adstring});
        $category->set_ad_string2($cdata->{adstring2});

        # avoid complex code if path hasn't changed on update
        if (not $update or $category->get_uri ne $cdata->{path}) {
            my $path = $cdata->{path};

            # check that the requested path doesn't already exist.
            die __PACKAGE__ . " : requested path \"$cdata->{path}\" " .
              "is already in use." if $paths{$path} ||=
              Bric::Biz::Category->lookup({ uri => $path });

            # special-case root category
            if ($path eq '/') {
                $category->set_directory("");
            } else {
                # get directory and parent
                my ($parent_path, $directory) = $path =~ m!(.*)/([^/]+)$!;
                die __PACKAGE__ . " : failed to extract directory from path ".
                    "\"$path\"" unless defined $directory;
                $parent_path = '/' unless length $parent_path;

                # make sure we've got a parent
                my $parent = $paths{$parent_path} ||=
                  Bric::Biz::Category->lookup({ uri => $parent_path });
                die __PACKAGE__ . " : couldn't find category object for path ".
                    "\"$parent_path\"\n" unless $parent;

                # Set directory and parent ID.
                $category->set_directory($directory);
                $category->set_parent_id($parent->get_id);

                # save category
                $category->save;
            }
        }

        # remove all keywords if updating
        $category->del_keyword([ $category->keywords ])
            if $update and $category->keywords;

        # add keywords, if we have any
        if ($cdata->{keywords} and $cdata->{keywords}{keyword}) {

            # collect keyword objects
            my @kws;
            foreach (@{$cdata->{keywords}{keyword}}) {
                my $kw = Bric::Biz::Keyword->lookup({ name => $_ });
                $kw ||= Bric::Biz::Keyword->new({ name => $_})->save;
                push @kws, $kw;
            }

            # add keywords to the category
            $category->add_keyword(\@kws);
        }

        # save category
        $category->save();
        log_event('category_' . ($update? 'save' : 'new'), $category);

        # all done, setup the category_id and cache the category.
        push(@category_ids, $category->get_id);
        $paths{$category->get_uri} = $category;
    }

    return name(ids => [ map { name(category_id => $_) } @category_ids ]);
}

=item $pkg->_serialize_category( writer => $writer,
                                 category_id => $category_id,
                                 args => $args)

Serializes a single category object into a <category> category using
the given writer and args.

=cut

sub _serialize_category {
    my $pkg         = shift;
    my %options     = @_;
    my $category_id  = $options{category_id};
    my $writer      = $options{writer};

    my $category = Bric::Biz::Category->lookup({id => $category_id});
    die __PACKAGE__ . "::export : category_id \"$category_id\" not found.\n"
        unless $category;

    die __PACKAGE__ .
        "::export : access denied for category \"$category_id\".\n"
            unless chk_authz($category, READ, 1);

    # open a category category
    $writer->startTag("category", id => $category_id);

    # write out simple categories in schema order
    $writer->dataElement(name        => $category->get_name());
    $writer->dataElement(description => $category->get_description());

    # write out path
    $writer->dataElement(path => $category->ancestry_path);

    # set active flag
    $writer->dataElement(active => ($category->is_active ? 1 : 0));

    # output adstrings
    $writer->dataElement(adstring => $category->get_ad_string);
    $writer->dataElement(adstring2 => $category->get_ad_string2);

    # output keywords
    $writer->startTag("keywords");
    foreach my $k ($category->keywords) {
        $writer->dataElement(keyword => $k->get_name);
    }
    $writer->endTag("keywords");

    # close the category
    $writer->endTag("category");
}

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::SOAP|Bric::SOAP>

=cut

1;
