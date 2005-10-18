#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);
use File::Basename;

exit unless test_column 'element_type', 'burner';

my %burner_name_for = (
    mc          => 'Mason',
    autohandler => 'Mason',
    php         => 'PHP',
    cat_tmpl    => 'PHP',
    pl          => 'HTML::Template',
    tmpl        => 'HTML::Template',
    tt          => 'Template Toolkit',
);

my %burner_id_for = (
    'Mason'            => 1,
    'HTML::Template'   => 2,
    'Template Toolkit' => 3,
    'PHP'              => 4,
);

my $sel = prepare(q{
    SELECT oc.id, oc.name, f.file_name
    FROM   formatting f RIGHT JOIN output_channel oc ON f.output_channel__id = oc.id
});

my (%oc_burner_map, %burner_for);

do {
execute($sel);
bind_columns($sel, \my($oc_id, $oc_name, $file_name));
while (fetch($sel)) {
    if (! defined $file_name) {
        # If the output channel has no template, default to Mason.
        $burner_for{$oc_id} ||= 1;
        next;
    }

    # Otherwise, figure out what burner is used for the template.
    my ($suffix) = $file_name =~ /\.([^.]+)$/;
    my $base_name = basename($file_name);
    if ($suffix && $burner_name_for{$suffix}) {
        # Probably an element or utility template.
        $oc_burner_map{$oc_id}->{name} = $oc_name;
        push @{ $oc_burner_map{$oc_id}->{$burner_name_for{$suffix}} },
            $file_name;
    }

    elsif ($burner_name_for{$base_name}) {
        # Probably a Mason or PHP category template.
        push @{ $oc_burner_map{$oc_id}->{$burner_name_for{$base_name}} },
            $file_name;
    }

    else {
        # Wha?
        print "###############################################################\n"
          . "# ERROR   ERROR    ERROR    ERROR    ERROR    ERRROR   ERROR  #\n"
          . "###############################################################\n"
          . "\n"
          . "Cannot determine the burner for template '$file_name' in output\n"
          . "channel '$oc_name'. Please restore the database to your cloned\n"
          . "copy (you did make a clone, right?) and fix this template in\n"
          . "the database so that it is properly named for the burner with\n"
          . "which it is associated. There may be others with the same\n"
          . "problem, and those should be fixed too. When they have been\n"
          . "fixed, re-run `make upgrade`.\n"
          . "\n"
          . "###############################################################\n\n";
        exit 1;
    }
}
};

# Okay, let's see what we've got.
while (my ($oc_id, $burner_fns) = each %oc_burner_map) {
    my $oc_name = delete $burner_fns->{name};
    my @burners = keys %$burner_fns;
    if (@burners > 1) {
        # Roh-roh: Different burner templates in the same OC!
        my $templates = '';
        my $most = '';
        my $last = 0;
        while (my ($k, $v) = each %$burner_fns) {
            $templates .= "   $k: " . join("\n      ", @$v) . $/;
            if (@$v > $last) {
                $most = $k;
                $last = @$v;
            }
        }
        my $update = y_n
          . "It looks like there are some templates in the $oc_name\n"
          . "output channel that are associated with multiple burners. This\n"
          . "is not a good idea and no longer supported (not that it ever\n"
          . "worked!). The templates appear to be mapped as follows: \n"
          . "\n"
          . "$templates\n"
          . "It looks like most of them are in the $most output channel\n"
          . "Shall I just assume that's the case and update the database\n"
          . "accordingly?\n";

        print "###############################################################\n"
          . "# ERROR   ERROR    ERROR    ERROR    ERROR    ERRROR   ERROR  #\n"
          . "###############################################################\n"
          . "Please restore from your cloned copy (you did make a clone,\n"
          . "right?) and repare these templates.\n"
          . "\n"
          . "###############################################################\n\n"
            && exit 1 unless $update;

        # If we get here, they want to force a burner on the OC.
        $burner_for{$oc_id} = $burner_id_for{$most};
    } else {
        $burner_for{$oc_id} = $burner_id_for{$burners[0]};
    }
}

# Okay, now we can do the update.
do_sql q{ALTER TABLE output_channel ADD COLUMN burner INT2};

my $ins = prepare(q{UPDATE output_channel SET burner = ? WHERE id = ?});

while (my ($oc_id, $burner) = each %burner_for) {
    execute($ins, $burner, $oc_id);
}

do_sql
    q{ALTER TABLE element_type DROP COLUMN burner},
    q{ALTER TABLE output_channel ALTER COLUMN burner SET NOT NULL},
;

1;
__END__
