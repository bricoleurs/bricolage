#!/usr/bin/perl -w

=head1 NAME

files.pl - installation script to create directories and copy files

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2002-04-08 20:00:13 $

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
use File::Path qw(mkpath);
use File::Find qw(find);
use File::Copy qw(copy);

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

create_paths();
find({ wanted => \&copy_files, no_chdir => 1 }, './comp', './data');
assign_permissions();


print "\n\n==> Finished Copying Bricolage Files <==\n\n";
exit 0;


# create paths configured by the user
sub create_paths {
    mkpath([catdir($CONFIG->{BRICOLAGE_ROOT}, "comp"),
	    catdir($CONFIG->{BRICOLAGE_ROOT}, "comp", "data"),
	    catdir($CONFIG->{BRICOLAGE_ROOT}, "data"),
	    catdir($CONFIG->{BRICOLAGE_ROOT}, "conf"),
	    $CONFIG->{TEMP_DIR},
	    $CONFIG->{LOG_DIR}],
	   1,
	   0755);
}

# copy files - should be called by a find() with no_chdir set
sub copy_files {
    return if /\.$/;
    return if /CVS/;
    return if /\.cvsignore$/;
    if (-d) {	
	my $path = catdir($CONFIG->{BRICOLAGE_ROOT}, $_);
	mkpath([$path], 1, 0755)
	    unless -e $path;
    } else {
	my $targ = catfile($CONFIG->{BRICOLAGE_ROOT}, $_);
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
	   catdir($CONFIG->{BRICOLAGE_ROOT}, "comp", "data"));
    system("chown", "-R", $AP->{user} . ':' . $AP->{group}, 
	   catdir($CONFIG->{BRICOLAGE_ROOT}, "data"));
    system("chown", "-R", $AP->{user} . ':' . $AP->{group}, 
	   catdir($CONFIG->{TEMP_DIR}));
    system("chown", "-R", $AP->{user} . ':' . $AP->{group}, 
	   catdir($CONFIG->{LOG_DIR}));
}
