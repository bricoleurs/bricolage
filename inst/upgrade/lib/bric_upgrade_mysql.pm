package bric_upgrade;

=pod

=head1 Name

bric_upgrade_mysql - Library with functions to assist upgrading a Bricolage MySQL database.

=head1 Description

See L<bric_upgrade> for details.

=cut

use strict;
use constant super_user => 'root';
use constant super_pass => '';

my $db = Bric::Config::DB_NAME();

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
        FROM   information_schema.tables
        WHERE  table_schema = '$db'
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
        FROM   information_schema.columns a
        WHERE  a.table_schema= '$db'
               AND a.table_name = '$table'
               AND a.column_name = '$column'
    };

    if (defined $size) {
        $sql .= "           AND a.character_maximum_length >= $size";
    }

    if (defined $not_null) {
        $not_null = $not_null ? 't' : 'f';
        $sql .= "           AND a.is_nullable = '$not_null'";
    }

    if (defined $type) {
        $sql .= "           AND a.data_type = '"
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
        FROM   information_schema.table_constraints a
        WHERE  a.table_schema = '$db'
           AND a.table_name = '$table'
               AND r.constraint_type = 'CHECK'
               AND r.constraint_name = '$con'
    };
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
        FROM   information_schema.table_constraints a
        WHERE  a.table_schema = '$db'
           AND a.table_name = '$table'
               AND r.constraint_type = 'FOREIGN KEY'
               AND r.constraint_name = '$fk'
    };
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
        FROM   information_schema.table_constraints a
        WHERE  a.table_schema = '$db'
           AND a.table_name = '$table'
               AND r.constraint_type = 'PRIMARY KEY'
               AND r.constraint_name = '$fk'
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
        FROM   information_schema.statistics a
        WHERE  a.table_schema = '$db'
               and a.index_name = '$index'
    });
}

##############################################################################

=head2 test_function

  exit if test_function $function_name;

This function returns true if the specified function exits in the Bricolage
database, and false if it does not. This is useful in upgrade scripts that add
a new function, and want to verify that the function has not already been created.

=cut

sub test_function($) {
    my $function = shift;
    return fetch_sql(qq{
        SELECT 1
        FROM   information_schema.routines a
        WHERE  a.routine_schema = '$db'
               and a.routine_name = '$function'
    });
}

##############################################################################

=head2 test_trigger

  exit if test_trigger $trigger_name;

This function returns true if the specified trigger exits in the Bricolage
database, and false if it does not. This is useful in upgrade scripts that add
a new trigger, and want to verify that the trigger has not already been created.

=cut

sub test_trigger($) {
    my $trigger = shift;
    return fetch_sql(qq{
        SELECT 1
        FROM   information_schema.triggers a
        WHERE  a.trigger_schema = '$db'
               and a.trigger_name = '$trigger'
    });
}

##############################################################################

=head2 db_version()

  if (db_version() ge '7.3') {
      do_sql "ALTER TABLE foo DROP bar";
  }

This function returns the the version number of the database server we're
connected to. It can be used to determine what functionality is available in
order to perform different tasks.

=cut

my $version;

sub db_version() {
    return $version if $version;
    $version = col_aref("status")->[0];
    $version =~ s/\s*Distrib\s+(\d\.\d(\.\d)?).*/$1/;
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
