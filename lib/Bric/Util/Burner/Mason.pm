package Bric::Util::Burner::Mason;
###############################################################################

=head1 NAME

Bric::Util::Burner::Mason - Bric::Util::Burner subclass to publish business assets using Mason formatting assets.

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

 use Bric::Util::Burner::Mason;

 # Create a new Mason burner using the settings from $burner
 $mason_burner = Bric::Util::Burner::Mason->new($burner);

 # burn an asset, get back a list of resources
 @resources = $mason_burner->burn_one($ba, $at, $oc, $cat);

=head1 DESCRIPTION

This module handles burning business assets using Mason formatting
assets.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies

use strict;

#--------------------------------------#
# Programatic Dependencies

use HTML::Mason::Interp;
use HTML::Mason::Compiler::ToObject;
use Bric::Util::Fault qw(throw_gen rethrow_exception isa_exception
                         throw_burn_error);
use Bric::Util::Trans::FS;
use Bric::Dist::Resource;
use Bric::Config qw(:burn :l10n);
use Bric::Util::Burner qw(:modes);
use Bric::Biz::AssetType;
require XML::Writer if INCLUDE_XML_WRITER;

#==============================================================================#
# Inheritance                          #
#======================================#
use base qw(Bric::Util::Burner);

#=============================================================================#
# Function Prototypes                  #
#======================================#



#==============================================================================#
# Constants                            #
#======================================#


#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields

#--------------------------------------#
# Private Class Fields
my $fs = Bric::Util::Trans::FS->new;
my $xml_fh = INCLUDE_XML_WRITER
  ? Bric::Util::Burner::Mason::XMLWriterHandle->new
  : undef;

#--------------------------------------#
# Instance Fields

BEGIN {
    Bric::register_fields({
                         #- Per burn/deploy values.
                         'job'            => Bric::FIELD_READ,
                         'more_pages'     => Bric::FIELD_READ,
                         'burn_again'     => Bric::FIELD_RDWR,

                         # Private Fields
                         '_interp'         => Bric::FIELD_NONE,
                         '_comp_root'      => Bric::FIELD_NONE,
                         '_buf'            => Bric::FIELD_NONE,
                         '_writer'         => Bric::FIELD_NONE,
                         '_elem'           => Bric::FIELD_NONE,
                         '_at'             => Bric::FIELD_NONE,
                         '_files'          => Bric::FIELD_NONE,
                         '_res'            => Bric::FIELD_NONE,
                         '_page_place'     => Bric::FIELD_NONE,
                        });
}

__PACKAGE__->_register_burner( Bric::Biz::AssetType::BURNER_MASON,
                               category_fn    => 'autohandler',
                               cat_fn_has_ext => 0,
                               exts           =>
                                 { mc => 'Mason Component (.mc)' }
                             );

#==============================================================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors

#------------------------------------------------------------------------------#

=item $obj = Bric::Util::Burner::Mason->new($burner);

Creates a new Mason burner object.  Takes a single parameters -
$burner - which is a Bric::Util::Burner object.  The new object will
has its attributes initialized by the passed object.

=cut

sub new {
    my ($class, $burner) = @_;
    my $init = { %$burner };

    # setup defaults (in addition to those provided by $burner)
    $init->{_res}     ||= [];

    # create the object using Bric's constructor and return it
    return $class->Bric::new($init);
}

#--------------------------------------#

=back

=head2 Public Instance Methods

=over 4

=cut

#------------------------------------------------------------------------------#

=item @resources = $b->burn_one($ba, $at, $oc, $cat);

Publishes an asset.  Returns a list of resources burned.  Parameters are:

=over 4

=item *

$ba

A business asset object to publish.

=item *

$at

A asset type object for $ba

=item *

$oc

An output channel object to use for the publish

=item *

cat

A category in which to publish.

=back

=cut

sub burn_one {
    my $self = shift;
    my ($ba, $oc, $cat) = @_;
    my ($outbuf, $retval);

    # Determine the component roots.
    my $comp_dir = $self->get_comp_dir;
    my $comp_root = [];
    foreach my $inc ($oc, $oc->get_includes) {
        my $inc_dir = "oc_" . $inc->get_id;

        push @$comp_root, [ 'sandbox' . $inc_dir =>
                            $fs->cat_dir($self->get_sandbox_dir, $inc_dir ) ]
          if $self->get_sandbox_dir;

        push @$comp_root, [ $inc_dir => $fs->cat_dir($comp_dir, $inc_dir) ];
    }

    # Save an existing Mason request object and Bricolage objects.
    my (%bric_objs);
    # XXX Perhaps we should use and check for a subclass, instead?
    my $m = HTML::Mason::Request->instance;
    if ($m and $m->out_method) {
        # If there's an out_method, assume that there's an existing burn
        # going on.
        no strict 'refs';
        for (qw(m story burner element writer)) {
            $bric_objs{$_} = ${TEMPLATE_BURN_PKG . "::$_"};
        }
    }

    # Find the inheritance path and the template name.
    my $element   = $ba->get_tile;
    my $tmpl_path = $cat->ancestry_path;
    my $tmpl_name = $element->get_key_name . '.mc';

    # Create the interpreter
    my $interp = HTML::Mason::Interp->new(
        $self->_interp_args,
        request_class => 'HTML::Mason::Request',
        error_mode    => 'fatal',
        comp_root     => $comp_root,
        data_dir      => $self->get_data_dir,
        out_method    => \$outbuf,
        dhandler_name => $tmpl_name,
    );

    # Push this element onto the top of the stack.
    $self->_push_element($element);

    # Set some global variables to be passed in.
    $interp->set_global('$story',   $ba);
    $interp->set_global('$element', $element);
    $interp->set_global('$burner',  $self);

    # Save some of the values for this burn.
    $self->_set([qw(_buf     _interp  _comp_root element)],
                [  \$outbuf, $interp, $comp_root, $element]);

    # Give 'em the XML Writer object if they want it.
    if (INCLUDE_XML_WRITER) {
        my $writer = XML::Writer->new(OUTPUT => $xml_fh, XML_WRITER_ARGS);
        $interp->set_global('$writer',  $writer);
        $self->_set(['_writer'], [$writer]);
    }

    # XXX Temporarily change Mason's inheritance behavior so that it
    # does inheritance from the category path, not from wherever it
    # finds the document template (acting as a dhandler). This will
    # likely break with HTML::Mason 1.40, but it will probably have
    # a parameter to do it for us (or allow us to subclass Component).
    no warnings 'redefine';
    local *HTML::Mason::Component::inherit_start_path = sub {
        my $self = shift;
        return $tmpl_path if $self->name =~ m/\Q$tmpl_name\E$/;
        return $self->{inherit_start_path};
    };

    while (1) {
        # Run the biz asset through the template
        eval { $retval = $interp->exec($tmpl_path . '/') };
        if (my $err = $@) {
            my $msg;
	    if (HTML::Mason::Exceptions::isa_mason_exception(
                  $err, 'TopLevelNotFound'
              )) {
                # We'll handle this exception ourselves to prevent it from
                # percolating back up to the UI and returning a 404.
		$err = "Mason error: ". $err->message;
                $msg = "Template '$tmpl_name' not found in path '$tmpl_path'";
	    } elsif (isa_exception($err)) {
                # Just dump it.
                rethrow_exception($err);
            } else {
                # Create a generic error message.
                $msg = "Error executing '"
                  . $fs->cat_uri($tmpl_path, $tmpl_name) . "'";
            }
            # Throw the exception.
            throw_burn_error error   => $msg,
                             payload => $err,
                             mode    => $self->get_mode,
                             oc      => $self->get_oc->get_name,
                             cat     => $self->get_cat->get_uri,
                             elem    => $element->get_name;
        }

        # End the page if there is content in the buffer.
        $self->end_page if $outbuf !~ /^\s*$/;

        my ($more, $again) = $self->_get(qw(more_pages burn_again));
        if ($again) {
            # Reset burn_again and move on to the next page.
            $self->_set(['burn_again'] => [0]);
            next;
        }

        # Keep burning this template if it contains more pages.
        last unless $more;
    }

    # Restore any existing Mason request object and Bricolage objects.
    if ($bric_objs{story}) {
        no strict 'refs';
        for (qw(m story burner element writer)) {
            ${TEMPLATE_BURN_PKG . "::$_"} = $bric_objs{$_};
        }
    }

    # Free up the element stack.
    $self->_pop_element;

    # Return a list of the resources we just burned.
    my $ret = $self->_get('_res') || return;
    $self->_set(['_res', 'page'], [[], 0]);
    return wantarray ? @$ret : $ret;
}

################################################################################

=item my $bool = $burner->chk_syntax($template, \$err)

Compiles the template found in C<$template>. If the compile succeeds with no
errors, C<chk_syntax()> returns true. Otherwise, it returns false, and the
error will be in the C<$err> variable passed by reference.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub chk_syntax {
    my ($self, $tmpl, $err_ref) = @_;
    # Just succeed if there is no template source code.
    my $data = $tmpl->get_data or return $self;

    # Create the interpreter
    my $interp = HTML::Mason::Interp->new( $self->_interp_args,
                                          'comp_root'  => $self->get_comp_dir,
                                          'data_dir'   => $self->get_data_dir,
                                          );

    $interp->set_global('$burner', $self);

    # Try to create a component.
    my $comp = eval { $interp->make_component(comp_source => $data) };
    if ($@) {
        $$err_ref = $@;   # $@->as_line()?
        return;
    } else {
        return $comp;
    }
}

#------------------------------------------------------------------------------#

=item my $template = $burner->find_template($uri, $tmpl_name)

Finds the first instance of the template with the name $tmpl_name in the URI
directory hierarchy in $uri. Returns the template path, if it exists, and undef
if it does not. For example:

  my $uri = '/foo/bar/bletch';
  my $tmpl_name = 'story.mc';
  my $template = $burner->find_template($uri, $tmpl_name);

The find_template() method will look first for '/foo/bar/bletch/story.mc', and
return that string if the template exists. If it doesn't, it'll look for
'/foo/bar/story.mc'. If it doesn't find that, it'll look for '/foo/story.mc' and
then '/story.mc'. If it finds none of these, it will rutrn null (or an empty
list in an array context.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses HTML::Mason::Interp->comp_exists() internally to determine if the
template exists.

=cut

sub find_template {
    my ($self, $uri, $name) = @_;
    my $interp = $self->_get('_interp');
    my @dirs = $fs->split_uri($uri);
    while (@dirs) {
        my $tmpl = $fs->cat_uri(@dirs, $name);
        return $tmpl if $interp->comp_exists($tmpl);
        # Pop off a directory.
        pop @dirs;
    }
    return;
}

#------------------------------------------------------------------------------#

=item my $template = $burner->find_first_template(@tmpl_list)

Returns the path to the first template it finds in @tmpl_list. It uses
find_template() (see above) to examine each template in @tmpl_list in turn.
Thus, this method looks down the directory hierarchy of each template in
@tmpl_list before moving on to the next one. For example:

  my @tmpl_list = ('/foo/bar/story.mc', '/sci/anthro/fizzle.mc');
  my $template =  $burner->find_first_template(@tmpl_list)

In this example, find_first_template will return the name of the first template
it finds in this order:

=over 4

=item *

/foo/bar/story.mc'

=item *

/foo/story.mc'

=item *

/story.mc'

=item *

/sci/anthro/fizzle.mc'

=item *

/sci/fizzle.mc'

=item *

/fizzle.mc'

=back

If no template is found to exist, find_first_template will return undef (or an
empty list in an array context).

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> See also find_template() above.

=cut

sub find_first_template {
    my $self = shift;
    while (my $tmpl = shift) {
        $tmpl = $self->find_template($fs->uri_dir_name($tmpl),
                                     $fs->uri_base_name($tmpl))
          || next;
        return $tmpl;
    }
    return;
}

#------------------------------------------------------------------------------#

=item $success = $b->display_pages($paginated_element_name)

=item $success = $b->display_pages($paginated_element_name, %ARGS)

=item $success = $b->display_pages(\@paginated_element_names, %ARGS)

A method to be called from template space. Use this method to display
paginated elements. If this method is used, the burn system will run once for
every page element listed in C<\@paginated_element_names> (or just
C<$paginated_element_name>) in the story; this is so that autohandlers will be
called when appropriate. All arguments after the first argument will be passed
to the template executed as its C<%ARGS> hash.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub display_pages {
    my $self = shift;
    my $names = shift;
    $names = [$names] unless ref $names;

    # Get the current element
    my $elem = $self->_current_element;
    my $page_place = $self->_get('_page_place') || 0;

    # Get the next two containers starting with place == $page_place
    # and having name eq one of @$names. $next_page will be undef
    # for the last page. The map changes old-style names to key_names.
    my $joined_names = join('|', map {y/a-z0-9/_/cs; lc $_} @$names);
    my ($page_elem, $next_page) =
      grep { $_->is_container
             && $_->get_place >= $page_place
             && $_->get_key_name =~ /^($joined_names)$/ }
      $elem->get_tiles;

    # Set the 'more_pages' and '_page_place' properties.
    $self->_set([ qw(more_pages _page_place) ],
                [ $next_page,
                  $page_elem ? $page_elem->get_place + 1 : $page_place + 1 ]);

    $self->display_element($page_elem, @_);
}

#------------------------------------------------------------------------------#

=item $success = $b->display_element($element)

=item $success = $b->display_element($element, %ARGS)

A method to be called from template space. This method will find the mason
element associated with the element passed in and call C<< $m->comp >>. All
arguments after the first argument will be passed to the template executed as
its C<%ARGS> hash.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub display_element {
    my $self = shift;
    my $elem = shift or return;
    $self->_render_element($elem, 1, @_);
}

#------------------------------------------------------------------------------#

=item $html = $b->sdisplay_element($element)

A method to be called from template space. This is a sprintf version
of $b->display_element(), i.e. it returns as a string of HTML what
would have been displayed with $b->display_element().

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub sdisplay_element {
    my $self = shift;
    my $elem = shift or return;
    return $self->_render_element($elem, 0, @_);
}

##############################################################################

=item my $more_pages = $b->get_more_pages

  % unless ($burner->get_more_pages) {
        <h3>Last page</h3>
  % }

Returns true if more pages remain to be burned, and false if not. Only
enumerated when C<display_pages()> is being used to output pages.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

##############################################################################

=item $success = $b->set_burn_again(1)

=item my $again = $b->get_burn_again

This method is designed to be called from within a template. When passed a
true value, it causes the burner to burn the current story and page again,
creating another file. This is useful for creating multi-file output without
extra paginated subelements. For example, if you need to create an index of
stories, and you only want to list 10 on a page over multiple pages, you can
use this method to force the burner to burn as many pages as you need to get
the job done.

When the burner prepares to burn the page again, it resets the C<burn_again>
attribute. So you'll need to set it for every page for which another page
burned.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

#------------------------------------------------------------------------------#

=item $success = $b->chain_next()

This method can be used in an autohandler template. It calls the next template
in the chain, whether its the next autohandler down the line or the template
itself.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:>

This is a wrapper around masons 'call_next' method. We wrap it here to make sure
we have control over the burn process at this level if we need it. It also gives
us the opportunity to tailor the verbiage to suit our application better.

=cut

sub chain_next {
    my $self = shift;
    HTML::Mason::Request->instance->call_next(@_);
}

#------------------------------------------------------------------------------#

=item $success = $b->end_page;

Writes out the current page and starts a new one.

B<Throws:>

=over 4

=item *

Unable to open file for writing.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub end_page {
    my $self = shift;

    my ($page, $buf) = $self->_get(qw(page _buf));
    my $file = $self->page_filepath(++$page);
    my $uri  = $self->page_uri($page);

    # Save the page we've created so far.
    open(OUT, ">$file")
      or throw_gen error => "Unable to open '$file' for writing",
                   payload => $!;
    binmode(OUT, ':' . $self->get_encoding || 'utf8') if ENCODE_OK;
    print OUT $$buf;
    close(OUT);

    # Add a resource to the job object.
    $self->_add_resource($file, $uri);

    # Clear the output buffer.
    $$buf = '';
    # Increment the page number
    $self->_set(['page'], [$page]);
}

#==============================================================================#

=back

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

=over 4

=item $success = $b->_add_resource();

Adds a Bric::Dist::Resource object to this burn.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _add_resource {
    my $self = shift;
    my ($file, $uri) = @_;
    my ($story, $ext) = $self->_get(qw(story output_ext));

    # Create a resource for the distribution stuff.
    my $res = Bric::Dist::Resource->lookup({
        path => $file,
        uri  => $uri,
    }) ||
    Bric::Dist::Resource->new({
        path => $file,
        uri  => $uri,
    });

    # Set the media type.
    $res->set_media_type(Bric::Util::MediaType->get_name_by_ext($ext));
    # Add our story ID.
    $res->add_story_ids($story->get_id);
    $res->save;
    my $ress = $self->_get('_res');
    push @$ress, $res;
}

#------------------------------------------------------------------------------#

=item $template = $b->_load_template_element($element);

Given an element (a business asset/data tile) return the template element that
formats it.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _load_template_element {
    my ($self, $element) = @_;
    my ($oc, $cat) = $self->_get(qw(oc cat));

    # Get the path (based at comp_root) and the template name.
    my $tmpl_path = $cat->ancestry_path;
    my $tmpl_name = $element->get_key_name . '.mc';

    # Look up the template (it may live few directories above $tmpl_path)
    my $tmpl = $self->find_template($tmpl_path, $tmpl_name)
      or throw_burn_error error => "Unable to find template '$tmpl_name'",
                          mode  => $self->get_mode,
                          oc    => $self->get_oc->get_name,
                          cat   => $self->get_cat->get_uri,
                          elem  => $element->get_name;
    return $tmpl;
}

#------------------------------------------------------------------------------#

=item $elem = $b->_current_element

Return the current element in this context.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _current_element { $_[0]->_get('_elem')->[-1] }

#------------------------------------------------------------------------------#

=item $elem = $b->_current_element_type

Return the current element type in this context.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _current_element_type { $_[0]->_get('_at')->[-1] }

#------------------------------------------------------------------------------#

=item $b = $b->_push_element($element)

=item $element = $b->_pop_element;

Push and pops an element from the element stack. As a story is burned, the burn
process can travel down several elements deep. This stack records the order in
which each element was transversed so when the burn process exits an element,
the correct and current element is at the top of the stack.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _push_element {
    my ($self, $element) = @_;
    my ($elem_stack, $at_stack) = $self->_get('_elem', '_at');

    push @$elem_stack, $element;
    push @$at_stack, $element->get_element;

    $self->_set(['_elem', '_at'], [$elem_stack, $at_stack]);
}

sub _pop_element {
    my $self = shift;
    my ($elem_stack, $at_stack) = $self->_get('_elem', '_at');

    pop @$at_stack;
    return pop @$elem_stack;
}

#------------------------------------------------------------------------------#

=item $html = $b->_render_element($element, $display)

Common code used by $b->display_element and $b->sdisplay_element.
It directly displays the HTML for display_element, while it
returns the HTML as a string for sdisplay_element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _render_element {
    my ($self, $elem, $display) = (shift, shift, shift);
    my $html = '';

    # Call another element if this is a container otherwise output the data.
    if ($elem->is_container) {
        my $interp = $self->_get('_interp');

        # Set the elem global to the current element.
        $interp->set_global('$element', $elem);
        $self->_set(['element'], [$elem]);

        # Push this element on to the stack
        $self->_push_element($elem);

        if (my $template = $self->_load_template_element($elem)) {
            # Display the element
            if ($display) {
                HTML::Mason::Request->instance->comp($template, @_);
            } else {
                $html = HTML::Mason::Request->instance->scomp($template, @_);
            }
        }

        # Pop the element back off again.
        $self->_pop_element();

        # Set the elem global to the previous element
        my $curr = $self->_current_element;
        $interp->set_global('$element', $curr);
        $self->_set(['element'], [$curr]);

        return $html;
    } else {
        if ($display) {
            HTML::Mason::Request->instance->out($elem->get_data);
        } else {
            return $elem->get_data();
        }
    }
}

#--------------------------------------#

=back

=head2 Private Functions

=over 4

=item _interp_args()

Returns HTML::Mason->Interp arguments, with custom tags set.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _interp_args {
    my $self = shift;
    # Mason Interp args

    my %interp_args = (
          'allow_globals' => [qw($story
                                 $burner
                                 $writer
                                 $element)],
          'in_package'    => TEMPLATE_BURN_PKG
     );

     $interp_args{compiler} = HTML::Mason::Compiler::ToObject->new
       ( %interp_args,
         preprocess => \&_custom_preprocess,
         preamble   => "use utf8;\n",
       );

     return %interp_args;
}

##############################################################################

=item _custom_preprocess($component, $burner)

HTML::Mason::Compiler pre-process filter, to allow custom mason tags.

Pre-processor checks the tagset for the context, which can be
PREVIEW_MODE, BURN_MODE or SYNTAX_MODE, and processes the tags
according to the context.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _custom_preprocess {
    my $s = shift;

    # Change %realtime to %text.
    $$s =~ s/<(\/)?\%realtime>/<$1\%text>/gi;

    my %modes = ( publish    => 'PUBLISH_MODE',
                  preview    => 'PREVIEW_MODE',
                  chk_syntax => 'SYNTAX_MODE'
                );

    # Change other custom tags to %perl that check the burn mode.
    # XXX This may be a bit naive, if people put the "<%publish>" in a context
    # where it's not actually a block (such as in a string). But why would
    # anyone do that??
    while (my ($tag, $mode) = each %modes) {
        $$s =~ s/<%$tag>/<%perl>if (\$burner->get_mode == Bric::Util::Burner->$mode) {/gi;
        $$s =~ s/<\/%$tag>/}<\/%perl>/gi;
    }
}

1;

##############################################################################
# This package is for the XML::Writer to use to write XML directly to the
# Mason buffer.
package Bric::Util::Burner::Mason::XMLWriterHandle;
use Bric::Config qw(:burn);

sub new { bless {} }

sub print {
    shift;
    HTML::Mason::Request->instance->out(@_);
}

1;

__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

Garth Webb L<gt>garth@perijove.comL<lt>

Sam Tregar L<gt>stregar@about-inc.comL<lt>

David Wheeler L<gt>david@wheeler.netL<lt>

=head1 SEE ALSO

L<Bric>, L<Bric::Util::Burner>

=cut
