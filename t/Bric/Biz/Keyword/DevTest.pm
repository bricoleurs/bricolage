package Bric::Biz::Keyword::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Test::Exception;
use Bric::Biz::Keyword;
use Bric::Util::Grp::Keyword;
use Bric::Biz::Category;
use Bric::Biz::Asset::Business::Story::DevTest;
use Bric::Biz::Asset::Business::Media::DevTest;
use Bric::Util::Fault qw(isa_bric_exception);

my %init = ( name        => 'testing',
             sort_name   => 'TESTING',
             screen_name => 'Testing',
 );

sub table { 'keyword' }

##############################################################################
# Setup methods.
##############################################################################
# Setup some keywords to play with.
sub setup_keywords : Test(setup => 19) {
    my $self = shift;
    # Create a new keyword group.
    ok( my $grp = Bric::Util::Grp::Keyword->new
        ({ name => 'Test KeywordGrp' }),
        "Create group" );

    # Look up the default category object.
    ok( my $cat = Bric::Biz::Category->lookup({ id => 1 }),
        "Look up default site's root category object." );

    # Create test story and media objects.
    ok( my $story = Bric::Biz::Asset::Business::Story::DevTest->construct,
        "Construct story object" );
    ok( my $media = Bric::Biz::Asset::Business::Media::DevTest->construct,
        "Construct media object" );

    # Create some test records.
    my @keywords;
    for my $n (1..5) {
        my %args = %init;
        my $name = $args{name} .= " $n";
        if ($n % 2) {
            $args{sort_name} = uc $args{name};
            $args{screen_name} = ucfirst $args{name};
        }

        ok( my $keyword = Bric::Biz::Keyword->new(\%args), "Create '$name'" );
        ok( $keyword->save, "Save '$name'" );
        # Save the ID for deleting (delete the group, too!).
        my $id = $keyword->get_id;
        $self->add_del_ids($id);
        $grp->add_member({ obj => $keyword }) if $n % 2;

        # Add it to some objects.
        if ($n % 2) {
            $cat->add_keywords($keyword);
            $story->add_keywords($keyword);
            $media->add_keywords($keyword);
        }

        # Cache the new keyword.
        push @keywords, $keyword;
    }

    # Save the keywords
    $self->{test_keywords} = \@keywords;

    # Save the groups.
    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');
    $self->{test_grp} = $grp;

    # Save the objects.
    ok( $cat->save, "Save category" );
    $self->{category} = $cat;
    ok( $story->save, "Save story" );
    $self->add_del_ids($story->get_id, 'story');
    $self->{story} = $story;
    ok( $media->save, "Save media" );
    $self->add_del_ids($media->get_id, 'media');
    $self->{media} = $media;
}

##############################################################################
# Test constructors.
##############################################################################
# Test new().
sub test_new : Test(24) {
    my $self = shift;

    # Make sure that passing in an empty string to the new parameter throws
    # an exception.
    throws_ok { Bric::Biz::Keyword->new({ name => '' }) }
      'Bric::Util::Fault::Error::Undef', "Test new kw null string name";

    # Make sure that an attempt to assign an undefined value to name does the
    # same thing.
    throws_ok { $self->{test_keywords}[0]->set_name(undef) }
      'Bric::Util::Fault::Error::Undef', "Test set undefined name";

    # And finally, make sure that when we try to save a keyword with no
    # name, we get an exception.
    ok( my $kw = Bric::Biz::Keyword->new, "Construct Keyword" );
    throws_ok { $kw->save } 'Bric::Util::Fault::Error::Undef',
      "Test saving keyword without name";

    # In addition, make sure that when we create a keyword without a sort
    # name or a screen name, that they default to the value of the name
    # attribute.
    ok( $kw->set_name('Larry'), "Set name to 'Larry'" );
    is( $kw->get_name, 'Larry', "Name is 'Larry'" );
    is( $kw->get_screen_name, 'Larry', "Screen ame is 'Larry'" );
    is( $kw->get_sort_name, 'Larry', "Sort name is 'Larry'" );

    # Save it and look it up again to make sure that those values persisted.
    ok( $kw->save, "Save keyword" );
    ok( my $kid = $kw->get_id, "Get ID" );
    $self->add_del_ids($kid);
    ok( $kw = $kw->lookup({ id => $kid}), "Look it up" );
    is( $kw->get_name, 'Larry', "Name is 'Larry'" );
    is( $kw->get_screen_name, 'Larry', "Screen ame is 'Larry'" );
    is( $kw->get_sort_name, 'Larry', "Sort name is 'Larry'" );

    # Also make sure that if we change the name, it doesn't change the
    # values of the sort name or the screen name.
    ok( $kw->set_name('Damian'), "Set name to 'Damian'" );
    is( $kw->get_name, 'Damian', "Name is 'Damian'" );
    is( $kw->get_screen_name, 'Larry', "Screen ame is 'Larry'" );
    is( $kw->get_sort_name, 'Larry', "Sort name is 'Larry'" );

    # Save it and look it up again to make sure that those values persisted.
    ok( $kw->save, "Save keyword" );
    ok( $kw = $kw->lookup({ id => $kid}), "Look it up" );
    is( $kw->get_name, 'Damian', "Name is 'Damian'" );
    is( $kw->get_screen_name, 'Larry', "Screen name is 'Larry'" );
    is( $kw->get_sort_name, 'Larry', "Sort name is 'Larry'" );

    # Now try to create a keyword with the same name as an existing keyword.
    throws_ok { $kw->new({ name => $kw->get_name }) }
      'Bric::Util::Fault::Error::NotUnique', "Test for non-unique keyword";
}

##############################################################################
# Test lookup().
sub test_lookup : Test(10) {
    my $self = shift;

    ok( my $sid = $self->{test_keywords}[0]->get_id, "Get keyword ID" );

    # Try ID.
    ok( my $keyword = Bric::Biz::Keyword->lookup({ id => $sid }),
        "Look up ID '$sid'" );
    isa_ok($keyword, 'Bric::Biz::Keyword');
    is( $keyword->get_id, $sid, "Keyword ID is '$sid'" );

    # Try a bogus ID.
    ok( ! Bric::Biz::Keyword->lookup({ id => -1 }), "Look up bogus ID" );

    # Try name.
    my $name = "$init{name} 1";
    ok( $keyword = Bric::Biz::Keyword->lookup({ name => $name }),
        "Look up '$name'" );
    isa_ok($keyword, 'Bric::Biz::Keyword');
    is( $keyword->get_name, "$name", "Check name is '$name'" );

    # Try a bogus name.
    ok( ! Bric::Biz::Keyword->lookup({ name => -1 }), "Look up bogus name" );

    # Try too many keywords by name.
    throws_ok { Bric::Biz::Keyword->lookup({ name => "$init{name}%" }) }
    'Bric::Util::Fault::Exception::DA', "Is a Exception::DA exception";
}

##############################################################################
# Test list().
sub test_list : Test(46) {
    my $self = shift;

    # Try name.
    my @keywords = Bric::Biz::Keyword->list({ name => $init{name} });
    is( scalar @keywords, 0, "Check for 0 keywords" );

    # Try name + wildcard.
    ok( @keywords = Bric::Biz::Keyword->list({ name => "$init{name}%" }),
        "List name '$init{name}%'" );
    is( scalar @keywords, 5, "Check for 5 keywords" );

    # Try a bogus name.
    ok( ! Bric::Biz::Keyword->list({ name => -1 }), "List bogus name" );

    # Try screen_name.
    ok( @keywords = Bric::Biz::Keyword->list
        ({ screen_name => $init{screen_name} }),
        "List screen name '$init{screen_name}'" );
    is( scalar @keywords, 2, "Check for 2 keywords" );

    # Try screen_name + wildcard.
    ok( @keywords = Bric::Biz::Keyword->list
        ({ screen_name => "$init{screen_name}%" }),
        "List screen name '$init{screen_name}%'" );
    is( scalar @keywords, 5, "Check for 5 keywords" );

    # Try a bogus screen_name.
    ok( ! Bric::Biz::Keyword->list({ screen_name => -1 }),
        "List bogus screen name" );

    # Try sort_name.
    ok( @keywords = Bric::Biz::Keyword->list
        ({ sort_name => $init{sort_name} }),
        "List sort name '$init{sort_name}'" );
    is( scalar @keywords, 2, "Check for 2 keywords" );

    # Try sort_name + wildcard.
    ok( @keywords = Bric::Biz::Keyword->list
        ({ sort_name => "$init{sort_name}%" }),
        "List sort name '$init{sort_name}%'" );
    is( scalar @keywords, 5, "Check for 5 keywords" );

    # Try a bogus sort_name.
    ok( ! Bric::Biz::Keyword->list({ sort_name => -1 }),
        "List bogus sort name" );

    # Try the objects we've used to create associations.
    foreach my $key (qw(category story media)) {
        my $obj = $self->{$key};
        ok( @keywords = Bric::Biz::Keyword->list({ object => $obj }),
            "List by $key object" );
        is( scalar @keywords, 3, "Check for 3 keywords" );

        # Try removing a keyword from the object.
        ok( $obj->del_keywords($keywords[0]), "Delete keyword from $key" );
        ok( $obj->save, "Save $key" );
        ok( @keywords = Bric::Biz::Keyword->list({ object => $obj }),
            "List by $key object" );
        is( scalar @keywords, 2, "Check for 2 keywords" );
    }

    # Try grp_id.
    my $grp = $self->{test_grp};
    my $grp_id = $grp->get_id;
    ok( @keywords = Bric::Biz::Keyword->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar @keywords, 3, "Check for 3 keywords" );
    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Biz::Keyword::INSTANCE_GROUP_ID;
    foreach my $keyword (@keywords) {
        is_deeply( [sort { $a <=> $b } $keyword->get_grp_ids],
                   [$all_grp_id, $grp_id],
                   "Check for both IDs" );
    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $keywords[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @keywords = Bric::Biz::Keyword->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @keywords, 2, "Check for 2 keywords" );

    # Try active.
    ok( @keywords = Bric::Biz::Keyword->list({ active => 1}), "List active => 1" );
    is( scalar @keywords, 5, "Check for 5 keywords" );

    # Deactivate one and make sure it doesn't come back.
    ok( $self->{test_keywords}[0]->deactivate->save,
        "Deactivate and save a keyword" );
    ok( @keywords = Bric::Biz::Keyword->list({ active => 1}),
        "List active => 1 again" );
    is( scalar @keywords, 4, "Check for 4 keywords" );
}

##############################################################################
# Test href().
sub test_href : Test(44) {
    my $self = shift;

    # Try name.
    my $keywords = Bric::Biz::Keyword->href({ name => $init{name} });
    is( scalar keys %$keywords, 0, "Check for 0 keywords" );

    # Try name + wildcard.
    ok( $keywords = Bric::Biz::Keyword->href({ name => "$init{name}%" }),
        "List name '$init{name}%'" );
    is( scalar keys %$keywords, 5, "Check for 5 keywords" );

    # Check the hash keys.
    while (my ($id, $keyword) = each %$keywords) {
        is($id, $keyword->get_id, "Check keyword ID '$id'" );
    }

    # Try a bogus name.
    is_deeply(Bric::Biz::Keyword->href({ name => -1 }) , {},
              "List bogus name" );

    # Try screen_name.
    ok( $keywords = Bric::Biz::Keyword->href
        ({ screen_name => $init{screen_name} }),
        "List screen name '$init{screen_name}'" );

    is( scalar keys %$keywords, 2, "Check for 2 keywords" );

    # Try screen_name + wildcard.
    ok( $keywords = Bric::Biz::Keyword->href
        ({ screen_name => "$init{screen_name}%" }),
        "List screen name '$init{screen_name}%'" );
    is( scalar keys %$keywords, 5, "Check for 5 keywords" );

    # Try a bogus screen_name.
    is_deeply( Bric::Biz::Keyword->href({ screen_name => -1 }), {},
        "List bogus screen name" );

    # Try sort_name.
    ok( $keywords = Bric::Biz::Keyword->href
        ({ sort_name => $init{sort_name} }),
        "List sort name '$init{sort_name}'" );

    is( scalar keys %$keywords, 2, "Check for 2 keywords" );

    # Try sort_name + wildcard.
    ok( $keywords = Bric::Biz::Keyword->href
        ({ sort_name => "$init{sort_name}%" }),
        "List sort name '$init{sort_name}%'" );
    is( scalar keys %$keywords, 5, "Check for 5 keywords" );

    # Try a bogus sort_name.
    is_deeply( Bric::Biz::Keyword->href({ sort_name => -1 }), {},
        "List bogus sort name" );

    # Try the objects we've used to create associations.
    foreach my $key (qw(category story media)) {
        my $obj = $self->{$key};
        ok( $keywords = Bric::Biz::Keyword->href({ object => $obj }),
            "List by $key object" );
        is( scalar keys %$keywords, 3, "Check for 3 keywords" );

        # Try removing a keyword from the object.
        my ($kw) = values %$keywords;
        ok( $obj->del_keywords($kw), "Delete keyword from $key" );
        ok( $obj->save, "Save $key" );
        ok( $keywords = Bric::Biz::Keyword->href({ object => $obj }),
            "List by $key object" );
        is( scalar keys %$keywords, 2, "Check for 2 keywords" );
    }

    # Try grp_id.
    my $grp = $self->{test_grp};
    my $grp_id = $grp->get_id;
    ok( $keywords = Bric::Biz::Keyword->href({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar keys %$keywords, 3, "Check for 3 keywords" );

    # Try active.
    ok( $keywords = Bric::Biz::Keyword->href({ active => 1}),
         "List active => 1" );
    is( scalar keys %$keywords, 5, "Check for 5 keywords" );

    # Deactivate one and make sure it doesn't come back.
    ok( $self->{test_keywords}[0]->deactivate->save,
        "Deactivate and save a keyword" );
    ok( $keywords = Bric::Biz::Keyword->href({ active => 1}),
        "List active => 1 again" );
    is( scalar keys %$keywords, 4, "Check for 4 keywords" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test list().
sub test_list_ids : Test(43) {
    my $self = shift;

    # Try name.
    my @keyword_ids = Bric::Biz::Keyword->list_ids({ name => $init{name} });
    is( scalar @keyword_ids, 0, "Check for 0 keyword IDs" );

    # Try name + wildcard.
    ok( @keyword_ids = Bric::Biz::Keyword->list_ids({ name => "$init{name}%" }),
        "List IDs name '$init{name}%'" );
    is( scalar @keyword_ids, 5, "Check for 5 keyword IDs" );

    # Try a bogus name.
    ok( ! Bric::Biz::Keyword->list_ids({ name => -1 }),
        "List IDs bogus name" );

    # Try screen_name.
    ok( @keyword_ids = Bric::Biz::Keyword->list_ids
        ({ screen_name => $init{screen_name} }),
        "List IDs screen name '$init{screen_name}'" );

    is( scalar @keyword_ids, 2, "Check for 2 keyword IDs" );

    # Try screen_name + wildcard.
    ok( @keyword_ids = Bric::Biz::Keyword->list_ids
        ({ screen_name => "$init{screen_name}%" }),
        "List IDs screen name '$init{screen_name}%'" );
    is( scalar @keyword_ids, 5, "Check for 5 keyword IDs" );

    # Try a bogus screen_name.
    ok( ! Bric::Biz::Keyword->list_ids({ screen_name => -1 }),
        "List IDs bogus screen name" );

    # Try sort_name.
    ok( @keyword_ids = Bric::Biz::Keyword->list_ids
        ({ sort_name => $init{sort_name} }),
        "List IDs sort name '$init{sort_name}'" );

    is( scalar @keyword_ids, 2, "Check for 2 keyword IDs" );

    # Try sort_name + wildcard.
    ok( @keyword_ids = Bric::Biz::Keyword->list_ids
        ({ sort_name => "$init{sort_name}%" }),
        "List IDs sort name '$init{sort_name}%'" );
    is( scalar @keyword_ids, 5, "Check for 5 keyword IDs" );

    # Try a bogus sort_name.
    ok( ! Bric::Biz::Keyword->list_ids({ sort_name => -1 }),
        "List IDs bogus sort name" );

    # Try the objects we've used to create associations.
    foreach my $key (qw(category story media)) {
        my $obj = $self->{$key};
        ok( @keyword_ids = Bric::Biz::Keyword->list_ids({ object => $obj }),
            "List IDs by $key object" );
        is( scalar @keyword_ids, 3, "Check for 3 keyword IDs" );

        # Try removing a keyword from the object.
        ok( $obj->del_keywords($keyword_ids[0]), "Delete keyword from $key" );
        ok( $obj->save, "Save $key" );
        ok( @keyword_ids = Bric::Biz::Keyword->list({ object => $obj }),
            "List by $key object" );
        is( scalar @keyword_ids, 2, "Check for 2 keyword IDs" );
    }

    # Try grp_id.
    my $grp = $self->{test_grp};
    my $grp_id = $grp->get_id;
    ok( @keyword_ids = Bric::Biz::Keyword->list_ids({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar @keyword_ids, 3, "Check for 3 keyword IDs" );

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $self->{test_keywords}[0] }),
        "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @keyword_ids = Bric::Biz::Keyword->list_ids({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @keyword_ids, 2, "Check for 2 keyword IDs" );

    # Try active.
    ok( @keyword_ids = Bric::Biz::Keyword->list_ids({ active => 1}),
        "List IDs active => 1" );
    is( scalar @keyword_ids, 5, "Check for 5 keyword IDs" );

    # Deactivate one and make sure it doesn't come back.
    ok( $self->{test_keywords}[0]->deactivate->save,
        "Deactivate and save a keyword" );
    ok( @keyword_ids = Bric::Biz::Keyword->list_ids({ active => 1}),
        "List IDs active => 1 again" );
    is( scalar @keyword_ids, 4, "Check for 4 keyword IDs" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test save() method (and the instance methods, while we're at it!).
sub test_save : Test(33) {
    my $self = shift;
    my $keyword = $self->{test_keywords}[0];
    my ($name, $screen, $sort) = ('save', 'Save', 'SAVE');
    ok( $keyword->set_name($name), "Change name" );
    is( $keyword->get_name, $name, "Check name" );
    ok( $keyword->set_screen_name($screen), "Change screen name" );
    is( $keyword->get_screen_name, $screen, "Check screen name" );
    ok( $keyword->set_sort_name($sort), "Change sort name" );
    is( $keyword->get_sort_name, $sort, "Check sort name" );
    ok( $keyword->is_active, "Check is active" );
    ok( my $grp_ids = $keyword->get_grp_ids, "Get group IDs" );
    isa_ok( $grp_ids, 'ARRAY', "Check group IDs are in an array" );
    # There could be other group IDs, but we can't know what they are now.
    ok( scalar @$grp_ids >= 1, "Check for at least one group ID" );
    ok( $keyword->save, "Save keyword" );

    # Look it up in the database and verify the values.
    ok( $keyword = $keyword->lookup({ id => $keyword->get_id }), "Look up keyword" );
    is( $keyword->get_name, $name, "Check name" );
    is( $keyword->get_screen_name, $screen, "Check screen name" );
    is( $keyword->get_sort_name, $sort, "Check sort name" );
    ok( $keyword->is_active, "Check is active" );
    ok( $grp_ids = $keyword->get_grp_ids, "Get group IDs" );
    isa_ok( $grp_ids, 'ARRAY', "Check group IDs are in an array" );
    ok( scalar @$grp_ids >= 2, "Check for at least two group IDs" );

    # Do it again, this time also deactivating.
    ($name, $screen, $sort) = ('ick', 'Ick', 'ICK');
    ok( $keyword->set_name($name), "Change name" );
    is( $keyword->get_name, $name, "Check name" );
    ok( $keyword->set_screen_name($screen), "Change screen name" );
    is( $keyword->get_screen_name, $screen, "Check screen name" );
    ok( $keyword->set_sort_name($sort), "Change sort name" );
    is( $keyword->get_sort_name, $sort, "Check sort name" );
    ok( $keyword->deactivate, "Deactivate keyword" );
    ok( $keyword->save, "Save keyword" );

    # Look it up in the database and verify the values again.
    ok( $keyword = $keyword->lookup({ id => $keyword->get_id }), "Look up keyword" );
    is( $keyword->get_name, $name, "Check name" );
    is( $keyword->get_screen_name, $screen, "Check screen name" );
    is( $keyword->get_sort_name, $sort, "Check sort name" );
    ok( ! $keyword->is_active, "Check is not active" );
    is_deeply( [ sort { $a <=> $b } $keyword->get_grp_ids],
               [ sort { $a <=> $b } @$grp_ids],
               "Check group IDs" );
}

1;
__END__
