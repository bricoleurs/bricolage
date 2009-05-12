#!/usr/bin/perl -w

=head1 Name

rm_files.pl - installation script to remove directories and files

=head1 Description

This script is called during C<make uninstall> to remove all
of Bricolage's files. This should be last so that the *.db
files exist for the other scripts executed during C<make uninstall>.

=head1 Author

Scott Lanning <slanning@theworld.com>

=head1 See Also

L<Bric::Admin>

=cut


use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);
use File::Path qw(rmtree);

# make sure we're root, otherwise uninformative errors result
unless ($> == 0) {
    print "This process must (usually) be run as root.\n";
    exit 1 unless ask_yesno("Continue as non-root user?", 1);
}

print "\n\n==> Deleting Bricolage Files <==\n\n";

# read in user config settings
our $CONFIG;
do "./config.db" or die "Failed to read config.db : $!";

delete_files();

print "\n\n==> Finished Deleting Bricolage Files <==\n\n";
exit 0;


sub delete_files {
    my $instruction = qq{This installation is configured to allow multiple
Bricolages to exist side-by-side. Do you want to remove everything
under Bricolage root ($CONFIG->{BRICOLAGE_ROOT}) in one swipe?};

    if ($CONFIG->{set} eq 'm' && ask_yesno($instruction, 1)) {
        # For 'multiple' configurations, the default is to put
        # everything under Bricolage root, so it's quicker just
        # to remove that.
        rmtree_or_die('Bricolage root', $CONFIG->{BRICOLAGE_ROOT});
    } else {
        my $dir = $CONFIG->{MAN_DIR};

        # Remove manpages
        if (-d $dir && ask_yesno(qq{Remove manpages ($dir/man1/bric_*, $dir/man3/Bric*)?}, 1)) {
            if ($CONFIG->{set} eq 's') {
                rm_dirfiles(catfile($dir, 'man1'), 'bric_', 'man1 pages');
                rm_dirfiles(catfile($dir, 'man3'), 'Bric', 'man3 pages');
            } else {
                rmtree_or_die('Man pages', $dir);
            }
        }

        # Remove executables
        $dir = $CONFIG->{BIN_DIR};
        if (-d $dir && ask_yesno(qq{Remove executables ($dir/bric_*)?}, 1)) {
            rm_dirfiles($dir, 'bric_', 'Executables');
        }

        # Remove modules
        $dir = $CONFIG->{MODULE_DIR};
        $dir = catfile($dir, 'Bric') if $CONFIG->{set} eq 's';
        if (-d $dir && ask_yesno(qq{Remove Perl Module directory "$dir"?}, 1)) {
            rmtree_or_die('Perl Module', $dir);

            # If the Bric.pm file is left after the directory is removed,
            # remove that too.
            my $file = "$dir.pm";
            if (-f $file) {
                unless (unlink($file)) {
                    print "File $file could not be removed: $!";
                }
            }
        }

        ask_rmtree('Mason Component',       $CONFIG->{MASON_COMP_ROOT});
        ask_rmtree('Mason Data',            $CONFIG->{MASON_DATA_ROOT});
        ask_rmtree('Bricolage root',        $CONFIG->{BRICOLAGE_ROOT});
    }
}

sub ask_rmtree {
    my ($text, $dir) = @_;

        if (-d $dir) {
            if (ask_yesno(qq{Remove $text directory "$dir"?}, 1)) {
                rmtree_or_die($text, $dir);
            }
        } else {
            hard_fail(qq{$text directory "$dir" not found.});
        }
}

sub rmtree_or_die {
    my ($text, $dir) = @_;

    if (rmtree($dir)) {
        print "$text directory removed.\n";
    } else {
        hard_fail(qq{Failed to drop $text directory "$dir".});
    }
}

sub rm_dirfiles {
    my ($dir, $regexp, $label) = @_;

    opendir(DIR, $dir) || hard_fail("Can't opendir $dir: $!");
    my @files = map {catfile($dir, $_)} grep { /^$regexp/ } readdir(DIR);
    closedir(DIR);
    if (unlink(@files) == @files) {
        print "$label removed.\n";
    } else {
        hard_fail("$label were not all removed: $!");
    }
    rmdir($dir);  # won't remove unless empty
}
