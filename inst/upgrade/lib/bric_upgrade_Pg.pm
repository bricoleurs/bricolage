package bric_upgrade;

=pod

=head1 Name

bric_upgrade_Pg - Library with functions to assist upgrading a Bricolage PostgreSQL database.

=head1 Description

See L<bric_upgrade> for details.

=cut

use strict;
use constant super_user => 'postgres';
use constant super_pass => '';

##############################################################################
# Tell STDERR to ignore PostgreSQL NOTICE messages by forking another Perl to
# filter them out.
open STDERR, '| ' . ($ENV{PERL} || $^X) . q{ -ne 'print unless /^NOTICE:  /'}
  or die "Cannot pipe STDERR: $!\n";

##############################################################################

=head1 Exported Functions

=head2 test_table

  exit if test_table $table_to_add;

This function returns true if a table exists in the Bricolage database, and
false if it does not. Use C<test_table()> in an upgrade script that adds a new
table to the database to make sure that the script has not already been run.

=cut

sub test_table($) {
    my $table = shift;
    return fetch_sql(qq{
        SELECT 1
        FROM   pg_class c
        WHERE  relkind = 'r'
               AND relname = '$table'
    });
}

##############################################################################

=head2 test_column

  exit if test_column $table_name, $column_name;
  exit if test_column $table_name, $column_name, $min_size;
  exit if test_column $table_name, $column_name, undef, $not_null;
  exit if test_column $table_name, $column_name, $min_size, $not_null;
  exit if test_column $table_name, $column_name, $min_size, $not_null, $type;

This function returns true if the specified column exists in specified table
in the Bricolage database, and false if it does not. Use C<test_column()> in
an upgrade script that adds a new column to the database to make sure that the
script has not already been run.

An optional third argument specifies a minimum size for the specified column
("size" generally meaning the length of a VARCHAR column). The function will
return true if the column exists and has at least the size specified. This is
useful in upgrade scripts that are changing the size of a column.

An optional fourth argument specifies whether the column is C<NOT NULL>. Thus
the function will return true if the column exists I<and> is not null, and
false if the column doesn't exist or can store NULL values. B<Note:> This
function will return true if a column has been made C<NOT NULL> by the use of
a constraint rather than a C<NOT NULL> in the statement that created the
column.

An optional fifth argument specifies the column type. The function will return
true if the column exists and is of the specified type. Typical examples
include "integer", "smallint", "boolean", "text", and "character varying(64)".

Of course, if both optional arguments are passed to C<test_column()>, it will
test that the column exists, that it is at least the size specified, and that
it is C<NOT NULL>.

=cut

sub test_column($$;$$$) {
    my ($table, $column, $size, $not_null, $type) = @_;
    my $sql = qq{
        SELECT 1
        FROM   pg_attribute a, pg_class c
        WHERE  a.attrelid = c.oid
               and pg_table_is_visible(c.oid)
               AND c.relname = '$table'
               AND attnum > 0
               AND NOT attisdropped
               AND a.attname = '$column'
    };

    if (defined $size) {
        $sql .= "           AND a.atttypmod >= $size";
    }

    if (defined $not_null) {
        $not_null = $not_null ? 't' : 'f';
        $sql .= "           AND a.attnotnull = '$not_null'";
    }

    if (defined $type) {
        $sql .= "           AND format_type(a.atttypid, a.atttypmod) = '"
          . lc $type . "'";
    }

    return fetch_sql($sql)
}

##############################################################################

=head2 test_constraint

  exit if test_constraint $table_name, $constraint_name;
  exit if test_constraint $table_name, $constraint_name, $delete_code;

This function returns true if the specified constraint exists on the specified
table in the Bricolage database, and false if it does not. This is useful in
upgrade scripts that add a new constraint, and want to verify that the
constraint has not already been created. The optional third argument specifies
the code for the C<DELETE> control on the constraint. The possible values are
as follows:

  VALUE    ON DELETE...
  -----    ------------
    r      RESTRICT
    c      CASCACDE
    n      SET NULL
    a      NO ACTION
    d      SET DEFAULT

=cut

sub test_constraint($$;$) {
    my ($table, $con, $delcode) = @_;
    my $sql = qq{
        SELECT 1
        FROM   pg_class c, pg_constraint r
        WHERE  r.conrelid = c.oid
               AND c.relname = '$table'
               AND r.contype = 'c'
               AND r.conname = '$con'
    };
    $sql .= "           AND r.confdeltype = '$delcode'\n" if $delcode;
    return fetch_sql($sql);
}

##############################################################################

=head2 test_foreign_key

  exit if test_foreign_key $table_name, $foreign_key_name;
  exit if test_foreign_key $table_name, $foreign_key_name, $delete_code;

This function returns true if the specified foreign key constraint exists on
the specified table in the Bricolage database, and false if it does not. This
is useful in upgrade scripts that add a new foreign key, and want to verify
that the constraint has not already been created. The optional third argument
specifies the code for the C<DELETE> control on the foreign key
constraint. See the documentation for C<test_constraint()> for the possible
values for this argument.

=cut

sub test_foreign_key($$;$) {
    my ($table, $fk, $delcode) = @_;
    my $sql = qq{
        SELECT 1
        FROM   pg_class c, pg_constraint r
        WHERE  r.conrelid = c.oid
               AND c.relname = '$table'
               AND r.contype = 'f'
               AND r.conname = '$fk'
    };
    $sql .= "           AND r.confdeltype = '$delcode'\n" if $delcode;
    return fetch_sql($sql);
}

##############################################################################

=head2 test_primary_key

  exit if test_primary_key $table_name, $primary_key_name;

This function returns true if the specified primary key constraint exists on
the specified table in the Bricolage database, and false if it does not. This
is useful in upgrade scripts that add a new primary key, and want to verify
that the constraint has not already been created.

=cut

sub test_primary_key($$) {
    my ($table, $fk) = @_;
    my $sql = qq{
        SELECT 1
        FROM   pg_class c, pg_constraint r
        WHERE  r.conrelid = c.oid
               AND c.relname = '$table'
               AND r.contype = 'p'
               AND r.conname = '$fk'
    };
    return fetch_sql($sql);
}

##############################################################################

=head2 test_index

  exit if test_index $index_name;

This function returns true if the specified index exits in the Bricolage
database, and false if it does not. This is useful in upgrade scripts that add
a new index, and want to verify that the index has not already been created.

=cut

sub test_index($) {
    my $index = shift;
    return fetch_sql(qq{
        SELECT 1
        FROM   pg_class c,
               pg_index i
        WHERE  i.indexrelid = c.oid
               and c.relname = '$index'
    });
}

##############################################################################

=head2 test_function

  exit if test_function $function_name;

This function returns true if the specified function exits in the Bricolage
database, and false if it does not. This is useful in upgrade scripts that add
a new function, and want to verify that the function has not already been
created.

=cut

sub test_function($) {
    my $function = shift;
    return fetch_sql(qq{
        SELECT 1
        FROM   pg_proc p
        WHERE  p.prorettype <> 'pg_catalog.cstring'::pg_catalog.regtype
               AND p.proargtypes[0] <> 'pg_catalog.cstring'::pg_catalog.regtype
               AND NOT p.proisagg
               AND pg_catalog.pg_function_is_visible(p.oid)
               AND p.proname = '$function'
    });
}

##############################################################################

=head2 test_aggregate

  exit if test_aggregate $aggregate_name;

This aggregate returns true if the specified aggregate exits in the Bricolage
database, and false if it does not. This is useful in upgrade scripts that add
a new aggregate, and want to verify that the aggregate has not already been
created.

=cut

sub test_aggregate($) {
    my $aggregate = shift;
    return fetch_sql(qq{
        SELECT 1
        FROM   pg_proc p
        WHERE  p.proisagg
               AND pg_catalog.pg_function_is_visible(p.oid)
               AND p.proname = '$aggregate'
    });
}

##############################################################################

=head2 test_trigger

  exit if test_trigger $trigger_name;

This trigger returns true if the specified trigger exits in the Bricolage
database, and false if it does not. This is useful in upgrade scripts that add
a new trigger, and want to verify that the trigger has not already been
created.

=cut

sub test_trigger($) {
    my $trigger = shift;
    return fetch_sql(qq{
        SELECT 1
        FROM   pg_trigger p,
           pg_class c
        WHERE  p.tgrelid = c.oid
               AND p.tgname = '$trigger'
    });
}


##############################################################################

=head2 db_version()

  if (db_version() ge '7.3') {
      do_sql "ALTER TABLE foo DROP bar";
  }

This function returns the the version number of the database server we're
connected to. It can be used to determine what functionality is available in
order to perform different tasks. For example, PostgreSQL 7.3 and later
support dropping columns. Thus, the above exmple demonstrates checking that
the server is 7.3 or later before executing dropping a column.

=cut

my $version;

sub db_version() {
    return $version if $version;
    $version = col_aref("SELECT version()")->[0];
    $version =~ s/\s*PostgreSQL\s+(\d\.\d(\.\d)?).*/$1/;
    return $version;
}

1;
__END__

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric:Util::DBI|Bric::Util::DBI>
L<bric_upgrade>

=cut
