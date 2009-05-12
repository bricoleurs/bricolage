package Bric::Util::DBI;

=pod

=head1 Name

Bric::Util::DBI - The Bricolage Database Layer

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=pod

=head1 Synopsis

  use Bric::Util::DBI qw(:standard);

  my @cols = qw(id lname fname mname title email phone foo bar bletch);

  my $select = prepare_c(qq{
      SELECT @cols
      FROM   person
      WHERE  person_id = ?
  }, undef);

  $self->_set(\@cols, row_aref($select, $id));

=head1 Description

This module exports a number of database functions for use by Bricolage object
classes. These functions have been designed to maximize database independence
by implementing separate driver modules for each database platform. These
modules, Bric::DBD::*, export into Bric::Util::DBI the variables and functions
necessary to provide database-independent functions for getting and setting
primary keys and dates in the format required by the database (but see
Bric::Util::Time for the time formatting functions).

Bric::Util::DBI also provides the principal avenue to querying the
database. No other Bricolage module should C<use DBI>. The advantage to this
approach (other than some level of database independence) is that the $dbh is
stored in only one place in the entire application. It will not be generated
in every module, or stored in every object. Indeed, objects themselves should
have no knowledge of the database at all, but should rely on their methods to
query, insert, update, and delete from the database using the functions
exported by Bric::Util::DBI.

Bric::Util::DBI is not a complete database-independent solution, however. In
particular, it does nothing to translate between the SQL syntaxes supported by
different database platforms. As a result, you are encouraged to write your
queries in as generic a way as possible, and to comment your code copiously
when you must use proprietary or not-widely supported SQL syntax (such as
outer joins).

B<NOTE:> Bric::Util::DBI is intended only for internal use by Bricolage
modules. It must not be C<use>d anywhere else in the application (e.g., in an
Apache startup file) or users of the application may be able to gain access to
our database.

=cut

##############################################################################
# Dependencies
##############################################################################
# Standard Dependencies
use strict;

##############################################################################
# Programmatic Dependences
##############################################################################
# DBI Error Handling.
##############################################################################
use Bric::Config qw(:dbi :mod_perl);

BEGIN {
    eval "require Bric::Util::DBD::".DBD_TYPE;
    die $@ if $@;
    ('Bric::Util::DBD::'.DBD_TYPE)->import(qw(:all));
}

use Bric::Util::Fault qw(throw_da);
use DBI qw(looks_like_number);
use Time::HiRes qw(gettimeofday);
use Digest::MD5 qw(md5_hex);

##############################################################################
# Constants
##############################################################################
use constant CALL_TRACE => DBI_CALL_TRACE || 0;
use constant DEBUG => DBI_DEBUG || 0;
# You can set DBI_TRACE from 0 (Disabled) through 9 (super verbose).
use constant DBI_TRACE => 0;

use constant CONNECT_USER => $ENV{BRIC_DBI_USER} || DBI_USER;
use constant CONNECT_PASS => exists $ENV{BRIC_DBI_PASS}
    ? $ENV{BRIC_DBI_PASS}
    : DBI_PASS;
DBI->trace(DBI_TRACE);

# The strftime format for DB dates. Used by Bric::Util::Time::db_date().
use constant DB_DATE_FORMAT => Bric::Config::ISO_8601_FORMAT;

# Package constant variables. This one is for the DB connection attributes.
my $ATTR =  { RaiseError         => 1,
          PrintError         => 0,
          AutoCommit         => 0,
          ChopBlanks         => 1,
          ShowErrorStatement => 1,
          LongReadLen        => 32768,
          LongTruncOk        => 0,
              DBH_ATTR,
};
my $AutoCommit = 1;

##############################################################################
# Inheritance
##############################################################################
use base qw(Exporter);

# You can explicitly import any of the functions in this class. The last two
# should only ever be imported by Bric::Util::Time, however.
our @EXPORT_OK = qw(prepare prepare_c prepare_ca execute fetch row_aref
            col_aref last_key next_key db_date_parts db_datetime
            DB_DATE_FORMAT clean_params bind_columns bind_col
            bind_param begin commit rollback finish is_num row_array
            all_aref fetch_objects order_by group_by build_query
            build_simple_query where_clause tables ANY NONE any_where
                    DBD_TYPE group_concat_sql LIMIT_DEFAULT);

# But you'll generally just want to import a few standard ones or all of them
# at once.
our %EXPORT_TAGS = (standard => [qw(prepare_c row_aref fetch fetch_objects
                                    execute next_key last_key bind_columns
                                    finish any_where DBD_TYPE
                                    group_concat_sql)],
            trans => [qw(begin commit rollback)],
                    junction => [qw(ANY NONE)],
            all => \@EXPORT_OK);

# Disconnect! Will be ignored by Apache::DBI.
END { _disconnect(); }

##############################################################################
# Exportable Functions
##############################################################################

=pod

=head1 Interface

There are several ways to C<use Bric::Util::DBI>. Some options include:

  # Get the standard db functions.
  use Bric::Util::DBI qw(:standard);

  # Get standard and transactional functions.
  use Bric::Util::DBI qw(:standard :trans);

  # Get all the functions.
  use Bric::Util::DBI qw(:all);

  # Get specific functions.
  use Bric::Util::DBI qw(prepare_c execute fetch);

The first example imports all the functions you are likely to need in the
normal course of writing a Bricolage class. The second example imports the
standard functions plus functions needed for managing transactions. The third
example imports all the functions and variables provided by Bric::Util::DBI.
These should cover all of your database needs. The last example imports only a
few key functions and variables. You may explicitly import as many functions
and variables as you wish in this way. Specifying no parameters, e.g.,

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

DB_DATE_FORMAT - the strftime format for the date format used by the
database. Used by Bric::Util::Time; you should not need this - use the
functions exported by Bric::Util::Time instead.

=back

=back

Each of the functions below that will directly access the database will first
check for a connection to the database and establish the connection if it does
not exist. There is no need to worry about accessing or storing a $dbh in any
Bricolage module. Plus, each function handles all aspects of database
exception handling so that you do not have to. The exception is with the
transactional functions; see Begin() below for more information.

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

=item ANY

  my @p = Bric::Biz::Person->list({ lname => ANY( 'wall', 'conway') });

Use this function when you want to perform a query comparing more than one
value, and you want objects returned that match any of the values passed.

B<Throws:>

=over 4

=item No parameters passed to ANY()"

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub ANY {
    throw_da "No parameters passed to ANY()" unless @_;
    bless \@_, 'Bric::Util::DBI::ANY';
}

=item NONE

  my @p = Bric::Biz::Person->list({ lname => NONE( 'wall', 'conway') });

Use this function when you want to perform a query comparing more than one
value, and you want objects returned that don't match any of the values passed
(c.f. L</ANY>; C<NONE> can be used anywhere that C<ANY> can be)

B<Throws:>

=over 4

=item No parameters passed to NONE()"

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub NONE {
    throw_da "No parameters passed to NONE()" unless @_;
    bless \@_, 'Bric::Util::DBI::NONE';
}

=item my $bool = is_num(@values)

Alias for DBI::looks_like_number() to determine whether or not the values
passed are numbers. Returns true for each value that looks like a number, and
false for each that does not. Returns undef for each element that is undefined
or empty.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

{ no warnings;
  *is_num = *DBI::looks_like_number;
}

##############################################################################

=item $sth = prepare($sql)

=item $sth = prepare($sql, $attr)

Returns an $sth from $dbh->prepare. Pass any attributes you want associated
with your $sth via the $attr hashref. In general, use prepare_c() instead of
prepare().

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
than fetch($select) with bound columns. If you need to use one of these
methods let me know and we will see about adding them as functions to
Bric::Util::DBI. But it should not be necessary. Better yet, anytime you find
yourself wanting to use $select->fetchrow_hashref(), take it as a cue to go
back, look at your code design, and decide whether you are making the best
design decisions.

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
    my $dbh = _connect();
    my $sth = eval { $dbh->prepare(@_) };
    throw_da error   => "Unable to prepare SQL statement\n\n$_[0]",
             payload => $@
      if $@;
    _debug_prepare(\$_[0]) if DEBUG;
    return $sth;
} # prepare()

##############################################################################

=pod

=item my $sth = prepare_c($sql, $attr)

Returns an $sth from $dbh->prepare_cached. Pass any attributes you want
associated with your $sth via the $attr hashref. A warning will also be issued
if the $sth returned is already active.

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
    my $dbh = _connect();
    my $sth = eval { $dbh->prepare_cached(@_) };
    throw_da error   => "Unable to prepare SQL statement\n\n$_[0]",
             payload => $@
      if $@;
    _debug_prepare(\$_[0]) if DEBUG;
    return $sth;
} # prepare_c()

##############################################################################

=pod

=item my $sth = prepare_ca($sql, $attr)

Returns an $sth from $dbh->prepare_cached, and will not issue a warning if the
$sth returned is already active. Pass any attributes you want associated with
your $sth via the $ATTR hashref.

See also the important note in the prepare() documentation above.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=back

B<Side Effects:> Calls $dbh->prepare_cached() with the active flag set to
true.

B<Notes:> NONE.

=cut

sub prepare_ca {
    my $dbh = _connect();
    my $sth = eval { $dbh->prepare_cached(@_[0, 1], 1) };
    throw_da error   => "Unable to prepare SQL statement\n\n$_[0]",
             payload => $@
      if $@;
    _debug_prepare(\$_[0]) if DEBUG;
    return $sth;
} # prepare_ca()

##############################################################################

=item my $ret = begin()

  begin();
  eval {
      execute($ins1);
      execute($ins2);
      execute($upd);
      commit();
  };
  if (my $err = $@) {
      rollback();
      rethrow_exception($err);
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
    return 1 if MOD_PERL && !$_[0];
    my $dbh = _connect();

    # Turn off AutoCommit. We can switch to begin_work() once DBD::Pg supports
    # it.
    my $ret = eval { $dbh->{AutoCommit} = 0 if $dbh->{AutoCommit} };
    throw_da error   => "Unable to turn AutoCommit off",
             payload => $@
      if $@;

    # Set our default attributes to have AutoCommit off for all new
    # connections.
    $AutoCommit = 0;
    return $ret;
} # begin()

##############################################################################

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
    return 1 if MOD_PERL && !$_[0];
    my $dbh = _connect();

    # Commit the transaction.
    my $ret = eval { $dbh->commit unless $dbh->{AutoCommit} };
    throw_da error   => "Unable to commit transaction",
             payload => $@
      if $@;

    # Turn AutoCommit back on. When DBD::Pg adds support for begin_work(),
    # we can eliminate this step.
    eval { $ret = $dbh->{AutoCommit} = 1 };
    throw_da error   => "Unable to turn AutoCommit on",
             payload => $@
      if $@;

    # Set our default attributes to have AutoCommit on for all new
    # connections.
    $AutoCommit = 1;

    return $ret;
} # commit()

##############################################################################

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
    return 1 if MOD_PERL && !$_[0];
    my $dbh = _connect();

    # Rollback the transaction.
    my $ret = eval { $dbh->rollback unless $dbh->{AutoCommit} };
    throw_da error   => "Unable to rollback transaction",
             payload => $@
      if $@;

    # Turn AutoCommit back on. When DBD::Pg adds support for begin_work(),
    # we can eliminate this step.
    eval { $ret = $dbh->{AutoCommit} = 1 };
    throw_da error   => "Unable to turn AutoCommit on",
             payload => $@
      if $@;

    # Set our default attributes to have AutoCommit on for all new
    # connections.
    $AutoCommit = 1;

    return $ret;
} # rollback()

##############################################################################

=item fetch_objects( $pkg, $sql, $fields, $grp_col_cnt, $args )

This function takes a package name, a reference to an SQL statement, an
arrayref of fields, a count of the number of columns containing lists of group
IDs, a list of arguments. It uses the results from the SQL statement to
construct objects of the specified package.

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
    my ($pkg, $sql, $fields, $grp_col_cnt, $args) =  @_;
    my (@objs, @d, $grp_ids);

    # Prepare and execute the query
    my $select = prepare_ca($$sql, undef);
    execute($select, @$args);
    bind_columns($select, \@d[0 .. $#$fields + $grp_col_cnt - 1]);

    # loop through the list, looking for different grp__id columns in
    # matching lines.  Note: this works for all sort orders except grp__id
    my $obj_col = $pkg->OBJECT_SELECT_COLUMN_NUMBER || 0;
    while (fetch($select)) {
        my $obj = bless {}, $pkg;
        # The group IDs are in the last four columns.
        $grp_ids = $d[-$grp_col_cnt] = [
            map { split } grep { defined } @d[-$grp_col_cnt..-1]
        ];
        $obj->_set($fields, \@d);
        $obj->_set__dirty(0);
        # Cache the object before reblessing it.
        $obj->cache_me;
        $obj = bless $obj, Bric::Util::Class->lookup({
            id => $obj->get_class_id })->get_pkg_name
            if $pkg->HAS_CLASS_ID;
        push @objs, $obj;
    }
    finish($select);
    # Return the objects.
    return (wantarray ? @objs : \@objs);
}

=item build_query($cols, $tables, $where_clause, $order);

Builds a and returns a reference to a query.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub build_query {
    my ($pkg, $cols, $grp_by, $tables, $where_clause, $order, $limit,
        $offset) = @_;

    # get the various parts of the query
    my $sql = qq{
      SELECT $cols
      FROM   $tables
      WHERE  $where_clause
      $grp_by
      $order\n};

    # LIMIT OFFSET compatibility measure for MySQL
    $limit = LIMIT_DEFAULT if DBD_TYPE eq 'mysql' and $offset and !$limit;
    $sql .= qq{      LIMIT $limit\n}   if $limit  && $limit  =~ /^\d+$/;
    $sql .= qq{      OFFSET $offset\n} if $offset && $offset =~ /^\d+$/;
    return \$sql;
}

=item $params = clean_params($params)

Parameters for Asset objects should be run through this before sending them to
the query building functions.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Bric::Util::Time must be loaded before this method is called.

=cut

sub clean_params {
    my $class = shift;
    # Copy the parameters to that we don't create any undesirable side-effects.
    my $param = defined $_[0] ? { %{+shift} } : {};
    # Make sure to set active explictly if its not passed.
    $param->{'active'} = exists $param->{'active'} ? $param->{'active'} : 1;
    # Map inverse alias inactive to active.
    $param->{'active'} = ($param->{'inactive'} ? 0 : 1)
      if exists $param->{'inactive'};
    unless ($param->{published_version} or $param->{version_id}) {
        # checked_out has some special cases
        # deal with the checked_out param.  The all argument is actually
        # the default behavior.
        $param->{_checked_out} = $param->{checked_out}
          if exists $param->{checked_out} && $param->{checked_out} ne 'all';
        # this will override the above
        $param->{_checked_out} = $param->{checkout} if exists $param->{checkout};
        # this is last because it's most important for defining a workspace
        $param->{_checked_out} = 1
          if defined $param->{user__id} || defined $param->{user_id};
        if (defined $param->{_checked_out}) {
            # Make sure we have valid checkout values -- that is, no null
            # strings!
            @{$param}{qw(_not_checked_out _checked_out)} = (0, 0)
              unless $param->{_checked_out};
            # Checked out and checked in don't mix.
            delete $param->{checked_in};
        } else {
            # finally the default
            $param->{_checked_in_or_out} = 1 unless $param->{checked_in};
        }

        # trim cruft
        delete $param->{checkout};
        delete $param->{checked_out};
    }
    # take care of the simple query, or lack thereof
    $param->{_not_simple} = 1 unless $param->{simple};
    # we can only handle the returned versions p in reverse
    $param->{_no_return_versions} = 1
      unless $param->{return_versions}
      || defined $param->{version}
      || $param->{published_version}
      || $param->{version_id};
    # add default order
    $param->{Order} = $class->DEFAULT_ORDER unless $param->{Order};
    # support of NULL workflow__id
    if( exists $param->{workflow__id} && ! defined $param->{workflow__id} ) {
        $param->{_null_workflow_id} = 1;
        delete $param->{workflow__id};
    }

    # Convert dates to UTC. Note that Bric::Util::Time must be loaded external
    # to Bric::Util::DBI, or else we run into nasty mutual dependencies.
    for my $df (qw(publish_date publish_date_start publish_date_end
                   first_publish_date first_publish_date_start first_publish_date_end
                   cover_date cover_date_start cover_date_end
                   expire_date expire_date_start expire_date_end)) {
        $param->{$df} = Bric::Util::Time::db_date($param->{$df}) if $param->{$df};
    }
    # Return the parameters.
    return $param;
}

=item tables

The from clause for the main select is built here.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub tables {
    my ($pkg, $param) = @_;
    my $from = $pkg->FROM;
    foreach (keys %$param) {
        my $t = $pkg->PARAM_FROM_MAP->{$_} or next;
        next if $from =~ m/$t/;
        $from .= ', ' . $t;
    }
    return $from;
}

=item where_clause

The where clause for the main select is built here.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub where_clause {
    my ($pkg, $param) = @_;
    my (@args, $where, $and);

    $where = $pkg->WHERE;

    # This is so that if there are both ANY and NOT (or multiple
    # of either, for that matter) of the same param,
    # it only gets added once (e.g. for 'site', we only need
    # to add 's.site__id = site.id' (in PARAM_ANYWHERE_MAP) once).
    my %seen;

    while (my ($k, $v) = each %$param) {
        next unless defined $v;
        my $sql = $pkg->PARAM_WHERE_MAP->{$k} or next;

        # XXX: this duplicates any_where
        my $not = UNIVERSAL::isa($v, 'Bric::Util::DBI::NONE') ? 'NOT' : '';
        if ($not or UNIVERSAL::isa($v, 'Bric::Util::DBI::ANY')) {
            # The WHERE clause may be in two parts.
            if (my $any = $pkg->PARAM_ANYWHERE_MAP->{$k}) {
                $where .= " AND $any->[0]" unless exists $seen{$k};
                $sql = $any->[1];
            }
            # For exclude with ANY, must use AND not OR
            my $op = $sql =~ /(?:<>|!=)\s+[?]/ ? ' AND ' : ' OR ';
            $where .= " AND $not(" . join($op, ($sql) x @$v) . ')';
            my $count = $sql =~ s/\?//g;
            push @args, ($_) x $count for @$v;
        } else {
            $where .= " AND $sql";
            push @args, ($v) x $sql =~ s/\?//g;
        }
    }
    return $where, \@args;
}

##############################################################################

=item any_where

  my $where = any_where($value, $where_expression, \@params);

Examines $value to determine whether it is a single value or an C<ANY> or
a C<NONE> value. If it is an C<ANY> or a C<NONE> value, then each of those
values is pushed on to the end of the C<$params> array reference and the
C<where> expression is grouped together in parentheses and C<OR>ed together
the same number of times as there are values (and in the case of C<NONE>,
the word "NOT" comes before the parentheses). Otherwise, a single value
is pushed onto the C<$params> array reference and the C<where> expression
simply returned.

For example, if called like so:

  my @params;
  my $where = any_where(ANY(1, 2, 3), "f.name = ?", \@params);

Then C<@params> will contain C<(1, 2, 3)> and the string "(f.name = ? OR
f.name = ? OR f.name = ?)" will be assigned to C<$where>. If called with
C<NONE> instead of C<ANY>, the string would be "NOT(f.name = ? OR
f.name = ? OR f.name = ?)".

However, if the value is not an C<ANY> or a C<NONE> value:

  my @params;
  my $where = any_where(1, "f.name = ?", \@params);

Then C<@params> will of course contain only C<(1)> and the string "f.name = ?"
will be assigned to C<$where>.

This function is useful in classes that wish to add C<ANY>/C<NONE> support to
specific C<list()> method parameters.

=cut

sub any_where {
    my ($value, $sql, $params) = @_;
    my $not = UNIVERSAL::isa($value, 'Bric::Util::DBI::NONE') ? 'NOT' : '';
    if ($not or UNIVERSAL::isa($value, 'Bric::Util::DBI::ANY')) {
        push @$params, @$value;
        # For exclude with ANY, must use AND not OR
        my $op = $sql =~ /(?:<>|!=)\s+[?]/ ? ' AND ' : ' OR ';
        return "$not(" . join($op, ($sql) x @$value) . ')';
    }
    push @$params, $value;
    return $sql;
}

##############################################################################

=item my $order_by = order_by

Builds up the ORDER BY clause.

B<Throws:>

=over 4

=item Bad Order parameter.

=item OrderDirection parameter must either ASC or DESC.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub order_by {
    my ($pkg, $param) = @_;

    my $id_col = $pkg->ID_COL;

    # Default to returning ID.
    return "ORDER BY $id_col" unless $param->{Order};

    # Grab the order map.
    my $map = $pkg->PARAM_ORDER_MAP;

    # Make sure it's legit.
    my $ords = ref $param->{Order} ? $param->{Order} : [ $param->{Order} ];
    my $dirs = ref $param->{OrderDirection} ? $param->{OrderDirection}
                                            : [ $param->{OrderDirection} ]
                                            ;

    # Assemble the order atttributes.
    my @ord;
    for my $i (0..$#$ords) {
        my $attr = $map->{$ords->[$i]}
            or throw_da "Bad Order parameter '$ords->[$i]'";
        if (my $dir = $dirs->[$i]) {
            throw_da 'OrderDirection parameter must either ASC or DESC.'
                if $dir ne 'ASC' and $dir ne 'DESC';
            $attr .= " $dir";
        }
        push @ord, $attr;
    }

    # Return the ORDER BY clause with the ID column.
    return 'ORDER BY ' . join(', ', @ord) . ", $id_col";
}

##############################################################################

=item my $group_by = group_by

Builds up the GROUP BY clause.

B<Throws:> None.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub group_by {
    my ($pkg, $param) = @_;
    my $grp_by = 'GROUP  BY ' . $pkg->COLUMNS . $pkg->RO_COLUMNS;
    return $grp_by unless $param->{Order};
    # Grab the specified ording column and add it to the GROUP BY clause,
    # if it's not already included.
    my $ord = $pkg->PARAM_ORDER_MAP->{$param->{Order}};
    # XXX I sure wish there was a hash to check for this, rather than
    # doint the regular expression.
    $grp_by .= ", $ord" unless $grp_by =~ /$ord/;
    return $grp_by;
}


##############################################################################

=item my $ret = execute($sth, @params)

Executes the prepared statement. Use this instead of $sth->execute(@params)
and it will take care of exception handling for you. Returns the value
returned by $sth->execute().

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

    my $ret = eval { $sth->execute(@_) };
    throw_da error   => "Unable to execute SQL statement",
             payload => $@
      if $@;
    _profile_stop()           if DBI_PROFILE;
    return $ret;
}

##############################################################################

=item my $ret = bind_columns($sth, @args)

Binds variables to the columns in the statement handle. Functions exactly the
same as $sth->bind_columns, only it handles the exception handling for
you. Returns the value returned by $sth->bind_columns.

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
    my $ret = eval { $sth->bind_columns(@_) };
    throw_da error   => "Unable to bind to columns to statement handle",
             payload => $@
      if $@;
    return $ret;
}

##############################################################################

=item my $ret = bind_col($sth, @args)

Binds a variable to a columns in the statement handle. Functions exactly the
same as $sth->bind_col, only it handles the exception handling for
you. Returns the value returned by $sth->bind_col.

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
    my $ret = eval { $sth->bind_col(@_) };
    throw_da error   => "Unable to bind to column to statement handle",
             payload => $@
      if $@;
    return $ret;
}

##############################################################################

=item my $ret = bind_param($sth, @args)

Binds parameter to the columns in the statement handle. Functions exactly the
same as $sth->bind_param, only it handles the exception handling for
you. Returns the value returned by $sth->bind_param.

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
    my $ret = eval { $sth->bind_param(@_) };
    throw_da error   => "Unable to bind parameters to columns in statement handle",
             payload => $@
      if $@;
    return $ret;
}

##############################################################################

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
    my $ret = eval { $sth->fetch(@_) };
    throw_da error   => "Unable to fetch row from statement handle",
             payload => $@
      if $@;
    return $ret;
}

##############################################################################

=item my $ret = finish($sth)

Performs $sth->finish() and returns the result. Functions exactly the same as
$sth->finish, only it handles the exception handling for you.

B<Throws:>

=over 4

=item *

Unable to finish statement handle.

=back

B<Side Effects:> Calls $sth->finish().

B<Notes:> Do B<not> confuse this function with finishing transactions. It
simply tells a SELECT statement handle that you are done fetching records from
it, so it can free up resources in the database. If you have started a series
of transactions with begin(), finish() will not commit them; only commit()
will commit them, and rollback() will roll them back.

=cut

sub finish {
    my $sth = shift;
    my $ret = eval { $sth->finish(@_) };
    throw_da error   => "Unable to finish statement handle",
             payload => $@
      if $@;
    return $ret;
}

##############################################################################

=begin comment

This was an experimental fetch_em method. Might return to it at some point,
but for now, neither I nor anyone else is using it.

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

An anonymous array of the names of the properties to be loaded into each
object. These should be in the same order as the columns selected from the
database. Required.

=item $args

An anonymous array of arguments to be passed to $select->execute(). Optional.

=item $join

An anonymous hash of arguments to be used for fetching a subset of data for an
object. Optional. The supported keys are:

=over 4

=item props

An anonymous array of the names of the properties to be loaded into each
joined data subset. These should be in the same order as the columns selected
from the database, following the columns selected for $props above. Required.

=item id

The name of the field that stores the objects unique ID. This will be used to
determine when a C<fetch_em>ed row represents a new object. Required.

=item obj_key

The name of the object property that will hold the joined data. Required.

=item key

The name of the field that holds a unique identifier for an individual joined
row so that the joined data subset can be stored in an anonymous
hash. Optional. If not defined, the joined data will be stored in an anonymous
array.

=item class

The class against which to call _new() to instantiate each joined data set as
an object. Optional. If not defined, each joined data set will be stored as an
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
  }, undef);
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
  }, undef);
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
  }, undef);
  # This will fill @people with 'Bric::Biz::Person' objects and an anonymous
  # hash of groups keyed by group ID.
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
    # categories of data we need to load - basic properties and
        # attributes.
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

##############################################################################

=pod

=item my $row = row_aref($select, @params)

Executes the SELECT statement in $select and returns the first row of values
in an array reference. Preferred for use fetching just one row, but if passed
a multi-row query, will return the first row only. If placeholders have been
used in $select, pass the parameters that map to them. This function B<will>
prepare() the query in $select, but it will not prepare_c() it. Thus it is
generally prefered to prepare_c($select) yourself and then pass it to
row_aref() as an $sth. See the Synopsis above for an example.

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
    my $dbh = _connect();
    _debug_prepare_and_execute(\@params, \$qry) if DEBUG;
    _profile_start() if DBI_PROFILE;

    my $aref = eval { $dbh->selectrow_arrayref($qry, undef, @params) };
    throw_da error   => "Unable to select row",
             payload => $@
      if $@;

    _profile_stop() if DBI_PROFILE;
    return $aref;
} # row_aref()

##############################################################################

=item my @row = row_array($select, @params)

Executes the SELECT statement in $select and returns the first row of values
in an array. Preferred for use fetching just one row, but if passed a
multi-row query, will return the first row only. If placeholders have been
used in $select, pass the parameters that map to them. This function B<will>
prepare() the query in $select, but it will not prepare_c() it. Thus it is
generally prefered to prepare_c($select) yourself and then pass it to
row_array() as an $sth. For an example, see how the Synopsis above does this
for row_aref().

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
    my $dbh = _connect();
    _debug_prepare_and_execute(\@params, \$qry) if DEBUG;
    _profile_start() if DBI_PROFILE;

    my @array;
    eval { @array = $dbh->selectrow_array($qry, undef, @params) };
    throw_da error   => "Unable to select row",
             payload => $@
      if $@;

    _profile_stop() if DBI_PROFILE;
    return @array;
} # row_array()

##############################################################################

=item my $data = all_aref($select, @params)

Executes $dbh->selectall_arrayref($select) and returns the data structure
returned by that DBI method. See DBI(2) for details on the data structure. If
placeholders have been used in $select, pass the parameters that map to
them. This function B<will> prepare() the query in $select, but it will not
prepare_c() it. Thus it is generally prefered to prepare_c($select) yourself
and then pass it to all_aref() as an $sth. For an example, see how the
Synopsis above does this for row_aref().

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
    my $dbh = _connect();
    _debug_prepare_and_execute(\@params, \$qry) if DEBUG;
    _profile_start() if DBI_PROFILE;

    my $aref = eval { $dbh->selectall_arrayref($qry, undef, @params) };
    throw_da error   => "Unable to select all",
             payload => $@
      if $@;

    _profile_stop() if DBI_PROFILE;
    return $aref;
} # all_aref()

##############################################################################

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
    my $dbh = _connect();
    _debug_prepare_and_execute(\@params, \$qry) if DEBUG;
    _profile_start() if DBI_PROFILE;

    my $col = eval { $dbh->selectcol_arrayref($qry, undef, @params) };
    throw_da error   => "Unable to select column into arrayref",
             payload => $@
      if $@;

    _profile_stop() if DBI_PROFILE;
    return $col;
} # col_aref()

##############################################################################

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
  }, undef);

  # Don't try to set ID - it will fail!
  execute($insert, $self->_get(@cols[1..$#cols));

  # Now grab the ID!
  $self->_set({id => last_key('person')});

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub next_key { next_key_sql(@_, $Bric::Cust); } # next_key()

##############################################################################

=item last_key($table_name)

=item last_key($table_name, $db_name)

Returns the last sequence number inserted into $db_name.$table_name by the
current process. If $db_name is not passed, it defaults to the value stored in
$Bric::Cust. Will return undef if this process has not yet inserted anything
into $table_name. Use for retreiving an object ID immediately after executing
an INSERT statement. See next_key() above for an example.

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
    my ($name, $db) = @_;
    my $sth = prepare_c(last_key_sql($name, $db || $Bric::Cust), undef);
    return row_aref($sth)->[0];
} # last_key()

=back

=head1 Private

NONE.

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=cut

##############################################################################

=head2 Private Functions

=over 4

=item _connect()

Returns a connection to the database using C<< DBI->connect_cached()
>>. Should be called at the start of every function that does database access.

B<Notes:> NONE.

=cut

sub _connect {
    my $dbh = eval {
        # Prevent using the same connection across processes.
        $ATTR->{bric_process_id} = $$;
        my $d = DBI->connect_cached(join(':', 'DBI', DBD_TYPE, DSN_STRING),
                                    CONNECT_USER, CONNECT_PASS, $ATTR);
        # Make sure we're consistent about what we think the transaction
        # state is.
        $d->{AutoCommit} = $AutoCommit;
        return $d;
    };

    throw_da error   => "Unable to connect to database",
             payload => $@
      if $@;
    return $dbh;
}

##############################################################################

=item _disconnect()

Disconnects from the database. Called by an END block installed by this
package.

=cut

sub _disconnect {
    eval {
        my $dbh = _connect();
        # Don't commit, in case we're ending unexpectedly.
        $dbh->rollback unless $dbh->{AutoCommit};
        $dbh->disconnect;
    };
    throw_da error   => "Unable to disconnect from database",
             payload => $@
      if $@;
    $AutoCommit = 1;
}

##############################################################################

=item _debug_prepare(\$sql)

Prints out debugging messages for a prepare call. Should be called by
functions that prepare statements when DEBUG (DBI_DEBUG) is true.

=cut

sub _debug_prepare {
    my $sql_ref = shift;
    my $sig = _statement_signature($sql_ref);
    print STDERR "############# Prepare Query [$sig]:\n$$sql_ref\n",
             "#############\n\n";
    _print_call_trace() if CALL_TRACE;
}

##############################################################################

=item _debug_execute(\@args, $sth)

Prints out debugging messages for an execute call. Should be called by
functions that execute statements when DEBUG (DBI_DEBUG) is true.

=cut

sub _debug_execute {
    my ($args, $sth) = @_;
    my $sig = _statement_signature(\$sth);
    print STDERR "+++++++++++++ Execute Query [$sig]\n";
    print STDERR "+++++++++++++ ARGS: ", 
    join(', ', map { defined $_ ? $_ : 'NULL' } @$args),
        "\n\n";
    _print_call_trace() if CALL_TRACE;
}

##############################################################################

=item _debug_prepare_and_execute(\@args, \$sql)

=item _debug_prepare_and_execute(\@args, \$sth)

Prints out debugging messages for a call that prepares and executes in one
call. Should be called by functions that prepare and execute when DEBUG
(DBI_DEBUG) is true.

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

##############################################################################

=item _statement_signature(\$sql)

=item _statement_signature(\$sth)

Returns a fingerprint for an sql statement or statement handle. Used in debug
output to match prepares to executes.

=cut

sub _statement_signature {
    my $ref = shift;
    my $sig = ref $$ref ? md5_hex(${$ref}->{Statement}) : md5_hex($$ref);
    substr($sig, $_, 0) = " " for (4, 9, 14, 19, 24, 29, 34);
    return $sig;
}

##############################################################################

=item _print_call_trace

Writes out a call trace to STDERR. Should be called by functions that prepare
statements when CALL_TRACE (DBI_CALL_TRACE) is true.

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

##############################################################################

=item _profile_start()

Starts a timer used to profile database calls. Should be called before query
execution when DBI_PROFILE is true.

=cut

{
    my $PROF_TIMER;
    sub _profile_start {
    $PROF_TIMER = gettimeofday();
    }

##############################################################################

=item _profile_stop()

Stops the profile timer and writes out the timing results to STDERR. Should be
called immediately after query execution when DBI_PROFILE is true.

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

=head1 Notes

NONE.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 See Also

L<DBI|DBI>,
L<Bric|Bric>,
L<Bric::Util::Time|Bric::Util::Time>,
L<Bric::Util::DBD::Oracle|Bric::Util::DBD::Oracle>

=cut
