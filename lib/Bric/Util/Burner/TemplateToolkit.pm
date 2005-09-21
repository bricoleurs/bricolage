package Bric::Util::Burner::TemplateToolkit;
###############################################################################

=head1 NAME

Bric::Util::Burner::TemplateToolkit - Bric::Util::Burner subclass to publish business assets using TemplateToolkit formatting assets.

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

 use Bric::Util::Burner::TemplateToolkit;

  # Create a new TemplateToolkit burner using the settings from $burner
  my $tt_burner = Bric::Util::Burner::TemplateToolkit->new($burner);

  # Burn an asset, get back a list of resources
  my $resources = $tt_burner->burn_one($ba, $at, $oc, $cat);

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

use Template 2.14;
use Bric::Util::Fault qw(throw_gen throw_burn_error);
use Bric::Util::Trans::FS;
use Bric::Config qw(:burn :l10n);
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

    # create the object using Bric's constructor and return it
    return $class->Bric::new($init);
}

#--------------------------------------#

=back

=head2 Public Instance Methods

=over 4

=cut

#------------------------------------------------------------------------------#

=item $resources = $b->burn_one($ba, $at, $oc, $cat);

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

    my $element = $story->get_element();

    my($ba);  #gone
    my ($outbuf, $retval);

    # Determine the component roots.
    my $comp_dir = $self->get_comp_dir;
    my $template_roots;
    foreach my $inc ($oc, $oc->get_includes) {
        my $inc_dir = "oc_" . $inc->get_id;

        push @$template_roots, $fs->cat_dir($self->get_sandbox_dir, $inc_dir)
          if $self->get_sandbox_dir;

        push @$template_roots, $fs->cat_dir($comp_dir, $inc_dir);
    }

    my @wrappers;
    my @cats = map { $_->get_uri } $self->get_cat->ancestry;

    # Search up category hierarchy for wrappers.
    CATEGORY:
    for my $cat (@cats) {
        ROOT:
        for my $troot (@$template_roots) {
            my $path = $fs->cat_dir($troot, $cat, 'wrapper.tt');
            if (-e $path) {
                push @wrappers, $path;
                next CATEGORY;
            }
        }
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

    # Find the template.
    my $template;
    my $tmpl_name = $element->get_key_name . '.tt';
    CATEGORY:
    for my $cat (@cats) {
        ROOT:
        foreach my $troot (@$template_roots) {
            $template = $fs->cat_dir($troot, $cat, $tmpl_name);
            last CATEGORY if -e $template;
        }
    }

    $self->_set([qw(_buf      page story   element   _comp_root       _tt)],
                [   \$outbuf, 0,   $story, $element, $template_roots, $tt]);

    $self->_push_element($element);

    while(1) {
        use utf8;
        $tt->process($template, (
            ENCODE_OK
              ? (undef, undef, binmode => ':utf8')
              : ()
          )) or throw_burn_error
            error   => "Error executing '$template'",
            payload => $tt->error,
            mode    => $self->get_mode,
            oc      => $self->get_oc->get_name,
            cat     => $self->get_cat->get_uri,
            elem    => $element->get_name,
            element => $element;

        my $page = $self->_get('page') + 1;

        if ($outbuf !~ /^\s*$/) {
            my $file = $self->page_filepath($page);
            my $uri  = $self->page_uri($page);

            # Save the page we've created so far.
            open(OUT, ">$file")
              or throw_gen error   => "Unable to open '$file' for writing",
                           payload => $!;
            binmode(OUT, ':' . $self->get_encoding || 'utf8') if ENCODE_OK;
            print OUT $outbuf;
            close(OUT);
            $outbuf = '';
            # Add a resource to the job object.
            $self->add_resource($file, $uri);
        }
        $self->_set([qw(page)],[$page]);
        last unless $self->_get('more_pages');
    }
    $self->_pop_element;

    $self->_set([qw(_tt _comp_root page)] => [undef, undef, 0]);
    return $self->get_resources;
}

################################################################################

=item my $bool = $burner->chk_syntax($ba, \$err)

Compiles the template found in $ba. If the compile succeeds with no
errors, chk_syntax() returns true. Otherwise, it returns false, and the error
will be in the $err variable passed by reference.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> This method has not yet been implemented for Template Toolkit
templates. For the time being, it always returns success.

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
    } while ( pop @cats );
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
    my $elements = $elem->get_elements;
    foreach my $place ($page_place..$#$elements) {
        my $e = $elements->[$place];
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

=item $content = $b->display_element($element)

=item $content = $b->display_element($element, %ARGS)

A method to be called from template space. This method will find the template
associated with the element passed in and call include it in the Template
Toolkit execution. The return value is the content to be output. Pass in a
list of arguments to have them set up variables in the stash of the element's
execution context.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub display_element {
    my $self = shift;
    my $elem = shift or return '';
    return $elem->get_data unless $elem->is_container;

    my $data = '';
    my $tt = $self->_get('_tt');

    # Push this element on to the stack
    $self->_push_element($elem);

    my $template = $self->_load_template_element($elem);
    $data .= $tt->context->include($template, {
        'element' => $elem,
        @_
    });

    # Pop the element back off again.
    $self->_pop_element;
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

#==============================================================================#

=back

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

=over 4

=item $template = $b->_load_template_element($element);

Given an element (a business asset/data element) return the template element
that formats it.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _load_template_element {
    my ($self, $element) = @_;
    my ($oc, $cat) = $self->_get(qw(oc cat));

    # Get the path (based at comp_root) and the template name.
    my $tmpl_path = $cat->ancestry_path;
    my $tmpl_name = $element->get_key_name . '.tt';
    # Look up the template (it may live few directories above $tmpl_path)
    my $tmpl = $self->find_template($tmpl_path, $tmpl_name)
      or throw_burn_error error => "Unable to find template '$tmpl_name'",
                          mode  => $self->get_mode,
                          oc    => $self->get_oc->get_name,
                          cat   => $self->get_cat->get_uri,
                          elem  => $element->get_name,
                          element => $element;
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
    push @$at_stack, $element->get_element_type;

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

None.

=cut

1;

__END__

=head1 NOTES

NONE.

=head1 AUTHOR

Garth Webb L<gt>garth@perijove.comL<lt>

Sam Tregar L<gt>stregar@about-inc.comL<lt>

David Wheeler L<gt>david@wheeler.netL<lt>

=head1 SEE ALSO

L<Bric>, L<Bric::Util::Burner>

=cut
