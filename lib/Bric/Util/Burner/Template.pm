package Bric::Util::Burner::Template;

###############################################################################

=head1 Name

Bric::Util::Burner::Template - Publish stories using HTML::Template templates

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::Burner::Template;

  # Create a new HTML::Template burner using the settings from $burner
  my $template_burner = Bric::Util::Burner::Template->new($burner);

  # burn an asset, get back a list of resources
  my $resources = $template_burner->burn_one($ba, $oc, $cat, $at);

=head1 Description

This module handles burning business assets using HTML::Template templates.

=cut

#======================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies                #
#--------------------------------------#

use strict;
# use warnings;

#--------------------------------------#
# Programatic Dependencies             #
#--------------------------------------#

use HTML::Template::Expr;
use Bric::Util::Trans::FS;
use Bric::Util::Fault qw(throw_gen throw_burn_error);
use Bric::Config qw(:burn :l10n);
use Digest::MD5 qw(md5 md5_hex);
use Time::HiRes qw(time);

#======================================#
# Inheritance                          #
#======================================#
use base qw(Bric::Util::Burner);


#--------------------------------------#
# Private Class Fields                 #
#--------------------------------------#

my $mni = 'Bric::Util::Fault::Exception::MNI';
my $ap  = 'Bric::Util::Fault::Exception::AP';
my $gen = 'Bric::Util::Fault::Exception::GEN';

my $fs = Bric::Util::Trans::FS->new();

my %SCRIPT_CACHE;

use constant PAGE_BREAK => "<<<<<<<<<<<<<<<<<< PAGE BREAK >>>>>>>>>>>>>>>>>>";
use constant DEBUG      => 0;

#--------------------------------------#
# Instance Fields                      #
#--------------------------------------#

BEGIN {
    Bric::register_fields({
                           # Private Fields
                           _template_roots  => Bric::FIELD_NONE,
                           _output_path     => Bric::FIELD_NONE,
                           _at              => Bric::FIELD_NONE,
                           _output          => Bric::FIELD_NONE,
                           _tmpl_file       => Bric::FIELD_NONE,
                          });
}

__PACKAGE__->_register_burner( Bric::Biz::OutputChannel::BURNER_TEMPLATE,
                               category_fn    => 'category',
                               cat_fn_has_ext => 1,
                               exts           =>
                                 { pl   => 'HTML::Template Script (.pl)',
                                   tmpl => 'HTML::Template Template (.tmpl)'
                                 }
                             );

#==============================================================================#

=head1 Interface

=head2 Constructors

=over 4

=item $obj = Bric::Util::Burner::Template->new($burner);

Creates a new Template burner object. Takes a single parameters - $burner which
is a Bric::Util::Burner object. The new object will have its attributes
initialized by the passed object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub new {
    my ($class, $burner) = @_;
    my $init = { %$burner };

    # create the object using Bric's constructor
    return $class->Bric::new($init);
}

=back

=head2 Public Instance Methods

=over 4

=item $resources = $template_burner->burn_one($ba, $oc, $cat, $at);

Burn an asset in a given output channel and category, this is usually called
by the preview or publish method. Returns a list of resources burned.

Parameters are:

=over 4

=item C<$ba>

A business asset object to burn.

=item C<$oc>

The output channel to which to burn the asset.

=item C<$cat>

A category in which to burn the asset.

=item C<$at>

A asset type object for $ba

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
    my ($story, $oc, $cat) = @_;

    print STDERR __PACKAGE__, "::burn_one() called.\n"
        if DEBUG;

    # compute template_roots for later
    my $comp_dir = $self->get_comp_dir;
    my $template_roots = [ map { $fs->cat_dir($comp_dir, "oc_" . $_->get_id) }
                           ($oc, $oc->get_includes) ];

    # add to the beginning of template_roots the sandbox paths if we are using a sandbox.
    if ( my $sandbox_dir = $self->get_sandbox_dir ) {
        unshift @$template_roots, map { $fs->cat_dir($sandbox_dir, "oc_" . $_->get_id) }
                           ($oc, $oc->get_includes);
    }

    my $at = $story->get_element_type;
    # save burn parameters
    $self->_set([qw(_at _template_roots)] => [$at, $template_roots]);

    # get the element for the story
    my $element = $story->get_element;

    # run the script for the element
    my $output = $self->run_script($element);

    # write the files
    $self->_write_pages(\$output, $element);

    # Return a list of the resources we just burned.
    return $self->get_resources
}

################################################################################

=item my $bool = $burner->chk_syntax($ba, \$err)

Compiles the template found in $ba. If the compile succeeds with no
errors, chk_syntax() returns true. Otherwise, it returns false, and the error
will be in the $err varible passed by reference.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub chk_syntax {
    my ($pkg, $ba, $err) = @_;
    my $data      = $ba->get_data;
    my $file_name = $ba->get_file_name;

    print STDERR __PACKAGE__, "::chk_syntax() called.\n"
        if DEBUG;

    # check a .tmpl template file
    if ($file_name =~ /.tmpl$/) {
        # includes are trouble for this check because it requires the
        # same "path" setting as burn_one() and that means calling
        # _get_template_path() which requires an oc and cat to run,
        # which aren't available in the chk_syntax context.
        $data =~ s/<[tT][mM][pP][lL]_[iI][nN][cC][lL][uU][dD][eE][^>]+>//g;

        eval {
            use utf8;
            HTML::Template::Expr->new(scalarref => \$data);
        };
        if ($@) {
            $$err = $@;
            $$err =~ s!/fake/path/for/non/file/template!$file_name!g;
            return 0;
        }
        return 1;
    }

    # check a .pl Perl script

    # construct the code block ala run_script
    my $time = md5_hex(time); # make sure package is unique
    my $code = <<END;
package Bric::Util::Burner::Template::SYNTAX$time;
use strict;
use utf8;
use vars ('\$burner', '\$element', '\$story');
sub _run_script {
#line 1 $file_name
$data
}
1;
END

    my $result = _compile($code);
    if (not $result and $@) {
        $$err = $@;
        return 0;
    }
    return 1;
}

=item $output = $burner->run_script($element, @args)

This method finds the script for the given element and executes it. The return
value is the output of the script.

If a script cannot be found for the element then one is autogenerated that looks
like:

  return $burner->new_template()->output;

This enables you to write template files that contain just the default template
autofill template tags and not have to create a script file to drive them.

An Apache::Registry-esque compilation is performed - the script source is
compiled as the body of a subroutine in a private package. After the first time
a script is compiled it is cached in memory and only re-compiled if changed.

B<Throws:>

=over 4

=item *

Bric::Util::Template::run_script() requires an $element argument.

=item *

Error compiling script ...

=item *

Error running script ...

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub run_script {
    my ($self, $element) = (shift, shift);
    throw_burn_error error =>  __PACKAGE__ . "::run_script() requires an " .
                              "\$element argument.",
                     mode  => $self->get_mode,
                     oc    => $self->get_oc->get_name,
                     cat   => $self->get_cat->get_uri
      unless $element;

    print STDERR __PACKAGE__, "::run_script() called.\n" if DEBUG;

    # find script element and run it.
    return $self->_runit($element, $self->_find_file($element, '.pl'));
}

=item $template = $burner->new_template(...)

This routine returns a new HTML::Template::Expr object. This method can take all
the same options as HTML::Template::Expr::new() (which is, in turn, mostly the
same as the options to HTML::Template::new()) with a few additions. The
additional options are:

=over 4

=item element

The element option tells the burner to find the template associated with that
object and open it. Defaults to the current global $element. To turn off this
option simply specify a template by name using the filename option.

=item autofill

The returned template object will have TMPL_VARs and TMPL_LOOPs set for the
element's attributes. You must specify the element option to use autofill. The
autofill option defaults to 1.

For details about the TMPL_VARs and TMPL_LOOPs that autofill creates see
L<Bric::HTMLTemplate>.

=back

Additionally, some of the defaults for HTML::Template::new() are different:

=over 4

=item global_vars

Defaults to on for the benefit of the autofill code and general sanity.

=item loop_context_vars

Defaults to on since you'll definitely want 'em.

=item cache

Defaults to off.  Don't turn it on unless you know what you're doing -
there are some potential problems with <tmpl_include> and Bricolage.

=back

A common usage of this method within a script file is:

  my $template = $burner->new_template();

Which is the equivalent of:

  my $template = $burner->new_template(element  => $element,
                                       autofill => 1);

See L<Bric::HTMLTemplate> for more examples and discussion.

B<Throws:>

new_template called with odd number of arguments.

Unable to find HTML::Template template file.

B<Side Effects:>

NONE

B<Notes:>

NONE


=cut

sub new_template {
    my $self = shift;

    print STDERR __PACKAGE__, "::new_template() called.\n"
        if DEBUG;

    # load args
    throw_burn_error error =>  "new_template called with odd number of"
                               . " arguments",
                     mode  => $self->get_mode,
                     oc    => $self->get_oc->get_name,
                     cat   => $self->get_cat->get_uri,
      if (@_ % 2);
    my %args = @_;

    # pull out params and delete from args
    my $element;
    if (exists $args{element}){
        $element = $args{element};
    } elsif (not exists $args{filename}) {
        # get the element from the current global setting
        no strict 'refs';
        $element = ${(caller)[0] . "::element"};
    }

    # need to setup path for includes
    $args{search_path_on_include} = 1;
    $args{path} ||= [];
    push(@{$args{path}}, $self->_get_template_path());
    print STDERR __PACKAGE__, "::new_template() : set path to ",
      join(', ', @{$args{path}}), "\n"
        if DEBUG;

    # autofil defaults on
    my $autofill = exists $args{autofill} ? $args{autofill} : 1;

    # delete custom args
    delete $args{element};
    delete $args{autofill};

    if ($element and not $args{filename} ||= $self->_get('_tmpl_file')) {
        # find element template file
        my $file = $self->_find_file($element, '.tmpl');
        throw_burn_error error => "Unable to find HTML::Template template"
                                  . " file '" . _element_filename($element)
                                  . ".tmpl)",
                         mode  => $self->get_mode,
                         oc    => $self->get_oc->get_name,
                         cat   => $self->get_cat->get_uri,
                         elem  => $element->get_name,
                         element => $element
          unless defined $file;

        print STDERR __PACKAGE__, "::new_template() : found template file ",
          "$file for element $element.\n"
            if DEBUG;

        # set filename arg
        $args{filename} = $file;
    }

    # autofill requires die_on_bad_params off for now
    $args{die_on_bad_params} = 0 if $autofill;

    # setup defaults
    $args{global_vars} = 1       unless exists $args{global_vars};
    $args{loop_context_vars} = 1 unless exists $args{loop_context_vars};
    $args{cache} = 0             unless exists $args{cache};

    # setup some useful functions
    #$args{functions}{call} => sub { $self->run_script($_[0]) };
    $args{functions}{get_page} = sub { $self->get_page(@_); };
    $args{functions}{page_link} = sub { $self->page_file(@_); };
    $args{functions}{next_page_link} = sub { $self->page_file($_[0] + 1); };
    $args{functions}{prev_page_link} = sub { $self->page_file($_[0] - 1); };

    # instantiate the template object
    my $template = do {
        use utf8;
        HTML::Template::Expr->new(%args);
    };

    # Add any existing content.
    if (my $content = $self->_get('_output')) {
        $template->param(content => $$content)
    }

    # autofill with element data
    if ($autofill and $element) {
        my $story = $self->get_story();
        # fill in some non-element data
        my $meths = $story->my_meths;
        while (my ($k, $v) = each %$meths) {
            next unless $template->query(name => $k);
            my $get = $v->{get_meth};
            $template->param($k => $get->($story));
        }
        $template->param(page_break => PAGE_BREAK)
          if $template->query(name => "page_break");

        if ($element ne 'category') {
            # setup data for template
            my $data = $self->_build_element_vars($element, $template, []);
            $template->param($data);
        }
    }
    return $template;
}

=item $burner->page_break()

This routine breaks pages in the output. It returns a page boundary marker to
insert in into the text.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub page_break {
    return PAGE_BREAK;
}

=back

=head2 Private Instance Methods

=over 4

=item $data = $self->_build_element_vars($element, $template, \@path);

This method builds all the TMPL_VARs and TMPL_LOOPs that can be extracted from
$element. Returns a hash-ref suitable for passing to $template->param().

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _build_element_vars {
    my ($self, $element, $template, $path) = @_;

    # FIX: this method could be made more efficient by actually using
    # the %exists data more often than just to prevent useless recursion.

    # get list of names in this scope
    my %exists;
    if (@$path) {
        %exists = map { $_ => 1 } grep { defined }
          $template->query(loop => [ @$path ]);
    } else {
        %exists = map { $_ => 1 } $template->param();
    }

    # get list of names in element_loop scope
    my %element_loop_exists;
    if (@$path) {
        %element_loop_exists = map { $_ => 1 }
          grep { defined } $template->query(loop => [ @$path, 'element_loop' ]);
    } elsif ($template->param('element_loop')) {
        %element_loop_exists = map { $_ => 1 } $template->param('element_loop');
    }

    # counter and loop hashes
    my %count;
    my %loop = ( element_loop => [] );
    my %var;

    # Get related story URI. Keep "link" for backwards compatability.
    if (my $thing = $element->get_related_story) {
        $var{link} = $var{rel_story_uri} = $thing->get_primary_uri;
    }

    # Get related media URI. Backwards-compatable "link" overrides story.
    if (my $thing = $element->get_related_media) {
        $var{link} = $var{rel_media_uri} = $thing->get_uri;
    }

    # loop over elements
    foreach my $e ($element->get_elements()) {
        # get a proper name
        my $name = lc $e->get_key_name;

        print STDERR __PACKAGE__ . "::_build_element_vars : saw $name (",
          join(', ', @$path), ")\n" if DEBUG;

        # incr count
        $count{$name}++;

        # simple data elements
        unless ($e->is_container) {
            $var{$name} = $e->get_value();
            $loop{"$name\_loop"} = [] unless exists $loop{"$name\_loop"};

            # push a row for this value
            push @{$loop{"$name\_loop"}}, { $name => $var{$name},
                                            "$name\_count" => $count{$name},
                                            "is_$name" => 1,
                                          };

            # push on the element_loop
            push @{$loop{element_loop}}, { $name => $var{$name},
                                           "$name\_count" => $count{$name},
                                           "is_$name" => 1,
                                         };
        } else {
            # container elements
            $loop{"$name\_loop"} = [] unless exists $loop{"$name\_loop"};

            # recurse into element if we have a matching var
            if($exists{$name}) {
                $var{$name} = $self->run_script($e);

                # push on the element_loop
                push @{$loop{element_loop}}, { $name => $var{$name},
                                               "$name\_count" => $count{$name},
                                               "is_$name" => 1,
                                             };

                # push on the name_loop
                push @{$loop{"$name\_loop"}}, { $name => $var{$name},
                                                "$name\_count" => $count{$name},
                                                "is_$name" => 1,
                                              };
            } elsif ($element_loop_exists{$name}) {
                # or if it just has an element loop entry
                push @{$loop{element_loop}}, { $name => $self->run_script($e),
                                               "$name\_count" => $count{$name},
                                               "is_$name" => 1,
                                             };

            } else {
                # recurse into _build_element_loop if we've got a matching loop
                push @{$loop{"$name\_loop"}},
                  { %{$self->_build_element_vars($e,
                                                 $template,
                                                 [ @$path,
                                                   "$name\_loop"
                                                 ])},
                    "$name\_count" => $count{$name},
                    "is_$name" => 1,
                  };
            }
        }
    }

    foreach my $name (keys %count) {
        # setup totals
        $var{"$name\_total"} = $count{$name};
    }
    return { %loop, %var };
}

=item $filename = $self->_find_file($element, $extension);

Finds a file for this element and extension (.pl or .tmpl) in the current oc and
cat. Searches up the category tree as necessary. Returns undef if the file
cannot be found.

As a special-case if $element eq "category" then the category script or template
is searched for.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _find_file {
    my ($self, $element, $extension) = @_;
    my $template_roots = $self->_get('_template_roots');

    my $filename = _element_filename($element) . $extension;

    print STDERR __PACKAGE__, "::_find_file(", $element->get_key_name,
      ", $extension)\n" if DEBUG and ref $element;

    # search up category hierarchy
    my @cats = map { $_->get_directory } $self->get_cat->ancestry;
    do {
        # if the file exists, return it
        foreach my $troot (@$template_roots) {
            my $path = $fs->cat_dir($troot, @cats, $filename);
            return $path if -e $path;
        }
    } while (pop @cats);

    # returns undef if we didn't find anything
    return undef;
}

=item @path = $self->_get_template_path()

Returns the HTML::Template path setting that will search up the category tree
for templates starting from the category returned by get_cat.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_template_path {
    my $self = shift;
    my $template_roots = $self->_get('_template_roots');

    print STDERR __PACKAGE__, "::_get_template_path()\n" if DEBUG;

    # search up category hierarchy
    my @cats = map { $_->get_directory } $self->get_cat->ancestry;
    my @path;
    do {
        foreach my $troot (@$template_roots) {
            push @path, $fs->cat_dir($troot, @cats);
        }
    } while(pop @cats);

    # return path setting
    return @path;
}


=item $self->_write_pages(\$output, $element)

Splits the pages in $$output in to their separate parts, executes any category
templates for each, and writes them to the appropriate output files on disk.
Also takes care of adding resources for the files written.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _write_pages {
    my ($self, $output, $element) = @_;

    print STDERR __PACKAGE__, "::_write_pages() called.\n"
        if DEBUG;

    my @cat_tmpls = $self->_find_category_scripts;

    my @pages = split /${\PAGE_BREAK}/, $$output;
    for (my $page = 0; $page < @pages; $page++) {
        # skip empty last page
        last if $page == $#pages and $pages[$page] =~ /^\s*$/;

        # compute filename
        my $filename = $self->page_filepath($page + 1);

        print STDERR __PACKAGE__, "::_write_pages() : opening page $filename\n"
          if DEBUG;

        # Execute any category templates.
        for my $catspec (@cat_tmpls) {
            $self->_set(['_output'] => [\$pages[$page]]);
            if ($catspec->[1] eq 'pl') {
                $self->_set(['_tmpl_file'] => ["$catspec->[0].tmpl"]);
                $pages[$page] = $self->_runit($element, "$catspec->[0].pl");
            } else {
                my $tmpl = $self->new_template(
                    element  => $element,
                    filename => "$catspec->[0].tmpl",
                );
                $pages[$page] = $tmpl->output;
            }
        }
        $self->_set([qw(_output _tmpl_file)] => [undef, undef]);

        # open new file and write to it
        open(OUT, ">$filename")
          or throw_gen error   => "Unable to open $filename",
                       payload => $!;
        binmode(OUT, ':' . $self->get_encoding || 'utf8') if ENCODE_OK;
        print OUT $pages[$page];
        close(OUT);

        # add resource object for this file
        my $uri = $self->page_uri($page + 1);
        $self->add_resource($filename, $uri);
    }
}

##############################################################################

=item $output = $self->_runit($element, $script)

Called by C<run_script()> and, for category templates, by C<_write_pages()>,
this method executes the script (with the full path to the F<.pl> script
defined in $script and returns the result. If $script is undefined,
C<_runit()> simply calls C<new_template()> and returns the output of the
template.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _runit {
    my ($self, $element, $script) = @_;
    my ($story) = $self->get_story;
    my $template_root = $fs->cat_dir(
        $self->get_comp_dir, 'oc_' . $self->get_oc->get_id
    );

    # Set the element attribute.
    $self->_set(['element'], [$element]);

    # no script, perform default script action directly
    if (not defined $script) {
        return $self->new_template(element => $element)->output();
    }

    print STDERR __PACKAGE__, "::run_script() : found script file : $script.\n"
      if DEBUG;

    # escape everything into valid perl identifiers
    my $package = $script;
    $package =~ s/([^A-Za-z0-9_\/])/sprintf("_%2x",unpack("C",$1))/eg;

    # second pass for slashes and words starting with a digit
    $package =~ s{
                  (/+)       # directory
                  (\d?)      # package's first character
              }[
                "::" . (length $2 ? sprintf("_%2x",unpack("C",$2)) : "")
               ]egx;

    # prepend our root package
    $package = "Bric::Util::Burner::Template::SANDBOX$package";

    # read script contents into $sub
    my $sub = "";
    print STDERR __PACKAGE__, "::run_script() : reading $script.\n"
      if DEBUG;
    open(SCRIPT, $script)
      or throw_burn_error error =>  "Unable to read $script : $!",
                          mode  => $self->get_mode,
                          oc    => $self->get_oc->get_name,
                          cat   => $self->get_cat->get_uri,
                          elem  => ref $element ? $element->get_name : $element,
                          (ref($element) ? (element => $element) : ());
    binmode(SCRIPT, ':utf8') if ENCODE_OK;
    while(read(SCRIPT, $sub, 102400, length($sub))) {};
    close(SCRIPT);

    # compute md5 for script - used in caching system
    my $md5 = md5($sub);

    # check if script is cached and unchanged
    if (exists $SCRIPT_CACHE{$package} and $SCRIPT_CACHE{$package} eq $md5) {
        # compiled code is still good - nothing to do
        print STDERR __PACKAGE__,
        "::run_script() : skipping compilation - cached copy still good.\n"
          if DEBUG;
    } else {
        print STDERR __PACKAGE__, "::run_script() : compiling...\n"
          if DEBUG;

        # determine filename for #line directive
        my $line_file = substr($script, length($template_root));

        # construct the code
        my $code = <<END;
package $package;
use strict;
use utf8;
use vars ('\$burner', '\$element', '\$story');
sub _run_script {
#line 1 $line_file
$sub
}
1;
END
        # compile the code
        undef &{"$package\::_run_script"}; #avoid warnings
        my $result = _compile($code);
        unless ($result) {
            throw_burn_error error   =>  "Error compiling script.",
                             payload => $@,
                             mode    => $self->get_mode,
                             oc      => $self->get_oc->get_name,
                             cat     => $self->get_cat->get_uri,
                             elem    => $element->get_name,
                             element => $element
              if $@;
        }

        # remember the md5
        $SCRIPT_CACHE{$package} = $md5;
    }

    # setup globals for the script
    {
        no strict 'refs';
        ${"$package\::burner"}  = $self;
        ${"$package\::story"}   = $story;
        ${"$package\::element"} = $element;
    }

    # call the script
    my $cv = \&{"$package\::_run_script"};
    my $output;
    eval { $output = $cv->(@_) };

    throw_burn_error error   =>  "Error running script.",
                     payload => $@,
                     mode    => $self->get_mode,
                     oc      => $self->get_oc->get_name,
                     cat     => $self->get_cat->get_uri,
                     elem    => ref $element ? $element->get_name : $element,
                     (ref($element) ? (element => $element) : ())
      if $@;
    return $output;
}

##############################################################################

=item @category_template_paths = $self->_find_category_scripts

This method is called by C<_write_pages()> fo find all of the category
templates that need executing. The templates are returned as a list of array
refereneces. Each array reference contains two items: The full path to the
script without the file type extension and a string indicating the template
type, either "pl" or "tmpl". The order of the list is defined by the order of
execution. For example, if a story was being published in the
F</reviews/books> category, and the category templates F</category.pl> and
F</reviews/category.tmpl> exist, then the return value will be

  (
    ['/reviews/category', 'tmpl'],
    ['/category', 'pl'],
  )

The upshot being that F</reviews/category.tmpl> should be executed first (by
calling C<new_template()>) and that F</category.pl> should be executed second
(by calling C<run_script()>).

=cut

sub _find_category_scripts {
    my $self = shift;

    # Search up category hierarchy for category templates.
    my $template_roots = $self->_get('_template_roots');
    my @cats =  map { $_->get_uri } $self->get_cat->ancestry;
    my @cat_tmpls;

    CATEGORY:
    for my $cat (@cats) {
        ROOT:
        for my $troot (@$template_roots) {
            my $path = $fs->cat_dir($troot, $cat, 'category');
            if (-e "$path.pl") {
                unshift @cat_tmpls, [$path, 'pl'];
                next CATEGORY;
            }
            next ROOT unless -e "$path.tmpl";
            unshift @cat_tmpls, [$path, "tmpl"];
        }
    }

    return @cat_tmpls;
}


#--------------------------------------#

=back

=head2 Private Class Methods

=over 4

=item $filename = _element_filename($element)

Translates the element name into a filename replacing non-alphanumeric
characters with underscores.  Not garaunteed to be unique, but assumed
to be close enough...

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _element_filename {
    my $element = shift;

    # handle fake category element
    return "category" if $element eq 'category';

    # otherwise get the name from the element object
    return $element->get_key_name;
}

=item _compile($code)

Evals $code in a clean lexical context.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _compile {
    return eval($_[0]);
}

=back

=cut

1;
__END__

=head1 Notes

Bric::Util::Burner::Template does not support the PERL_LOADER or
XML_WRITER options described in L<Bric::Admin>.

=head1 Author

Sam Tregar L<gt>stregar@about-inc.comL<lt>

=head1 See Also

L<Bric::Util::Burner>

=cut
