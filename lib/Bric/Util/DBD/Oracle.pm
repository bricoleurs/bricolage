package Bric::Util::DBD::Oracle;

=pod

=head1 Name

Bric::Util::DBD::Oracle - The Bricolage Oracle Driver

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=pod

=head1 Synopsis

In Bric::Util::DBI(1), just

  use Bric::Util::DBD::Oracle ':all';

=head1 Description

This module exports into Bric::Util::DBI's name space a number of
database-dependent functions and variables such that Bric::Util::DBI can interface
seamlessly with an Oracle database. See Bric::Util::DBI for details.
Bric::Util::DBD::Oracle should never be C<use>d in any other Bricolage class. Nor should
any other Bric::DBD::* driver.

The architecture of this module must be adapted to use Bric with other databases.
Use Bric::Util::DBD::Oracle as a template.

=head1 Interface

NONE.

=head2 Constructors

NONE.

=head2 Destructors

NONE.

=head2 Public Class Methods

NONE.

=head2 Public Instance Methods

NONE.

=head1 Private

NONE.

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use DBD::Oracle qw(:ora_types);
use Bric::Util::Fault qw(throw_ap);

################################################################################
# Constants
################################################################################
# This is the name of the DBI database driver - DBD::Oracle. Used by
# Bric::Util::DBI::_connect().
our $DBD = 'Oracle';

# This is the connection string that $dbh->connect() will use to connect to the
# database. Used by Bric::Util::DBI's &$connect() closure.
our $DSN = 'DEV.ABOUT.COM';

# This is the strftime format for dates in the Oracle database. Used by
# Bric::Util::Time::db_date().
our $DB_DATE_FORMAT = "%Y-%m-%d %T";

# This is the bind_col() and bind_param() argument needed for binding BLOBS.
#our $BLOB_TYPE = { ora_type => ORA_CLOB };
our $BLOB_TYPE = { ora_type => ORA_BLOB };

# This variable tells Bric::Util::DBI whether this driver supports transactions or
# not.
our $TRANSACTIONAL = 1;

################################################################################
# Inheritance
################################################################################
use base qw(Exporter);
our @EXPORT_OK = qw($DBD $DSN $DB_DATE_FORMAT last_key_sql next_key_sql
            db_date_parts $BLOB_TYPE $TRANSACTIONAL);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

################################################################################
# Private Functions
################################################################################
BEGIN {
    # Oracle requires that certain environment variables be set. Set them here.
    $ENV{ORACLE_HOME} = '/usr/local/oracle';
    $ENV{ORAPIPES} = 'V2';
    $ENV{EPC_DISABLED} = 'TRUE';
    $ENV{NLS_LANG} = 'english.UTF8';
    $ENV{NLS_DATE_FORMAT} = 'YYYY-MM-DD HH24:MI:SS';
} # BEGIN

################################################################################
# Exportable Functions
################################################################################
sub last_key_sql {
    # Returns the SQL to fetch the last key fetched by this process for a table.
    # Used by Bric::Util::DBI::last_key().
    my ($table_name, $db_name) = @_;
    $db_name .= $db_name ? '.' : '';
    return "SELECT ${db_name}seq_$table_name.CurrVal FROM dual";
} # last_key_sql()

################################################################################
sub next_key_sql {
    # Returns the SQL to fetch the next key for a table. Intended to be used
    # inside an INSERT query, not on its own. Used by Bric::Util::DBI::next_key().
    my ($table_name, $db_name) = @_;
    $db_name .= $db_name ? '.' : '';
    return "${db_name}seq_$table_name.NextVal";
} # next_key()

################################################################################
sub db_date_parts {
    # This function unpacks a date/time string as it is formatted for the
    # database and returns a list of time tokens for use by timelocal(). Used by
    # Bric::Util::Time::strfdate().
    my @t;
    eval { @t = unpack('a4 x a2 x a2 x a2 x a2 x a2', shift) };
    throw_ap(error => "Unable to unpack date: $@") if $@;
    $t[0] -= 1900;
    $t[1] -= 1;
    return reverse @t;
} # date_parts()

1;
__END__

=head1 Notes

NONE.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 See Also

L<Bric::Util::DBI|Bric::Util::DBI>

=cut
