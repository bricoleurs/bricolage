#!/usr/bin/perl -w

=head1 Name

files.pl - installation script to create directories and copy files

=head1 Description

This script is called during "make install" to create Bricolage's
directories, copy files and setup permissions.

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::Admin>

=cut


use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);
use File::Path qw(mkpath rmtree);
use File::Find qw(find);
use File::Copy qw(copy);

# avoid uninitialized value warnings
$ENV{PERL_INSTALL_ROOT}='' unless exists $ENV{PERL_INSTALL_ROOT};

# make sure we're root, otherwise uninformative errors result
unless ($> == 0) {
    print "This process must (usually) be run as root.\n";
    exit 1 unless ask_yesno("Continue as non-root user?", 1);
}

print "\n\n==> Copying Bricolage Files <==\n\n";

# read in user config settings
our $CONFIG;
do "./config.db" or die "Failed to read config.db: $!";
our $AP;
do "./apache.db" or die "Failed to read apache.db: $!";

# check if we're upgrading
our $UPGRADE;
$UPGRADE = 1 if $ARGV[0] and $ARGV[0] eq 'UPGRADE';

our $HOT_COPY;
$HOT_COPY = 1 if $ARGV[1] and $ARGV[1] eq 'HOT_COPY';

create_paths();

# Remove old object files if this is an upgrade.
rmtree catdir($CONFIG->{MASON_DATA_ROOT}, 'obj') if $UPGRADE;

# Copy the Mason UI components.
find({
    no_chdir => 1,
    wanted   => sub {
        copy_files(
            catdir($ENV{PERL_INSTALL_ROOT}, $CONFIG->{MASON_COMP_ROOT}),
            $HOT_COPY,
        )
    },
}, './comp') unless $ENV{DEVELOPER};

# Copy the contents of the bconf directory.
find({
    no_chdir => 1,
    wanted   => sub {
        copy_files(
            catdir($ENV{PERL_INSTALL_ROOT}, $CONFIG->{BRICOLAGE_ROOT}, 'conf'),
            0,
            0640,
        )
    },
}, './bconf');

unless ($UPGRADE) {
    # Copy the contents of the data directory.
    find({
        no_chdir => 1,
        wanted   => sub {
            copy_files(
                catdir($ENV{PERL_INSTALL_ROOT}, $CONFIG->{MASON_DATA_ROOT}),
                $HOT_COPY,
            )
        },
    }, './data');
}

assign_permissions() unless ($ENV{PERL_INSTALL_ROOT});

print "\n\n==> Finished Copying Bricolage Files <==\n\n";
exit 0;

# create paths configured by the user
sub create_paths {
    my $inst_root = $ENV{PERL_INSTALL_ROOT};
    mkpath(
        [
            catdir($inst_root, $CONFIG->{MASON_COMP_ROOT}, 'data'),
            catdir($inst_root, $CONFIG->{MASON_DATA_ROOT}),
            catdir($inst_root, $CONFIG->{BRICOLAGE_ROOT}, 'conf'),
            catdir($inst_root, $CONFIG->{TEMP_DIR}, 'bricolage'),
            catdir($inst_root, $CONFIG->{LOG_DIR})
        ],
        1,
        0755
    );
}

# copy files - should be called by a find() with no_chdir set
sub copy_files {
    my $root = shift;
    my $link = shift;
    my $mode = shift || 0444;
    return if /\.$/;
    return if /.svn/;
    return if $UPGRADE and m!/data/!; # Don't upgrade data files.

    # construct target by lopping off ^./foo/ and appending to $root
    my $targ;
    ($targ = $_) =~ s!^\./\w+/?!!;
    return unless length $targ;
    $targ = catdir($root, $targ);
    # Don't upgrade .conf files.
    return if $UPGRADE and /bconf/ and /\.conf$/ && -f $targ;

    if (-d) {
        mkpath([$targ], 1, 0755) unless -e $targ;
    } else {
        if ($link) {
            link($_, $targ) or die "Unable to link $_ to $targ: $!";
        } else {
            copy($_, $targ) or die "Unable to copy $_ to $targ: $!";
            chmod($mode, $targ)
                or die "Unable to copy mode from $_ to $targ: $!";
        }
    }
}

# assigns the proper permissions to the various directories created
# and the files beneath them.
sub assign_permissions {
    system('chown', '-R', $AP->{user} . ':' . $AP->{group},
       catdir($CONFIG->{MASON_COMP_ROOT}, 'data'));
    system('chown', '-R', $AP->{user} . ':' . $AP->{group},
       $CONFIG->{MASON_DATA_ROOT});
    system('chown', '-R', $AP->{user} . ':' . $AP->{group},
       catdir($CONFIG->{TEMP_DIR}, 'bricolage'));
    system('chown', '-R', $AP->{user} . ':' . $AP->{group},
       catdir($CONFIG->{LOG_DIR}));
}
