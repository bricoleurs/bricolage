package Bric::Util::Burner::TemplateToolkit;
###############################################################################

=head1 NAME

Bric::Util::Burner::TemplateToolkit - Bric::Util::Burner subclass to publish business assets using TemplateToolkit formatting assets.

=head1 VERSION

$Revision: 1.4 $

=cut

our $VERSION = (qw$Revision: 1.4 $ )[-1];

=head1 DATE

$Date: 2003-10-01 17:39:12 $

=head1 SYNOPSIS

 use Bric::Util::Burner::TemplateToolkit;

 # Create a new TemplateToolkit burner using the settings from $burner
 $tt_burner = Bric::Util::Burner::TemplateToolkit->new($burner);

 # Burn an asset, get back a list of resources
 @resources = $tt_burner->burn_one($ba, $at, $oc, $cat);

=head1 DESCRIPTION

This module handles burning business assets using TemplateToolkit formatting
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

use Template;
use Bric::Util::Fault::Exception::GEN;
use Bric::Util::Fault::Exception::AP;
use Bric::Util::Fault::Exception::MNI;
use Bric::Util::Trans::FS;
use Bric::Dist::Resource;
use Bric::Config qw(:burn);
use Template::Constants qw( :debug );

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

#--------------------------------------#
# Instance Fields

BEGIN {
    Bric::register_fields({
                         #- Per burn/deploy values.
                         'job'            => Bric::FIELD_READ,
                         'more_pages'     => Bric::FIELD_READ,

                         # Private Fields
                         '_tt'             => Bric::FIELD_NONE,
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

__PACKAGE__->_register_burner( Bric::Biz::AssetType::BURNER_TT,
                               category_fn    => 'wrapper',
                               cat_fn_has_ext => 1,
                               exts           =>
                                 { tt   => 'Template Toolkit (.tt)',
                                 }
                             );


#==============================================================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors

#------------------------------------------------------------------------------#

=item $obj = Bric::Util::Burner::TemplateToolkit->new($burner);

Creates a new TemplateToolkit burner object.  Takes a single parameters -
$burner - which is a Bric::Util::Burner object.  The new object will
has its attributes initialized by the passed object.

=cut

sub new {
    my ($class, $burner) = @_;
    my $init = { %$burner };

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
    my ($story, $oc, $cat, $at) = @_;

    my $element = $story->get_tile();

    my($ba);  #gone

    print STDERR __PACKAGE__, "::burn_one() called.\n"
	if DEBUG;

    my ($outbuf, $retval);

    # Determine the component roots.
    my $comp_dir = $self->get_comp_dir;

    my $comp_dir = $self->get_comp_dir;
    my $template_roots = [ map { $fs->cat_dir($comp_dir, "oc_" . $_->get_id) }
                           ($oc, $oc->get_includes) ];

    # Save an existing TemplateToolkit request object and Bricolage objects.
    my (%bric_objs);

    my @wrappers;

    {
	# search up category hierarchy for wrappers
	my @cats = map { $_->get_directory } $self->get_cat->ancestry;

	do {
	    # if the file exists, return it
	    foreach my $troot (@$template_roots) {
		my $path = $fs->cat_dir($troot, @cats, 'wrapper.tt');
		if(-e $path) {
		    push @wrappers, $path;
		    last;
		}
	    }
	} while(pop(@cats));
	@wrappers = reverse @wrappers;
    }

    my $tt = Template->new({
	#questionable layout things, but we got the time to sort it out
	PRE_CHOMP  => 1,
	POST_CHOMP => 1,
	TRIM       => 1,

	# now for the real stuff
	OUTPUT       => \$outbuf,
	INCLUDE_PATH => $template_roots,
	WRAPPER      => \@wrappers,
	EVAL_PERL    => 1,
	ABSOLUTE     => 1,
	VARIABLES    => {
	    burner  => $self,
	    story   => $story,
	    element => $element,
	},
    });


    my $template;
    {
	my @cats = map { $_->get_directory } $self->get_cat->ancestry;
	my $tmpl_name = _fmt_name($element->get_name) . '.tt';
        do {
	    # if the file exists, return it
#	    print STDERR "Trying: ", join('/',@cats),"\n";

	    foreach my $troot (@$template_roots) {
		my $path = $fs->cat_dir($troot, @cats, $tmpl_name);
#		print STDERR "\t$path\n";
		if(-e $path) {
		    $template = $path;
		    goto LABEL;
		}
	    }
	} while(pop(@cats));
      LABEL:
    }

    $self->_set([qw(_buf      page story   element   _comp_root       _tt)],
		[   \$outbuf, 0,   $story, $element, $template_roots, $tt]);

    $self->_push_element($element);

    while(1) {

        # XXX Throw an exception. Use throw_burn_error().
	$tt->process($template) || die $tt->error(), "; trying to burn '$template'\n";
	my $page = $self->_get('page') + 1;


	if($outbuf !~ /^\s*$/) {
	    my $file = $self->page_filepath($page);
	    my $uri  = $self->page_uri($page);

	    # Save the page we've created so far.
	    open(OUT, ">$file")
		|| die $gen->new({ msg => "Unable to open '$file' for writing",
				   payload => $! });
	    print OUT $outbuf;
	    close(OUT);
	    $outbuf = '';
	    # Add a resource to the job object.
	    $self->_add_resource($file, $uri);
	}
	$self->_set([qw(page)],[$page]);
	last unless $self->_get('more_pages');
    }
    $self->_pop_element;

    $self->_set(['_tt','_comp_root'],[undef,undef]);
    my $ret = $self->_get('_res') || return;
    $self->_set(['_res', 'page'], [[], 0]);
    return wantarray ? @$ret : $ret;

    # XXX DELETE FROM HERE TO THE END OF THE METHOD?
   # XXX Perhaps we should use and check for a subclass, instead?
    my $m = HTML::TemplateToolkit::Request->instance;
    if ($m and $m->out_method) {
        # If there's an out_method, assume that there's an existing burn
        # going on.
        no strict 'refs';
        for (qw(m story burner element writer)) {
            $bric_objs{$_} = ${TEMPLATE_BURN_PKG . "::$_"};
        }
    }

    # Create the interpreter
    my $interp = HTML::TemplateToolkit::Interp->new('allow_globals' => [qw($story
                                                                 $burner
                                                                 $writer
                                                                 $element)],
                                          'in_package'    => TEMPLATE_BURN_PKG,
                                          'data_dir'   => $self->get_data_dir,
                                          'out_method' => \$outbuf);



    my $element = $ba->get_tile;
    $self->_push_element($element);

    # Set some global variables to be passed in.
    $interp->set_global('$story',   $ba);
    $interp->set_global('$element', $element);
    $interp->set_global('$burner',  $self);

    # save some of the values for this burn.
#    $self->_set([qw(_buf     _interp  _comp_root)],
#                [  \$outbuf, $interp, $comp_root]);


    # Get the template name. Because this is a top-level Element, we don't want
    # to look far for its corresponding template.
    my $tmpl_path = $cat->ancestry_path;
    my $tmpl_name = _fmt_name($element->get_name);
    my $template = $fs->cat_uri($tmpl_path, $tmpl_name);
    if ( $interp->comp_exists($template . '.mc') ) {
        # The top-level .mc template exits.
        $template .= '.mc';
    } else {
        # If we're in here, there's no top-level .mc template. So create a
        # dhandler for it if there isn't one already.
#        _create_dhandler($comp_root, $oc, $cat, $tmpl_name)
#          unless $interp->comp_exists($fs->cat_uri($tmpl_path, 'dhandler'));
    }

    while (1) {
        # Run the biz asset through the template
        eval { $retval = $interp->exec($template) if $template };
        die ref $@ ? $@ :
          $ap->new({ msg     => "Error executing template '$template'.",
                     payload => $@ })
          if $@;

        # End the page if there is still content in the buffer.
        $self->end_page if $outbuf !~ /^\s*$/;

        # Keep burning this template if it contains more pages.
        last unless $self->_get('more_pages');
    }

    # Restore any existing Mason request object and Bricolage objects.
    if ($bric_objs{story}) {
        no strict 'refs';
        for (qw(m story burner element writer)) {
            ${TEMPLATE_BURN_PKG . "::$_"} = $bric_objs{$_};
        }
    }

    $self->_pop_element;

    # Return a list of the resources we just burned.
    my $ret = $self->_get('_res') || return;
    $self->_set(['_res', 'page'], [[], 0]);
    return wantarray ? @$ret : $ret;
}

################################################################################

=item my $bool = $burner->chk_syntax($ba, \$err)

Compiles the template found in $ba. If the compile succeeds with no
errors, chk_syntax() returns true. Otherwise, it returns false, and the error
will be in the $err variable passed by reference.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub chk_syntax {
    my ($self, $ba, $err_ref) = @_;
    # Just succeed if there is no template source code.
    my $data = $ba->get_data or return $self;
    #no way to do this yet
    return $self;
    die;
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
    my @cats = $fs->split_uri($uri);
    my $root = $self->_get('_comp_root');
    do {
	# if the file exists, return it
	foreach my $troot (@$root) {
	    my $path = $fs->cat_dir($troot, @cats, $name);
	    return $path if -e $path;
	}
    } while(pop(@cats));
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

    my ($next_page, $page_elem);
    my $tiles = $elem->get_tiles;
    foreach my $place ($page_place..$#$tiles) {
        my $e = $tiles->[$place];
        next unless $e->is_container;
        foreach my $name (@$names) {
            next unless $e->has_name($name);
            $page_elem ? $next_page = 1 : $page_elem = $e;
            next unless $next_page;
            last;
        }
    }

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
    my $buf = $self->_get('_buf');
    my $data = '';
    # Call another element if this is a container otherwise output the data.


    if ($elem->is_container) {
        my $tt = $self->_get('_tt');

        # Set the elem global to the current element.
        # Push this element on to the stack
        $self->_push_element($elem);

        my $template = $self->_load_template_element($elem);
	print STDERR "Including $template\n";
	$data .= $tt->context->include($template, {
	    'element' => $elem,
	});

        # Pop the element back off again.
        $self->_pop_element();

        # Set the elem global to the previous element

    } else {
	$data .= $elem->get_data();
    }
    return $data;
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
      || die $gen->new({ msg => "Unable to open '$file' for writing",
                         payload => $! });
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

=over 4

=item _fmt_name

Needs documenting.

=cut

sub _fmt_name {
    # Lowercase the name.
    my $name = lc $_[0];
    # Replace non-alphanumeric characters with underscores.
    $name =~ y/a-z0-9/_/cs;
    return $name;
}

#--------------------------------------#

=back

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
    my ($story, $ext) = $self->_get(qw(story ext));

    # Create a resource for the distribution stuff.
    my $res = Bric::Dist::Resource->lookup({ path => $file }) ||
      Bric::Dist::Resource->new({ path => $file,
                                  uri  => $uri });

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
    my $tmpl_name = _fmt_name($element->get_name) . '.tt';
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

=back

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

sub _create_dhandler {
    my ($comp_root, $oc, $cat, $tmpl_name) = @_;
    # The complete path on the file system sans the filename.
    my $path = $fs->cat_dir($comp_root->[0][1],
                            $fs->uri_to_dir($cat->ancestry_path));

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
