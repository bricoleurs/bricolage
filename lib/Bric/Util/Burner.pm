package Bric::Util::Burner;
###############################################################################

=head1 NAME

Bric::Biz::Publisher - A class to manage publishing of business assets.


=head1 VERSION

$Revision: 1.2 $

=cut

our $VERSION = substr(q$Revision: 1.2 $, 10, -1);

=head1 DATE

$Date: 2001-10-03 19:25:19 $

=head1 SYNOPSIS

 use Bric::Util::Burner;

 # Create a new publish object.
 $burner = new Bric::Util::Burner($init);

 $burner = $burner->deploy($fa);

 # Burn a business asset given an output chanels.
 $burner = $burner->burn($ba, $oc);

=head1 DESCRIPTION

This modeule joins a formatting asset with a business asset to create a complete
and formatted asset.

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

#==============================================================================#
# Inheritance                          #
#======================================#
use base qw(Bric);

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

#--------------------------------------#
# Instance Fields

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
			 # Public Fields
                         'data_dir'       => Bric::FIELD_RDWR,
			 'comp_dir'       => Bric::FIELD_RDWR,
			 'out_dir'        => Bric::FIELD_RDWR,

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

=item $obj = new Bric::Util::Burner($init);

Creates a new burn object.  Keyw to $init are:

=over 4

=item *

data

The area where mason keeps all its data when compiling and executing elements

=item *

comp

The root path for the mason elements by this burn object.

=item *

out

The output directory for all the object burned.

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>


=cut

sub new {
    my $class = shift;
    my ($init) = @_;

    # Create the object via fields which returns a blessed object.
    my $self = bless {}, ref $class || $class;

    $init->{data_dir} ||= BURN_DATA_ROOT;
    $init->{comp_dir} ||= BURN_COMP_ROOT;
    $init->{out_dir}  ||= BURN_ROOT;
    $init->{page}     ||= 0;
    $init->{_res} = [];

    # Call the parent's constructor.
    $self->SUPER::new($init);

    # Return the object.
    return $self;
}

#------------------------------------------------------------------------------#

=item @objs = lookup Bric::Util::Burner($id);

Return a publish object for a given publish ID.

B<Throws:>

=over

=item *

Bric::Util::Burner::lookup() method not implemented.

=back

B<Side Effects:>

NONE

B<Notes:>


=cut

sub lookup {
    die $mni->new({msg => __PACKAGE__."::lookup() method not implemented."});
}

#------------------------------------------------------------------------------#

=item @objs = list Bric::Util::Burner(%criterion);

Returns a list of publish events based on %criterion.

B<Throws:>

=over

=item *

Bric::Util::Burner::list() method not implemented.

=back

B<Side Effects:>

NONE

B<Notes:>


=cut

sub list {
    die $mni->new({msg => __PACKAGE__."::list() method not implemented."});
}


#--------------------------------------#

=head2 Destructors

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=head2 Public Class Methods

=cut

#--------------------------------------#

=head2 Public Instance Methods

=cut

#------------------------------------------------------------------------------#

=item $success = $b->deploy($fa);

Deploys a template to the file system.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub deploy {
    my ($self, $fa) = @_;
    my $oc  = $fa->get_output_channel;
    my $cat = $fa->get_category;

    # Grab the file name and create it.
    my $comp_dir = $self->get_comp_dir;
    my $dir = $fs->cat_dir($comp_dir, $self->template_path($oc, $cat));
    my $file = $fs->cat_dir($comp_dir, ('oc_' . $oc->get_id), $fa->get_file_name);

    $fs->mk_path($dir);
    open (MC, ">$file")
      or die $ap->new({ msg => "Could not open '$file'", payload => $! });
    print MC $fa->get_data;
    close(MC);
}

#------------------------------------------------------------------------------#

=item $success = $b->undeploy($fa);

Deletes a template from the file system.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub undeploy {
    my ($self, $fa) = @_;
    my $oc  = $fa->get_output_channel;

    # Grab the file name.
    my $file = $fs->cat_dir($self->get_comp_dir, ('oc_' . $oc->get_id),
			    $fa->get_file_name);

    # Delete it from the file system.
    $fs->del($file) if -e $file;
}

#------------------------------------------------------------------------------#

=item $success = $b->burn($ba, $oc, $cat);

Publishes an asset.  Keys for $init are:

=over 4

=item *

ba

Names a business asset object to publish.

=item *

oc

Names an output channel object to use for the publish

=item *

cat

Names a category in which to publish.

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub burn_one {
    my $self = shift;
    my ($ba, $oc, $cat) = @_;
    my $at = Bric::Biz::AssetType->lookup({'id' => $ba->get_element__id});
    my ($outbuf, $retval);

    # Create a parser and allow some global variables.
    my $parser = new HTML::Mason::Parser('allow_globals' => [qw($story
								$burner
								$element)],
					 'in_package'    => __PACKAGE__);
    # Create the interpreter
    my $interp = new HTML::Mason::Interp('parser'     => $parser,
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
    $self->_set(['story', 'oc', 'cat', '_buf',   '_interp'],
		[$ba,     $oc,  $cat,  \$outbuf, $interp]);

    my $template = $self->load_template_element($element);

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

	my $template = $self->load_template_element($elem);

	# Display the element
	$Bric::Util::Burner::m->comp($template) if $template;

	# Pop the element back off again.
	$self->_pop_element();

	# Set the elem global to the previous element
	$interp->set_global('$element', $self->current_element);
    } else {
	$Bric::Util::Burner::m->out($elem->get_data);
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

sub chain_next { $Bric::Util::Burner::m->call_next }

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
    my $base       = $self->base_path;

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
    $Bric::Util::Burner::m->flush_buffer;

    # Save the page we've created so far.
    my $err_msg  = "Unable to open '$file' for writing";
    open(OUT, ">$file")
      or die Bric::Util::Fault::Exception::GEN->new({'msg'     => $err_msg,
						   'payload' => $@});
    print OUT $$buf;
    close(OUT);

    # Add a resource to the job object.
    $self->add_resource($file, $uri);

    # Clear the output buffer.
    $$buf = '';
    # Increment the page number
    $self->set_page(++$page);
}

#------------------------------------------------------------------------------#

=item $success = $b->add_resource();

Adds a Bric::Dist::Resource object to this burn.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_resource {
    my $self = shift;
    my ($file, $uri) = @_;
    my $ba  = $self->get_story;
    my $job = $self->get_job;

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

=item $template = $b->load_template_element($element);

Given an element (a business asset/data tile) return the template element 
that formats it.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub load_template_element {
    my $self = shift;
    my ($element) = @_;
    my ($oc, $cat) = $self->_get('oc', 'cat');

    # Get the path (based at comp_root) and the template name.
    my $tmpl_path = $self->template_path($oc, $cat);
    my $tmpl_name = _fmt_name($element->get_name);

    # Look up the template (it may live few directories above $tmpl_path)
    my $tmpl = $self->locate_template($tmpl_path, $tmpl_name);

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

=item ($base, $path) = $b->base_path

Returns the full path to the output directory.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub base_path {
    my $self = shift;
    my $oc   = $self->get_oc;

    my $base = $fs->cat_dir($self->get_out_dir, 'oc_' . $oc->get_id);

    return $base;
}

#------------------------------------------------------------------------------#

=item $path = $b->template_path

Returns the URI portion of the template path.  This is the path that is
considered 'absolute' with respect to the Mason element root.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub template_path {
    my ($self, $oc, $cat) = @_;

    $oc  ||= $self->get_oc;
    $cat ||= $self->get_cat;

    return $fs->cat_dir(('oc_' . $oc->get_id), $oc->get_pre_path,
			$cat->ancestry_path, $oc->get_post_path);
}

#------------------------------------------------------------------------------#

=item $template = $b->locate_template

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

sub locate_template {
    my ($self, $init_path, $tmpl_name) = @_;
    my $comp_dir  = $self->_get('comp_dir');
    my $dir       = $fs->cat_dir($comp_dir, $init_path);
    my $full_path = $fs->cat_dir($dir, $tmpl_name . '.mc');

    # Return the path right away if we have an exact match.
    return $fs->cat_dir($init_path, $tmpl_name.'.mc') if -e $full_path;

    # Get the current element and then its asset type.
    my $element = $self->current_element;
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

=item $elem = $b->current_element

Return the current element in this context.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub current_element {
    my $self = shift;
    my $elem_stack = $self->_get('_elem');

    return $elem_stack->[-1];
}

#------------------------------------------------------------------------------#

=item $elem = $b->current_element_type

Return the current element type in this context.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub current_element_type {
    my $self = shift;
    my $at_stack = $self->_get('_at');

    return $at_stack->[-1];
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
__END__

=back

=head1 NOTES


=head1 AUTHOR

"Garth Webb" <garth@perijove.com>
Bricolage Engineering

=head1 SEE ALSO

L<Perl>, L<Bric>

=head1 REVISION HISTORY

$Log: Burner.pm,v $
Revision 1.2  2001-10-03 19:25:19  samtregar
Merge from Release_1_0 to HEAD

Revision 1.1.1.1.2.1  2001/10/01 10:28:57  wheeler
Added support for custom file naming on a per-output channel basis. The filename
is specified in the Output Channel profile, and used during the burn phase to
name files on the file system. Configuration directives specifying default
values for the filename fields have also been added and documented in
Bric::Admin.

Revision 1.1.1.1  2001/09/06 21:54:57  wheeler
Upload to SourceForge.

=cut
