#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

=pod

=begin comment

This script adds a tree function which constructs the full path for a given
category from it's category_grp_id.

=end comment

=cut

# This is PostgreSQL-specific, but that shouldn't matter, since PostgreSQL
# is the only supported database at this time, so no other database should
# need the patch.
exit if fetch_sql( qq{
       SELECT category_full_path(0), 1
} );

my @sql = (qq{
        CREATE FUNCTION category_full_path(INT) RETURNS VARCHAR AS'
        DECLARE v_category_grp_id ALIAS FOR $1
        ;
        DECLARE tmp_record RECORD
        ;
        DECLARE tmp_id VARCHAR
        ;
        DECLARE tmp_code VARCHAR
        ;
        BEGIN
            tmp_code:=''''
            ;
            SELECT INTO tmp_record 
                            category.id AS category_id,
                            category.directory AS directory,
                            grp.parent_id AS parent_id
            FROM        category, grp 
            WHERE       grp.id = v_category_grp_id
            AND         grp.id = category.category_grp_id
            ;
            IF NOT FOUND THEN
                RETURN ''''::varchar
                ;
            END IF
            ;
            IF tmp_record.category_id=0 THEN 
                RETURN tmp_record.directory
                ;
            END IF
            ;
            tmp_id:=category_full_path(tmp_record.parent_id)
            ;
            IF tmp_record.category_id<>0 THEN
                tmp_code:=tmp_id::varchar || '' '' || tmp_record.directory::varchar || ''''
            ;
            END IF
            ;
            RETURN tmp_code
            ;
        END
        ;
        ' LANGUAGE 'plpgsql'
        ;

    });

# install the function
do_sql( @sql );
