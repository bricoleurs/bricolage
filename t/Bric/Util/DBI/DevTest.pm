package Bric::Util::DBI::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Util::DBI qw(:all);

##############################################################################
# Set up a flat version of the story for easy testing of _fetch_objects
##############################################################################
sub test_fetch_objects: Test(4) {
    my $self = shift;
    # drop to prevent sql errors that wouldn't tell us anything anyhow
    eval { Bric::Util::DBI::execute(
      Bric::Util::DBI::prepare('DROP TABLE test_fetch_objects') ) };
    # create a fake story table. It doesn't need to have
    # the same structure as the real ones, it just needs
    # to produce the same result
    Bric::Util::DBI::execute( Bric::Util::DBI::prepare(q{
         CREATE TABLE test_fetch_objects (
                one        NUMERIC(10,0) NULL,
                two        NUMERIC(10,0) NULL,
                three      NUMERIC(10,0) NULL,
                four       NUMERIC(10,0) NULL,
                five       NUMERIC(10,0) NULL,
                six        NUMERIC(10,0) NULL,
                seven      NUMERIC(10,0) NULL,
                eight      NUMERIC(10,0) NULL,
                nine       NUMERIC(10,0) NULL,
                ten        NUMERIC(10,0) NULL,
                eleven     NUMERIC(10,0) NULL,
                twelve     NUMERIC(10,0) NULL
            ) }));

    my $sth = prepare(q{
        INSERT INTO test_fetch_objects (
            one, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve
        ) VALUES (
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        )
    });

    for my $row ([1, 1, 1, 1, 1, 1, 1, 1, 1, undef, undef, 1],
                 [1, 1, 1, 1, 1, 1, 1, 1, 1, 4, undef, 2],
                 [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3],

                 [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 1],
                 [2, 2, 2, 2, 2, 2, 2, 2, 2, 5, 2, 2],
                 [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 3],

                 [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1],
                 [3, 3, 3, 3, 3, 3, 3, 3, 6, 3, 3, 2],
                 [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3],

                 [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1],
                 [4, 4, 4, 4, 4, 4, 4, 4, 4, 8, 4, 2],
                 [4, 4, 4, 4, 4, 4, 4, 4, 7, 4, 4, 3],
             ) {
        execute($sth, @$row);
    }

    # check that _fetch_objects produces the right objs
    my $sql = q{ SELECT one, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve
                 FROM test_fetch_objects
                 ORDER BY one, twelve ASC };
    my $fields = [ qw( one two three four five six seven eight nine ) ];
    my $stories = fetch_objects('Bric', $sql, $fields, undef, undef, undef);
    $_->{nine} = [sort @{$_->{nine}}] for @$stories;
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
                      nine    => [ 1, 2, 3, 4 ],
                      _dirty  => 0,
                    }, 'Bric' ),
             bless( {
                      one     => 2,
                      two     => 2,
                      three   => 2,
                      four    => 2,
                      five    => 2,
                      six     => 2,
                      seven   => 2,
                      eight   => 2,
                      nine    => [ 1, 2, 3, 4, 5 ],
                      _dirty  => 0,
                    }, 'Bric' ),
             bless( {
                      one     => 3,
                      two     => 3,
                      three   => 3,
                      four    => 3,
                      five    => 3,
                      six     => 3,
                      seven   => 3,
                      eight   => 3,
                      nine    => [ 1, 2, 3, 6 ],
                      _dirty  => 0,
                    }, 'Bric' ),
             bless( {
                      one     => 4,
                      two     => 4,
                      three   => 4,
                      four    => 4,
                      five    => 4,
                      six     => 4,
                      seven   => 4,
                      eight   => 4,
                      nine    => [ 1, 2, 3, 4, 7, 8 ],
                      _dirty  => 0,
                    }, 'Bric' ),
           ];
    is_deeply($stories, $expect, 'Checking that _fetch_objects produces the correct object structure');
    # test limit
    $stories = fetch_objects('Bric', $sql, $fields, undef, 2, undef);
    $_->{nine} = [sort @{$_->{nine}}] for @$stories;
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
                      nine    => [ 1, 2, 3, 4 ],
                      _dirty  => 0,
                    }, 'Bric' ),
             bless( {
                      one     => 2,
                      two     => 2,
                      three   => 2,
                      four    => 2,
                      five    => 2,
                      six     => 2,
                      seven   => 2,
                      eight   => 2,
                      nine    => [ 1, 2, 3, 4, 5 ],
                      _dirty  => 0,
                    }, 'Bric' ),
           ];
    is_deeply($stories, $expect, 'limit of 2 gets first two objects');
    # test offset
    $stories = fetch_objects('Bric', $sql, $fields, undef, undef, 2);
    $_->{nine} = [sort @{$_->{nine}}] for @$stories;
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
                      nine    => [ 1, 2, 3, 6 ],
                      _dirty  => 0,
                    }, 'Bric' ),
             bless( {
                      one     => 4,
                      two     => 4,
                      three   => 4,
                      four    => 4,
                      five    => 4,
                      six     => 4,
                      seven   => 4,
                      eight   => 4,
                      nine    => [ 1, 2, 3, 4, 7, 8 ],
                      _dirty  => 0,
                    }, 'Bric' ),
           ];
    is_deeply($stories, $expect, 'offset of two gets last two objects');
    # test limit and offset together
    $stories = fetch_objects('Bric', $sql, $fields, undef, 2, 1);
    $_->{nine} = [sort @{$_->{nine}}] for @$stories;
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
                      nine    => [ 1, 2, 3, 4, 5 ],
                      _dirty  => 0,
                    }, 'Bric' ),
             bless( {
                      one     => 3,
                      two     => 3,
                      three   => 3,
                      four    => 3,
                      five    => 3,
                      six     => 3,
                      seven   => 3,
                      eight   => 3,
                      nine    => [ 1, 2, 3, 6],
                      _dirty  => 0,
                    }, 'Bric' ),
           ];
    is_deeply($stories, $expect, 'can use limit and offset together to return middle two objects');
    # drop the test objects
    Bric::Util::DBI::execute( Bric::Util::DBI::prepare('DROP TABLE test_fetch_objects'));

}

1;
__END__
