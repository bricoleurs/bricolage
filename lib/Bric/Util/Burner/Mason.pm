package Bric::Util::Burner::Mason;
###############################################################################

=head1 NAME

Bric::Util::Burner::Mason - Bric::Util::Burner subclass to publish business assets using Mason formatting assets.

=head1 VERSION

$Revision: 1.1 $

=cut

our $VERSION = substr(q$Revision: 1.1 $, 10, -1);

=head1 DATE

$Date: 2001-11-19 21:37:36 $

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
					  'in_package'    => __PACKAGE__);
    # Create the interpreter
    my $interp = HTML::Mason::Interp->new('parser'     => $parser,
			 		  'comp_root'  => $self->get_comp_dir,
				 	  'data_dir'   => $self->get_data_dir,
					  'out_method' => \$outbuf);

    my $element = $ba->get_tile;
    $self->_push_element($element);

    # Set some global variables to be passed in.
    $interp->set_global('$story',   $ba);
    $interp->set_global('$element', $element);
    $interp->set_global('$burner',  $self);

    # save some of the values for this burn.
    $self->_set([qw(story   oc   cat   _buf    _interp)],
		[   $ba,   $oc, $cat, \$outbuf, $interp]);

    if (INCLUDE_XML_WRITER) {
	my $writer = XML::Writer->new(OUTPUT => $xml_fh, XML_WRITER_ARGS);
	$interp->set_global('$writer',  $writer);
	$self->_set(['_writer'], [$writer]);
    }

    my $template = $self->_load_template_element($element);

    while (1) {
	# Run the biz asset through the template
	$retval = $interp->exec($template) if $template;

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


#------------------------------------------------------------------------------#

=item $success = $b->display_pages($paginated_element_name)

A method to be called from template space. Use this method to display paginated
elements. If this method is used, the burn system will run once for every page
in the story; this is so autohandlers will be called when appropriate.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub display_pages {
    my $self = shift;
    my ($elem_name) = @_;
    my $interp   = $self->_get('_interp');
    my $page_num = $self->get_page;

    # Get the current element
    my $elem      = $self->_head_element;
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

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

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
	$Bric::Util::Burner::Mason::m->comp($template) if $template;

	# Pop the element back off again.
	$self->_pop_element();

	# Set the elem global to the previous element
	$interp->set_global('$element', $self->_current_element);
    } else {
	$Bric::Util::Burner::Mason::m->out($elem->get_data);
    }
}


#------------------------------------------------------------------------------#

=item $success = $b->chain_next()

This method can be used in an autohandler template.  It calls the next template 
in the chain, whether its the next autohandler down the line or the template
itself.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

This is a wrapper around masons 'call_next' method.  We wrap it here to make 
sure we have control over the burn process at this level if we need it.  It 
also gives us the opportunity to tailor the verbage to suit our application 
better.

=cut

sub chain_next { $Bric::Util::Burner::Mason::m->call_next }

#------------------------------------------------------------------------------#

=item $success = $b->end_page();

Writes out the current page and starts a new one.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

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
    my $base       = $self->_base_path;

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
    $Bric::Util::Burner::Mason::m->flush_buffer;

    # Save the page we've created so far.
    my $err_msg  = "Unable to open '$file' for writing";
    open(OUT, ">$file")
      or die Bric::Util::Fault::Exception::GEN->new({'msg'     => $err_msg,
						   'payload' => $@});
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
    my ($name) = @_;

    # Lowercase the name.
    $name = lc $name;
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

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

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

Given an element (a business asset/data tile) return the template element 
that formats it.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _load_template_element {
    my $self = shift;
    my ($element) = @_;
    my ($oc, $cat) = $self->_get('oc', 'cat');

    # Get the path (based at comp_root) and the template name.
    my $tmpl_path = $self->_template_path($oc, $cat);
    my $tmpl_name = _fmt_name($element->get_name);

    # Look up the template (it may live few directories above $tmpl_path)
    my $tmpl = $self->_locate_template($tmpl_path, $tmpl_name);

    unless ($tmpl) {
	my $payload = {'class'   => __PACKAGE__,
		       'action'  => 'load template',
		       'context' => {'oc'   => $oc,
				     'cat'  => $cat,
				     'elem' => $element}};

	my $msg = "Unable to find template '$tmpl_name'";
	die Bric::Util::Fault::Exception::AP->new({'msg'     => $msg,
						 'payload' => $payload});
    }

    return $fs->cat_dir('', $tmpl) if $tmpl;
    return;
}

#------------------------------------------------------------------------------#

=item ($base, $path) = $b->_base_path

Returns the full path to the output directory.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _base_path {
    my $self = shift;
    my $oc   = $self->get_oc;

    my $base = $fs->cat_dir($self->get_out_dir, 'oc_' . $oc->get_id);

    return $base;
}

#------------------------------------------------------------------------------#

=item $path = $b->_template_path

Returns the URI portion of the template path.  This is the path that is
considered 'absolute' with respect to the Mason element root.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _template_path {
    my ($self, $oc, $cat) = @_;

    $oc  ||= $self->get_oc;
    $cat ||= $self->get_cat;

    return $fs->cat_dir(('oc_' . $oc->get_id), $oc->get_pre_path,
			$cat->ancestry_path, $oc->get_post_path);
}

#------------------------------------------------------------------------------#

=item $template = $b->_locate_template

Returns the template name with full path with respect to the element root.  If
the named template $tmpl_name cannot be found at path $init_path, then this
method will create a special dhanlder that will check for $tmpl_name, one 
directory up.  It will continue searching for the template in this way until 
it either finds it or it gets to the root of the element tree, in which case 
it returns undef.

This code is put into a dhandler so that mason can continue to call any
autohandlers if necessary.  If the correct element was searched for and called
directly, someone might call:

/foo/bar/blitz.mc

and expect that the autohandler in:

/foo/autohandler

will be called.  However if the element actually lives in:

/blitz.mc

And we call it directly the autohandler will never be called.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _locate_template {
    my ($self, $init_path, $tmpl_name) = @_;
    my $comp_dir  = $self->_get('comp_dir');
    my $dir       = $fs->cat_dir($comp_dir, $init_path);
    my $full_path = $fs->cat_dir($dir, $tmpl_name . '.mc');

    # Return the path right away if we have an exact match.
    return $fs->cat_dir($init_path, $tmpl_name.'.mc') if -e $full_path;

    # Get the current element and then its asset type.
    my $element = $self->_current_element;
    my $at      = $element->get_element;

    if ($at and $at->get_top_level) {
	_create_dhandler($dir);

	# Return the path to our dhandler with the template name tacked on
	return $fs->cat_dir($init_path, $tmpl_name);
    } else {	
	# Search for the file ourselves.
	while (not -e $full_path) {
	    # Bail if we can't find the element.
	    unless ($init_path) {
		my $payload = {'class'   => __PACKAGE__,
			       'action'  => 'load template',
			       'context' => {'oc'   => $self->get_oc,
					     'cat'  => $self->get_cat,
					     'elem' => $element}};
		
		my $msg = "Unable to find template '$tmpl_name'";
		die Bric::Util::Fault::Exception::AP->new({'msg'    =>$msg,
							 'payload'=>$payload});
	    }

	    # Chop off one directory.
	    $init_path = $fs->trunc_dir($init_path);
	    $full_path = $fs->cat_dir($comp_dir, $init_path, $tmpl_name.'.mc');
	}
	
	# Return the template path.
	return $fs->cat_dir($init_path, $tmpl_name.'.mc');
    }
}

#------------------------------------------------------------------------------#

=item $elem = $b->_current_element

Return the current element in this context.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _current_element {
    my $self = shift;
    my $elem_stack = $self->_get('_elem');

    return $elem_stack->[-1];
}

#------------------------------------------------------------------------------#

=item $elem = $b->_current_element_type

Return the current element type in this context.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _current_element_type {
    my $self = shift;
    my $at_stack = $self->_get('_at');

    return $at_stack->[-1];
}

#------------------------------------------------------------------------------#

=item $b = $b->_push_element($element)

=item $element = $b->_pop_element;

Push and pops an element from the element stack.  As a story is burned, the 
burn process can travel down several elements deep.  This stack records the 
order in which each element was transversed so when the burn process exits an
element, the correct and current element is at the top of the stack.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _push_element {
    my $self = shift;
    my ($element) = @_;
    my ($elem_stack, $at_stack) = $self->_get('_elem', '_at');

    push @$elem_stack, $element;
    push @$at_stack, $element->get_element;

    $self->_set(['_elem', '_at'], [$elem_stack, $at_stack]);
}

sub _pop_element {
    my $self = shift;
    my ($elem_stack, $at_stack) = $self->_get('_elem', '_at');

    pop @$at_stack;
    my $elem = pop @$elem_stack;

    return $elem;
}

sub _head_element {
    my $self = shift;
    my ($elem_stack, $at_stack) = $self->_get('_elem', '_at');

    return $elem_stack->[-1];
}

#--------------------------------------#

=head2 Private Functions

NONE

=cut


sub _create_dhandler {
    my ($dir) = @_;

    # See if a universal dhanlder has been created here yet.
    unless (-e $fs->cat_dir($dir, 'dhandler')) {
	# Create dhandler to call our element so that the proper autohandlers
	# will be called.
	my $dhandler = _gen_dhandler_code();
	
	# Create the necessary directories
	$fs->mk_path($dir);

	my $file = $fs->cat_dir($dir, 'dhandler');

	# Write out the dhandler.
	my $err_msg  = "Unable to open '$file' for writing";
	open(DH, ">$file")
	  or die Bric::Util::Fault::Exception::GEN->new({'msg'     => $err_msg,
						       'payload' => $@});
	print DH $dhandler;
	close(DH);
    }
}

sub _gen_dhandler_code {
    return
      q{<%init>
	my $fs = Bric::Util::Trans::FS->new;
	my $comp_root = $m->interp->comp_root;
	my $dir       = $m->current_comp->dir_path;
	my $tmpl_name = $m->dhandler_arg;
	my $full_path = $fs->cat_dir($comp_root, $dir, $tmpl_name.'.mc');
	
	
	while (not -e $full_path) {
	    # Bail if we can't find the element.
	    unless ($dir) {
		my $payload = {'class'   => __PACKAGE__,
			       'action'  => 'load template',
			       'context' => {'oc'   => $burner->get_oc,
					     'cat'  => $burner->get_cat,
					     'elem' => $element}};
		
		my $msg = "Unable to find template '$tmpl_name'";
		die Bric::Util::Fault::Exception::AP->new({'msg'    =>$msg,
							 'payload'=>$payload});
	    }

	    # Chop off one directory.
	    $dir       = $fs->trunc_dir($dir);
	    $full_path = $fs->cat_dir($comp_root, $dir, $tmpl_name.'.mc');
	}
	
	$m->comp($fs->cat_dir($dir, $tmpl_name.'.mc'));
	</%init>
       };
}

1;

package Bric::Util::Burner::Mason::XMLWriterHandle;

sub new { bless {} }

sub print { $HTML::Mason::Commands::m->out(@_[1..$#_]) }

1;

__END__

=back

=head1 NOTES


=head1 AUTHOR

"Garth Webb" <garth@perijove.com>
Bricolage Engineering

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric>, L<Bric::Util::Burner>

=cut
