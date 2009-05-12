package Bric::Util::FTP::DirHandle;

=pod

=head1 Name

Bric::Util::FTP::DirHandle - Virtual FTP Server DirHandle

=cut

require Bric; our $VERSION = Bric->VERSION;

=pod

=head1 Description

This module provides a directory handle object for use by
Bric::Util::FTP::Server.

=head1 Interface

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
use Bric::Biz::Asset::Template;
use Bric::Config qw(:ftp);
use Bric::Biz::ElementType;
use Net::FTPServer::DirHandle;
use Bric::Util::Burner::Mason;
use Bric::Util::FTP::FileHandle;
use Bric::Util::Priv::Parts::Const qw(:all);
use File::Basename qw(fileparse);

################################################################################
# Inheritance
################################################################################
our @ISA = qw(Net::FTPServer::DirHandle);


=item new($ftps, [$pathname, $oc_id, $category_id])

Creates a new Bric::Util::FTP::DirHandle object. Requires a
Bric::Util::FTP::Server object as its first parameter. Optionally takes a
pathname, a site_id, an oc_id, and a category_id. If not supplied the pathname
defaults to "/".

=cut

sub new {
  my $class       = shift;
  my $ftps        = shift;       # FTP server object.
  my $pathname    = shift || "/";
  my $site_id     = shift;
  my $oc_id       = shift;
  my $category_id = shift;

  # Create object.
  my $self = Net::FTPServer::DirHandle->new($ftps, $pathname);
  bless $self, $class;

  # get output channel, site, and cagetory_id from args, default to dummy value
  $self->{site_id}     = defined $site_id     ? $site_id     : -1;
  $self->{oc_id}       = defined $oc_id       ? $oc_id       : -1;
  $self->{category_id} = defined $category_id ? $category_id : -1;

  print STDERR __PACKAGE__, "::new() : $self->{oc_id} : $self->{site_id} :"
    . " $self->{category_id}\n" if FTP_DEBUG;

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
  my $site_id     = $self->{site_id};
  my $oc_id       = $self->{oc_id};
  my $category_id = $self->{category_id};

  print STDERR __PACKAGE__, "::get() : $filename\n" if FTP_DEBUG;

  my $deploy = $filename =~ s/\.deploy$//i;

  # look for a template by that name
  my $list = Bric::Biz::Asset::Template->list({
      site_id            => $site_id,
      output_channel__id => $oc_id,
      category_id        => $category_id,
      file_name          => "%/$filename",
  });

  if ($list and @$list) {
    # warn on multiple templates
    warn("Multiple template files called $filename in category $self->{category_id}!")
      if @$list > 1;

    # found at least one template
    my $template = $list->[0];
    return Bric::Util::FTP::FileHandle->new(
        $self->{ftps},
        $template,
        $site_id,
        $oc_id,
        $category_id,
        $deploy,
    )
      # Allow access only to template if the user has READ access to it.
      if $self->{ftps}{user_obj}->can_do($template, READ);
  }

  # Search for a site if we don't have one.
  if ($site_id == -1) {
      my ($id) = Bric::Biz::Site->list_ids({ name => $filename,
                                             active => 1 });
      return Bric::Util::FTP::DirHandle->new($self->{ftps},
                                             "/" . $filename . "/",
                                             $id,
                                             $oc_id,
                                             $category_id,
                                         )
        if $id;
  }

  # search for an output channel if we don't have one
  if ($oc_id == -1) {
      my ($id) = Bric::Biz::OutputChannel->list_ids({ name => $filename,
                                                      site_id => $site_id,
                                                      active => 1});
      if ($id) {
          # Find the root category.
          my ($cid) = Bric::Biz::Category->list_ids({ site_id => $site_id,
                                                      uri     => '/' });
          return Bric::Util::FTP::DirHandle->new($self->{ftps},
                                                 "/" . $filename . "/",
                                                 $site_id,
                                                 $id,
                                                 $cid,
                                             )
            if $cid;
      }
  }

  # search for a subcategories
  my $cats = $self->_get_cats;
  foreach my $child_id (@{$cats->{children}{$category_id}}) {
    if ($cats->{$child_id}{directory} eq $filename) {
      return Bric::Util::FTP::DirHandle->new($self->{ftps},
                                             $self->pathname . $filename . "/",
                                             $site_id,
                                             $oc_id,
                                             $child_id,
                                            );
    }
  }

  # nothing found.
  return undef;
}

=item open($filename, $mode)

This method is called to open a file in the current directory. The possible
modes are 'r', 'w' and 'a'. It will return a Bric::Util::FTP::FileHandle
object if the file exists and the user has permission to it. If they don't
have permission, it returns C<undef>. If the file does not exist, it will be
created (provided the user has CREATE permission) and the
Bric::Util::FTP::FileHandle object returned.

=cut

sub open {
    my $self        = shift;
    my $filename    = shift;
    my $mode        = shift;
    my $site_id     = $self->{site_id};
    my $oc_id       = $self->{oc_id};
    my $category_id = $self->{category_id};

    print STDERR __PACKAGE__, "::open($filename, $mode)\n" if FTP_DEBUG;

    if ($site_id == -1) {
        print STDERR __PACKAGE__, "::open() called without site_id!\n"
          if FTP_DEBUG;
        return undef;
  }

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

    my $deploy = $filename =~ s/\.deploy$//i;

    # find filename
    my $list = Bric::Biz::Asset::Template->list({
        site_id            => $site_id,
        output_channel__id => $oc_id,
        category_id        => $category_id,
        file_name          => "%/$filename"
    });

    if ($list) {
        # warn on multiple templates
        warn("Multiple template files called $filename in category $category_id!")
          if @$list > 1;

        # file exists, return it
        my $template = $list->[0];

        # Make sure they have permission.
        return undef unless $self->{ftps}{user_obj}->can_do($template, READ);

        # Let 'em have it.
        return Bric::Util::FTP::FileHandle->new($self->{ftps},
                                                $template,
                                                $site_id,
                                                $oc_id,
                                                $category_id,
                                                $deploy,
                                            )->open($mode);
    }

    # Perhaps they want to create a new template. Just return unless they're
    # requesting write mode.
    return undef unless $mode eq 'w';

    print STDERR __PACKAGE__, "::open($filename, $mode) : creating new template\n"
      if FTP_DEBUG;

    # Figure out if they have permission to create a new template.
    my $wf = $self->{ftps}->find_workflow($site_id);
    my $start_desk = $wf->get_start_desk;
    my $gid = $start_desk->get_asset_grp;
    return undef
      unless $self->{ftps}{user_obj}->can_do('Bric::Biz::Asset::Template',
                                             CREATE, 0, $gid);
    # create the new template
    my ($name, $dir, $file_type) = fileparse($filename, qr/\..*$/);
    # Remove the dot.
    $file_type =~ s/^\.//;
    my $tplate_type = Bric::Biz::Asset::Template::UTILITY_TEMPLATE;

    # don't look for an element for category templates
    my $at;
    if ( Bric::Util::Burner->class_for_cat_fn($name)) {
        # It's a category template.
        $tplate_type = Bric::Biz::Asset::Template::CATEGORY_TEMPLATE;
        print STDERR __PACKAGE__, "::open($filename, $mode): will create a "
          . "category template\n" if FTP_DEBUG;
    } else {
        # Look for an element to associate it with.
        if ($at = Bric::Biz::ElementType->lookup({ key_name => $name })) {
            # It's an element template!
            $tplate_type = Bric::Biz::Asset::Template::ELEMENT_TEMPLATE;
            print STDERR __PACKAGE__, "::open($filename, $mode): creating for",
              " asset type: ", $at->get_name, "\n" if FTP_DEBUG;
        } else {
            # Leave it as a utiility template.
            print STDERR __PACKAGE__, "::open($filename, $mode): creating ",
              "utility template\n" if FTP_DEBUG;
        }
    }

    ## create the new template object
    my $template = Bric::Biz::Asset::Template->new({
        'element'            => $at,
        'site_id'            => $site_id,
        'file_type'          => $file_type,
        'output_channel__id' => $oc_id,
        'category_id'        => $category_id,
        'tplate_type'        => $tplate_type,
        'priority'           => 3,
        'name'               => ($at ? $at->get_key_name : $name),
        'user__id'           => $self->{ftps}{user_obj}->get_id,
    });

    $self->{ftps}->move_into_workflow($template, $wf);

    # send to the database
    $template->save;

    # now pass off to FileHandle
    return Bric::Util::FTP::FileHandle->new($self->{ftps},
                                            $template,
                                            $site_id,
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
  my $site_id     = $self->{site_id};
  my $oc_id       = $self->{oc_id};
  my $category_id = $self->{category_id};
  my $cats        = $self->_get_cats();
  my $ftps        = $self->{ftps};

  print STDERR __PACKAGE__, "::list() : ", $wildcard || "", "\n" if FTP_DEBUG;

  my @results;

  # translate wildcard to like
  my $like;
  if ($wildcard and $wildcard ne '*') {
    $like = $ftps->wildcard_to_sql_like($wildcard);
  }

  # If no site, just search sites.
  if ($site_id == -1) {
      # get output channels
      my @sites  = Bric::Biz::Site->list({name => ($like || '%'),
                                          active => 1});
      foreach my $site (@sites) {
          next unless $self->{ftps}{user_obj}->can_do($site, READ);
          my $dirh = Bric::Util::FTP::DirHandle->new($self->{ftps},
                                                     "/" . $site->get_name . "/",
                                                     $site->get_id,
                                                     -1,
                                                     -1);
          push @results, [ $site->get_name, $dirh ];
      }
      @results = sort { $a->[0] cmp $b->[0] } @results;
      return \@results;
  }


  # if no oc, just search ocs
  if ($oc_id == -1) {
      # get output channels
      my @ocs  = Bric::Biz::OutputChannel->list({name => ($like || '%'),
                                                 site_id => $site_id,
                                                 active => 1});
      foreach my $oc (@ocs) {
          next unless $self->{ftps}{user_obj}->can_do($oc, READ);

          # Find its root category ID.
          my ($cid) = Bric::Biz::Category->list_ids({ site_id => $site_id,
                                                      uri     => '/' });

          my $dirh = Bric::Util::FTP::DirHandle->new($self->{ftps},
                                                     "/" . $oc->get_name . "/",
                                                     $site_id,
                                                     $oc->get_id(),
                                                     $cid);
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
          my $dirh = Bric::Util::FTP::DirHandle->new(
              $self->{ftps},
              $self->pathname . $cat->get_directory,
              $site_id,
              $oc_id,
              $cat->get_id);
          push @results, [ $cat->get_directory, $dirh ];
      }
  } else {
      if ($cats->{children}{$category_id}) {
          foreach my $child_id (@{$cats->{children}{$category_id}}) {
              my $dirh = Bric::Util::FTP::DirHandle->new(
                  $self->{ftps},
                  $self->pathname . $cats->{$child_id}{directory} . "/",
                  $site_id,
                  $oc_id,
                  $child_id);
              push(@results, [ $cats->{$child_id}{directory}, $dirh ]);
          }
      }
  }

  # get templates
  my $list;
  if ($like) {
      $list = Bric::Biz::Asset::Template->list({
          site_id            => $site_id,
          output_channel__id => $oc_id,
          category_id        => $category_id,
          file_name          => "%/" . ($like || '%')
      });
  } else {
      $list = Bric::Biz::Asset::Template->list({ 
          site_id            => $site_id,
          output_channel__id => $oc_id,
          category_id        => $category_id,
      });
  }

  # create filehandles
  if ($list) {
      foreach my $template (@$list) {
          next unless $self->{ftps}{user_obj}->can_do($template, READ);
          my $fileh = Bric::Util::FTP::FileHandle->new($self->{ftps},
                                                       $template,
                                                       $site_id,
                                                       $oc_id,
                                                       $self->{category_id});
        my $filename = $template->get_file_name;
        $filename = substr($filename, rindex($filename, '/') + 1);
        push @results, [ $filename, $fileh ];
    }
  }

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
  my $site_id = $self->{site_id};
  my $category_id = $self->{category_id};
  my $cats = $self->_get_cats;

  print STDERR __PACKAGE__, "::parent() : ", $category_id, "\n" if FTP_DEBUG;

  return $self if $self->is_root;

  # get a new directory handle and change category_id to parent's
  my $dirh = $self->SUPER::parent;
  $dirh->{category_id} = $cats->{$category_id}{parent_id} || -1;

  # magic to get the right oc_id
  my ($cid) = Bric::Biz::Category->list_ids({ site_id => $site_id,
                                              uri     => '/' });

  if ($self->{category_id} == $cid) {
      $dirh->{oc_id} = -1;
  } elsif ($self->{oc_id} == -1) {
      $dirh->{site_id} = -1;
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
  my $site_id     = $self->{site_id} || -1;
  my $oc_id       = $self->{oc_id} || -1;
  my $category_id = $self->{category_id} || -1;

  print STDERR __PACKAGE__, "::status() : $site_id : $oc_id : $category_id \n"
    if FTP_DEBUG;

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

=head1 Private

=head2 Private Functions

=over 4

=item _get_cats()

Returnes a reference to a hash of category information.  Caches this
data in a package global and returns the cached data if already
called.

=cut

# XXX This caching of all categories is suboptimal for systems with
# 1000s of categories. It sould probably be changed to be more dynamic,
# less caching.

# returns a data structure for categories - caches in a global
# variable.
sub _get_cats {
  our $CATS;
  return $CATS if $CATS;
  my $self = shift;

  for my $cat (Bric::Biz::Category->list) {
      next unless $self->{ftps}{user_obj}->can_do($cat, READ);
      my $parent_id = $cat->get_parent_id;
      my $cid = $cat->get_id;
      $CATS->{$cid}{directory} = $cat->get_directory;
      $CATS->{$cid}{parent_id} = $parent_id;
      if (defined $parent_id) {
          if (exists $CATS->{children}{$parent_id}) {
              push(@{$CATS->{children}{$parent_id}}, $cid);
          } else {
              $CATS->{children}{$parent_id} = [ $cid ];
          }
      }
  }

  return $CATS;
}


# Handle bad FTP clients that try and use directories as files.
sub dir {
    my $self = shift;
    return $self;
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

1;

__END__

=pod

=back

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Net:FTPServer::DirHandle|Net:FTPServer::DirHandle>

L<Bric::Util::FTP::Server|<Bric::Util::FTP::Server>

L<Bric::Util::FTP::FileHandle|Bric::Util::FTP::FileHandle>

=cut
