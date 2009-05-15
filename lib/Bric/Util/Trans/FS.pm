package Bric::Util::Trans::FS;

###############################################################################

=head1 Name

Bric::Util::Trans::FS - Utility class for handling files, paths and filenames.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::Trans::FS;

  # Constructors.
  my $fs = Bric::Util::Trans::FS->new;

  # Class methods.
  Bric::Util::Trans->put_res($res, @sts);
  Bric::Util::Trans->del_res($res, @sts);

  # Instance methods.
  $fs->copy($src, $loc);
  $fs->move($src, $loc);
  $fs->mk_path($path);
  $fs->del(@files);
  my $dir  = $fs->cat_dir(@dir_parts);
  my $file = $fs->cat_file(@file_parts);
  my $dir  = $fs->trunc_dir($dir);
  my $uri  = $fs->cat_uri(@uri_parts);
  my $uri  = $fs->trunc_uri($dir);
  my $uri  = $fs->dir_to_uri($dir);
  my $dir  = $fs->uri_to_dir($uri);

=head1 Description

This class provides a thin abstraction around a number of File::*
modules (Copy, Spec, Basename, Find, etc.).  Use it for all your
portable file-system access needs.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use File::Path qw(mkpath rmtree);
use File::Basename ();
use File::Copy qw(cp mv);
use File::Find qw(find);
use File::Spec::Functions ();
use File::Spec::Unix;
use Bric::Util::Fault qw(throw_gen);
use Bric::Util::ApacheUtil qw(escape_uri);

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($cp, $mv, $cpdir, $glob, $glob_rec);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $osen = { mac => 'MacOS',
             macos => 'MacOS',
             os2 => 'os2',
             vms => 'VMS',
             win32 => 'MSWin32',
             'windows nt' => 'MSWin32',
             'windows 95' => 'MSWin32',
             'windows 98' => 'MSWin32',
             'windows xp' => 'MSWin32',
             'windows me' => 'MSWin32',
             win95 => 'MSWin32',
             win98 => 'MSWin32',
             winnt => 'MSWin32',
             win2k => 'MSWin32',
             winxp => 'MSWin32',
             win3x => 'MSWin32',
             dos => 'MSDOS',
             msdos => 'MSDOS',
             amiga => 'AmigaOS',
             amigaos => 'AmigaOS',
           };

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields();
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $mail = Bric::Util::Trans::FS->new

Instantiates a Bric::Util::Trans::FS object.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;
    my $self = bless {}, ref $pkg || $pkg;
    $self->SUPER::new($init);
}

################################################################################

=back

=head2 Destructors

=over 4

=item $org->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

=over 4

=item my $bool = Bric::Util::Trans::FS->put_res($resources, $st)

Copies the resources in the $resources anonymous array to each of the file
system document roots specified by the servers associated with the $st server
type.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'uri' required.

=item *

No AUTOLOAD method.

=item *

Error copying $src to $dst.

=item *

Error creating path.

=item *

Error deleting path.

=item *

Error opening directory.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub put_res {
    my ($pkg, $res, $st) = @_;
    # Get the resource URIs and paths.
    my %src_paths = map { $_->get_uri => $_->get_tmp_path || $_->get_path } @$res;
    foreach my $s ($st->get_servers) {
        next unless $s->is_active;
        my $doc_root = $s->get_doc_root;
        # We've got the document root on each server.
        while (my ($uri, $src) = each %src_paths) {
            # Copy the resource to $doc_root/$uri.
            copy($pkg, $src, cat_dir($pkg, $doc_root, $uri));
        }
    }
    return 1;
}

################################################################################

=item my $bool = Bric::Util::Trans::FS->del_res($resources, $st)

Deletes the resources in the $resources anonymous array from each of the file
system document roots specified by the servers associated with the $st server
type.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

No AUTOLOAD method.

=item *

Error deleting path.

=item *

Error opening directory.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_res {
    my ($pkg, $res, $st) = @_;
    # Get the resource paths.
    my @paths = map { $_->get_uri } @$res;
    foreach my $s ($st->get_servers) {
        next unless $s->is_active;
        # Grab the document root.
        my $doc_root = $s->get_doc_root;
        # Delete all the resources.
        del($pkg, map { cat_dir($pkg, $doc_root, $_) } @paths);
    }
    return 1;
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $fs = $fs->copy($src, $dst, $recurse)

Copies $src to $dest. If the directory hierarchy for $dst does not exist, it
will be created. If $src is a file and $dst doesn't exist, $dst will be created
as a copy of $src. If $srcs is a file and $dst exists as a directory, then $src
will be copied into $dst. If $src is a file and $dst is a file, then $dst will
be replaced with a copy of $src. If $src is a directory, then only the immediate
contents of $src will be copied unless $recurse is true. If $src is a directory
and $dst doesn't exist, then $dst will be created as a copy of $src. If $src is
a directory and $dst is a directory, then $src will be copied into $dst. If $src
is a directory and $dst is a file, then $dst will be wiped out and replaced with
a copy of $src.

B<Throws:>

=over 4

=item *

Error copying $src to $dst.

=item *

Error creating path.

=item *

Error deleting path.

=item *

Error opening directory.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub copy {
    my ($self, $src, $dst, $recurse) = @_;
    return unless -e $src;
    # Are we copying a file or a directory?
    my $is_src_dir = -d $src;
    my $src_base = base_name($self, $src);

    # Figure out the status of $dst.
    my $is_dst = -e $dst;
    my $is_dst_dir = -d $dst;
    my $dst_dir = $is_dst_dir ? undef : dir_name($self,$dst);
    my $dst_base = base_name($self, $dst);

    if (!$is_src_dir && !$is_dst) {
        # $src is a file and $dst doesn't exist. Create a path to $dst's
        # directory, if necessary.
        mk_path($self, $dst_dir) if $dst_dir;
        # Do a straight-ahead copy.
        &$cp($src, $dst);
    } elsif (!$is_src_dir && $is_dst) {
        # $src is a file and $dst exists. Do a straight-ahead copy. If $dst is
        # a file, it will be replaced atomically. If $dst is a directory, $src
        # will be copied into it.
        my $new_file = cat_dir($self, $dst, $src_base);
        if(-d $new_file) {
            # Delete existing directory inside $dst.
            del($self, $new_file);
            # Copy $src to $dst.
            &$cp($src, $dst);
        }  else {
            # Copy to a temporary file in the same destination path.
            my $tmpdst = $dst . '.tmp';
            &$cp($src, $tmpdst);
            # Move the file to its final destination, overwriting the old
            # file.
            &$mv($tmpdst, $dst);
        }
    } elsif ($is_src_dir && !$is_dst) {
        # $src is a directory and $dst doesn't exist. Create a path to $dst and
        # copy $src's contents into it.
        mk_path($self, $dst);
        &$cpdir($src, $dst, $recurse);
    } elsif ($is_src_dir && $is_dst_dir) {
        # $src is a directory and so is $dst. Create a subdirectory of $dst with
        # the same name as $src, and then copy $src into $dst. May want to
        # change this behavior to copy contents of $src into $dst, rather than
        # into a subdirectory of $dst. This is trickier - either have to blow
        # away the existing contents of $dst, or check to see if each file to be
        # copied to $dst doesn't already exist as a directory. However, neither
        # opition is very appealing, and the current implementation matches what
        # cp -r does.
        my $newdir = cat_dir($self, $dst,$src_base);
        # Get rid of any existing file or directory inside $dst.
        del($self, $newdir) if -e $newdir;
        # Create a new path to $newdir.
        mk_path($self, $newdir);
        # Copy the contents of $src to $newdir.
        &$cpdir($src, $newdir, $recurse);
    } elsif ($is_src_dir && $is_dst) {
        # $src is a directory and $dst is a file. Wipe out $dst, then create a
        # path to $dst, then copy the contents of $src into $dst.
        del($self, $dst);
        mk_path($self, $dst);
        &$cpdir($src, $dst, $recurse);
    } else {
        # Nothing.
    }
    return $self;
}

################################################################################

=item $fs = $fs->move($src, $dest)

Moves $src to $dest. If the directory hierarchy for $dst does not exist, it will
be created. If $src is a file and $dest is a file or doesn't exist, $src will be
moved to (become) $dst. If $src is a file and $dst is a directory, $src will be
moved into $dst. If $src is a directory and $dst doesn't exist, then $src will
be moved to (become) $dst, including all of its contents. If $src is a directory
and $dsts is a directory, then $src will be moved, with all of its contents,
into $dst. If $src is a directory and $dst is a file, $dst will be blown away
and then $src will be moved to (become) $dst.

B<Throws:>

=over 4

=item *

Error creating path.

=item *

Error deleting path.

=item *

Error moving $src to $dst.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub move {
    my ($self, $src, $dst) = @_;
    if (-d $src && -e $dst) {
        # Source is a directory.
        if (-d $dst) {
            # Destination is a directory. Create a subdirectory name and then
            # do the move.
            $dst = cat_dir($self, $dst, base_name($self, $src));
            mk_path($self, $dst);
        } else {
            # Destination is a file. Delete it.
            del($self, $dst);
        }
    }
    # Okay, now we can just do the move!
    return &$mv($src, $dst) ? $self : undef;
}

################################################################################

=item my $bool = $fs->mk_path($path)

Creates a directory path.

B<Throws:>

=over 4

=item *

Error creating path.

=back

B<Side Effects:> NONE.

B<Notes:> Uses File::Path::mkpath() internally.

=cut

sub mk_path {
    my $self = shift;
    my $ret;
    File::Basename::fileparse_set_fstype( $^O );
    eval { $ret = mkpath @_ };
    throw_gen(error => "Error creating path @_.", payload => $@)
      if $@;
    return $ret;
}

################################################################################

=item my $bool = $fs->del(@paths)

Deletes a an entire directory tree from the file system. If any path in @paths
is a simple file, it will be deleted.

B<Throws:>

=over 4

=item *

Error deleting path.

=back

B<Side Effects:> NONE.

B<Notes:> Uses File::Path::rmtree() internally.

=cut

sub del {
    my $self = shift;
    my $ret;
    eval { $ret = rmtree [@_] };
    throw_gen(error => "Error deleting paths @_.", payload => $@)
      if $@;
    return $ret;
}

################################################################################

=item my $dir = $fs->cat_dir(@dir_parts)

Takes a list of directory parts and concatenates them for the local file system.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses File::Spec::Functions::catdir() internally.

=cut

sub cat_dir { shift; return File::Spec::Functions::catdir(@_) }

################################################################################

=item my $file = $fs->cat_file(@file_parts)

Takes a list of directory parts and a filename and concatenates them
for the local file system.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses File::Spec::Functions::catfile() internally.

=cut

sub cat_file { shift; return File::Spec::Functions::catfile(@_) }


################################################################################

=item my $uri = $fs->cat_uri(@uri_parts)

Takes a URI and returns its directory parts.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses File::Spec::Unix->catdir() internally.

=cut

sub cat_uri { shift; return File::Spec::Unix->catdir(@_) }

################################################################################

=item my @dir_parts = $fs->split_dir($dir)

Takes a local filesystem directory name and and returns its directory parts.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses File::Spec::Functions::splitdir() internally.

=cut

sub split_dir { shift; return File::Spec::Functions::splitdir(@_) }

################################################################################

=item my @uri_parts = $fs->split_uri($uri)

Takes a URI and and returns its directory parts.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses File::Spec::Unix->splitdir() internally.

=cut

sub split_uri {
    (my $uri = $_[1]) =~ s|(?<=.)/$||;
    return File::Spec::Unix->splitdir($uri);
}

################################################################################

=item my $dir = $fs->trunc_dir($dir)

  my $dir = '/here/there/every/where';
  $dir = $fs->trunc_dir($dir);
  print $dir; # Prints "/here/there/every" on Unix.

Takes a directory name, chops off the last directory specification, and returns
the truncated directory. Returns undef when the directory passed in is the root
directory (e.g., '/').

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses File::Spec::Functions::catdir() and
File::Spec::Functions::splitdir() internally.

=cut

sub trunc_dir {
    my @d = File::Spec::Functions::splitdir($_[1]);
    return if $#d <= 1 && !$d[1] && $d[1] ne '0';
    my $ret =  File::Spec::Functions::catdir(@d[0..$#d - 1]);
}

################################################################################

=item my $uri = $fs->trunc_uri($uri)

Takes a URI name, chops off the last URI specification, and returns the
truncated URI. Returns undef when the URI passed in is the root URI (e.g., '/').

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses File::Spec::Unix->catdir() and File::Spec::Unix->splitdir()
internally.

=cut

sub trunc_uri {
    my @d = File::Spec::Unix->splitdir($_[1]);
    return if $#d <= 1 && !$d[1] && $d[1] ne '0';
    return File::Spec::Unix->catdir(@d[0..$#d - 1]);
}

################################################################################

=item my $uri = $fs->dir_to_uri($dir)

Takes a platform-specific directory name and changes it to a URI.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses File::Spec::Unix->catdir() and File::Spec::Unix->splitdir()
internally.

=cut

sub dir_to_uri {
    my @d = File::Spec::Functions::splitdir($_[1]);
    # Dump any leading drive name on Win32 and OS/2.
    $d[0] = '' if ($^O eq 'Win32' || $^O eq 'OS2') &&
      File::Spec::Functions::file_name_is_absolute($_[1]);
    return File::Spec::Unix->catdir(map { escape_uri($_) } @d);
}

################################################################################

=item my $uri = $fs->uri_to_dir($uri)

Takes a URI and changes it to a directory name for the local platform.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses File::Spec::Unix->catdir() and File::Spec::Unix->splitdir()
internally.

=cut

sub uri_to_dir {
    my @d = File::Spec::Unix->splitdir($_[1]);
    return File::Spec::Functions::catdir(@d);
}

################################################################################

=item my $base_name = $fs->base_name($file_name)

=item my $base_name = $fs->base_name($file_name, $OS)

Takes a complete file path name and extracts just the file name. The $OS
argument may be any one of the following:

=over 4

=item Unix

=item SomeNix

=item Windows NT

=item Windows 95

=item Windows 98

=item Windows XP

=item Windows ME

=item MacOS

=item Mac

=item VMS

=item DOS

=item MSDOS

=item Amiga

=item AmigaOS

=back

If it's not included, the $OS argument is assumed to be 'Unix'.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses File::Basename::basename() and
File::Basename::fileparse_set_fstype() internally.

=cut

sub base_name {
    File::Basename::fileparse_set_fstype(
        $_[2] ? ($osen->{lc $_[2]} || $^O) :  $^O
    );
    return File::Basename::basename($_[1]);
}

################################################################################

=item my $uri_base_name = $fs->uri_base_name($uri)

Takes a URI as an argument and returns just the base name of the file at the
end of the URI.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses File::Basename::basename() and
File::Basename::fileparse_set_fstype() internally.

=cut

sub uri_base_name {
    File::Basename::fileparse_set_fstype('unix');
    return File::Basename::basename($_[1]);
}

################################################################################

=item my $dir_name = $fs->dir_name($file_name)

=item my $dir_name = $fs->dir_name($file_name, $OS)

Takes a complete file path name and extracts just the file name. The $OS
argument may be any one of the options listed in base_name() above.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses File::Basename::dirname() and
File::Basename::fileparse_set_fstype() internally.

=cut

sub dir_name {
    File::Basename::fileparse_set_fstype($_[2] ? $osen->{ lc $_[2] } :  $^O);
    return File::Basename::dirname($_[1]);
}

################################################################################

=item my $uri_dir_name = $fs->uri_dir_name($uri)

Takes a URI as an argument and returns just the directory name, minus the
filename at the end of the URI.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses File::Basename::basename() and
File::Basename::fileparse_set_fstype() internally.

=cut

sub uri_dir_name {
    File::Basename::fileparse_set_fstype('unix');
    return File::Basename::dirname($_[1]);
}

################################################################################

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $bool = &$cp($src, $dst)

Copies a source file to a destination file.

B<Throws:>

=over 4

=item *

Error copying $src to $dst.

=back

B<Side Effects:> NONE.

B<Notes:> Uses File::Copy::copy() internally.

=cut

$cp = sub {
    cp(@_) ||
      throw_gen(error => "Error copying $_[0] to $_[1].", payload => $!);
};

################################################################################

=item my $bool = &$mv($src, $dst)

Moves a source file or directory to a destination file or directory.

B<Throws:>

=over 4

=item *

Error moving $src to $dst.

=back

B<Side Effects:> NONE.

B<Notes:> Uses File::Copy::move() internally.

=cut

$mv = sub {
    mv(@_) ||
      throw_gen(error => "Error moving $_[0] to $_[1].", payload => $!);
};

################################################################################

=item my $bool = &$cpdir($src, $dst, $recurse)

Copies the contents of $src into $dst. If $recurse is true, it will copy all
the subdirectories of $src, too. Otherwise, it'll just copy the immediate
contents of $src.

B<Throws:>

=over 4

=item *

Error opening directory.

=item *

Error copying $src to $dst.

=back

B<Side Effects:> NONE.

B<Notes:> Uses &$glob() and &$glob_rec() internally.

=cut

$cpdir = sub { $_[2] ? &$glob_rec : &$glob };

################################################################################

=item my $bool = &$glob($src_dir, $dst_dir)

Copies the immediate contents of $src_dir into $dst_dir. Does not recursively
copy the subdirectories of $src.

B<Throws:>

=over 4

=item *

Error opening directory.

=item *

Error copying $src to $dst.

=back

B<Side Effects:> NONE.

B<Notes:> Uses &$cp() internally.

=cut

$glob = sub {
    my ($src_dir, $dst_dir) = @_;
    opendir DIR, $src_dir
      || throw_gen(error => "Error opening directory $src_dir",
                   payload => $!);
    foreach my $src ( grep { ! -d $_ } map { cat_dir(__PACKAGE__, $src_dir, $_) }
                                               readdir (DIR) ) {
        &$cp($src, $dst_dir);
    }
    closedir DIR;
    return 1;
};

################################################################################

=item my $bool = &$glob_rec($src_dir, $dest_dir)

Recursively copies the contents of $src to $dst.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses File::Find::find() internally. Not yet implemented.

=cut

$glob_rec = sub {
    my ($src_dir, $dst_dir) = @_;

    my $wanted = sub {
        if (-d) {
            cat_dir(__PACKAGE__, $dst_dir, $_);
        }
    };

    find($wanted, $src_dir);
    return 1;
};

1;
__END__

=back

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<File::Copy|File::Copy>,
L<File::Path|File::Path>,
L<File::Basename|File::Basename>,
L<File::Find|File::Find>,
L<File::Spec|File::Spec>

=cut
