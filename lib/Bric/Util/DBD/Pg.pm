package Bric::Util::DBD::Pg;

=head1 NAME

Bric::Util::DBD::Pg - Bricolage PostgreSQL database adaptor

=head1 VITALS

=over 4

=item Version

$Revision: 1.12 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.12 $ )[-1];

=item Date

$Date: 2003-09-10 18:39:07 $

=item CVS ID

$Id: Pg.pm,v 1.12 2003-09-10 18:39:07 wheeler Exp $

=back

=head1 SYNOPSIS

In F<bricolage.conf>:

  DBD_TYPE = Pg

=head1 DESCRIPTION

This module exports into Bric::Util::DBI's namespace a number of
database-dependent functions and variables such that Bric::Util::DBI can
interface seamlessly with a PostgreSQL database. See Bric::Util::DBI for
details. Bric::Util::DBD::Pg should never be C<use>d in any other Bricolage
class. Nor should any other Bric::DBD::* driver.

=cut

##############################################################################
# Dependencies
##############################################################################
# Standard Dependencies
use strict;

##############################################################################
# Programmatic Dependences
use DBD::Pg;
use Bric::Config qw(:dbi);
use Bric::Util::Fault qw(throw_dp);

##############################################################################
# Constants
##############################################################################
# This variable tells Bric::Util::DBI whether this driver supports
# transactions.
use constant TRANSACTIONAL => 1;

# This is the DSN that Bric::Util::DBI will use to connect to the database.
use constant DSN_STRING => 'dbname=' . DB_NAME
  . (DB_HOST ? eval "';host=' . DB_HOST" : '')
  . (DB_PORT ? eval "';port=' . DB_PORT" : '');

##############################################################################
# Inheritance
##############################################################################
use base qw(Exporter);
our @EXPORT_OK = qw(last_key_sql next_key_sql db_date_parts DSN_STRING
		    TRANSACTIONAL);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

##############################################################################
# Private Functions
##############################################################################
BEGIN {
     $ENV{PGTZ} = 'UTC';
     $ENV{PGDATESTYLE} = 'ISO';          # Should default to this, anyway.
#    $ENV{PGCLIENTENCODING} = 'UNICODE'; # Should default to this, anyway.
#    $ENV{PGSERVERENCODING} = 'UNICODE'; # Should default to this, anyway.
} # BEGIN

##############################################################################
# Exportable Functions
##############################################################################
sub last_key_sql {
    # Returns the SQL to fetch the last key fetched by this process for a table.
    # Used by Bric::Util::DBI::last_key().
    my ($table_name, $db_name) = @_;
    $db_name .= $db_name ? '.' : '';
    return "SELECT CURRVAL('${db_name}seq_$table_name')";
} # last_key_sql()

##############################################################################
sub next_key_sql {
    # Returns the SQL to fetch the next key for a table. Intended to be used
    # inside an INSERT query, not on its own. Used by Bric::Util::DBI::next_key().
    my ($table_name, $db_name) = @_;
    $db_name .= $db_name ? '.' : '';
    return $db_name . "NEXTVAL('${db_name}seq_$table_name')";
} # next_key()

##############################################################################
sub db_date_parts {
    # This function unpacks a date/time string as it is formatted for the
    # database and returns a list of time tokens for use by timelocal(). Used by
    # Bric::Util::Time::strfdate().
    my @t = eval { unpack('a4 x a2 x a2 x a2 x a2 x a2', shift) };
    throw_dp "Unable to unpack date: $@" if $@;
    $t[0] -= 1900;
    $t[1] -= 1;
    return reverse @t;
} # date_parts()

1;
__END__

=head1 AUTHOR

David Wheeler <david@kineticode.com>

=head1 SEE ALSO

=over 4

=item L<Bric::Util::DBI|Bric::Util::DBI>

The Bricolage DBI interface.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2001 About.com. See L<Bric::License|Bric::License> for complete
license terms and conditions.

=cut
