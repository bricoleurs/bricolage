package Bric::SOAP::Template;

###############################################################################

use strict;
use warnings;

use Bric::Biz::Asset::Template;
use Bric::Biz::ElementType;
use Bric::Biz::Category;
use Bric::Biz::Site;
use Bric::Biz::Workflow qw(TEMPLATE_WORKFLOW);
use Bric::App::Session  qw(get_user_id);
use Bric::App::Authz    qw(chk_authz READ CREATE);
use Bric::App::Event    qw(log_event);
use Bric::Util::Fault   qw(throw_ap);
use Bric::Biz::Person::User;
use Bric::Util::Burner;
use File::Basename qw(fileparse basename);
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::Config qw(:l10n);

use Bric::SOAP::Util qw(category_path_to_id
                        output_channel_name_to_id
                        workflow_name_to_id
                        site_to_id
                        xs_date_to_db_date
                        db_date_to_xs_date
                        parse_asset_document
                       );

use SOAP::Lite;
import SOAP::Data 'name';

use base qw(Bric::SOAP::Asset);

use constant DEBUG => 0;
require Data::Dumper if DEBUG;

# this is needed by Template.pl so it can test create() and update()
# without damaging the system.
use constant ALLOW_DUPLICATE_TEMPLATES => 0;

=head1 Name

Bric::SOAP::Template - SOAP interface to Bricolage templates.

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

  # set uri for Template module
  $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Template');

  # get a list of template_ids in the root category
  my $template_ids = $soap->list_ids(name(category => '/'))->result;

=head1 Description

This module provides a SOAP interface to manipulating Bricolage templates.

=cut

=head1 Interface

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

=item site

The name of the site that the template is in.

=item simple (M)

a single OR search that hits element and filename.

=item priority

The priority of the template.

=item deploy_status

Templates that have been deployed have a deploy_status of "1",
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

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: In addition to the parameters listed above, you can use most of the
parameters listed in the documentation for the list method in
Bric::Biz::Asset::Template.

=cut

sub list_ids {
    my $self = shift;
    my $env = pop;
    my $args = $env->method || {};
    my $method = 'list_ids';

    print STDERR __PACKAGE__ . "->list_ids() called : args : ",
        Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::list_ids : unknown parameter \"$_\".")
            unless $self->is_allowed_param($_, $method);
    }

    # handle site => site_id conversion
    $args->{site_id} = site_to_id(__PACKAGE__, $args->{site})
      if exists $args->{site};

    # handle workflow => workflow__id mapping
    $args->{workflow_id} =
      workflow_name_to_id(__PACKAGE__, delete $args->{workflow}, $args)
      if exists $args->{workflow};

    # handle output_channel => output_channel__id mapping
    $args->{output_channel_id} =
      output_channel_name_to_id(__PACKAGE__, delete $args->{output_channel}, $args)
      if exists $args->{output_channel};

    # handle category => category_id conversion
    $args->{category_id} =
      category_path_to_id(__PACKAGE__, delete $args->{category}, $args)
      if exists $args->{category};

    # translate dates into proper format
    for my $name (grep { /_date_/ } keys %$args) {
        my $date = xs_date_to_db_date($args->{$name});
        throw_ap(error => __PACKAGE__ . "::list_ids : bad date format for $name parameter "
                   . "\"$args->{$name}\" : must be proper XML Schema dateTime format.")
          unless defined $date;
        $args->{$name} = $date;
    }

    # element is name for templates
    $args->{name} = delete $args->{element}
      if exists $args->{element};

    # We're done with the site now.
    delete $args->{site};

    my @list = Bric::Biz::Asset::Template->list_ids($args);

    print STDERR "Bric::Biz::Asset::Template->list_ids() called : ",
        "returned : ", Data::Dumper->Dump([\@list],['list'])
            if DEBUG;

    # name the results
    my @result = map { name(template_id => $_) } @list;

    # name the array and return
    return name(template_ids => \@result);
}

=item export

The export method retrieves a set of templates from the database,
serializes them and returns them as a single XML document.  See
L<Bric::SOAP|Bric::SOAP> for the schema of the returned
document.

Accepted paramters are:

=over 4

=item template_id

Specifies a single template_id to be retrieved.

=item template_ids

Specifies a list of template_ids.  The value for this option should be an
array of interger "template_id" elements.

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
contain at least one template object.

=item workflow

Specifies the initial workflow the story is to be created in

=item desk

Specifies the initial desk the story is to be created on

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: New stories are put in the first "template workflow" unless you pass
in the --workflow option. The start desk of the workflow is used unless
you pass the --desk option.

=cut


=item update

The update method updates template using the data in an XML document of
the format created by export().  A common use of update() is to
export() a selected template object, make changes to one or more fields
and then submit the changes with update().

Returns a list of new ids created in the order of the assets in the
document.

Takes the following options:

=over 4

=item document (required)

The XML document where the objects to be updated can be found.  The
document must contain at least one template and may contain any number of
related template objects.

=item update_ids (required)

A list of "template_id" integers for the assets to be updated.  These
must match id attributes on template elements in the document.  If you
include objects in the document that are not listed in update_ids then
they will be treated as in create().  For that reason an update() with
an empty update_ids list is equivalent to a create().

=item workflow

Specifies the workflow to move the template to

=item desk

Specifies the desk to move the template to

=back

Throws:

=over

=item Exception::AP

=back

Side Effects: NONE

Notes: Due to the way Bric::Biz::Asset::Template->new() works it
isn't possible to fully update file_name.  To change it you need to
update it indirectly by changing category, element and the file_name
extension.  This should be fixed.

=cut


=item delete

The delete() method deletes templates.  It takes the following options:

=over 4

=item template_id

Specifies a single template_id to be deleted.

=item template_ids

Specifies a list of template_ids to delete.

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
    my $method = 'delete';

    print STDERR __PACKAGE__ . "->delete() called : args : ",
      Data::Dumper->Dump([$args],['args']) if DEBUG;

    # check for bad parameters
    for (keys %$args) {
        throw_ap(error => __PACKAGE__ . "::delete : unknown parameter \"$_\".")
          unless $pkg->is_allowed_param($_, $method);
    }

    # template_id is sugar for a one-element template_ids arg
    $args->{template_ids} = [ $args->{template_id} ]
      if exists $args->{template_id};

    # make sure template_ids is an array
    throw_ap(error => __PACKAGE__ . "::delete : missing required template_id(s) setting.")
      unless defined $args->{template_ids};
    throw_ap(error => __PACKAGE__ . "::delete : malformed template_id(s) setting.")
      unless ref $args->{template_ids} and ref $args->{template_ids} eq 'ARRAY';

    # delete the template
    foreach my $template_id (@{$args->{template_ids}}) {
        print STDERR __PACKAGE__ .
          "->delete() : deleting template_id $template_id\n"
            if DEBUG;

        # first look for a checked out version
        my $template = Bric::Biz::Asset::Template->lookup
          ({ id => $template_id, checkout => 1 });

        unless ($template) {
            # settle for a non-checked-out version and check it out
            $template = Bric::Biz::Asset::Template->lookup
              ({ id => $template_id });
            throw_ap(error => __PACKAGE__ .
                       "::delete : no template found for id \"$template_id\"")
                unless $template;
            throw_ap(error => __PACKAGE__ .
                       "::delete : access denied for template \"$template_id\".")
                unless chk_authz($template, EDIT, 1);
            $template->checkout({ user__id => get_user_id });
            log_event("template_checkout", $template);
        }

        # Remove the template from any desk it's on.
        if (my $desk = $template->get_current_desk) {
            $desk->checkin($template);
            $desk->remove_asset($template);
            $desk->save;
        }

        # Remove the template from workflow.
        if ($template->get_workflow_id) {
            $template->set_workflow_id(undef);
            log_event("template_rem_workflow", $template);
        }

        # Deactivate the template and save it.
        $template->deactivate;
        $template->save;
        log_event("template_deact", $template);
    }

    return name(result => 1);
}

=item $self->module

Returns the module name, that is the first argument passed
to bric_soap.

=cut

sub module { 'template' }

=item $self->class

Returns the class name used for 'lookup' (used in the delete method).

=cut

sub class { 'Bric::Biz::Asset::Template' }


=item is_allowed_param

=item $pkg->is_allowed_param($param, $method)

Returns true if $param is an allowed parameter to the $method method.

=cut

my $allowed = {
    list_ids => { map { $_ => 1 } qw(element file_name output_channel category
                                     workflow simple priority deploy_status
                                     element deploy_date_start deploy_date_end
                                     expire_date_start expire_date_end site
                                     Order OrderDirection Offset Limit),
                  grep { /^[^_]/}
                    keys %{ Bric::Biz::Asset::Template->PARAM_WHERE_MAP }
                },
    export   => { map { $_ => 1 } map { module() . "_$_" }  qw(id ids) },
    create   => { map { $_ => 1 } qw(document workflow desk) },
    update   => { map { $_ => 1 } qw(document update_ids workflow desk) },
};

$allowed->{delete} = $allowed->{export};

sub is_allowed_param {
    my ($pkg, $param, $method) = @_;
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
        throw_ap(error => __PACKAGE__ .
                   " : problem parsing asset document : no template found!")
          unless ref $data and ref $data eq 'HASH' and exists $data->{template};
        print STDERR Data::Dumper->Dump([$data],['data']) if DEBUG;
    }

    # Determine workflow and desk for templates
    my ($workflow, $desk, $no_wf_or_desk_param);
    $no_wf_or_desk_param = ! (exists $args->{workflow} || exists $args->{desk});
    if (exists $args->{workflow}) {
        (my $look = $args->{workflow}) =~ s/([_%\\])/\\$1/g;
        $workflow = Bric::Biz::Workflow->lookup({ name => $look })
          || throw_ap error => "workflow '" . $args->{workflow} . "' not found!";
    }

    if (exists $args->{desk}) {
        (my $look = $args->{desk}) =~ s/([_%\\])/\\$1/g;
        $desk = Bric::Biz::Workflow::Parts::Desk->lookup({ name => $look })
          || throw_ap error => "desk '" . $args->{desk} . "' not found!";
    }

    # loop over templates, filling @template_ids
    my @template_ids;
    foreach my $tdata (@{$data->{template}}) {
        my $id = $tdata->{id};

        # are we updating?
        my $update = exists $to_update{$id};

        # setup init data for create
        my %init;

        # get user__id from Bric::App::Session
        $init{user__id} = get_user_id;

        # Get the site ID.
        $tdata->{site} = 'Default Site' unless exists $tdata->{site};
        $init{site_id} = site_to_id($pkg, $tdata->{site});

        # handle output_channel => output_channel__id mapping

        ($init{output_channel__id}) = Bric::Biz::OutputChannel->list_ids
          ({ name => $tdata->{output_channel}[0] });
        throw_ap(error => __PACKAGE__ . " : no output_channel found matching "
                   . "(output_channel => \"$tdata->{output_channel}[0]\")")
          unless defined $init{output_channel__id};

        # figure out file_type
        my ($fn, $dir, $ext) = fileparse($tdata->{file_name}, qr/\..*$/);
        if ($ext) {
            $ext =~ s/^\.//;
            $init{file_type} = $ext;
        } elsif (Bric::Util::Burner->class_for_cat_fn($fn)) {
            # It's okay, it's a category template. Only complain if it's
            # mandated to have an extension.
            throw_ap(error => __PACKAGE__ .
                     " : unable to determine file_type for file_name " .
                     "\"$tdata->{file_name}\".")
              if Bric::Util::Burner->cat_fn_has_ext($fn);
        }

        # get element and name for asset type if this is an element template.
        if ($tdata->{type} eq 'Element Template') {
            my $elem_type = $tdata->{element_type} ? $tdata->{element_type}[0]
                                                   : $tdata->{element}[0]
                                                   ;
            (my $look = $elem_type) =~ s/([_%\\])/\\$1/g;
            my $element = Bric::Biz::ElementType->lookup({
                key_name => $look
            }) or throw_ap __PACKAGE__ . " : no element found matching " .
              "(element => \"$elem_type\")";
            $init{element_type} = $element;
            $init{name}        = $element->get_name;
        } elsif ($tdata->{type} eq 'Utility Template') {
            $init{name}        = basename($tdata->{file_name});
        }

        # assign catgeory_id (not category__id, for some reason...)
        $init{category_id} =
          category_path_to_id(__PACKAGE__, $tdata->{category}[0], \%init)
          unless defined $init{category_id};

        # setup data
        if ($tdata->{data}[0]) {
            $init{data}    = MIME::Base64::decode_base64($tdata->{data}[0]);
        } else {
            $init{data}    = '';
        }

        # mix in dates
        for my $name qw(expire_date deploy_date) {
            my $date = $tdata->{$name};
            if ($date) {
                throw_ap error => __PACKAGE__ . "::create : $name must be undefined if deploy_status is false"
                    unless $tdata->{deploy_status} or $name ne 'deploy_date';
                my $db_date = xs_date_to_db_date($date);
                throw_ap(error => __PACKAGE__ . "::export : bad date format for $name : $date")
                    unless defined $db_date;
                $init{$name} = $db_date;
            } else {
                throw_ap error => __PACKAGE__ . "::create : $name must be defined if deploy_status is true"
                    if $tdata->{deploy_status} && $name eq 'deploy_date';
            }
        }

        # setup simple fields
        $init{priority}    = $tdata->{priority};
        $init{description} = $tdata->{description};

        unless ($update && $no_wf_or_desk_param) {
            unless (exists $args->{workflow}) {  # already done above
                $workflow = (Bric::Biz::Workflow->list({
                    type => TEMPLATE_WORKFLOW,
                    site_id => $init{site_id}
                }))[0];
            }
            unless (exists $args->{desk}) {   # already done above
                $desk = $workflow->get_start_desk;
            }
        }

        # get base template object
        my $template;
        unless ($update) {
            # Set the template type. It shouldn't be updated for an existing
            # template, only set for a new template.
            $init{tplate_type} =
              Bric::Biz::Asset::Template->get_tplate_type_code($tdata->{type});
            # create empty template
            $template = Bric::Biz::Asset::Template->new(\%init);
            throw_ap(error => __PACKAGE__ .
                       "::create : failed to create empty template object.")
              unless $template;
            print STDERR __PACKAGE__ .
                "::create : created empty template object\n"
                    if DEBUG;

            # is this is right way to check create access for template?
            throw_ap(error => __PACKAGE__ . " : access denied.")
                unless chk_authz($template, CREATE, 1, $desk->get_asset_grp);

            # check that there isn't already an active template with the same
            # output channel and file_name (which is composed of category,
            # file_type and element name).
            my $found_dup = 0;
            my $file_name  = $template->get_file_name;
            my @list = Bric::Biz::Asset::Template->list_ids(
                              { output_channel__id => $init{output_channel__id},
                                file_name => $file_name      });
            if (@list) {
                $found_dup = 1;
            } else {
                # Arrgh.  This is the only way to search all checked out
                # template assets.  According to Garth this isn't a
                # problem...  I'd like to show him this code sometime and see
                # if he still thinks so!
                my @user_ids = Bric::Biz::Person::User->list_ids({});
                foreach my $user_id (@user_ids) {
                    @list = Bric::Biz::Asset::Template->list_ids(
                           { output_channel__id => $init{output_channel__id},
                             file_name          => $file_name,
                             user__id           => $user_id   });
                    if (@list) {
                        $found_dup = 1;
                        last;
                    }
                }
            }

            throw_ap(error => __PACKAGE__ . "::create : found duplicate template for "
                       . "file_name \"$file_name\" and "
                       . "output channel \"$tdata->{output_channel}\".")
              if $found_dup and not ALLOW_DUPLICATE_TEMPLATES;

            log_event('template_new', $template);
        } else {
            # updating - first look for a checked out version
            $template = Bric::Biz::Asset::Template->lookup({ id => $id,
                                                               checkout => 1
                                                             });
            if ($template) {
                # make sure it's ours
                throw_ap(error => __PACKAGE__ . "::update : template \"$id\" "
                           . "is checked out to another user: "
                           . $template->get_user__id . ".")
                  if defined $template->get_user__id
                    and $template->get_user__id != get_user_id;
                throw_ap(error => __PACKAGE__ . " : access denied.")
                    unless chk_authz($template, EDIT, 1);
            } else {
                # try a non-checked out version
                $template = Bric::Biz::Asset::Template->lookup({id => $id});
                throw_ap(error => __PACKAGE__ . "::update : no template found for \"$id\"")
                    unless $template;
                throw_ap(error => __PACKAGE__ . " : access denied.")
                    unless chk_authz($template, RECALL, 1);

                # FIX: race condition here - between lookup and checkout
                #      someone else could checkout...

                # check it out
                $template->checkout( { user__id => get_user_id });
                $template->save();
                log_event('template_checkout', $template);
            }

            # update %init fields
            $template->_set([keys(%init)],[values(%init)]);
        }

        # need a save here to get the desk stuff working
        $template->deactivate;
        $template->save;

        unless ($update && $no_wf_or_desk_param) {
            $template->set_workflow_id($workflow->get_id);
            log_event("template_add_workflow", $template,
                      { Workflow => $workflow->get_name });
            if ($update) {
                my $olddesk = $template->get_current_desk;
                if (defined $olddesk) {
                    $olddesk->transfer({ asset => $template, to => $desk });
                    $olddesk->save;
                } else {
                    $desk->accept({ asset => $template });
                }
            } else {
                $desk->accept({ asset => $template });
            }
            log_event('template_moved', $template, { Desk => $desk->get_name });
        }

        # activate if desired
        $template->activate if $tdata->{active};

        # checkin and save
        $template->checkin();
        log_event('template_checkin', $template,
                  { Version => $template->get_version });
        $template->save();
        log_event('template_save', $template);

        # all done, setup the template_id
        push(@template_ids, $template->get_id);
    }

    $desk->save if defined $desk;

    return name(ids => [ map { name(template_id => $_) } @template_ids ]);
}

=item $pkg->serialize_asset(writer => $writer, template_id => $template_id, args => $args)

Serializes a single template object into a <template> element using
the given writer and args.

=cut

sub serialize_asset {
    my $pkg         = shift;
    my %options     = @_;
    my $template_id = $options{template_id};
    my $writer      = $options{writer};

    my $template = Bric::Biz::Asset::Template->lookup({id => $template_id});
    throw_ap(error => __PACKAGE__ . "::export : template_id \"$template_id\" not found.")
        unless $template;

    throw_ap(error => __PACKAGE__ .
               "::export : access denied for template \"$template_id\".")
      unless chk_authz($template, READ, 1);

    # open a template element
    $writer->startTag("template", id => $template_id);

    # write out site
    my $site_id = $template->get_site_id;
    my $site = Bric::Biz::Site->lookup({ id => $site_id });
    $writer->dataElement(site => $site->get_name);

    # write out element, known to bric as "name" and save it for later
    $writer->dataElement(element_type =>
                         ($template->get_tplate_type ==
                          Bric::Biz::Asset::Template::ELEMENT_TEMPLATE
                          ? $template->get_element_key_name
                          : ()));

    # Determine if its template type.
    $writer->dataElement(type => $template->get_tplate_type_string);

    # write out simple elements in schema order
    foreach my $e (qw(file_name description priority deploy_status)) {
        $writer->dataElement($e => $template->_get($e));
    }

    # set active flag
    $writer->dataElement(active => ($template->is_active ? 1 : 0));

    # output category
    $writer->dataElement(category => $template->get_category->ancestry_path);

    # get output channel
    my $oc = Bric::Biz::OutputChannel->lookup({
                        id => $template->get_output_channel__id });
    throw_ap(error => __PACKAGE__ . "::export : unable to find output channel")
        unless $oc;
    $writer->dataElement(output_channel => $oc->get_name);

    # get dates and output them in dateTime format
    for my $name qw(expire_date deploy_date) {
        my $date = $template->_get($name);
        next unless $date; # skip missing date
        my $xs_date = db_date_to_xs_date($date);
        throw_ap(error => __PACKAGE__ . "::export : bad date format for $name : $date")
            unless defined $xs_date;
        $writer->dataElement($name, $xs_date);
    }

    # output data
    my $data = $template->get_data;
    Encode::_utf8_off($data) if ENCODE_OK;
    $writer->dataElement(data => MIME::Base64::encode_base64($data,''))
        if $data;

    # close the template
    $writer->endTag("template");
}

=back

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::SOAP|Bric::SOAP>

=cut

1;
