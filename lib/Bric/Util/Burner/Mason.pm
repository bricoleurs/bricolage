package Bric::Util::Burner::Mason;
###############################################################################

=head1 NAME

Bric::Util::Burner::Mason - Bric::Util::Burner subclass to publish business assets using Mason formatting assets.

=head1 VERSION

$Revision: 1.13 $

=cut

our $VERSION = (qw$Revision: 1.13 $ )[-1];

=head1 DATE

$Date: 2002-03-09 00:43:02 $

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

use HTML::Mason::Parser;
use HTML::Mason::Interp;
use Bric::Util::Fault::Exception::GEN;
use Bric::Util::Fault::Exception::AP;
use Bric::Util::Fault::Exception::MNI;
use Bric::Util::Trans::FS;
use Bric::Dist::Resource;
use Bric::Config qw(:burn);
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
my $mni = 'Bric::Util::Fault::Exception::MNI';
my $ap = 'Bric::Util::Fault::Exception::AP';
my $gen = 'Bric::Util::Fault::Exception::GEN';
my $fs = Bric::Util::Trans::FS->new;
my $xml_fh = INCLUDE_XML_WRITER ? Bric::Util::Burner::Mason::XMLWriterHandle->new
  : undef;

#--------------------------------------#
# Instance Fields

BEGIN {
    Bric::register_fields({
			 #- Per burn/deploy values.
			 'job'            => Bric::FIELD_READ,
			 'page'           => Bric::FIELD_RDWR,
			 'story'          => Bric::FIELD_READ,
			 'oc'             => Bric::FIELD_READ,
			 'cat'            => Bric::FIELD_READ,
			 'uri_path'       => Bric::FIELD_READ,

			 # Private Fields
			 '_interp'         => Bric::FIELD_NONE,
			 '_comp_root'      => Bric::FIELD_NONE,
			 '_buf'            => Bric::FIELD_NONE,
			 '_writer'         => Bric::FIELD_NONE,
			 '_elem'           => Bric::FIELD_NONE,
			 '_at'             => Bric::FIELD_NONE,
			 '_files'          => Bric::FIELD_NONE,
			 '_res'            => Bric::FIELD_NONE,
			 '_more_pages'     => Bric::FIELD_NONE,
			});
}

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
    $init->{page}     ||= 0;
    $init->{_res}     ||= [];

    # create the object using Bric's constructor and return it
    return $class->Bric::new($init);
}

#--------------------------------------#

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
    my ($ba, $at, $oc, $cat) = @_;
    my ($outbuf, $retval);

    # Create a parser and allow some global variables.
    my $parser = HTML::Mason::Parser->new('allow_globals' => [qw($story
								 $burner
								 $writer
								 $element)],
					  'in_package'    => TEMPLATE_BURN_PKG);
    # Determine the component roots.
    my $comp_dir = $self->get_comp_dir;
    my $comp_root = [];
    foreach my $inc ($oc, $oc->get_includes) {
	my $inc_dir = "oc_" . $inc->get_id;
	push @$comp_root, [ $inc_dir => $fs->cat_dir($comp_dir, $inc_dir) ];
    }

    # Create the interpreter
    my $interp = HTML::Mason::Interp->new('parser'     => $parser,
			 		  'comp_root'  => $comp_root,
				 	  'data_dir'   => $self->get_data_dir,
					  'out_method' => \$outbuf);

    my $element = $ba->get_tile;
    $self->_push_element($element);

    # Set some global variables to be passed in.
    $interp->set_global('$story',   $ba);
    $interp->set_global('$element', $element);
    $interp->set_global('$burner',  $self);

    # save some of the values for this burn.
    $self->_set([qw(story   oc   cat   _buf     _interp  _comp_root)],
		[   $ba,   $oc, $cat, \$outbuf, $interp, $comp_root]);

    # Give 'em the XML Writer object if they want it.
    if (INCLUDE_XML_WRITER) {
	my $writer = XML::Writer->new(OUTPUT => $xml_fh, XML_WRITER_ARGS);
	$interp->set_global('$writer',  $writer);
	$self->_set(['_writer'], [$writer]);
    }

    # Get the template name. Because this is a top-level Element, we don't want
    # to look far for its corresponding template.
    my $tmpl_path = $fs->cat_uri('', $oc->get_pre_path, $cat->ancestry_path,
				 $oc->get_post_path);
    my $tmpl_name = _fmt_name($element->get_name);
    my $template = $fs->cat_uri($tmpl_path, $tmpl_name);
    if ( $interp->lookup($template . '.mc') ) {
	# The top-level .mc template exits.
	$template .= '.mc';
    } else {
	# If we're in here, there's no top-level .mc template. So create a
	# dhandler for it if there isn't one already.
	_create_dhandler($comp_root, $oc, $cat, $tmpl_name)
	  unless $interp->lookup($fs->cat_uri($tmpl_path, 'dhandler'));
    }

    while (1) {
	# Run the biz asset through the template
	eval { $retval = $interp->exec($template) if $template };
	die $ap->new({ msg     => "Error executing template '$template'.",
		       payload => $@ }) if $@;

	# End the page if there is still content in the buffer.
	$self->end_page if $outbuf !~ /^\s*$/;

	# Keep burning this template if it contains more pages.
	last unless $self->_get('_more_pages');
    }

    $self->_pop_element();

    # Return a list of the resources we just burned.
    my $ret = $self->_get('_res') || return;
    $self->_set(['_res', 'page'], [[], 0]);
    return wantarray ? @$ret : $ret;
}

################################################################################

=item my $bool = $burner->chk_syntax($template_code, \$err)

Compiles the template found in $template_data. If the compile succeeds with no
errors, chk_syntax() returns true. Otherwise, it returns false, and the error
will be in the $err varible passed by reference.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub chk_syntax {
    my ($self, $ba, $err_ref) = @_;

    # Create a parser and allow some global variables.
    my $parser = HTML::Mason::Parser->new('allow_globals' => [qw($story
								 $burner
								 $writer
								 $element)],
					  'in_package'    => TEMPLATE_BURN_PKG);
    # Create the interpreter
    my $interp = HTML::Mason::Interp->new('parser'     => $parser,
			 		  'comp_root'  => $self->get_comp_dir,
				 	  'data_dir'   => $self->get_data_dir);

    # Try to create a component.
    return $parser->make_component(script => $ba->get_data,
				   error  => $err_ref);
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

B<Notes:> Uses HTML::Mason::Interp->lookup() internally to determine if the
template exists.

=cut

sub find_template {
    my ($self, $uri, $name) = @_;
    my $interp = $self->_get('_interp');
    my @dirs = $fs->split_uri($uri);
    while (@dirs) {
	my $tmpl = $fs->cat_uri(@dirs, $name);
	return $tmpl if $interp->lookup($tmpl);
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

A method to be called from template space. Use this method to display paginated
elements. If this method is used, the burn system will run once for every page
in the story; this is so autohandlers will be called when appropriate.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub display_pages {
    my $self = shift;
    my ($elem_name) = @_;
    my $interp   = $self->_get('_interp');
    my $page_num = $self->get_page;

    # Get the current element
    my $elem      = $self->_current_element;
    # Get the current page to burn (+1 since the $page var starts at 0).
    my $page_elem = $elem->get_container($elem_name, $page_num+1);

    # Do a look ahead to the next page.
    my $next_page = $elem->get_container($elem_name, $page_num+2);
    # Set the '_more_pages' variable if there are more pages to burn after this.
    $self->_set(['_more_pages'], [(defined($next_page) ? 1 : 0)]);

    $self->display_element($page_elem);
}

#------------------------------------------------------------------------------#

=item $success = $b->display_element()

A method to be called from template space. This method will find the mason
element associated with the element passed in and call $m->comp.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub display_element {
    my ($self, $elem) = @_;
    return unless $elem;

    # Call another element if this is a container otherwise output the data.
    if ($elem->is_container) {
	my $interp = $self->_get('_interp');

	# Set the elem global to the current element.
	$interp->set_global('$element', $elem);

	# Push this element on to the stack
	$self->_push_element($elem);

	my $template = $self->_load_template_element($elem);

	# Display the element
	{
	    no strict 'refs';
	    ${TEMPLATE_BURN_PKG . '::m'}->comp($template) if $template;
	}

	# Pop the element back off again.
	$self->_pop_element();

	# Set the elem global to the previous element
	$interp->set_global('$element', $self->_current_element);
    } else {
	    no strict 'refs';
	    ${TEMPLATE_BURN_PKG . '::m'}->out($elem->get_data);
    }
}


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
    no strict 'refs';
    ${TEMPLATE_BURN_PKG . '::m'}->call_next;
}

#------------------------------------------------------------------------------#

=item $success = $b->end_page();

Writes out the current page and starts a new one.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub end_page {
    my $self = shift;
    my $ba   = $self->get_story;
    my $buf  = $self->_get('_buf');

    my ($cat, $oc) = $self->_get('cat', 'oc');
    my $fn = $oc->get_filename;
    my $ext = $oc->get_file_ext;
    my $page       = $self->get_page || '';
    my $filename   = "$fn$page.$ext";
    my $base       = $fs->cat_dir($self->get_out_dir, 'oc_' . $oc->get_id);

    # The URI minus the page name.
    my $base_uri = $ba->get_uri($cat, $oc);
    # The complete URI
    my $uri      = $fs->cat_uri($base_uri, $filename);
    # The complete path on the file system sans the filename.
    my $path     = $fs->cat_dir($base, $base_uri);
    # The complete path on the file system including the filename.
    my $file     = $fs->cat_dir($path, $filename);

    # Create the necessary directories
    $fs->mk_path($path);

    # Flush the output buffer before writing the file.
    {
	no strict 'refs';
	${TEMPLATE_BURN_PKG . '::m'}->flush_buffer;
	}

    # Save the page we've created so far.
    open(OUT, ">$file")
      || die $gen->new({ msg => "Unable to open '$file' for writing",
			 payload => $! });
    print OUT $$buf;
    close(OUT);

    # Add a resource to the job object.
    $self->_add_resource($file, $uri);

    # Clear the output buffer.
    $$buf = '';
    # Increment the page number
    $self->set_page(++$page);
}

#==============================================================================#

=head2 PRIVATE

=cut

#--------------------------------------#

=head2 Private Class Methods

=cut

sub _fmt_name {
    # Lowercase the name.
    my $name = lc $_[0];
    # Replace non-alphanumeric characters with underscores.
    $name =~ y/a-z0-9/_/cs;
    return $name;
}

#--------------------------------------#

=head2 Private Instance Methods

NONE

=cut

#------------------------------------------------------------------------------#

=item $success = $b->_add_resource();

Adds a Bric::Dist::Resource object to this burn.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _add_resource {
    my $self = shift;
    my ($file, $uri) = @_;
    my $ba  = $self->get_story;

    # Create a resource for the distribution stuff.
    my $res = Bric::Dist::Resource->lookup({ path => $file}) ||
      Bric::Dist::Resource->new({ path => $file,
				uri  => $uri});
    # Set the media type.
    $res->set_media_type(Bric::Util::MediaType->get_name_by_ext('html'));
    # Add our story ID.
    $res->add_story_ids($ba->get_id);
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
    my $tmpl_path = $fs->cat_uri('', $oc->get_pre_path, $cat->ancestry_path,
				 $oc->get_post_path);
    my $tmpl_name = _fmt_name($element->get_name) . '.mc';

    # Look up the template (it may live few directories above $tmpl_path)
    my $tmpl = $self->find_template($tmpl_path, $tmpl_name)
      || die $ap->new({ msg     => "Unable to find template '$tmpl_name'",
			payload => { class   => __PACKAGE__,
				     action  => 'load template',
				     context => { oc   => $self->get_oc,
						  cat  => $self->get_cat,
						  elem => $element
						}
				   }
		      });
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

#--------------------------------------#

=head2 Private Functions

=over 4

=item _create_dhandler($comp_root, $oc, $cat, $tmpl_name)

Creates a top-level dhandler. This dhandler, when executed, will find the proper
template in its URI hierarchy. The reason we create this dhandler is to ensure
that a mason component gets executed at the end of the URI hierarchy, so that
all the corresponding autohandlers will also be executed properly.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

=back

=cut

sub _create_dhandler {
    my ($comp_root, $oc, $cat, $tmpl_name) = @_;
    # The complete path on the file system sans the filename.
    my $path = $fs->cat_dir($comp_root->[0][1], $oc->get_pre_path,
			    $cat->ancestry_path, $oc->get_post_path);

    # The complete path on the file system including the filename.
    my $file = $fs->cat_dir($path, 'dhandler');

    # Create the necessary directories
    $fs->mk_path($path);

    # Now just write it out to the file system.
    open(DH, ">$file")
      || die $gen->new({ msg => "Unable to open '$file' for writing",
			 payload => $! });
	print DH q{<%once>;
my $ap = 'Bric::Util::Fault::Exception::AP';
</%once>
<%init>;
my $template = $burner->find_template($m->current_comp->dir_path,
                                      $m->dhandler_arg . '.mc')
  || die $ap->new({ msg     => "Unable to find template '"
                               . $m->dhandler_arg . "\.mc'",
                    payload => { class   => __PACKAGE__,
			         action  => 'load template',
			         context => { oc   => $burner->get_oc,
					      cat  => $burner->get_cat,
					      elem => $element }}
                   });
$m->comp($template);
</%init>
};
	close(DH);
}

1;

package Bric::Util::Burner::Mason::XMLWriterHandle;
use Bric::Config qw(:burn);

sub new { bless {} }

sub print {
    no strict 'refs';
    ${TEMPLATE_BURN_PKG . '::m'}->out(@_[1..$#_]);
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
