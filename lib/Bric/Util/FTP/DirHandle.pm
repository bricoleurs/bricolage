package Bric::Util::FTP::DirHandle;

=pod

=head1 NAME

Bric::Util::FTP::DirHandle - Virtual FTP Server DirHandle

=head1 VERSION

$Revision $

=cut

our $VERSION = (qw$Revision: 1.4 $ )[-1];

=pod

=head1 DATE

$Date: 2001-12-03 18:27:37 $

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
use Bric::Biz::Asset::Formatting;
use Bric::Config qw(:ftp);
use Carp qw(confess croak);

use Net::FTPServer::DirHandle;
use Bric::Util::FTP::FileHandle;

################################################################################
# Inheritance
################################################################################
our @ISA = qw(Net::FTPServer::DirHandle);


=item new($ftps, [$pathname, $category_id])

Creates a new Bric::Util::FTP::DirHandle object.  Requires a
Bric::Util::FTP::Server object as its first paramater.  Optionally
takes a pathname and a category_id.  If not supplied the pathname
defaults to "/" and the corresponding catgeory_id is looked up from
the database.

=cut

sub new {
  my $class = shift;
  my $ftps = shift;	       # FTP server object.
  my $pathname = shift || "/"; # (only used in internal calls)
  my $category_id = shift;     # (only used in internal calls)

  # Create object.
  my $self = Net::FTPServer::DirHandle->new($ftps, $pathname);
  bless $self, $class;
 
  # store category object or default to the root - always 0. if the
  # root category could be something else then we could do a lookup
  # for a null directory
  $self->{category_id} = $category_id || 0;
  
  print STDERR __PACKAGE__, "::new() : $self->{category_id}\n" if FTP_DEBUG;
  
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
  my $self = shift;
  my $filename = shift;
  my $category_id = $self->{category_id};
  my $category_grp_id = $self->{category_grp_id};

  print STDERR __PACKAGE__, "::get() : $filename\n" if FTP_DEBUG;
  
  # look for a template by that name
  my $list = Bric::Biz::Asset::Formatting->list({ category__id => $category_id, file_name => "%/$filename" });
                                   
  if ($list and @$list) {
    # warn on multiple templates
    warn("Multiple template files called $filename in category $self->{category_id}!")
      if @$list > 1;
    
    # found at least one template
    my $template = $list->[0];
    return new Bric::Util::FTP::FileHandle ($self->{ftps},
                                            $template,
                                            $category_id);

  }

  # search for a subcategories
  my $cats = _get_cats();
  foreach my $child_id (@{$cats->{children}{$category_id}}) {
    if ($cats->{$child_id}{directory} eq $filename) {
      return Bric::Util::FTP::DirHandle->new($self->{ftps},
                                             $self->pathname . $filename . "/",
                                             $child_id
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
  my $self = shift;
  my $filename = shift;
  my $mode = shift;

  print STDERR __PACKAGE__, "::open($filename, $mode)\n" if FTP_DEBUG;
  
  # find filename
  my $list = Bric::Biz::Asset::Formatting->list({ category__id => $self->{category_id}, file_name => "%/$filename" });

  if ($list) {
    my $template = shift @$list;
    return Bric::Util::FTP::FileHandle->new($self->{ftps},
                                            $template,
                                            $self->{category_id}
                                           )->open($mode);
  }

  # not handling creation yet...
  return undef;
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
  my $self = shift;
  my $wildcard = shift;
  my $category_id = $self->{category_id};
  my $cats = _get_cats();
  my $grp_id = $cats->{category_id}{grp_id};
  my $ftps = $self->{ftps};

  print STDERR __PACKAGE__, "::list() : ", $wildcard || "", "\n" if FTP_DEBUG;
  
  my @results;

  # translate wildcard to like
  my $like;
  if ($wildcard and $wildcard ne '*') {
    $like = $ftps->wildcard_to_sql_like($wildcard);
  }
  
  # get subdirectories.
  if ($like) {
    # select matching subdirectories
    my $results = all_aref("SELECT c.id, c.directory FROM category c, grp g WHERE g.id = c.category_grp_id AND g.parent_id = ? AND c.directory LIKE ?", $grp_id, $like);

    # create dirhandles
    foreach my $row (@$results) {
      my $dirh = new Bric::Util::FTP::DirHandle ($self->{ftps},
                                                 $self->pathname . $row->[1] . "/",
                                                 $row->[0]);
      
      push @results, [ $row->[1], $dirh ];
    }
  } else {
    if ($cats->{children}{$category_id}) {
      foreach my $child_id (@{$cats->{children}{$category_id}}) {
        my $dirh = new Bric::Util::FTP::DirHandle ($self->{ftps},
                                                   $self->pathname . $cats->{$child_id}{directory} . "/",
                                                   $child_id);
        push(@results, [ $cats->{$child_id}{directory}, $dirh ]);
      }
    }
  }     

  # get templates
  my $list;
  if ($like) {
    $list = Bric::Biz::Asset::Formatting->list({ category__id => $self->{category_id}, file_name => "%/" . ($like || '%') });
  } else {
    $list = Bric::Biz::Asset::Formatting->list({ category__id => $self->{category_id} });
  }

  # create filehandles
  if ($list) {
    foreach my $template (@$list) {
      my $fileh = new Bric::Util::FTP::FileHandle ($self->{ftps},
                                                   $template,
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
  $dirh->{category_id} = $cats->{$category_id}{parent_id};
  
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
  my $self = shift;
  my $category_id = $self->{category_id};

  print STDERR __PACKAGE__, "::status() : ", $category_id, "\n";  
  
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
sub _get_cats {
  our $CATS;
  return $CATS if $CATS;

  my ($category_id, $grp_id, $directory, $parent_id);
  my $sth = prepare('SELECT c.id, c.directory, c.category_grp_id, pg.id as parent_directory FROM category c LEFT OUTER JOIN (grp g LEFT OUTER JOIN category pg ON g.parent_id = pg.category_grp_id) ON c.category_grp_id = g.id');
  $sth->execute();
  $sth->bind_columns(\$category_id, \$directory, \$grp_id, \$parent_id);

  while($sth->fetch()) {
    # store data under category_id
    $CATS->{$category_id}{directory} = $directory;
    $CATS->{$category_id}{grp_id}    = $grp_id;
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


1;

__END__

=pod

=head1 AUTHOR

Sam Tregar (stregar@about-inc.com)

=head1 SEE ALSO

Net:FTPServer::DirHandle, Bric::Util::FTP::Server, Bric::Util::FTP::FileHandle

=cut
