package Bric::SOAP::Category;

###############################################################################

use strict;
use warnings;

use Bric::Biz::Category;
use Bric::Biz::Keyword;
use Bric::Biz::Site;
use Bric::App::Authz  qw(chk_authz READ CREATE);
use Bric::App::Event  qw(log_event);
use Bric::SOAP::Util  qw(parse_asset_document site_to_id);
use Bric::Util::Fault qw(throw_ap);

use SOAP::Lite;
import SOAP::Data 'name';

use base qw(Bric::SOAP::Asset);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

=head1 Name

Bric::SOAP::Category - SOAP interface to Bricolage categories.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

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

=head1 Description

This module provides a SOAP interface to manipulating Bricolage categories.

=cut

=head1 Interface

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

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: Neither parent searches nor path searches may be combined with
other searches.  This is because the underlying list() method does not
support them directly.  Instead they are emulated at the SOAP level
and as such do not benefit from SQL's OR of search parameters.  This
should be fixed by adding them to the underlying list().

=cut

sub list_ids {
    my $self = shift;
    my $env = pop;
    my $args = $env->method || {};
    my @cat_ids;

    print STDERR __PACKAGE__ . "->list_ids() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::list_ids : unknown parameter \"$_\".")
          unless $self->is_allowed_param($_, 'list_ids');
    }

    # handle site => site_id conversion
    $args->{site_id} = site_to_id(__PACKAGE__, delete $args->{site})
      if exists $args->{site};

    # Handle parent => uri and path => uri conversion.
    if ($args->{parent}) {
        # Prefer the parent argument.
        $args->{parent} .= '/' unless $args->{parent} =~ m|/$|;
        $args->{uri} = delete($args->{parent}) . '%';
        delete $args->{path};
    } else {
        $args->{uri} = delete $args->{path} if $args->{path};
    }

    # name the results
    my @result = map { name(category_id => $_) }
      Bric::Biz::Category->list_ids($args);

    # name the array and return
    return name(category_ids => \@result);
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
array of integer "category_id" categories.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut


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

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut


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

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut


=item delete

The delete() method deletes categories.  It takes the following options:

=over 4

=item category_id

Specifies a single category_id to be deleted.

=item category_ids

Specifies a list of category_ids to delete.

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: NONE

=cut

sub delete {
    my $pkg = shift;
    my $env = pop;
    my $args = $env->method || {};

    print STDERR __PACKAGE__ . "->delete() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::delete : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, 'delete');
    }

    # category_id is sugar for a one-element category_ids arg
    $args->{category_ids} = [ $args->{category_id} ]
        if exists $args->{category_id};

    # make sure category_ids is an array
    throw_ap(error => __PACKAGE__ . "::delete : missing required category_id(s) setting.")
      unless defined $args->{category_ids};
    throw_ap(error => __PACKAGE__ . "::delete : malformed category_id(s) setting.")
      unless ref $args->{category_ids} and ref $args->{category_ids} eq 'ARRAY';

    # delete the category
    foreach my $category_id (@{$args->{category_ids}}) {
        print STDERR __PACKAGE__ .
            "->delete() : deleting category_id $category_id\n"
                if DEBUG;

        # lookup category
        my $category = Bric::Biz::Category->lookup({ id => $category_id });
        throw_ap(error => __PACKAGE__
                   . "::delete : no category found for id \"$category_id\"")
          unless $category;
        throw_ap(error => __PACKAGE__
                   . "::delete : access denied for category \"$category_id\".")
          unless chk_authz($category, CREATE, 1);

        # make sure we're not trying to delete the root category
        throw_ap(error => __PACKAGE__ . "::delete : cannot delete root category: "
                   . "\"$category_id\"")
          if $category->is_root_category;

        # delete the category
        $category->deactivate;
        $category->save;
        log_event('category_deact', $category);
    }
    return name(result => 1);
}


=item $self->module

Returns the module name, that is the first argument passed
to bric_soap.

=cut

sub module { 'category' }

=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

sub is_allowed_param {
    my ($pkg, $param, $method) = @_;
    my $module = $pkg->module;

    my $allowed = {
        list_ids => { map { $_ => 1 } qw(name site directory path uri parent active) },
        export   => { map { $_ => 1 } ("$module\_id", "$module\_ids") },
        create   => { map { $_ => 1 } qw(document) },
        update   => { map { $_ => 1 } qw(document update_ids) },
        delete   => { map { $_ => 1 } ("$module\_id", "$module\_ids") },
    };

    return exists($allowed->{$method}->{$param});
}


=back

=head2 Private Class Methods

=over 4

=item $pkg->load_asset($args)

This method provides the meat of both create() and update().  The only
difference between the two methods is that update_ids will be empty on
create().

=cut

sub load_asset {
    my ($pkg, $args) = @_;
    my $document     = $args->{document};
    my $data         = $args->{data};
    my %to_update    = map { $_ => 1 } @{$args->{update_ids}};

    # parse and catch errors
    unless ($data) {
        eval { $data = parse_asset_document($document) };
        throw_ap(error => __PACKAGE__ . " : problem parsing asset document : $@")
          if $@;
        throw_ap(error => __PACKAGE__
                   . " : problem parsing asset document : no category found!")
          unless ref $data and ref $data eq 'HASH' and exists $data->{category};
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
        $cdata->{site} = 'Default Site' unless exists $cdata->{site};
        my $site_id = site_to_id(__PACKAGE__, $cdata->{site});

        # are we updating?
        my $update = exists $to_update{$id};

        # get category object
        my $category;
        unless ($update) {
            # create empty category
            $category = Bric::Biz::Category->new;
            throw_ap(error => __PACKAGE__ . " : failed to create empty category object.")
              unless $category;
            print STDERR __PACKAGE__ . " : created empty category object\n"
                if DEBUG;
            throw_ap(error => __PACKAGE__ . " : access denied.")
              unless chk_authz($category, CREATE, 1);
        } else {
            # updating - first look for a checked out version
            $category = Bric::Biz::Category->lookup({ id => $id, site_id => $site_id  });
            throw_ap(error => __PACKAGE__ . "::update : no category found for \"$id\"")
              unless $category;
            throw_ap(error => __PACKAGE__ . " : access denied.")
              unless chk_authz($category, CREATE, 1);
        }

        # set site
        $category->set_site_id($site_id);

        # set simple fields
        $category->set_name($cdata->{name});
        $category->set_description($cdata->{description});
        $category->set_ad_string($cdata->{adstring});
        $category->set_ad_string2($cdata->{adstring2});
        if (exists $cdata->{active}) {
            if ($cdata->{active}) {
                $category->activate;
            } else {
                $category->deactivate;
            }
        }

        # avoid complex code if path hasn't changed on update
        if (not $update or $category->get_uri ne $cdata->{path}) {
            my $path = $cdata->{path};
            (my $esc_path = $path) =~ s/([_%\\])/\\$1/g;

            # check that the requested path doesn't already exist.
            throw_ap(error => __PACKAGE__ . " : requested path \"$path\""
                       . " is already in use.")
              if $paths{$path} ||= Bric::Biz::Category->lookup({
                  uri     => $esc_path,
                  site_id => $site_id,
              });

            # special-case root category
            if ($path eq '/') {
                $category->set_directory('');
            } else {
                # get directory and parent
                my ($parent_path, $directory) = $path =~ m!(.*/)([^/]+)\/?$!;
                $parent_path = '' unless defined $parent_path;
                (my $esc_parent_path = $parent_path) =~ s/([_%\\])/\\$1/g;

                # make sure we've got a parent
                my $parent = $paths{$parent_path} ||=
                    Bric::Biz::Category->lookup({
                        uri     => $esc_parent_path,
                        site_id => $site_id,
                    });
                throw_ap(error => __PACKAGE__ . " : couldn't find category object "
                           . "for path \"$parent_path\"")
                  unless $parent;

                # Set directory and parent ID.
                $category->set_parent_id($parent->get_id);
                $category->set_directory($directory);

                # save category and cache it for possible subcategories.
                $category->save;
                $paths{$category->get_uri} = $category;
            }
        }

        # delete old keywords if updating
        if ($update) {
            my $old;
            my @keywords = ($cdata->{keywords} and $cdata->{keywords}{keyword}) ? @{$cdata->{keywords}{keyword}} : ();
            my $keywords = { map { $_ => 1 } @keywords };
            foreach ($category->get_keywords) {
                push @$old, $_ unless $keywords->{$_->get_id};
            }
            $category->del_keywords(@$old) if $old;
        }

        # add keywords, if we have any
        if ($cdata->{keywords} and $cdata->{keywords}{keyword}) {
            # collect keyword objects
            my @kws;
            foreach (@{$cdata->{keywords}{keyword}}) {
                (my $name = $_) =~ s/([_%\\])/\\$1/g;
                my $kw = Bric::Biz::Keyword->lookup({ name => $name });
                if ($kw) {
                    throw_ap(error => __PACKAGE__ . qq|::create : access denied for keyword "$name"|)
                      unless chk_authz($kw, READ, 1);
                } else {
                    if (chk_authz('Bric::Biz::Keyword', CREATE, 1)) {
                        $kw = Bric::Biz::Keyword->new({ name => $_ })->save;
                        log_event('keyword_new', $kw);
                    }
                    else {
                        throw_ap(error => __PACKAGE__ . '::create : access denied for creating new keywords.');
                    }
                }
                push @kws, $kw;
            }

            # add keywords to the category
            $category->add_keywords(\@kws);
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

=item $pkg->serialize_category( writer => $writer,
                                category_id => $category_id,
                                args => $args)

Serializes a single category object into a <category> category using
the given writer and args.

=cut

sub serialize_asset {
    my $pkg         = shift;
    my %options     = @_;
    my $category_id  = $options{category_id};
    my $writer      = $options{writer};

    my $category = Bric::Biz::Category->lookup({id => $category_id});
    throw_ap(error => __PACKAGE__ . "::export : category_id \"$category_id\" not found.")
      unless $category;

    throw_ap(error => __PACKAGE__ .
               "::export : access denied for category \"$category_id\".")
      unless chk_authz($category, READ, 1);

    # open a category category
    $writer->startTag("category", id => $category_id);

    # Write out the name of the site.
    my $site = Bric::Biz::Site->lookup({ id => $category->get_site_id });
    $writer->dataElement('site' => $site->get_name);

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
    foreach my $k ($category->get_keywords) {
        $writer->dataElement(keyword => $k->get_name);
    }
    $writer->endTag("keywords");

    # close the category
    $writer->endTag("category");
}

=back

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>

=cut

1;
