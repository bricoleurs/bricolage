#!/usr/bin/perl

use strict;
use Test;
BEGIN { plan tests => 29 };
use Bric::Biz::OutputChannel;
ok(1); # If we made it this far, we're ok.

my $param = {
	     name        => 'mike\'s test5',
	     description => 'a fun test',
	     tile_aware  => 1,
	     primary     => 1,
	     pre_path    => 'foo',
	     post_path   => 'en',
	     active      => 1
};

# Construct a new OC.
ok( my $oc = Bric::Biz::OutputChannel->new($param) );
ok( $oc->save );
ok( my $id = $oc->get_id );

# Okay, now lookup an existing one.
ok( $oc = Bric::Biz::OutputChannel->lookup({ id => $id }) );
ok( $oc->get_id == $id);

# Test all the instance methods.
ok( my $id = $oc->get_id );
ok( $oc->get_name eq 'mike\'s test5' );
ok( $oc->set_name('Another test!!!') );
ok( $oc->get_description eq 'a fun test');
ok( $oc->set_description('fun, fun, fun!') );

ok( $oc->get_primary );
ok( $oc->set_primary(undef) );
ok( !$oc->get_primary );
ok( $oc->set_primary(1) );
ok( $oc->get_primary );

ok( $oc->get_pre_path eq 'foo' );
ok( $oc->set_pre_path('bar') );
ok( $oc->get_post_path eq 'en');
ok( $oc->set_post_path('fr') );

ok( $oc->is_active );
ok( $oc->deactivate );
ok( !$oc->is_active );
ok( $oc->activate );
ok( $oc->is_active );
ok( $oc->save );


# Okay, now get a list.
ok( my @ocs = Bric::Biz::OutputChannel->list({ name => 'Another test!!!' }) );
ok( $ocs[0]->get_id );

# Now clean up.
Bric::Util::DBI::prepare(qq{
    DELETE FROM output_channel
    WHERE  id = $id
})->execute;

ok(1); # Success!
