package Bric::Util::DBI::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Util::DBI qw(:all);

my $CLASS = 'Bric::Util::DBI::Test';


# I'm just using the stuff from story for programming speed.
use constant TABLE      => 'story';

use constant VERSION_TABLE => 'story_instance';

use constant WHERE => 's.id = i.story__id';

use constant FROM => VERSION_TABLE . ' i, member m';
use constant ID_COL => 't.id';

use constant PARAM_FROM_MAP =>
    {
       category_id        =>  'story__category sc',
       category_uri       =>  'story__category sc',
       keyword            =>  'story_keyword sk, keyword k',
       simple             =>  'story s LEFT OUTER JOIN story_keyword sk LEFT OUTER JOIN keyword k ON (sk.keyword_id = k.id) ON (s.id = sk.story_id)',
       _not_simple        =>  TABLE . ' s',
    };

use constant RELATION_JOINS =>
    {
        story      => 'sm.object_id = s.id AND m.id = sm.member__id',
        category   => 'sc.story_instance__id = i.id AND cm.object_id = sc.category__id AND m.id = cm.member__id',
        desk       => 'dm.object_id = s.desk__id AND m.id = dm.member__id',
        workflow   => 'wm.object_id = s.workflow__id AND m.id = wm.member__id',
    };

use constant PARAM_WHERE_MAP =>
    {
      id                  => 's.id = ?',
      active              => 's.active = ?',
      inactive            => 's.active = ?',
      workflow__id        => 's.workflow__id = ?',
      _null_workflow__id  => 's.workflow__id IS NULL',
      primary_uri         => 'LOWER(s.primary_uri) LIKE LOWER(?)',
      element_type_id     => 's.element_type_id = ?',
      source__id          => 's.source__id = ?',
      priority            => 's.priority = ?',
      publish_status      => 's.publish_status = ?',
      publish_date_start  => 's.publish_date >= ?',
      publish_date_end    => 's.publish_date <= ?',
      cover_date_start    => 's.cover_date >= ?',
      cover_date_end      => 's.cover_date <= ?',
      expire_date_start   => 's.expire_date >= ?',
      expire_date_end     => 's.expire_date <= ?',
      desk_id             => 's.desk_id = ?',
      name                => 'LOWER(i.name) LIKE LOWER(?)',
      title               => 'LOWER(i.name) LIKE LOWER(?)',
      description         => 'LOWER(i.description) LIKE LOWER(?)',
      version             => 'i.version = ?',
      slug                => 'LOWER(i.slug) LIKE LOWER(?)',
      user__id             => 'i.usr__id = ?',
      _checked_out        => 'i.checked_out = ?',
      primary_oc_id       => 'i.primary_oc__id = ?',
      category_id         => 'i.id = c.story_instance__id AND c.category_id = ?',
      category_uri        => 'i.id = c.story_instance__id AND c.category__id in (SELECT id FROM category WHERE LOWER(uri) LIKE LOWER(?))',
      keyword             => 'sk.story_id = s.id AND k.id = sk.keyword_id AND LOWER(k.name) LIKE LOWER(?)',
      _no_return_versions => 's.current_version = i.version',
      grp_id              => 's.id IN ( SELECT DISTINCT sm.object_id FROM story_member sm, member m WHERE m.grp__id = ? AND sm.member__id = m.id )',
      simple              => '(LOWER(k.name) LIKE LOWER(?) OR LOWER(i.name) LIKE LOWER(?) OR LOWER(i.description) LIKE LOWER(?) OR LOWER(s.primary_uri) LIKE LOWER(?))',
    };

use constant PARAM_ANYWHERE_MAP => {
      keyword             => [ 'sk.story_id = s.id AND k.id = sk.keyword_id',
                               'LOWER(k.name) LIKE LOWER(?)' ],
};

use constant PARAM_ORDER_MAP =>
    {
      active              => 'active',
      inactive            => 'active',
      workflow__id        => 'workflow__id',
      primary_uri         => 'primary_uri',
      element_type_id     => 'element_type_id',
      source__id          => 'source__id',
      priority            => 'priority',
      publish_status      => 'publish_status',
      publish_date        => 'publish_date',
      cover_date          => 'cover_date',
      expire_date         => 'expire_date',
      name                => 'name',
      title               => 'name',
      description         => 'description',
      version             => 'version',
      version_id          => 'version_id',
      slug                => 'slug',
      user__id             => 'usr__id',
      _checked_out        => 'checked_out',
      primary_oc_id       => 'primary_oc__id',
      category_id         => 'category_id',
      category_uri        => 'uri',
      keyword             => 'name',
      return_versions     => 'version',
    };

use constant DEFAULT_ORDER => 'cover_date';


#### start tests

sub test_build_query: Test(2) {
    my $self = shift;
    ok( my $got = build_query('pkg', 'cols', 'grp_by', 'tables', 'where', 'order'),
        "Build query" );
    my $expected = q{  SELECT cols
                    FROM   tables
                    WHERE  where
                    grp_by
                    order
                 };
    $$got =~ s/\s+/ /gm; # ignore whitespace
    $expected =~ s/\s+/ /gm; # ignore whitespace
    is( $$got, $expected, 'check the normal query builder' );
}

sub test_where: Test(72) {
    my $self = shift;
    my (@match_count, $cols);
    my $base = 's.id = i.story__id'; # the base output
    my ($where, $args) = where_clause($CLASS, );
    is ( $where , $base, 'The minimal where clause' );
    # an argument *could* possibly be made for looping through these or
    # something, but it seems better for tests to be as literal as possible
    # otherwise all we would wind up doing is checking one hash literal
    # against another...
    # id
    ($cols, $args) = where_clause($CLASS, { id => 1 });
    is( $cols, $base . ' AND s.id = ?', 'check id param');
    is_deeply( $args, [1], ' ... and the arg');
    # active
    ($cols, $args) = where_clause($CLASS, { active => 1 });
    is( $cols, $base . ' AND s.active = ?', 'check active param');
    is_deeply( $args, [1], ' ... and the arg');
    # inactive
    ($cols, $args) = where_clause($CLASS, { inactive => 1 });
    is( $cols, $base . ' AND s.active = ?', 'check inactive param');
    is_deeply( $args, [1], ' ... and the arg');
    # workflow__id
    ($cols, $args) = where_clause($CLASS, { workflow__id => 1 });
    is( $cols, $base . ' AND s.workflow__id = ?', 'check workflow__id param');
    is_deeply( $args, [1], ' ... and the arg');
    # _null_workflow__id
    ($cols, $args) = where_clause($CLASS, { _null_workflow__id => 1 });
    is( $cols, $base . ' AND s.workflow__id IS NULL', 'check simple param');
    is_deeply( $args, [], ' ... and the arg');
    # primary_uri
    ($cols, $args) = where_clause($CLASS, { primary_uri => 1 });
    is( $cols, $base . ' AND LOWER(s.primary_uri) LIKE LOWER(?)', 'check primary_uri param');
    is_deeply( $args, [1], ' ... and the arg');
    # element_type_id
    ($cols, $args) = where_clause($CLASS, { element_type_id => 1 });
    is( $cols, $base . ' AND s.element_type_id = ?', 'check element_type_id param');
    is_deeply( $args, [1], ' ... and the arg');
    # source__id
    ($cols, $args) = where_clause($CLASS, { source__id => 1 });
    is( $cols, $base . ' AND s.source__id = ?', 'check source__id param');
    is_deeply( $args, [1], ' ... and the arg');
    # priority
    ($cols, $args) = where_clause($CLASS, { priority => 1 });
    is( $cols, $base . ' AND s.priority = ?', 'check priority param');
    is_deeply( $args, [1], ' ... and the arg');
    # publish_status
    ($cols, $args) = where_clause($CLASS, { publish_status => 1 });
    is( $cols, $base . ' AND s.publish_status = ?', 'check publish_status param');
    is_deeply( $args, [1], ' ... and the arg');
    # publish_date_start
    ($cols, $args) = where_clause($CLASS, { publish_date_start => 1 });
    is( $cols, $base . ' AND s.publish_date >= ?', 'check publish_date_start param');
    is_deeply( $args, [1], ' ... and the arg');
    # publish_date_end
    ($cols, $args) = where_clause($CLASS, { publish_date_end => 1 });
    is( $cols, $base . ' AND s.publish_date <= ?', 'check publish_date_end param');
    is_deeply( $args, [1], ' ... and the arg');
    # expire_date_start
    ($cols, $args) = where_clause($CLASS, { expire_date_start => 1 });
    is( $cols, $base . ' AND s.expire_date >= ?', 'check expire_date_start param');
    is_deeply( $args, [1], ' ... and the arg');
    # expire_date_end
    ($cols, $args) = where_clause($CLASS, { expire_date_end => 1 });
    is( $cols, $base . ' AND s.expire_date <= ?', 'check expire_date_end param');
    is_deeply( $args, [1], ' ... and the arg');
    # cover_date_start
    ($cols, $args) = where_clause($CLASS, { cover_date_start => 1 });
    is( $cols, $base . ' AND s.cover_date >= ?', 'check cover_date_start param');
    is_deeply( $args, [1], ' ... and the arg');
    # cover_date_end
    ($cols, $args) = where_clause($CLASS, { cover_date_end => 1 });
    is( $cols, $base . ' AND s.cover_date <= ?', 'check cover_date_end param');
    is_deeply( $args, [1], ' ... and the arg');
    # element_type_id
    ($cols, $args) = where_clause($CLASS, { element_type_id => 1 });
    is( $cols, $base . ' AND s.element_type_id = ?', 'check element_type_id param');
    is_deeply( $args, [1], ' ... and the arg');
    # name
    ($cols, $args) = where_clause($CLASS, { name => 1 });
    is( $cols, $base . ' AND LOWER(i.name) LIKE LOWER(?)', 'check name param');
    is_deeply( $args, [1], ' ... and the arg');
    # title
    ($cols, $args) = where_clause($CLASS, { title => 1 });
    is( $cols, $base . ' AND LOWER(i.name) LIKE LOWER(?)', 'check title param');
    is_deeply( $args, [1], ' ... and the arg');
    # description
    ($cols, $args) = where_clause($CLASS, { description => 1 });
    is( $cols, $base . ' AND LOWER(i.description) LIKE LOWER(?)', 'check description param');
    is_deeply( $args, [1], ' ... and the arg');
    # version
    ($cols, $args) = where_clause($CLASS, { version => 1 });
    is( $cols, $base . ' AND i.version = ?', 'check version param');
    is_deeply( $args, [1], ' ... and the arg');
    # slug
    ($cols, $args) = where_clause($CLASS, { slug => 1 });
    is( $cols, $base . ' AND LOWER(i.slug) LIKE LOWER(?)', 'check slug param');
    is_deeply( $args, [1], ' ... and the arg');
    # user__id
    ($cols, $args) = where_clause($CLASS, { user__id => 1 });
    is( $cols, $base . ' AND i.usr__id = ?', 'check user__id param');
    is_deeply( $args, [1], ' ... and the arg');
    # _checked_out
    ($cols, $args) = where_clause($CLASS, { _checked_out => 1 });
    is( $cols, $base . ' AND i.checked_out = ?', 'check _checked_out param');
    is_deeply( $args, [1], ' ... and the arg');
    # primary_oc_id
    ($cols, $args) = where_clause($CLASS, { primary_oc_id => 1 });
    is( $cols, $base . ' AND i.primary_oc__id = ?', 'check primary_oc__id param');
    is_deeply( $args, [1], ' ... and the arg');
    # category_id
    ($cols, $args) = where_clause($CLASS, { category_id => 1 });
    is( $cols, $base . ' AND i.id = c.story_instance__id AND c.category_id = ?', 'check category_id param');
    is_deeply( $args, [1], ' ... and the arg');
    # category_uri
    ($cols, $args) = where_clause($CLASS, { category_uri => 1 });
    is( $cols, $base . ' AND i.id = c.story_instance__id AND c.category__id in (SELECT id FROM category WHERE LOWER(uri) LIKE LOWER(?))', 'check category_uri param');
    is_deeply( $args, [1], ' ... and the arg');
    # keyword
    ($cols, $args) = where_clause($CLASS, { keyword => 1 });
    is( $cols, $base . ' AND sk.story_id = s.id AND k.id = sk.keyword_id AND LOWER(k.name) LIKE LOWER(?)', 'check keyword param');
    is_deeply( $args, [1], ' ... and the arg');
    # ANY(keyword)
    ($cols, $args) = where_clause($CLASS, { keyword => ANY('foo', 'bar') });
    is( $cols, $base . ' AND sk.story_id = s.id AND k.id = sk.keyword_id AND (LOWER(k.name) LIKE LOWER(?) OR LOWER(k.name) LIKE LOWER(?))', 'check ANY(keyword) param');
    is_deeply( $args, ['foo', 'bar'], ' ... and the arg');

    # return_versions
    ($cols, $args) = where_clause($CLASS, { _no_return_versions => 1 });
    is( $cols, $base . ' AND s.current_version = i.version', 'check _no_return_versions param');
    is_deeply( $args, [], ' ... and the arg');
    # grp_id
    ($cols, $args) = where_clause($CLASS, { grp_id => 1 });
    is( $cols, $base . ' AND s.id IN ( SELECT DISTINCT sm.object_id FROM story_member sm, member m WHERE m.grp__id = ? AND sm.member__id = m.id )', 'check grp__id param');
    is_deeply( $args, [1], ' ... and the arg');
    # simple
    ($cols, $args) = where_clause($CLASS, { simple => 1 });
    is( $cols, $base . ' AND (LOWER(k.name) LIKE LOWER(?) OR LOWER(i.name) LIKE LOWER(?) OR LOWER(i.description) LIKE LOWER(?) OR LOWER(s.primary_uri) LIKE LOWER(?))', 'check simple param');
    is_deeply( $args, [1, 1, 1, 1], ' ... and the arg');
    # try with as many params as we can come up with
    my $param = {
                    id                  => 1,
                    active              => 2,
                    workflow__id        => 3,
                    primary_uri         => 4,
                    element_type_id     => 5,
                    source__id          => 6,
                    priority            => 7,
                    publish_status      => 8,
                    publish_date_start  => 9,
                    publish_date_end    => 10,
                    cover_date_start    => 11,
                    cover_date_end      => 12,
                    expire_date_start   => 13,
                    expire_date_end     => 14,
                    name                => 15,
                    title               => 16,
                    description         => 17,
                    version             => 18,
                    slug                => 19,
                    user__id             => 20,
                    primary_oc_id       => 21,
                    category_id         => 22,
                    category_uri        => 23,
                    keyword             => 24,
                    _no_return_versions => 25,
                    grp_id              => 26,
                  };
    ($cols, $args) = where_clause($CLASS, $param);
    unlike( $cols, qr/^[ \t]*AND/, "musn't start with AND");
    unlike( $cols, qr/^[ \t]*AND/, "... or end with it");
    # make sure the AND doesn't get munged
    unlike( $cols, qr/[^ ]AND/, "AND needs a space in front of it");
    # args tests
    unlike( $cols, qr/AND[^ ]/, "... and a space in back");
    $args = [ sort { $a <=> $b } @$args ];
    is_deeply( $args, [  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 
                         11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 
                         21, 22, 23, 24, 26 ], 'a long list of args works');
    ($cols, $args) = where_clause($CLASS, { id => undef });
    is( $cols, $base, '... or into the column list');
    is( @$args, 0, 'test that undef args do not get into args list');
}

sub test_tables: Test(16) {
    my $self = shift;
    my @match_count;
    my $base = 'story_instance i, member m'; # the base output
    # does it work at all?
    is( tables($CLASS, ), $base, 'no params' );
    is( tables($CLASS, { active => 1 } ), $base, 'active param only');
    # test those params that effect the output
    is( tables($CLASS, { category_id => 0 } ), $base . ', story__category sc', 'category_id param');
    is( tables($CLASS, { category_uri => 0 } ), $base . ', story__category sc', 'category_uri param');
    is( tables($CLASS, { keyword => 'foo' } ), $base . ', story_keyword sk, keyword k', 'keyword param');
    is( tables($CLASS, { simple => 'foo' } ), $base . ', story s LEFT OUTER JOIN story_keyword sk LEFT OUTER JOIN keyword k ON (sk.keyword_id = k.id) ON (s.id = sk.story_id)', 'simple param');
    # we should be able to send both params, and still get just the one
    # instance of the table name
    is( tables($CLASS, { category_id => 0, category_uri => 0 }), 
            $base . ', story__category sc', 'both category params');
    # order doesn't matter in SQL let's just test that each table
    # name and alias appear one time exactly
    my $t = tables($CLASS, { category_id => 0, keyword => 'foo', _not_simple => 1});
    # the like and is pairs that follow are redundant, but having both of
    # them will provide better debugging info if something fails
    like( $t , qr/$base/, 'keyword and category together get base tables');
    @match_count = $t =~ /$base/g;
    is (@match_count, 1, '... exactly once');
    like( $t , qr/, story__category sc/, 'keyword and cat together get sc');
    @match_count = $t =~ / story__category sc/g;
    is (@match_count, 1, '... exactly once');
    like( $t , qr/, story_keyword sk/, 'keyword and cat together get sk');
    @match_count = $t =~ / story_keyword sk/g;
    is (@match_count, 1, '... exactly once');
    like( $t , qr/, keyword k/, 'keyword and cat together get k');
    @match_count = $t =~ / keyword k/g;
    is (@match_count, 1, '... exactly once');
    @match_count = $t =~ / story s/g;
    is (@match_count, 1, '... exactly once');
}

sub test_order_by: Test(9) {
    my $self = shift;
    my ($got, $expected);

    $got = eval { order_by($CLASS, { Order => 'name',
                                     OrderDirection => 'NORTH' }) };
    like( $@, qr/OrderDirection parameter must either ASC or DESC./,
      'bad order throws exception');

    $got = eval { order_by($CLASS, { Order => 'NORTH' }) };
    like( $@, qr/Bad Order parameter 'NORTH'/,
            'bad order throws exception');

    $got = order_by($CLASS, undef);
    is( $got, 'ORDER BY t.id' ,'missing order orders by ID');

    $got = order_by($CLASS, { Order => 'slug' });
    is( $got, 'ORDER BY slug, t.id', 'order works');

    $got = order_by($CLASS, { Order => 'slug', OrderDirection => 'ASC' });
    is( $got, 'ORDER BY slug ASC, t.id','order works with ASC');

    $got = order_by($CLASS, { Order => 'slug', OrderDirection => 'DESC' });
    is( $got, 'ORDER BY slug DESC, t.id', 'order works with DESC');

    # Try combining attributes.
    is order_by($CLASS, { Order => [qw(slug name) ] }),
        'ORDER BY slug, name, t.id',
        'order works with an array of attributes';

    is order_by($CLASS, {
        Order => [qw(slug name)],
        OrderDirection => ['ASC', 'DESC']
    }), 'ORDER BY slug ASC, name DESC, t.id',
        'order works with an array of attributes and directions';

    is order_by($CLASS, {
        Order => [qw(slug name)],
        OrderDirection => [undef, 'DESC']
    }), 'ORDER BY slug, name DESC, t.id',
        'order works with an array of attributes and one direction';

}

sub testclean_params: Test(8) {
    my $self = shift;
    my $exp;
    $exp = { 
             active => 1,
             _no_return_versions => 1,
             _not_simple => 1,
             _checked_in_or_out => 1,
             Order => 'cover_date',
           };
    is_deeply( clean_params($CLASS, undef), $exp, 'correct base params added');
    $exp = { 
             active => 1,
             _no_return_versions => 1,
             _not_simple => 1,
             _checked_in_or_out => 1,
             Order => 'slug',
           };
    is_deeply( clean_params($CLASS, { Order => 'slug' }), $exp, 'Order works right');
    $exp = { 
             active => 1,
             return_versions => 1,
             _not_simple => 1,
             _checked_in_or_out => 1,
             Order => 'cover_date',
           };
    is_deeply( clean_params($CLASS, { return_versions => 1 }), $exp, 'add return versions');
    $exp = { 
             active => 1,
             _no_return_versions => 1,
             simple => 1,
             _checked_in_or_out => 1,
             Order => 'cover_date',
           };
    is_deeply( clean_params($CLASS, {simple => 1}), $exp, 'simple sets itself and not _not_simple');
    # active <-> inactive
    $exp = { 
             active => 0,
             _no_return_versions => 1,
             _not_simple => 1,
             _checked_in_or_out => 1,
             Order => 'cover_date',
           };
    is_deeply( clean_params($CLASS, { inactive => 1 }), $exp, 'inactive sets active 0');
    $exp = { 
             active => 1,
             _no_return_versions => 1,
             _not_simple => 1,
             user__id => 1,
             _checked_out => 1,
             Order => 'cover_date',
           };
    is_deeply( clean_params($CLASS, { user__id => 1 }), $exp, 'set _checked_out to 1 for user__id');
    $exp = { 
             active => 1,
             _no_return_versions => 1,
             _not_simple => 1,
             _checked_out => 0,
             _not_checked_out => 0,
             Order => 'cover_date',
           };
    is_deeply( clean_params($CLASS, { checked_out => '' }), $exp,
               "set _checked_out to 0 when it's ''");
    $exp = { 
             active => 1,
             _no_return_versions => 1,
             _not_simple => 1,
             _null_workflow_id => 1,
             _checked_in_or_out => 1,
             Order => 'cover_date',
           };
    is_deeply( clean_params($CLASS, { workflow__id => undef }),
               $exp, 'undef workflow__id sets _null_workflow_id');
}


1;
__END__

