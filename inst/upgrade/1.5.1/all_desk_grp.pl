#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit if fetch_sql(qq{SELECT 1 FROM grp WHERE id = 34});

do_sql

  # Add the new "All Desks" group.
  q{INSERT INTO grp (id, parent_id, class__id, name, description, secret,
                     permanent)
    VALUES (34, NULL, 40, 'All Desks', 'All desks in the system.', 0, 1)},

  # Add it to the "All Groups" group.
  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (146, 34, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (35, 34, 146)}
  ;

# Add all desks to it.
my $nextmem = next_key('member');
my $nextdm = next_key('desk_member');

my $ins_mem = prepare_c(qq{
    INSERT INTO member (id, grp__id, class__id, active)
    VALUES ($nextmem, 34, 45, 1)
});

my $ins_dm = prepare_c(qq{
    INSERT INTO desk_member (id, object_id, member__id)
    VALUES ($nextdm, ?, ?)
});

my $desk_ids = col_aref(q{SELECT id FROM desk});

foreach my $did (@$desk_ids) {
    execute($ins_mem);
    my $mem_id = last_key('member');
    execute($ins_dm, $did, $mem_id);
}

__END__
