package Bric::Util::DBI;

=pod

=head1 NAME

Bric::Util::DBI - The Bricolage Database Layer

=head1 VERSION

$Revision: 1.21.2.4 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.21.2.4 $ )[-1];

=pod

=head1 DATE

$Date: 2003-03-19 03:28:43 $

=head1 SYNOPSIS

  use Bric::Util::DBI qw(:standard);

  my @cols = qw(id lname fname mname title email phone foo bar bletch);

  my $select = prepare_c(qq{
      SELECT @cols
      FROM   person
      WHERE  person_id = ?
  });

  $self->_set(\@cols, row_aref($select, $id));

=head1 DESCRIPTION

This module exports a number of database functions for use by Bricolage object
classes. These functions have been designed to maximize database independence
by implementing separate driver modules for each database platform. These
modules, Bric::DBD::*, export into Bric::Util::DBI the variables and functions
necessary to provide database-independent functions for getting and setting
primary keys and dates in the format required by the database (but see
Bric::Util::Time for the time formatting functions).

Bric::Util::DBI also provides the principal avenue to querying the database. No
other Bricolage module should C<use DBI>. The advantage to this approach (other than
some level of database independence) is that the $dbh is stored in only one
place in the entire application. It will not be generated in every module, or
stored in every object. Indeed, objects themselves should have no knowledge of
the database at all, but should rely on their methods to query, insert, update,
and delete from the database using the functions exported by Bric::Util::DBI.

Bric::Util::DBI is not a complete database-independent solution, however. In
particular, it does nothing to translate between the SQL syntaxes supported by
different database platforms. As a result, you are encouraged to write your
queries in as generic a way as possible, and to comment your code copiously when
you must use proprietary or not-widely supported SQL syntax (such as outer
joins).

B<NOTE:> Bric::Util::DBI is intended only for internal use by Bricolage modules. It must
not be C<use>d anywhere else in the application (e.g., in an Apache startup
file) or users of the application may be able to gain access to our database.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
################################################################################
# DBI Error Handling.
################################################################################
use Bric::Config qw(:dbi);
use Bric::Util::DBD::Pg qw(:all); # Required for our DB platform.
use Bric::Util::Fault::Exception::DA;
use DBI qw(looks_like_number);
use Time::HiRes qw(gettimeofday);
use Digest::MD5 qw(md5_hex);

################################################################################
# Constants
################################################################################
use constant CALL_TRACE => DBI_CALL_TRACE || 0;
use constant DEBUG => DBI_DEBUG || 0;
# You can set DBI_TRACE from 0 (Disabled) through 9 (super verbose).
use constant DBI_TRACE => 0;

DBI->trace(DBI_TRACE);

our $dbh;

# The strftime format for DB dates. Used by Bric::Util::Time::db_date().
use constant DB_DATE_FORMAT => '%Y-%m-%d %T';

# Package constant variables. This one is for the DB connection attributes.
my $ATTR =  { RaiseError => 1,
	      PrintError => 0,
	      AutoCommit => 1,
	      ChopBlanks => 1,
	      ShowErrorStatement => 1,
	      LongReadLen => 32768,
	      LongTruncOk => 0
};

################################################################################
# Inheritance
################################################################################
use base qw(Exporter);

# You can explicitly import any of the functions in this class. The last two
# should only ever be imported by Bric::Util::Time, however.
our @EXPORT_OK = qw(prepare prepare_c prepare_ca execute fetch row_aref col_aref
		    last_key next_key db_date_parts DB_DATE_FORMAT clean_params
		    bind_columns bind_col bind_param begin commit rollback
		    finish is_num row_array all_aref fetch_objects order_by
                    build_query_with_unions build_query where_clause tables);

# But you'll generally just want to import a few standard ones or all of them
# at once.
our %EXPORT_TAGS = (standard => [qw(prepare_c row_aref fetch fetch_objects execute 
                                    next_key last_key bind_columns finish)],
		    trans => [qw(begin commit rollback)],
		    all => \@EXPORT_OK);

# Disconnect! Will be ignored by Apache::DBI.
END { _disconnect(); }

################################################################################
# Exportable Functions
################################################################################

=pod

=head1 INTERFACE

There are several ways to C<use Bric::Util::DBI>. Some options include:

  use Bric::Util::DBI qw(:standard);            # Get the standard db functions.
  use Bric::Util::DBI qw(:standard :trans);     # Get standard and transactional functions.
  use Bric::Util::DBI qw(:all);                 # Get all the functions.
  use Bric::Util::DBI qw(prepare_c); # Get specific functions.

The first example imports all the functions you are likely to need in the normal
course of writing a Bricolage class. The second example imports the standard functions
plus functions needed for managing transactions. The third example imports all
the functions and variables provided by Bric::Util::DBI. These should cover all of
your database needs. The last example imports only a few key functions and
variables. You may explicitly import as many functions and variables as you wish
in this way. Specifying no parameters, e.g.,

  use Bric::Util::DBI;

will compile DBI, but will provide no database access functions. You are not
going to want to do this.

Here are the functions and variables imported with each import list:

=over 4

=item standard

=over 4

=item *

prepare_c()

=item *

row_aref()

=item *

fetch()

=item *

execute()

=item *

next_key()

=item *

last_key()

=item *

bind_columns()

=back

=item trans

=over

=item *

begin()

=item *

commit()

=item *

rollback()

=back

=item all

all of the above, plus

=over 4

=item *

prepare()

=item *

prepare_ca()

=item *

col_aref()

=item *

db_date_parts()

=item *

bind_col()

=item *

bind_param()

=item *

DB_DATE_FORMAT - the strftime format for the date format used by the databse.
Used by Bric::Util::Time; you should not need this - use the functions exported
by Bric::Util::Time instead.

=back

=back

Each of the functions below that will directly access the database will first
check for a connection to the database and establish the connection if it does
not exist. There is no need to worry about accessing or storing a $dbh in any Bricolage module. Plus, each function handles all aspects of database exception handling
so tht you do not have to. The exception is with the transactional functions; 
see Begin() below for more information.

=head2 Constructors

NONE.

=head2 Destructors

NONE.

=head2 Public Class Methods

NONE.

=head2 Public Instance Methods

NONE.

=head2 Functions

=over 4

=item my $bool = is_num(@values)

Alias for DBI::looks_like_number() to determine whether or not the values passed
are numbers. Returns true for each value that looks like a number, and false for
each that does not. Returns undef for each element that is undefined or empty.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

*is_num = *DBI::looks_like_number;

################################################################################

=item $sth = prepare($sql)

=item $sth = prepare($sql, $attr)

=item $sth = prepare($sql, $attr, $DEBUG)

Returns an $sth from $dbh->prepare. Pass any attributes you want associated
with your $sth via the $attr hashref. If $DEBUG is true, it will also issue a
warning that prints $sql. In general, use prepare_c() instead of prepare().

B<IMPORTANT:> We strongly encourage only very specific uses of statement
handles. It is easy to use them inefficiently, but the following guidelines
should keep your code as speedy as possible. But the main point is: Use only
functions exported by Bric::Util::DBI, not statement handle methods.

=over 4

=item *

Use prepare_c() whenever possible, as it will cache the $sth for future use,
even if your copy of it goes out of scope. This will save a lot of time for
frequently-used queries, as they will only be compiled once per process. If
you find that you are frequently doing only partial fetches from a statement
handle, use prepare_ca().

=item *

Always use placeholders. If you have got a query you want to stick a variable
in to the WHERE clause, do not put in the variable! Put in a placeholder (?)
instead! Doing so allows the same statement to be used over and over without
recompiling in the database. Placeholders also eliminate the need to use the
DBI quote() method (which, you will notice, is not exported by this module).

=item *

When fetching values back from the statement handle, always bind variables to
columns (using bind_col($select) or bind_columns($select)), and fetch each row
with the fetch($select) function (see below). Do not use statement handle 
methods yourself; avoid using the $select->fetchrow_array() method, and 
I<especially> the $select->fetchrow_hashref() methods, as they are much slower 
than fetch($select) with bound columns. If you need to use one of these methods 
let me know and we will see about adding them as functions to Bric::Util::DBI. 
But it should not be necessary. Better yet, anytime you find yourself wanting 
to use $select->fetchrow_hashref(), take it as a cue to go back, look at your 
code design, and decide whether you are making the best design decisions.

=back

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=back

B<Side Effects:> Calls $dbh->prepare().

B<Notes:> NONE.

=cut

sub prepare {
    _connect();
    my $sth;
    eval { $sth = $dbh->prepare(@_[0..1]) };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to prepare SQL statement\n\n$_[0]", payload => $@ })
      if $@;
    _debug_prepare(\$_[0]) if DEBUG;
    return $sth;
} # prepare()

################################################################################

=pod

=item my $sth = prepare_c($sql)

=item my $sth = prepare_c($sql, $attr)

=item my $sth = prepare_c($sql, $attr, $DEBUG)

Returns an $sth from $dbh->prepare_cached. Pass any attributes you want
associated with your $sth via the $attr hashref. If $DEBUG is true, it will also
issue a warning that prints $sql. A warning will also be issued if the $sth
returned is already active.

See also the important note in the prepare() documentation above.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=back

B<Side Effects:> Calls $dbh->prepare_cached().

B<Notes:> NONE.

=cut

sub prepare_c {
    _connect();
    my $sth;
    eval { $sth = $dbh->prepare_cached(@_[0..1]) };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to prepare SQL statement\n\n$_[0]", payload => $@ })
      if $@;
    _debug_prepare(\$_[0]) if DEBUG;
    return $sth;
} # prepare_c()

################################################################################

=pod

=item my $sth = prepare_ca($sql)

=item my $sth = prepare_ca($sql, $attr)

=item my $sth = prepare_ca($sql, $attr, $DEBUG)

Returns an $sth from $dbh->prepare_cached, and will not issue a warning if the
$sth returned is already active. Pass any attributes you want associated with
your $sth via the $ATTR hashref. If $DEBUG is true, it will also issue a warning
that prints $sql.

See also the important note in the prepare() documentation above.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=back

B<Side Effects:> Calls $dbh->prepare_cached() with the active flag set to true.

B<Notes:> NONE.

=cut

sub prepare_ca {
    _connect();
    my $sth;
    eval { $sth = $dbh->prepare_cached(@_[0..1], 1) };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to prepare SQL statement\n\n$_[0]", payload => $@ })
      if $@;
    _debug_prepare(\$_[0]) if DEBUG;
    return $sth;
} # prepare_ca

################################################################################

=item my $ret = begin()

  begin();
  eval {
      execute($ins1);
      execute($ins2);
      execute($upd);
      commit();
  };
  if ($@) {
      rollback();
      die $@;
  }

Sets $dbh->{AutoCommit} = 0. Use before a series of database transactions so
that none of them is committed to the database until commit() is called. If
there is a problem, call rollback() instead. Each of these two functions will
also turn AutoCommit back on, so if you need to more transactional control, be
sure to call begin() again. Also, be sure to always call either commit() or
rollback() when you are done with your transactions, or AutoCommit will not be
switched back on and future database activity will have unexpected results
(nothing will be committed - except you, you insane hacker!).

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to turn AutoCommit off.

=back

B<Side Effects:> Calls $dbh->{AutoCommit} = 0.

B<Notes:> NONE.

=cut

sub begin {
    return 1 unless TRANSACTIONAL;
    return 1 if $ENV{MOD_PERL} && !$_[0];
    _connect();
    my $ret;
    eval { $ret = $dbh->{AutoCommit} = 0 };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to turn AutoCommit off", payload => $@ }) if $@;
    return $ret;
}

################################################################################

=item my $ret = commit()

Call this function after calling begin() and executing a series of database
transactions. It commits the transactions to the database, and then sets
AutoCommit to true again. See begin() for an example.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to commit transactions.

=item *

Unable to turn on AutoCommit.

=back

B<Side Effects:> Calls $dbh->commit.

B<Notes:> NONE.

=cut

sub commit {
    return 1 unless TRANSACTIONAL;
    return 1 if $ENV{MOD_PERL} && !$_[0];
    _connect();
    my $ret;
    eval { $ret = $dbh->commit };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to commit transactions", payload => $@ }) if $@;
    eval { $ret = $dbh->{AutoCommit} = 1 };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to turn AutoCommit on", payload => $@ }) if $@;
    return $ret;
}

################################################################################

=item = fetch_objects( $pkg, $sql, $fields, $args )

fetch_objects takes a package name, a sql statement, an arrayref of fields,
and a list of arguments.  It uses the results from the sql statement to
construct objects of the specified package, in which the final column is
variable over a number of lines in which the other columns are the same.
Like this:

    1 1 1
    1 1 2
    1 1 3
    2 2 1
    2 2 2
    2 2 3

which would, given the package name of Bric, and fields [ qw( one two three) ] 
assemble the following objects:

    [ 
        bless ( {
                one   => 1,
                two   => 1,
                three => [ 1, 2, 3 ],
              }, 'Bric' ),
        bless ( {
                one   => 2,
                two   => 2,
                three => [ 1, 2, 3 ],
              }, 'Bric' ),
    ]

In practice this is used for the grp_ids aggrigation of Asset objects.


B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=back

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub fetch_objects {
    my ($pkg, $sql, $fields, $args, $limit, $offset) =  @_;
    my (@objs, @d, $grp_ids);
    # make offset numeric
    $offset = $offset || 0;
    # figure out the fields we need to fill
    my $count = @$fields - 1;
    # set and execute the query
    my $select = prepare_ca($sql, undef, DEBUG);
    execute($select, @$args);
    bind_columns($select, \@d[0 .. $count]);
    # loop through the list, looking for diferrent grp__id columns in
    # matching lines.  Note: this works for all sort orders except grp__id
    my $obj_col = $pkg->OBJECT_SELECT_COLUMN_NUMBER || 0;
    my $last = -1;
    my $i;
    while (fetch($select)) {
        if ($d[$obj_col] != $last) {
            last if $limit && @objs >= $limit;
            $last = $d[$obj_col];
            next unless $i++ >= $offset;
            my $obj = bless {}, $pkg;
            $grp_ids = $d[$#d] = [$d[$#d]];
            $obj ->_set($fields, [@d, $grp_ids]);
            $obj->_set__dirty(0);
            $obj = bless $obj, Bric::Util::Class->lookup(
              { id => $obj->get_class_id })->get_pkg_name()
              if $pkg->HAS_CLASS_ID;
            push @objs, $obj->cache_me;
        } else {
            # Append the ID.
            push @$grp_ids, $d[$#d];
        }
    }
    finish($select);
    # Return the objects.
    return (wantarray ? @objs : \@objs);
}

=item = _build_query($cols, $tables, $where_clause, $order)

Called by list will return objects or ids depending on who is calling

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub build_query {
    my ($cols, $tables, $where_clause, $order) = @_;
    # get the various parts of the query
    return qq{ SELECT DISTINCT $cols
               FROM   $tables
               WHERE  $where_clause
               $order
             };
}

=item = _build_query_with_unions($cols, $tables, $where_clause, $order);

Called by list will return objects or ids depending on who is calling

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub build_query_with_unions {
    my ($pkg, $cols, $tables, $where_clause, $order) = @_;
    my (@queries);
    # loop through the relations building a query
    foreach my $rel ( @{$pkg->RELATIONS} ) {
        my $rtables = $pkg->RELATION_TABLES->{$rel};
        my $rwhere_clause = $pkg->RELATION_JOINS->{$rel};
        push @queries, qq{ SELECT DISTINCT $cols
                           FROM   $tables, $rtables
                           WHERE  $where_clause AND $rwhere_clause
                         };
    }
    return join("UNION\n", @queries) . "$order";
}

=item = $params = clean_params($params)

Parameters for Asset objects should be run through this before sending them
to the query building functions.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub clean_params {
    my ($class, $param) = @_;
    # Make sure to set active explictly if its not passed.
    $param->{'active'} = exists $param->{'active'} ? $param->{'active'} : 1;
    # Map inverse alias inactive to active.
    $param->{'active'} = ($param->{'inactive'} ? 0 : 1)
      if exists $param->{'inactive'};
    # checked_out has some special cases
    if (exists $param->{checked_out}) {
        if ($param->{checked_out} eq 'all') {
            delete $param->{_checked_out};
        } else {
            $param->{_checked_out} = $param->{checked_out};
        }
    } elsif (exists $param->{checkout}) {
        $param->{_checked_out} = $param->{checkout};
    } elsif (defined $param->{user_id}) {
        $param->{_checked_out} = 1;
    } else {
        $param->{_checked_out} = 0;
    }
    $param->{_checked_out} = 1 if defined $param->{user__id};
    # take care of the simple query, or lack thereof
    $param->{_not_simple} = 1 unless $param->{simple};
    # we can only handle the returned versions p in reverse
    $param->{_no_returned_versions} = 1 unless $param->{return_versions};
    # add default order
    $param->{Order} = $class->DEFAULT_ORDER unless $param->{Order};
    # support of NULL workflow__id
    if( exists $param->{workflow_id} && ! defined $param->{workflow_id} ) {
        $param->{_null_workflow_id} = 1;
        delete $param->{workflow_id};
    }
    return $param;
}

=item = _select_tables

The from clause for the main select is built here.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub tables {
    my ($pkg, $param) = @_;
    my $from = $pkg->FROM;
    foreach (keys %$param) {
        next unless $pkg->PARAM_FROM_MAP->{$_};
        my $t = $pkg->PARAM_FROM_MAP->{$_};
        next if $from =~ m/$t/;
        $from .= ', ' . $t;
    }
    return $from;
}

=item = where_clause

The where clause for the main select is built here.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub where_clause {
    my ($pkg, $param) = @_;
    my (@args, $where, $and);
    $where = $pkg->WHERE;
    foreach (keys %$param) {
        next unless $pkg->PARAM_WHERE_MAP->{$_};
        next unless defined $param->{$_};
        my $sql = $pkg->PARAM_WHERE_MAP->{$_};
        $where .= ' AND ' . $sql;
        my $i;
        my $count = $sql =~ s/\?//g;
        while ( $i++ < $count ) { 
            push @args, $param->{$_};
        }
    }
    return $where, \@args;
}

=item = order_by

Builds up the ORDER BY clause

B<Throws:>

OrderDirection parameter must either ASC or DESC.

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub order_by {
    my ($pkg, $param) = @_;

    if ($param->{Order}) {
        # Grab the order map.
        my $map = $pkg->PARAM_ORDER_MAP;

        # Make sure it's legit.
        my $ord = $map->{$param->{Order}}
          or die Bric::Util::Fault::Exception::DA->new
          ({ msg => "Bad Order parameter '$param->{Order}'" });

        # Set up the order direction.
        my $dir = 'ASC';
        if ($param->{OrderDirection}) {
            # Make sure it's legit.
            die Bric::Util::Fault::Exception::DA->new
              ({ msg => 'OrderDirection parameter must either ASC or DESC.' })
                if $param->{OrderDirection} ne 'ASC'
                  and $param->{OrderDirection} ne 'DESC';
            # Grab it.
            $dir = $param->{OrderDirection};
        }
        # Return the ORDER BY clause with the ID column.
        return "ORDER BY $ord $dir, id";
    }

    # Default to returning ID.
    return "ORDER BY id";
}


################################################################################

=item my $ret = rollback()

Call this function after calling begin() and executing a series of database
transactions, where one or more of the transactions fails and they all need to
be rolled back. See begin() for an example.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to rollback transactions.

=item *

Unable to turn on AutoCommit.

=back

B<Side Effects:> Calls $dbh->commit.

B<Notes:> NONE.

=cut

sub rollback {
    return 1 unless TRANSACTIONAL;
    return 1 if $ENV{MOD_PERL} && !$_[0];
    _connect();
    my $ret;
    eval { $ret = $dbh->rollback };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to rollback transactions", payload => $@ }) if $@;
    eval { $ret = $dbh->{AutoCommit} = 1 };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to turn AutoCommit on", payload => $@ }) if $@;
    return $ret;
}

################################################################################

=item my $ret = execute($sth, @params)

Executes the prepared statement. Use this instead of $sth->execute(@params) and
it will take care of exception handling for you. Returns the value returned by
$sth->execute().

B<Throws:>

=over 4

=item *

Unable to execute SQL statement.

=back

B<Side Effects:> Calls C<< $sth->execute >>.

B<Notes:> NONE.

=cut

sub execute {
    my $sth = shift;
    _debug_execute(\@_, $sth) if DEBUG;
    _profile_start()          if DBI_PROFILE;
    my $ret;

    eval { $ret = $sth->execute(@_) };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to execute SQL statement", payload => $@ }) if $@;
    _profile_stop()           if DBI_PROFILE;
    return $ret;
}

################################################################################

=item my $ret = bind_columns($sth, @args)

Binds variables to the columns in the statement handle. Functions exactly the
same as $sth->bind_columns, only it handles the exception handling for you.
Returns the value returned by $sth->bind_columns.

B<Throws:>

=over 4

=item *

Unable to bind to columns to statement handle.

=back

B<Side Effects:> Calls $sth->bind_columns().

B<Notes:> NONE.

=cut

sub bind_columns {
    my $sth = shift;
    my $ret;
    eval { $ret = $sth->bind_columns(@_) };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to bind to columns to statement handle",
	payload => $@ }) if $@;
    return $ret;
}

################################################################################

=item my $ret = bind_col($sth, @args)

Binds a variable to a columns in the statement handle. Functions exactly the
same as $sth->bind_col, only it handles the exception handling for you. Returns
the value returned by $sth->bind_col.

B<Throws:>

=over 4

=item *

Unable to bind to column to statement handle.

=back

B<Side Effects:> Calls $sth->bind_columns().

B<Notes:> NONE.

=cut

sub bind_col {
    my $sth = shift;
    my $ret;
    eval { $ret = $sth->bind_col(@_) };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to bind to column to statement handle",
	payload => $@ }) if $@;
    return $ret;
}

################################################################################

=item my $ret = bind_param($sth, @args)

Binds parameter to the columns in the statement handle. Functions exactly the
same as $sth->bind_param, only it handles the exception handling for you.
Returns the value returned by $sth->bind_param.

B<Throws:>

=over 4

=item *

Unable to bind parameters to columns in statement handle.

=back

B<Side Effects:> Calls $sth->bind_columns().

B<Notes:> NONE.

=cut

sub bind_param {
    my $sth = shift;
    my $ret;
    eval { $ret = $sth->bind_param(@_) };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to bind parameters to columns in statement handle",
	payload => $@ })
      if $@;
    return $ret;
}

################################################################################

=item my $ret = fetch($sth)

Performs $sth->fetch() and returns the result. Functions exactly the same as
$sth->fetch, only it handles the exception handling for you.

B<Throws:>

=over 4

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> Calls $sth->bind_columns().

B<Notes:> NONE.

=cut

sub fetch {
    my $sth = shift;
    my $ret;
    eval { $ret = $sth->fetch(@_) };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to fetch row from statement handle", payload => $@ })
      if $@;
    return $ret;
}

################################################################################

=item my $ret = finish($sth)

Performs $sth->finish() and returns the result. Functions exactly the same as
$sth->finish, only it handles the exception handling for you.

B<Throws:>

=over 4

=item *

Unable to finish statement handle.

=back

B<Side Effects:> Calls $sth->finish().

B<Notes:> Do B<not> confuse this function with finishing transactions. It simply
tells a SELECT statement handle that you are done fetching records from it, so 
it can free up resources in the database. If you have started a series of 
transactions with begin(), finish() will not commit them; only commit() will 
commit them, and rollback() will roll them back.

=cut

sub finish {
    my $sth = shift;
    my $ret;
    eval { $ret = $sth->finish(@_) };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to finish statement handle", payload => $@ }) if $@;
    return $ret;
}

################################################################################

=begin comment

This was an experimental fetch_em method. Might return to it at some point, but
for now, neither I nor anyone else is using it.

=pod

=item fetch_em($class, $select, $props)

=item fetch_em($class, $select, $props, $args)

=item fetch_em($class, $select, $props, $args, $attr)

Populates an object or array of objects of type $class with data returned from
the select query $select. The arguments work as follows:

=over 4

=item $class

The class against which to call new() to instantiate each object. Required.

=item $select

The prepared SQL SELECT statement handle. Required.

=item $props

An anonymous array of the names of the properties to be loaded into each object.
These should be in the same order as the columns selected from the database.
Required.

=item $args

An anonymous array of arguments to be passed to $select->execute(). Optional.

=item $join

An anonymous hash of arguments to be used for fetching a subset of data for an
object. Optional. The supported keys are:

=over 4

=item props

An anonymous array of the names of the properties to be loaded into each joined
data subset. These should be in the same order as the columns selected from the
database, following the columns selected for $props above. Required.

=item id

The name of the field that stores the objects unique ID. This will be used
to determine when a C<fetch_em>ed row represents a new object. Required.

=item obj_key

The name of the object property that will hold the joined data. Required.

=item key

The name of the field that holds a unique identifier for an individual joined
row so that the joined data subset can be stored in an anonymous hash. Optional.
If not defined, the joined data will be stored in an anonymous array.

=item class

The class against which to call _new() to instantiate each joined data set as an
object. Optional. If not defined, each joined data set will be stored as an
anonymous hash.

=back

=back

Examples:

  my @cols = qw(id lname fname mname title email phone foo bar bletch
                  dancing_small_person);

  ##############################################################################
  # Simple atomic select - don't use fetch_em().
  local $" = ', ';
  my $select = prepare_c(qq{
      SELECT @cols
      FROM   person
      WHERE  person_id = ?
  });
  # Using row_aref() is faster than using fetch_em() when we're just fetching
  # one row.
  $self->_set(\@cols, row_aref($select, undef, $id));

  ##############################################################################
  # Simple batch select.
  local $" = ', ';
  my $select = prepare_c(qq{
      SELECT @cols
      FROM   person
      WHERE  lname like 'W%'
  });
  # This will fill @people with 'Bric::Biz::Person' objects.
  my @people = fetch_em('Bric::Biz::Person', $select, \@cols);


  ##############################################################################
  # Joined select.
  my $select = prepare_c(qq{
      SELECT p.id, @cols[1..$#cols], g.id, g.name
      FROM   person p, group g, person__map__group pmg
      WHERE  p.id = pmg.person_id
             AND pmg.group_id = g.id
             AND p.id = ?
  });
  # This will fill @people with 'Bric::Biz::Person' objects and an anonymous hash of
  # groups keyed by group ID.
  my @people = fetch_em('Bric::Biz::Person', $select, \@cols, [$id],
                     {props   => [qw(id name)],
                      id      => 'id',
                      key     => '_groups',
                      obj_key => 'id',
                     });)

 =cut

sub fetch_em {
    my ($class, $select, $props, $args, $join) = @_;
    $select->execute(@$args);
    my @ret;
    if ($join) {
	# This is a joined query, so we'll be grabbing two sets of data - the
	# primary properties of an object, and attributes of that object.
	my (@d, @a, %obj, $last);
	# By binding @d and @a, we automatically have nice arrays of the two
	# categories of data we need to load - basic properties and attributes.
	$select->bind_columns(\@d[0..$#$props], \@a[0..$#{$join->{props}}]);
	while ($select->fetch) {
	    if ( $last != $obj{ $join->{id} } ) {
		# It's a new object. Save the last one.
		push @ret, $class->new(\%obj);
		# Grab the new object's ID.
		$last = $obj{ $join->{id} };
		# Now grab the new object.
		@obj{@$props} = @d;
	    }
	    # Grab any attributes. These will vary from row to row.
	    if ($a[0]) {
		my $data;
		# Get the data into a  hashref.
		@{$data}{ @{ $join->{props} } } = @a;
		# Bless that data into its own class, if necessary.
		$data = $join->{class}->_new($data) if $join->{class};
		# Now, either add it to a hashref or to an arrayref.
		$join->{key} ? $obj{ $join->{obj_key} }->{$join->{key}} = $data
		  : push @{ $obj{ $join->{obj_key} } }, $data;
	    }
	}
	# Grab the last object.
	push @ret, $class->new(\%obj);
    } else {
	# This is a much simpler query with no joins.
	my @d;
	$select->bind_columns(\@d[0..$#$props]);
	while ($select->fetch) {
	    # Instantiate a new object.
	    my $obj = $class->new;
	    # Set the object's properties.
	    $obj->_set($props, \@d);
	    # Save the object for returning.
	    push @ret, $obj;
	}
    }
    # Return either the first object or all the objects.
    return wantarray ? @ret : $ret[0];
}

=end comment

=cut

################################################################################

=pod

=item my $row = row_aref($select, @params)

Executes the SELECT statement in $select and returns the first row of values in
an array reference. Preferred for use fetching just one row, but if passed a
multi-row query, will return the first row only. If placeholders have been used
in $select, pass the parameters that map to them. This function B<will>
prepare() the query in $select, but it will not prepare_c() it. Thus it is
generally prefered to prepare_c($select) yourself and then pass it to row_aref()
as an $sth. See the Synopsis above for an example.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to select row.

=back

B<Side Effects:> Calls $dbh->selectrow_arrayref().

B<Notes:> NONE.

=cut

sub row_aref {
    my ($qry, @params) = @_;
    _connect();
    _debug_prepare_and_execute(\@params, \$qry) if DEBUG;
    _profile_start() if DBI_PROFILE;
    my $aref;
    eval { $aref = $dbh->selectrow_arrayref($qry, undef, @params) };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to select row", payload => $@ }) if $@;
    _profile_stop() if DBI_PROFILE;
    return $aref;
} # row_aref()

=pod

=item my @row = row_array($select, @params)

Executes the SELECT statement in $select and returns the first row of values in
an array. Preferred for use fetching just one row, but if passed a multi-row
query, will return the first row only. If placeholders have been used in
$select, pass the parameters that map to them. This function B<will> prepare()
the query in $select, but it will not prepare_c() it. Thus it is generally 
prefered to prepare_c($select) yourself and then pass it to row_array() as an $sth. For an example, see how the Synopsis above does this for row_aref().

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to select row.

=back

B<Side Effects:> Calls $dbh->selectrow_array().

B<Notes:> NONE.

=cut

sub row_array {
    my ($qry, @params) = @_;
    _connect();
    _debug_prepare_and_execute(\@params, \$qry) if DEBUG;
    _profile_start() if DBI_PROFILE;
    my @array;
    eval { @array = $dbh->selectrow_array($qry, undef, @params) };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to select row", payload => $@ }) if $@;
    _profile_stop() if DBI_PROFILE;
    return @array;
} # row_array()

=pod

=item my $data = all_aref($select, @params)

Executes $dbh->selectall_arrayref($select) and returns the data structure
returned by that DBI method. See DBI(2) for details on the data structure. If
placeholders have been used in $select, pass the parameters that map to them.
This function B<will> prepare() the query in $select, but it will not 
prepare_c() it. Thus it is generally prefered to prepare_c($select) yourself 
and then pass it to all_aref() as an $sth. For an example, see how the Synopsis above does this for row_aref().

This function is not generally recommended for use except for grabbing a very
few, simple rows and you do not need to change the data structure. If you do 
need to change the data structure, it would probably be faster to 
fetch($select) with bound variables and construct the data structure yourself.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to select all.

=back

B<Side Effects:> Calls $dbh->selectall_arrayref().

B<Notes:> NONE.

=cut

sub all_aref {
    my ($qry, @params) = @_;
    _connect();
    _debug_prepare_and_execute(\@params, \$qry) if DEBUG;
    _profile_start() if DBI_PROFILE;
    my $aref;
    eval { $aref = $dbh->selectall_arrayref($qry, undef, @params) };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to select all", payload => $@ }) if $@;
    _profile_stop() if DBI_PROFILE;
    return $aref;
} # all_aref()

=pod

=item my $col = col_aref($select, @params)

Executes the SELECT statement in $select and returns the values of the first
column from every row in an array reference. Preferred for fetching many rows
for just one column. If placeholders have been used in $select, pass the
parameters that map to them. This function B<will> prepare() the query in
$select, but it will not prepare_c() it. Thus it is generally prefered to
prepare_c($select) yourself and then pass it to col_aref() as an $sth. For an
example, see how the Synopsis above does this for row_aref().

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=back

B<Side Effects:> Calls $dbh->selectcol_arrayref().

B<Notes:> NONE.

=cut

sub col_aref {
    my ($qry, @params) = @_;
    _connect();
    _debug_prepare_and_execute(\@params, \$qry) if DEBUG;
    _profile_start() if DBI_PROFILE;
    my $col;
    eval { $col = $dbh->selectcol_arrayref($qry, undef, @params) };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to select column into arrayref", payload => $@ }) if $@;
    _profile_stop() if DBI_PROFILE;
    return $col;
} # col_aref()

################################################################################

=pod

=item my $id = next_key($table_name)

=item my $id = next_key($table_name, $db_name)

Returns an SQL string for inserting the next available key into
$db_name.$table_name within the context of a larger INSERT statement. If
$db_name is not passed, it defaults to the value stored in $Bric::Cust.

  my @cols = qw(id lname fname mname title email phone foo bar bletch);

  local $" = ', ';
  my $insert = prepare_c(qq{
      INSERT INTO person (@cols)
      VALUES (${\next_key('person')}, ${\join ', ', map '?', @cols[1..$#cols]})
  });

  # Don't try to set ID - it will fail!
  execute($insert, $self->_get(@cols[1..$#cols));

  # Now grab the ID!
  $self->_set({id => last_key('person')});

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub next_key { next_key_sql(@_, $Bric::Cust); } # next_key()

=pod

=item last_key($table_name)

=item last_key($table_name, $db_name)

=item last_key($table_name, $db_name, $DEBUG)

Returns the last sequence number inserted into $db_name.$table_name by the
current process. If $db_name is not passed, it defaults to the value stored in
$Bric::Cust. Will return undef if this process has not yet inserted anything into
$table_name. Use for retreiving an object ID immediately after executing an
INSERT statement. See next_key() above for an example.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select row.

=back

B<Side Effects:> Gets the last sequence number by using prepare_c() to prepare
the query, and row_aref() to fetch the result.

B<Notes:> NONE.

=cut

sub last_key {
    _connect();
    my ($name, $db, $debug) = @_;
    my $sth = prepare_c(last_key_sql($name, $db || $Bric::Cust), undef, $debug);
    return row_aref($sth)->[0];
} # last_key()

=back

=head1 PRIVATE

NONE.

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item _connect()

Connects to the database and stores the connection in $dbh.  Will
re-connect if $dbh->ping fails.  Should be called at the start of
every function that does database access.

B<Notes:> We may need to override $dbh->ping. If so, do it in the
Bric::DBI::DBD::* driver class.

=cut

sub _connect {
    eval {
	unless ($dbh && $dbh->ping) {
	    $dbh = DBI->connect(join(':', 'DBI', DBD_TYPE, DSN_STRING),
				DBI_USER, DBI_PASS, $ATTR);
	}
    };
    die Bric::Util::Fault::Exception::DA->new(
        { msg => "Unable to connect to database", payload => $@ }) if $@;
}

=item _disconnect()

Disconnects from the database.  Called by an END block installed by
this package.

=cut

sub _disconnect {
    eval {
	if ($dbh && $dbh->ping) {
	    # Don't commit, in case we're ending unexpectedly.
	    $dbh->rollback unless $dbh->{AutoCommit};
	    $dbh->disconnect;
	}
    };
    die Bric::Util::Fault::Exception::DA->new(
      { msg => "Unable to disconnect from database", payload => $@ }) if $@;
}

=item _debug_prepare(\$sql)

Prints out debugging messages for a prepare call.  Should be called by
functions that prepare statements when DEBUG (DBI_DEBUG) is true.

=cut

sub _debug_prepare {
    my $sql_ref = shift;
    my $sig = _statement_signature($sql_ref);
    print STDERR "############# Prepare Query [$sig]:\n$$sql_ref\n", 
	         "#############\n\n";
    _print_call_trace() if CALL_TRACE;
}

=item _debug_execute(\@args, $sth)

Prints out debugging messages for an execute call.  Should be called
by functions that execute statements when DEBUG (DBI_DEBUG) is true.

=cut

sub _debug_execute {
    my ($args, $sth) = @_;
    my $sig = _statement_signature(\$sth);
    print STDERR "+++++++++++++ Execute Query [$sig]\n";
    print STDERR "+++++++++++++ ARGS: ", 
	join(', ', map { defined $_ ? $_ : 'NULL' } @{$_[0]}),
	    "\n\n";
    _print_call_trace() if CALL_TRACE;
}

=item _debug_prepare_and_execute(\@args, \$sql)

=item _debug_prepare_and_execute(\@args, \$sth)

Prints out debugging messages for a call that prepares and executes in
one call.  Should be called by functions that prepare and execute when
DEBUG (DBI_DEBUG) is true.

=cut

sub _debug_prepare_and_execute {
    my ($args, $ref) = @_;
    my $sig = _statement_signature($ref);
    unless (ref $$ref) {
	# new prepare
	print STDERR "############# Prepare Query [$sig]:\n$$ref\n",
                     "#############\n\n";
	_print_call_trace() if CALL_TRACE;
    }
    print STDERR "+++++++++++++ Execute Query [$sig]:\n";
    print STDERR "+++++++++++++ ARGS: ", 
	join(', ', map { defined $_ ? $_ : 'NULL' } @$args),
	     "\n\n\n";
}

=item _statement_signature(\$sql)

=item _statement_signature(\$sth)

Returns a fingerprint for an sql statement or statement handle.  Used
in debug output to match prepares to executes.

=cut

sub _statement_signature {
    my $ref = shift;
    my $sig = ref $$ref ? md5_hex(${$ref}->{Statement}) : md5_hex($$ref);
    substr($sig, $_, 0) = " " for (4, 9, 14, 19, 24, 29, 34);
    return $sig;
}

=item _print_call_trace

Writes out a call trace to STDERR.  Should be called by functions that
prepare statements when CALL_TRACE (DBI_CALL_TRACE) is true.

=cut

sub _print_call_trace {
  print STDERR "------------- Call Trace:\n";
  my $n = 2;
  while (my @c = caller($n++)) {
    printf STDERR " %-40s => %s()\n", "$c[0] ($c[2])", $c[3];
    last if $c[0] =~ /HTML::Mason/;
  }
  print STDERR "\n";
}

=item _profile_start()

Starts a timer used to profile database calls.  Should be
called before query execution when DBI_PROFILE is true.

=cut

{
    my $PROF_TIMER;
    sub _profile_start {
	$PROF_TIMER = gettimeofday();
    }

=item _profile_stop()

Stops the profile timer and writes out the timing results to STDERR.
Should be called immediately after query execution when DBI_PROFILE is
true.

=cut

    sub _profile_stop {
	printf STDERR "************* Time: %0.6f seconds\n\n\n\n",
	    gettimeofday() - $PROF_TIMER;
    }
}

=back

=cut

1;

__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David E. Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<DBI|DBI>,
L<Bric|Bric>,
L<Bric::Util::Time|Bric::Util::Time>,
L<Bric::Util::DBD::Oracle|Bric::Util::DBD::Oracle>

=cut
