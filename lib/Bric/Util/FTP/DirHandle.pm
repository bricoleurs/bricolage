package Bric::Util::FTP::DirHandle;

=pod

=head1 NAME

Bric::Util::FTP::DirHandle - Virtual FTP Server DirHandle

=head1 VERSION

$Revision $

=cut

our $VERSION = (qw$Revision: 1.14 $ )[-1];

=pod

=head1 DATE

$Date: 2003-10-01 16:50:58 $

=head1 DESCRIPTION

This module provides a directory handle object for use by
Bric::Util::FTP::Server.

=head1 INTERFACE

This module inherits from Net::FTPServer::DirHandle and overrides the
required methods.  This class is used internally by Bric::Util::FTP::Server.

=head2 Constructors

=over 4

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);
use Bric::Biz::Category;
use Bric::Biz::OutputChannel;
use Bric::Biz::Workflow qw(TEMPLATE_WORKFLOW);
use Bric::Biz::Asset::Formatting;
use Bric::Config qw(:ftp);
use Bric::Biz::AssetType;
use Carp qw(confess croak);
use Net::FTPServer::DirHandle;
use Bric::Util::FTP::FileHandle;
use Bric::Util::Priv::Parts::Const qw(:all);
use File::Basename qw(fileparse);

################################################################################
# Inheritance
################################################################################
our @ISA = qw(Net::FTPServer::DirHandle);


=item new($ftps, [$pathname, $oc_id, $category_id])

Creates a new Bric::Util::FTP::DirHandle object.  Requires a
Bric::Util::FTP::Server object as its first paramater.  Optionally
takes a pathname, an oc_id and a category_id.  If not supplied the
pathname defaults to "/" and the corresponding oc_id and catgeory_id
is looked up from the database.

=cut

sub new {
  my $class       = shift;
  my $ftps        = shift;       # FTP server object.
  my $pathname    = shift || "/";
  my $oc_id       = shift;
  my $category_id = shift;

  # Create object.
  my $self = Net::FTPServer::DirHandle->new($ftps, $pathname);
  bless $self, $class;

  # get output channel and cagetory_id from args, default to dummy value
  $self->{oc_id}       = defined $oc_id       ? $oc_id       : -1;
  $self->{category_id} = defined $category_id ? $category_id : -1;

  print STDERR __PACKAGE__, "::new() : $self->{oc_id} : $self->{category_id}\n"
    if FTP_DEBUG;

  return $self;
}

=back

=head2 Public Instance Methods

=over 4

=item get($filename)

The get() method is used to do a lookup on a specific filename.  If a
template called $filename exists in this category then get() will call
Bric::Util::FTP::FileHandle->new() and return the object.  If a
category exists underneath this category called $filename then new()
will be called and the directory handle will be returned.  Failing
that, undef is returned.

=cut

sub get {
  my $self        = shift;
  my $filename    = shift;
  my $oc_id       = $self->{oc_id};
  my $category_id = $self->{category_id};

  print STDERR __PACKAGE__, "::get() : $filename\n" if FTP_DEBUG;

  # look for a template by that name
  my $list = Bric::Biz::Asset::Formatting->list(
               {
                output_channel__id => $oc_id,
                category_id       => $category_id,
                file_name          => "%/$filename",
               });

  if ($list and @$list) {
    # warn on multiple templates
    warn("Multiple template files called $filename in category $self->{category_id}!")
      if @$list > 1;

    # found at least one template
    my $template = $list->[0];
    return new Bric::Util::FTP::FileHandle ($self->{ftps},
                                            $template,
                                            $oc_id,
                                            $category_id,
                                           )
      # Allow access only to template if the user has READ access to it.
      if $self->{ftps}{user_obj}->can_do($template, READ);
  }

  # search for an output channel if we don't have one
  if ($oc_id == -1) {
      my ($id) = Bric::Biz::OutputChannel->list_ids({ name => $filename });
      if ($id) {
          return Bric::Util::FTP::DirHandle->new($self->{ftps},
                                                 "/" . $filename . "/",
                                                 $id,
                                                 0,
                                                );
      }
  }

  # search for a subcategories
  ##########################################################################
  # HACK! _get_cats() does a direct query of the database! Naughty, naughty!
  # There is currently no way to check permissions on categories now.
  ##########################################################################
  my $cats = _get_cats();
  foreach my $child_id (@{$cats->{children}{$category_id}}) {
    if ($cats->{$child_id}{directory} eq $filename) {
      return Bric::Util::FTP::DirHandle->new($self->{ftps},
                                             $self->pathname . $filename . "/",
                                             $oc_id,
                                             $child_id,
                                            );
    }
  }

  # nothing found.
  return undef;
}

=item open($filename, $mode)

This method is called to open a file in the current directory.  Right
now this is equivalent to get($filename)->open($mode) since it doesn't
support creating new files.  The possible modes are 'r', 'w' and 'a'.
The method returns a Bric::Util::FTP::FileHandle or undef on failure.

=cut

sub open {
  my $self        = shift;
  my $filename    = shift;
  my $mode        = shift;
  my $oc_id       = $self->{oc_id};
  my $category_id = $self->{category_id};

  print STDERR __PACKAGE__, "::open($filename, $mode)\n" if FTP_DEBUG;

  if ($oc_id == -1) {
      print STDERR __PACKAGE__, "::open() called without oc_id!\n"
          if FTP_DEBUG;
      return undef;
  }

  if ($category_id == -1) {
      print STDERR __PACKAGE__, "::open() called without category_id!\n"
          if FTP_DEBUG;
      return undef;
  }

  # find filename
  my $list = Bric::Biz::Asset::Formatting->list
    ({ output_channel__id => $oc_id,
       category_id       => $category_id,
       file_name          => "%/$filename"
     });

  if ($list) {
    # warn on multiple templates
    warn("Multiple template files called $filename in category $category_id!")
      if @$list > 1;

    # file exists, return it
    my $template = $list->[0];
    # Allow access only to template if the user has READ access to it.
    return Bric::Util::FTP::FileHandle->new($self->{ftps},
                                            $template,
                                            $oc_id,
                                            $category_id
                                           )->open($mode)
      if $self->{ftps}{user_obj}->can_do($template, READ);
  }

  print STDERR __PACKAGE__, "::open($filename, $mode) : creating new template\n";

  # create a new template
  my ($name, $dir, $file_type) = fileparse($filename, qr/\..*$/);
  # Remove the dot.
  $file_type =~ s/^\.//;

  # don't look for an asset for generic templates
  my $at;
  unless ( Bric::Util::Burner->class_for_cat_fn($name)) {
      # It's not a category template. Look for an element to associate it with.
      $at = Bric::Biz::AssetType->lookup({ key_name => $name });

      # If we didn't find an element then Formatting.pm will assume it's a
      # utility template.
      if (FTP_DEBUG) {
          if ($at) {
              print STDERR __PACKAGE__, "::open($filename, $mode) : matched",
                " asset type : ", $at->get_name, "\n";
          } else {
              print STDERR __PACKAGE__, "::open($filename, $mode) : failed",
                " to find matching asset type\n";
          }
      }
  }

  print STDERR __PACKAGE__, "::open($filename, $mode) : creating : ",
    $self->pathname, $filename, "\n" if FTP_DEBUG;

  ## create the new template object
  my $template = Bric::Biz::Asset::Formatting->new
    ({ 'element'            => $at,
       'file_type'          => $file_type,
       'output_channel__id' => $oc_id,
       'category_id'        => $category_id,
       'priority'           => 3,
       'name'               => ($at ? lc $at->get_key_name : undef),
       'user__id'           => $self->{ftps}{user_obj}->get_id,
     });

  # find a template workflow.  Might be nice if
  # Bric::Biz::Workflow->list too a type key...
  foreach my $workflow (Bric::Biz::Workflow->list()) {
      if ($workflow->get_type == TEMPLATE_WORKFLOW) {
          $template->set_workflow_id($workflow->get_id());
          $template->checkin();
          last;
      }
  }

  # send to the database
  $template->activate();
  $template->save();

  # now pass off to FileHandle
  return Bric::Util::FTP::FileHandle->new($self->{ftps},
                                          $template,
                                          $oc_id,
                                          $category_id,
                                         )->open($mode);
}

=item list($wildcard)

The list() method is called to do a wildcard search inside a
directory.  The method performs a search for categories and templates
matching the specified wildcard.  The return value is a reference to
an array of two-element arrays - the first element is the name and the
second is the corresponding FileHandle or DirHandle object.  The
results are sorted by names before being returned.  If nothing matches
the wildcard then a reference to an empty array is returned.

=cut

sub list {
  my $self        = shift;
  my $wildcard    = shift;
  my $oc_id       = $self->{oc_id};
  my $category_id = $self->{category_id};
  my $cats        = _get_cats();
  my $ftps        = $self->{ftps};

  print STDERR __PACKAGE__, "::list() : ", $wildcard || "", "\n" if FTP_DEBUG;

  my @results;

  # translate wildcard to like
  my $like;
  if ($wildcard and $wildcard ne '*') {
    $like = $ftps->wildcard_to_sql_like($wildcard);
  }

  # if no oc, just search ocs
  if ($oc_id == -1) {
      # get output channels
      my @ocs  = Bric::Biz::OutputChannel->list({name => ($like || '%')});
      foreach my $oc (@ocs) {
          ##############################################################
          # XXX Should probably exclude certain output channels here according
          # to permissions -- same with comp/tmpl_prof/edit_new.html!
          # next unless $self->{ftps}{user_obj}->can_do($oc, READ);
          ##############################################################
          my $dirh = Bric::Util::FTP::DirHandle->new($self->{ftps},
                                                     "/" . $oc->get_name . "/",
                                                     $oc->get_id(),
                                                     0);
          push @results, [ $oc->get_name, $dirh ];
      }
      @results = sort { $a->[0] cmp $b->[0] } @results;
      return \@results;
  }

  # get subdirectories.
  if ($like) {
      my $results = Bric::Biz::Category->list({ directory => $like,
                                                parent_id => $category_id });
      # create dirhandles
      foreach my $cat (@$results) {
          # Allow access only to categories the user has READ access to.
          next unless $self->{ftps}{user_obj}->can_do($cat, READ);
          my $dirh = new Bric::Util::FTP::DirHandle ($self->{ftps},
                                                     $self->pathname . 
                                                     $cat->get_directory,
                                                     $oc_id,
                                                     $cat->get_id);

          push @results, [ $cat->get_directory, $dirh ];
      }
  } else {
      if ($cats->{children}{$category_id}) {
          foreach my $child_id (@{$cats->{children}{$category_id}}) {
              my $dirh = new Bric::Util::FTP::DirHandle ($self->{ftps},
                                                         $self->pathname . $cats->{$child_id}{directory} . "/",
                                                         $oc_id,
                                                         $child_id);
              push(@results, [ $cats->{$child_id}{directory}, $dirh ]);
          }
      }
  }

  # get templates
  my $list;
  if ($like) {
      $list = Bric::Biz::Asset::Formatting->list(
       {
        output_channel__id => $oc_id,
        category_id       => $category_id,
        file_name         => "%/" . ($like || '%')
       });
  } else {
      $list = Bric::Biz::Asset::Formatting->list(
        {
         output_channel__id => $oc_id,
         category_id       => $category_id,
        });
  }

  # create filehandles
  if ($list) {
    foreach my $template (@$list) {
        next unless $self->{ftps}{user_obj}->can_do($template, READ);
        my $fileh = new Bric::Util::FTP::FileHandle ($self->{ftps},
                                                     $template,
                                                     $oc_id,
                                                     $self->{category_id});
        my $filename = $template->get_file_name;
        $filename = substr($filename, rindex($filename, '/') + 1);
        push @results, [ $filename, $fileh ];
    }
  }

  @results = sort { $a->[0] cmp $b->[0] } @results;

  return \@results;
}

=item list_status($wildcard)

This method performs the same as list() but also adds a third element
to each returned array - the results of calling the status() method on
the object.  See the status() method below for details.

=cut

sub list_status { 
  my $self = shift;
  my $wildcard = shift;

  my $list = $self->list($wildcard);
  foreach my $row (@$list) {
    $row->[3] = [ $row->[1]->status ];
  }

  return $list;
}

=item parent()

Returns the Bric::FTP::DirHandle object for the parent of this
directory.  For the root directory it returns itself.

=cut

sub parent {
  my $self = shift;
  my $category_id = $self->{category_id};
  my $cats = _get_cats();

  print STDERR __PACKAGE__, "::parent() : ", $category_id, "\n" if FTP_DEBUG;

  return $self if $self->is_root;

  # get a new directory handle and change category_id to parent's
  my $dirh = $self->SUPER::parent;
  $dirh->{category_id} = $cats->{$category_id}{parent_id} || -1;

  # magic to get the right oc_id
  if ($self->{category_id} == 0) {
      $dirh->{oc_id} = -1;
  } else {
      $dirh->{category_id} = $self->{oc_id};
  }

  return bless $dirh, ref $self;
}

=item status()

This method returns information about the object.  The return value is
a list with seven elements - ($mode, $perms, $nlink, $user, $group,
$size, $time).  To quote the good book (Net::FTPServer::Handle):

          $mode     Mode        'd' = directory,
                                'f' = file,
                                and others as with
                                the find(1) -type option.
          $perms    Permissions Permissions in normal octal numeric format.
          $nlink    Link count
          $user     Username    In printable format.
          $group    Group name  In printable format.
          $size     Size        File size in bytes.
          $time     Time        Time (usually mtime) in Unix time_t format.

In this case all of these values are fixed for all categories: ( 'd',
0777, 1, "nobody", "", 0, 0 ).

=cut

sub status {
  my $self        = shift;
  my $oc_id       = $self->{oc_id} || -1;
  my $category_id = $self->{category_id} || -1;

  print STDERR __PACKAGE__, "::status() : $oc_id : $category_id \n";

  return ( 'd', 0777, 2, "nobody", "nobody", 0, 0 );
}

=item move()

Unsupported method that always returns -1.  Category management using
the FTP interface will probably never be supported.

=cut

sub move   {
  $_[0]->{error} = "Categories cannot be modified through the FTP interface.";
  -1;
}

=item delete()

Unsupported method that always returns -1.  Category management using
the FTP interface will probably never be supported.

=cut

sub delete {
  $_[0]->{error} = "Categories cannot be modified through the FTP interface.";
  -1;
}

=item mkdir()

Unsupported method that always returns -1.  Category management using
the FTP interface will probably never be supported.

=cut

sub mkdir  {
  $_[0]->{error} = "Categories cannot be modified through the FTP interface.";
  -1;
}

=item can_*()

Returns permissions information for various activites.  can_write(),
can_enter() and can_list() all return true since these operations are
supported on all categories.  can_delete(), can_rename() and
can_mkdir() all return false since these operations are never
supported.

=cut

sub can_write  { 1; }
sub can_delete { 0; }
sub can_enter  { 1; }
sub can_list   { 1; }
sub can_rename { 0; }
sub can_mkdir  { 0; }

=back

=head1 PRIVATE

=head2 Private Functions

=over 4

=item _get_cats()

Returnes a reference to a hash of category information.  Caches this
data in a package global and returns the cached data if already
called.

=cut

# returns a data structure for categories - caches in a global
# variable.
##############################################################################
# HACK! _get_cats() does a direct query of the database! Naughty, naughty!
# There is currently no way to check permissions on categories. This needs
# fixing, of course.
##############################################################################
sub _get_cats {
  our $CATS;
  return $CATS if $CATS;

  my ($category_id, $directory, $parent_id);
  my $sth = prepare_c('SELECT id, directory, parent_id FROM Category', undef);
  $sth->execute();
  $sth->bind_columns(\$category_id, \$directory, \$parent_id);

  while($sth->fetch()) {
    # store data under category_id
    $CATS->{$category_id}{directory} = $directory;
    $CATS->{$category_id}{parent_id} = $parent_id;

    # build reverse mapping children->parents
    if (defined $parent_id) {
      if (exists $CATS->{children}{$parent_id}) {
        push(@{$CATS->{children}{$parent_id}}, $category_id);
      } else {
        $CATS->{children}{$parent_id} = [ $category_id ];
      }
    }
  }

  return $CATS;
}

=item _forget_cats()

Invalidates the cache used by _get_cats().  If the module ever
provided operations that change catgeories then this method could be
used to forget stale values.

=cut

sub _forget_cats {
  our $CATS;
  undef($CATS);
}

sub dir {
    my $self = shift;
    return $self;
}


1;

__END__

=pod

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

Net:FTPServer::DirHandle

L<Bric::Util::FTP::Server>

L<Bric::Util::FTP::FileHandle>

=cut
