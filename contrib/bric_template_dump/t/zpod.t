#!perl -w

# $Id: zpod.t,v 1.1 2004/03/23 22:23:11 wheeler Exp $

use strict;
use Test::More;
use File::Spec::Functions 'curdir';
eval "use Test::Pod 1.06";
plan skip_all => "Test::Pod 1.06 required for testing POD" if $@;
all_pod_files_ok(Test::Pod::all_pod_files(curdir));
