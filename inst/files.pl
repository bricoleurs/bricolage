#!/usr/bin/perl -w

=head1 NAME

files.pl - installation script to create directories and copy files

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 DESCRIPTION

This script is called during "make install" to create Bricolage's
directories, copy files and setup permissions.

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::Admin>

=cut


use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);
use File::Path qw(mkpath rmtree);
use File::Find qw(find);
use File::Copy qw(copy move);

# make sure we're root, otherwise uninformative errors result
unless ($> == 0) {
    print "This process must (usually) be run as root.\n";
    exit 1 unless ask_yesno("Continue as non-root user? [yes] ", 1);
}

print "\n\n==> Copying Bricolage Files <==\n\n";

# read in user config settings
our $CONFIG;
do "./config.db" or die "Failed to read config.db : $!";
our $AP;
do "./apache.db" or die "Failed to read apache.db : $!";

# check if we're upgrading
our $UPGRADE;
$UPGRADE = 1 if $ARGV[0] and $ARGV[0] eq 'UPGRADE';

if ($UPGRADE) {
    # Remove old object files.
    rmtree catdir($CONFIG->{MASON_DATA_ROOT}, 'obj');

    # Find a good new name for the component directory.
    my $dest = "$CONFIG->{MASON_COMP_ROOT}.old";
    my $i;
    while (-e $dest) {
        $dest = "$CONFIG->{MASON_COMP_ROOT}.old" . ++$i;
    }

    # Move the component directory.
    move $CONFIG->{MASON_COMP_ROOT}, $dest
      or die "Cannot move '$CONFIG->{MASON_COMP_ROOT}' to '$dest': $!\n";

    # Create the new paths.
    create_paths();

    # Now move the "data" directory back.
    move catdir($dest, 'data'), catdir($CONFIG->{MASON_COMP_ROOT}, 'data')
      or die "Cannot move '", catdir($dest, 'data'), "' to '",
      catdir($CONFIG->{MASON_COMP_ROOT}, 'data'), "': $!\n";

    # Holler at 'em.
    print "$CONFIG->{MASON_COMP_ROOT} moved to $dest\n";
    print "Delete it if you haven't added or altered files in it.\n";
} else {
    # Just create the new paths.
    create_paths();
}

# Copy the Mason UI components.
find({ wanted   => sub { copy_files($CONFIG->{MASON_COMP_ROOT}) },
       no_chdir => 1 }, './comp');

# Copy the contents of the bconf directory.
find({ wanted   => sub { copy_files(catdir $CONFIG->{BRICOLAGE_ROOT}, "conf") },
       no_chdir => 1 }, './bconf');

unless ($UPGRADE) {
    # Copy the contents of the data directory.
    find({ wanted   => sub { copy_files($CONFIG->{MASON_DATA_ROOT}) },
           no_chdir => 1 }, './data');
}

assign_permissions();


print "\n\n==> Finished Copying Bricolage Files <==\n\n";
exit 0;


# create paths configured by the user
sub create_paths {
    mkpath([catdir($CONFIG->{MASON_COMP_ROOT}, "data"),
	    $CONFIG->{MASON_DATA_ROOT},
	    catdir($CONFIG->{BRICOLAGE_ROOT}, "conf"),
	    catdir($CONFIG->{TEMP_DIR}, "bricolage"),
	    $CONFIG->{LOG_DIR}],
	   1,
	   0755);
}

# copy files - should be called by a find() with no_chdir set
sub copy_files {
    my $root = shift;
    return if /\.$/;
    return if /.svn/;
    return if $UPGRADE and m!/data/!; # Don't upgrade data files.
    return if $UPGRADE and /bconf/ and /\.conf$/; # Don't upgrade .conf files.

    # construct target by lopping off ^./foo/ and appending to $root
    my $targ;
    ($targ = $_) =~ s!^\./\w+/?!!;
    return unless length $targ;
    $targ = catdir($root, $targ);

    if (-d) {
	mkpath([$targ], 1, 0755) unless -e $targ;
    } else {
	copy($_, $targ)
	    or die "Unable to copy $_ to $targ : $!";
	chmod((stat($_))[2], $targ)
	    or die "Unable to copy mode from $_ to $targ : $!";
    }
}

# assigns the proper permissions to the various directories created
# and the files beneath them.
sub assign_permissions {
    system("chown", "-R", $AP->{user} . ':' . $AP->{group},
	   catdir($CONFIG->{MASON_COMP_ROOT}, "data"));
    system("chown", "-R", $AP->{user} . ':' . $AP->{group},
	   $CONFIG->{MASON_DATA_ROOT});
    system("chown", "-R", $AP->{user} . ':' . $AP->{group},
	   catdir($CONFIG->{TEMP_DIR}, "bricolage"));
    system("chown", "-R", $AP->{user} . ':' . $AP->{group},
	   catdir($CONFIG->{LOG_DIR}));
}
