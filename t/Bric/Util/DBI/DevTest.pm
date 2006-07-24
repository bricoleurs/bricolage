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
    # create a fake story table. It doesn't need to have
    # the same structure as the real ones, it just needs
    # to produce the same result
    Bric::Util::DBI::execute( Bric::Util::DBI::prepare(q{
         CREATE TABLE test_fetch_objects (
                one        INTEGER NULL,
                two        INTEGER NULL,
                three      INTEGER NULL,
                four       INTEGER NULL,
                five       INTEGER NULL,
                six        INTEGER NULL,
                seven      INTEGER NULL,
                eight      INTEGER NULL,
                nine       INTEGER NULL,
                ten        INTEGER NULL,
                eleven     INTEGER NULL,
                twelve     INTEGER NULL
            ) })) if (DBD_TYPE eq "Pg");

    eval {
    my $sth = prepare(q{
        INSERT INTO test_fetch_objects (
            one, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve
        ) VALUES (
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        )
    });

    for my $row ([1, 1, 1, 1, 1, 1, 1, 1, 1, undef, undef, 2],
                 [1, 1, 1, 1, 1, 1, 1, 1, undef, 4, undef, undef],
                 [1, 1, 1, 1, 1, 1, 1, 1, 3, 5, 6, 7],

                 [2, 2, 2, 2, 2, 2, 2, 2, 1, 4, 7, 10],
                 [2, 2, 2, 2, 2, 2, 2, 2, 2, 5, 8, 20],
                 [2, 2, 2, 2, 2, 2, 2, 2, 3, 6, 9, 30],

                 [3, 3, 3, 3, 3, 3, 3, 3, 3, undef, 2, 1],
                 [3, 3, 3, 3, 3, 3, 3, 3, 6, 0, 0, 0],
                 [3, 3, 3, 3, 3, 3, 3, 3, 4, 0, 0, 0],

                 [4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 5, 1],
                 [4, 4, 4, 4, 4, 4, 4, 4, 0, 8, 0, 2],
                 [4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 3],
             ) {
        execute($sth, @$row);
    }

    # check that _fetch_objects produces the right objs
    my $sql = ' SELECT one, two, three, four, five, six, seven, eight,
                 group_concat(DISTINCT nine '.GROUP_SEP.'), group_concat(DISTINCT ten '.GROUP_SEP.'),
                 group_concat(DISTINCT eleven '.GROUP_SEP.'), group_concat(DISTINCT twelve '.GROUP_SEP.')
                 FROM test_fetch_objects
                 GROUP BY one, two, three, four, five, six, seven, eight
                 ORDER BY one, eight ASC ';
    my $fields = [ qw( one two three four five six seven eight nine ) ];
    my $stories = fetch_objects('Bric::Biz::Asset', \$sql, $fields, 4, undef, undef, undef);
    $_->{nine} = [sort { $a <=> $b } @{$_->{nine}}] for @$stories;
    my $expect = [
             bless( {
                      one     => 1,
                      two     => 1,
                      three   => 1,
                      four    => 1,
                      five    => 1,
                      six     => 1,
                      seven   => 1,
                      eight   => 1,
                      nine    => [ 1, 2, 3, 4, 5, 6, 7 ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
             bless( {
                      one     => 2,
                      two     => 2,
                      three   => 2,
                      four    => 2,
                      five    => 2,
                      six     => 2,
                      seven   => 2,
                      eight   => 2,
                      nine    => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30 ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
             bless( {
                      one     => 3,
                      two     => 3,
                      three   => 3,
                      four    => 3,
                      five    => 3,
                      six     => 3,
                      seven   => 3,
                      eight   => 3,
                      nine    => [ 1, 2, 3, 4, 6 ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
             bless( {
                      one     => 4,
                      two     => 4,
                      three   => 4,
                      four    => 4,
                      five    => 4,
                      six     => 4,
                      seven   => 4,
                      eight   => 4,
                      nine    => [ 1, 2, 3, 4, 5, 8 ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
           ];
    is_deeply($stories, $expect,
              'Checking that _fetch_objects produces the correct object structure');
    # test limit
    $sql .= ' LIMIT 2';
    $stories = fetch_objects('Bric::Biz::Asset', \$sql, $fields, 4, undef, 2, undef);
    $_->{nine} = [sort { $a <=> $b } @{$_->{nine}}] for @$stories;
    $expect = [
             bless( {
                      one     => 1,
                      two     => 1,
                      three   => 1,
                      four    => 1,
                      five    => 1,
                      six     => 1,
                      seven   => 1,
                      eight   => 1,
                      nine    => [ 1, 2, 3, 4, 5, 6, 7 ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
             bless( {
                      one     => 2,
                      two     => 2,
                      three   => 2,
                      four    => 2,
                      five    => 2,
                      six     => 2,
                      seven   => 2,
                      eight   => 2,
                      nine    => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30 ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
           ];
    is_deeply($stories, $expect, 'limit of 2 gets first two objects');
    # test offset
    $sql =~ s/LIMIT 2//;
    $sql .= ' LIMIT ' . LIMIT_DEFAULT if LIMIT_DEFAULT;
    $sql .= ' OFFSET 2';
    $stories = fetch_objects('Bric::Biz::Asset', \$sql, $fields, 4, undef);
    $_->{nine} = [sort { $a <=> $b } @{$_->{nine}}] for @$stories;
    $expect = [
             bless( {
                      one     => 3,
                      two     => 3,
                      three   => 3,
                      four    => 3,
                      five    => 3,
                      six     => 3,
                      seven   => 3,
                      eight   => 3,
                      nine    => [ 1, 2, 3, 4, 6 ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
             bless( {
                      one     => 4,
                      two     => 4,
                      three   => 4,
                      four    => 4,
                      five    => 4,
                      six     => 4,
                      seven   => 4,
                      eight   => 4,
                      nine    => [ 1, 2, 3, 4, 5, 8 ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
           ];
    is_deeply($stories, $expect, 'offset of two gets last two objects');
    # test limit and offset together
    $sql =~ s/OFFSET 2/OFFSET 1/;
    $sql =~ s/LIMIT LIMIT_DEFAULT/LIMIT 2/ if LIMIT_DEFAULT;
    $stories = fetch_objects('Bric::Biz::Asset', \$sql, $fields, 4, undef, 2, 1);
    $_->{nine} = [sort { $a <=> $b } @{$_->{nine}}] for @$stories;
    $expect = [
             bless( {
                      one     => 2,
                      two     => 2,
                      three   => 2,
                      four    => 2,
                      five    => 2,
                      six     => 2,
                      seven   => 2,
                      eight   => 2,
                      nine    => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30 ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
             bless( {
                      one     => 3,
                      two     => 3,
                      three   => 3,
                      four    => 3,
                      five    => 3,
                      six     => 3,
                      seven   => 3,
                      eight   => 3,
                      nine    => [ 1, 2, 3, 4, 6 ],
                      _dirty  => 0,
                    }, 'Bric::Biz::Asset' ),
           ];
    is_deeply($stories, $expect, 'can use limit and offset together to return middle two objects');
    };

    my $err = $@;
    Bric::Util::DBI::execute(
      Bric::Util::DBI::prepare('DROP TABLE test_fetch_objects')
    ) if (DBD_TYPE eq "Pg");
    Bric::Util::DBI::execute(
      Bric::Util::DBI::prepare('DELETE FROM test_fetch_objects')
    ) if (DBD_TYPE eq "mysql");    
    die $err if $err;
}

1;
__END__
