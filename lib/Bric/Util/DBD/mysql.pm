package Bric::Util::DBD::mysql;

=head1 NAME

Bric::Util::DBD::mysql - Bricolage MySQL database adaptor

=head1 VITALS

=over 4

=item Version

$LastChangedRevision$

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=item Date

$LastChangedDate$

=item Subversion ID

$Id$

=back

=head1 SYNOPSIS

In F<bricolage.conf>:

  DBD_TYPE = mysql

=head1 DESCRIPTION

This module exports into Bric::Util::DBI's namespace a number of
database-dependent functions and variables such that Bric::Util::DBI can
interface seamlessly with a MySQL database. See Bric::Util::DBI for
details. Bric::Util::DBD::mysql should never be C<use>d in any other Bricolage
class. Nor should any other Bric::DBD::* driver.

=cut

##############################################################################
# Dependencies
##############################################################################
# Standard Dependencies
use strict;

##############################################################################
# Programmatic Dependences
use DBD::mysql;
use Bric::Config qw(:dbi);
use Bric::Util::Fault qw(throw_dp);

##############################################################################
# Constants
##############################################################################
# This variable tells Bric::Util::DBI whether this driver supports
# transactions.
use constant TRANSACTIONAL => 1;

# This is the DSN that Bric::Util::DBI will use to connect to the database.
use constant DSN_STRING => 'database=' . DB_NAME
  . ';mysql_client_found_rows=1'
  . (DB_HOST ? eval "';host=' . DB_HOST" : '')
  . (DB_PORT ? eval "';port=' . DB_PORT" : '');

# This is to set up driver-specific database handle attributes.
use constant DBH_ATTR => ( );

##############################################################################
# Inheritance
##############################################################################
use base qw(Exporter);
our @EXPORT_OK = qw(last_key_sql next_key_sql db_date_parts DSN_STRING
		    DBH_ATTR TRANSACTIONAL);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

##############################################################################
# Exportable Functions
##############################################################################
sub last_key_sql {
    # Returns the SQL to fetch the last key inserted by this process.
    # Used by Bric::Util::DBI::last_key().
#    my ($table_name, $db_name) = @_;
    return "SELECT LAST_INSERT_ID()";
} # last_key_sql()

##############################################################################
sub next_key_sql {
    # Returns the SQL to fetch the next key for a table. Intended to be used
    # inside an INSERT query, not on its own. Used by
    # Bric::Util::DBI::next_key().
#    my ($table_name, $db_name) = @_;
    return 'NULL';
} # next_key()

##############################################################################
sub db_date_parts {
    # This function unpacks a date/time string as it is formatted for the
    # database and returns a list of time tokens for use by timelocal(). Used
    # by Bric::Util::Time::strfdate().
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

=item L<Bric::Util::DBD::Pg|Bric::Util::DBD::Pg>

The Bricolage PostgreSQL database adaptor, which is the model on which all
other adaptors are based.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003 Kineticode, Inc. See L<Bric::License|Bric::License> for
complete license terms and conditions.

=cut
