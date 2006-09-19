package Bric::Util::DBI::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Util::DBI qw(:all);
use Bric::Biz::Asset;

##############################################################################
# Set up a flat version of the story for easy testing of _fetch_objects
##############################################################################
sub test_fetch_objects: Test(4) {
    my $self = shift;
    eval {
    my $sth = prepare(q{
        INSERT INTO story (
            site__id, uuid, source__id, desk__id, element_type__id, current_version, workflow__id, primary_uri,published_version
        ) VALUES (
            ?, ?, ?, ?, ?, ?, ?, ?, ?
        )
    });

    for my $row ([100, 1, 1, 0, 1, 1, 0, 1, undef],
                 [100, 1, 1, 0, 1, 1, 0, undef, 4],
                 [100, 1, 1, 0, 1, 1, 0, 3, 5],

                 [100, 2, 1, 0, 2, 2, 0, 1, 4],
                 [100, 2, 1, 0, 2, 2, 0, 2, 5],
                 [100, 2, 1, 0, 2, 2, 0, 3, 6],

                 [100, 3, 1, 0, 3, 3, 0, 3, undef],
                 [100, 3, 1, 0, 3, 3, 0, 6, 0],
                 [100, 3, 1, 0, 3, 3, 0, 4, 0],

                 [100, 4, 1, 0, 4, 4, 0, 4, 0],
                 [100, 4, 1, 0, 4, 4, 0, 0, 8],
                 [100, 4, 1, 0, 4, 4, 0, 0, 0],
             ) {
                     execute($sth, @$row);
    }

    # check that _fetch_objects produces the right objs
    my $sql = ' SELECT site__id, uuid, source__id, desk__id, element_type__id, current_version, workflow__id,
                 group_concat(DISTINCT alias_id '.GROUP_SEP.'),
                 group_concat(DISTINCT published_version '.GROUP_SEP.')
                 FROM story
                 GROUP BY site__id, uuid, source__id, desk__id, element_type__id, current_version, workflow__id
                 ORDER BY site__id, workflow__id ASC ';
    my $sqltemp=$sql;
    my $fields = [ qw( site__id uuid source__id desk__id element_type__id current_version workflow__id alias_id ) ];
    my $stories = fetch_objects('Bric::Biz::Asset', \$sql, $fields, 2, undef, undef , undef);
#    print ('//'.$stories->[0]{priority}.'//');
    $_->{alias_id} = [sort { $a <=> $b } @{$_->{alias_id}}] for @$stories;
    my $expect = [
             bless( {
                      site__id     => 100,
                      uuid     => 1,
                      source__id    => 1,
                      desk__id    => 0,
                      element_type__id     => 1,
                      current_version   => 1,
                      workflow__id   => 0,
                      alias_id    => [ 4, 5 ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
             bless( {
                      site__id     => 100,
                      uuid     => 2,
                      source__id    => 1,
                      desk__id    => 0,
                      element_type__id     => 2,
                      current_version   => 2,
                      workflow__id   => 0,
                      alias_id    => [ 4, 5, 6],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
             bless( {
                      site__id     => 100,
                      uuid     => 3,
                      source__id    => 1,
                      desk__id    => 0,
                      element_type__id     => 3,
                      current_version   => 3,
                      workflow__id   => 0,
                      alias_id    => [ ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
             bless( {
                      site__id     => 100,
                      uuid     => 4,
                      source__id    => 1,
                      desk__id    => 0,
                      element_type__id     => 4,
                      current_version   => 4,
                      workflow__id   => 0,
                      alias_id    => [ 8 ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
           ];
    is_deeply($stories, $expect,
              'Checking that _fetch_objects produces the correct object structure');
    # test limit
    $sql = $sqltemp.' LIMIT 2';
    $stories = fetch_objects('Bric::Biz::Asset', \$sql, $fields, 2,  undef, 2, undef);
    $_->{alias_id} = [sort { $a <=> $b } @{$_->{alias_id}}] for @$stories;
    $expect = [
             bless( {
                      site__id     => 100,
                      uuid     => 1,
                      source__id    => 1,
                      desk__id    => 0,
                      element_type__id     => 1,
                      current_version   => 1,
                      workflow__id   => 0,
                      alias_id    => [ 4, 5 ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
             bless( {
                      site__id     => 100,
                      uuid     => 2,
                      source__id    => 1,
                      desk__id    => 0,
                      element_type__id     => 2,
                      current_version   => 2,
                      workflow__id   => 0,
                      alias_id    => [ 4, 5, 6],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
           ];
    is_deeply($stories, $expect, 'limit of 2 gets first 2 objects');
    # test offset
    $sql = $sqltemp;
    $sql .= ' LIMIT ' . LIMIT_DEFAULT if LIMIT_DEFAULT;
    $sql .= ' OFFSET 2';
    $stories = fetch_objects('Bric::Biz::Asset', \$sql, $fields, 2, undef);
    $_->{alias_id} = [sort { $a <=> $b } @{$_->{alias_id}}] for @$stories;
    $expect = [
                 bless( {
                      site__id     => 100,
                      uuid     => 3,
                      source__id    => 1,
                      desk__id    => 0,
                      element_type__id     => 3,
                      current_version   => 3,
                      workflow__id   => 0,
                      alias_id    => [ ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
             bless( {
                      site__id     => 100,
                      uuid     => 4,
                      source__id    => 1,
                      desk__id    => 0,
                      element_type__id     => 4,
                      current_version   => 4,
                      workflow__id   => 0,
                      alias_id    => [ 8 ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
               ];
    is_deeply($stories, $expect, 'offset of 2 gets last 2 objects');
    # test limit and offset together
    $sql = $sqltemp;
    $sql .= ' LIMIT 2 OFFSET 1';
    $stories = fetch_objects('Bric::Biz::Asset', \$sql, $fields, 2, undef, 2, 1);
    $_->{alias_id} = [sort { $a <=> $b } @{$_->{alias_id}}] for @$stories;
    $expect = [
             bless( {
                      site__id     => 100,
                      uuid     => 2,
                      source__id    => 1,
                      desk__id    => 0,
                      element_type__id     => 2,
                      current_version   => 2,
                      workflow__id   => 0,
                      alias_id    => [ 4, 5, 6],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
             bless( {
                      site__id     => 100,
                      uuid     => 3,
                      source__id    => 1,
                      desk__id    => 0,
                      element_type__id     => 3,
                      current_version   => 3,
                      workflow__id   => 0,
                      alias_id    => [ ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
           ];
    is_deeply($stories, $expect, 'can use limit and offset together to return middle 2 objects');
    };
    my $err = $@;

    Bric::Util::DBI::execute(
      Bric::Util::DBI::prepare("DELETE FROM story WHERE site__id=100"));
    die $err if $err;

}

1;
__END__
