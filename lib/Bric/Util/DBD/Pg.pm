package Bric::Util::DBD::Pg;

=pod

=head1 NAME

Bric::Util::DBD::Pg - The Bricolage PostgreSQL Driver

=head1 VERSION

$Revision: 1.8.6.1 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.8.6.1 $ )[-1];

=pod

=head1 DATE

$Date: 2003/08/30 20:59:58 $

=head1 SYNOPSIS

In Bric::Util::DBI(1), just

  use Bric::Util::DBD::Pg ':all';

=head1 DESCRIPTION

This module exports into Bric::Util::DBIs name space a number of
database-dependent functions and variables such that Bric::Util::DBI can interface
seamlessly with a PostgreSQL database. See Bric::Util::DBI for details.
Bric::Util::DBD::Pg should never be C<use>d in any other Bricolage class. Nor should any
other Bric::DBD::* driver.

=head1 INTERFACE

NONE.

=head2 Constructors

NONE.

=head2 Destructors

NONE.

=head2 Public Class Methods

NONE.

=head2 Public Instance Methods

NONE.

=head1 PRIVATE

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

use DBD::Pg;
use Bric::Config qw(:dbi);

################################################################################
# Constants
################################################################################

# This variable tells Bric::Util::DBI whether this driver supports transactions
use constant TRANSACTIONAL => 1;
use constant DSN_STRING => 'dbname=' . DB_NAME
  . (DB_HOST ? eval "';host=' . DB_HOST" : '')
  . (DB_PORT ? eval "';port=' . DB_PORT" : '');

################################################################################
# Inheritance
################################################################################
use base qw(Exporter);
our @EXPORT_OK = qw(last_key_sql next_key_sql db_date_parts DSN_STRING
		    TRANSACTIONAL);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

################################################################################
# Private Functions
################################################################################
BEGIN {
    $ENV{PGTZ} = 'UTC';
    $ENV{PGDATESTYLE} = 'ISO';
#    $ENV{PGCLIENTENCODING} = 'UNICODE'; # Should default to this, anyway.
#    $ENV{PGSERVERENCODING} = 'UNICODE'; # Should default to this, anyway.
} # BEGIN

################################################################################
# Exportable Functions
################################################################################
sub last_key_sql {
    # Returns the SQL to fetch the last key fetched by this process for a table.
    # Used by Bric::Util::DBI::last_key().
    my ($table_name, $db_name) = @_;
    $db_name .= $db_name ? '.' : '';
    return "SELECT CURRVAL('${db_name}seq_$table_name')";
} # last_key_sql()

################################################################################
sub next_key_sql {
    # Returns the SQL to fetch the next key for a table. Intended to be used
    # inside an INSERT query, not on its own. Used by Bric::Util::DBI::next_key().
    my ($table_name, $db_name) = @_;
    $db_name .= $db_name ? '.' : '';
    return $db_name . "NEXTVAL('${db_name}seq_$table_name')";
} # next_key()

################################################################################
sub db_date_parts {
    # This function unpacks a date/time string as it is formatted for the
    # database and returns a list of time tokens for use by timelocal(). Used by
    # Bric::Util::Time::strfdate().
    my @t;
    eval { @t = unpack('a4 x a2 x a2 x a2 x a2 x a2', shift) };
    die Bric::Util::Fault::Exception::AP->new(
      { msg => "Unable to unpack date: $@" }) if $@;
    $t[0] -= 1900;
    $t[1] -= 1;
    return reverse @t;
} # date_parts()

1;
__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric::Util::DBI|Bric::Util::DBI>

=cut
