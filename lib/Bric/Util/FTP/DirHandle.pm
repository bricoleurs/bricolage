package Bric::Util::FTP::DirHandle;

=pod

=head1 NAME

Bric::Util::FTP::DirHandle - Virtual FTP Server DirHandle

=head1 VERSION

1.0

=cut

our $VERSION = "1.0";

=pod

=head1 DATE

$Date: 2001-10-02 16:23:59 $

=head1 DESCRIPTION

This module provides a directory handle object for use by
Bric::Util::FTP::Server.

=head1 AUTHOR

Sam Tregar (stregar@about-inc.com

=head1 SEE ALSO

Bric::Util::FTP::Server

=head1 REVISION HISTORY

$Log: DirHandle.pm,v $
Revision 1.1  2001-10-02 16:23:59  samtregar
Added FTP interface to templates


=cut


use strict;
use warnings;

use Bric::Util::DBI qw(:all);
use Bric::Biz::Category;
use Bric::Biz::Asset::Formatting;
use Bric::Config qw(:ftp);
use Carp qw(confess croak);

use Net::FTPServer::DirHandle;
use Bric::Util::FTP::FileHandle;

our @ISA = qw(Net::FTPServer::DirHandle);

# Return a new directory handle.
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

# called when an error occured
sub system_error_hook {
  my $self = shift;
  print STDERR __PACKAGE__, "::system_error_hook()\n" if FTP_DEBUG;
  return delete $self->{error}
    if exists $self->{error};
  return "Unknown error occurred.";
}

# return a subdirectory handle or a file handle within this directory.
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

sub list_status { 
  my $self = shift;
  my $wildcard = shift;

  my $list = $self->list($wildcard);
  foreach my $row (@$list) {
    $row->[3] = [ $row->[1]->status ];
  }

  return $list;
}

# get parent of current directory.
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

# get directory status - this is all fake data 
sub status {
  my $self = shift;
  my $category_id = $self->{category_id};
  
  return ( 'd', 0777, 1, "nobody", "", 0, 0 );
}

# unsupported ops
sub move   { 
  $_[0]->{error} = "Categories cannot be modified through the FTP interface.";
  -1;
}

sub delete { 
  $_[0]->{error} = "Categories cannot be modified through the FTP interface.";
  -1;
}
sub mkdir  { 
  $_[0]->{error} = "Categories cannot be modified through the FTP interface.";
  -1;
}

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
  # $self->{ftps}->reply(214, "Template creation not yet supported.");
  return undef;
}

sub can_write  { 1; }
sub can_delete { 0; }
sub can_enter  { 1; }
sub can_list   { 1; }
sub can_rename { 0; }
sub can_mkdir  { 0; }

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

# invalidate category cache - forces reload on next call to _get_cats
sub _forget_cats {
  our $CATS;
  undef($CATS);
}


1;
