package Bric::Util::Pref;

=head1 NAME

Bric::Util::Pref - Interface to Bricolage preferences.

=Head1 VERSION

$Revision: 1.4 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.4 $ )[-1];

=head1 DATE

$Date: 2001-11-20 00:02:45 $

=head1 SYNOPSIS

  use Bric::Util::Pref;

  # Constructors.
  my $pref = Bric::Util::Pref->new($init);
  $pref = Bric::Util::Pref->lookup({ id => $id });
  $pref = Bric::Util::Pref->lookup({ name => $name });
  my @prefs = Bric::Util::Pref->list($params);

  # Class Methods.
  my @pref_ids = Bric::Util::Pref->list_ids($params);
  my $meths = Bric::Util::Pref->my_meths;
  my @meths = Bric::Util::Pref->my_meths(1);
  # Fetch a value from the cache.
  my $val = Bric::Util::Pref->lookup_val($name);

  # Instance Methods
  my $id = $pref->get_id;
  my $name = $pref->get_name;
  my $desc = $pref->get_description;
  my $default = $pref->get_default;
  my $val_name = $pref->get_val_name;

  # Get a list of available value options.
  my @opts = $pref->get_opts;
  my $opts_ref = $pref->get_opts_href;

  # Get and set the value.
  my $value = $pref->get_value;
  $pref = $pref->set_value($value);

  # Save the pref.
  $pref = $pref->save;

=head1 DESCRIPTION

This is the central interface for managing Bricolage application preferences. It should
scale when we later decide to add user and user group preferences. Right now
it'll just support those global application preferencest that we deem necessary
for the application to work, such as Time Zone.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);
use Bric::Util::Fault::Exception::DP;
use Bric::App::Cache;
# Use require to prevent circular conflicts.
require Bric::Util::Grp::Pref;

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $get_opts, $load_cache, $cache_val);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::Pref';
use constant INSTANCE_GROUP_ID => 22;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $dp = 'Bric::Util::Fault::Exception::DP';
my @cols = qw(p.id p.name p.description p.def p.value o.description);
my @props = qw(id name description default value val_name);
my @ord = @props[1..$#props];
my $prefkey = '__PREF__';
my $meths;
my $cache;

################################################################################

################################################################################
# Instance Fields
use Bric::Util::Grp;
BEGIN {
    Bric::register_fields({
			 # Public Fields
			 id => Bric::FIELD_READ,
			 name => Bric::FIELD_READ,
			 description => Bric::FIELD_READ,
			 value => Bric::FIELD_RDWR,
			 default => Bric::FIELD_READ,
			 val_name => Bric::FIELD_READ,

			 # Private Fields
			 _opts => Bric::FIELD_NONE,
			 _val_ch => Bric::FIELD_NONE
			});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $pref = Bric::Util::Pref->lookup({ id => $id })

=item my $pref = Bric::Util::Pref->lookup({ name => $name })

Looks up and instantiates a new Bric::Util::Pref object based on the
Bric::Util::Pref object ID or name passed. If $id or $name is not found in the
database, lookup() returns undef.

B<Throws:>

=over

=item *

Too many Bric::Dist::Util::Pref objects found.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> If $id is found, populates the new Bric::Util::Pref object with
data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pref = &$get_em(@_);
    # We want @$pref to have only one value.
    die $dp->new({ msg => 'Too many Bric::Util::Pref objects found.' })
      if @$pref > 1;
    return @$pref ? $pref->[0] : undef;
}

################################################################################

=item my (@prefs || $prefs_aref) = Bric::Util::Pref->list($params)

Returns a list or anonymous array of Bric::Util::Pref objects based on the search
parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item *

description

=item *

default

=item *

value

=item *

val_name

=back

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> Populates each Bric::Util::Pref object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=back 4

=head2 Destructors

=over 4

=item $pref->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

=over

=item my (@pref_ids || $pref_ids_aref) = Bric::Util::Pref->list_ids($params)

Returns a list or anonymous array of Bric::Util::Pref object IDs based on the
search criteria passed via an anonymous hash. The supported lookup keys are the
same as those for list().

B<Throws:>

over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_ids { wantarray ? @{ &$get_em(@_, 1) } : &$get_em(@_, 1) }

################################################################################

=item my $val = Bric::Util::Pref->lookup_val($pref_name)

Looks up and returns the value of a preference without the expense of
instantiating an object. Plus, it uses caching to keep it quick - the cache
changes only when a value changes.

B<Throws:>

=over 4

=item *

Unable to instantiate create cache.

=item *

Unable to populate preference cache.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Unable to get cache value.

=back

B<Side Effects:> See &$load_cache().

B<Notes:> See &$load_cache().

=cut

sub lookup_val {
    $cache ||= &$load_cache;
    return $cache->get($prefkey)->{$_[1]};
}

################################################################################

=item $meths = Bric::Util::Pref->my_meths

=item (@meths || $meths_aref) = Bric::Util::Pref->my_meths(TRUE)

Returns an anonymous hash of instrospection data for this object. If called with
a true argument, it will return an ordered list or anonymous array of
intrspection data. The format for each introspection item introspection is as
follows:

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item *

name - The name of the property or attribute. Is the same as the hash key when
an anonymous hash is returned.

=item *

disp - The display name of the property or attribute.

=item *

get_meth - A reference to the method that will retrieve the value of the
property or attribute.

=item *

get_args - An anonymous array of arguments to pass to a call to get_meth in
order to retrieve the value of the property or attribute.

=item *

set_meth - A reference to the method that will set the value of the
property or attribute.

=item *

set_args - An anonymous array of arguments to pass to a call to set_meth in
order to set the value of the property or attribute.

=item *

type - The type of value the property or attribute contains. There are only
three types:

=over 4

=item short

=item date

=item blob

=back

=item *

len - If the value is a 'short' value, this hash key contains the length of the
field.

=item *

search - The property is searchable via the list() and list_ids() methods.

=item *

req - The property or attribute is required.

=item *

props - An anonymous hash of properties used to display the property or attribute.
Possible keys include:

=over 4

=item *

type - The display field type. Possible values are

=item text

=item textarea

=item password

=item hidden

=item radio

=item checkbox

=item select

=back

=item *

length - The Length, in letters, to display a text or password field.

=item *

maxlength - The maximum length of the property or value - usually defined by the
SQL DDL.

=item *

rows - The number of rows to format in a textarea field.

=item

cols - The number of columns to format in a textarea field.

=item *

vals - An anonymous hash of key/value pairs reprsenting the values and display
names to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_meths {
    my ($pkg, $ord) = @_;

    # Return 'em if we got em.
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}]
      if $meths;

    # We don't got 'em. So get 'em!
    $meths = {
	      name      => {
			     name     => 'name',
			     get_meth => sub { shift->get_name(@_) },
			     get_args => [],
			     set_meth => sub { shift->set_name(@_) },
			     set_args => [],
			     disp     => 'Name',
			     search   => 1,
			     len      => 64,
			     req      => 0,
			     type     => 'short',
			     props    => {   type       => 'text',
					     length     => 32,
					     maxlength => 64
					 }
			    },
	      description      => {
			     name     => 'description',
			     get_meth => sub { shift->get_description(@_) },
			     get_args => [],
			     set_meth => sub { shift->set_description(@_) },
			     set_args => [],
			     disp     => 'Description',
			     len      => 256,
			     req      => 0,
			     type     => 'short',
			     props    => { type => 'textarea',
					   cols => 40,
				           rows => 4
					 }
			    },
	      default      => {
			     name     => 'default',
			     get_meth => sub { shift->get_default(@_) },
			     get_args => [],
			     set_meth => sub { shift->set_default(@_) },
			     set_args => [],
			     disp     => 'Default',
			     len      => 256,
			     req      => 0,
			     type     => 'short',
			     props    => { type => 'textarea',
					   cols => 40,
				           rows => 4
					 }
			    },
	      value      => {
			     name     => 'value',
			     get_meth => sub { shift->get_value(@_) },
			     get_args => [],
			     set_meth => sub { shift->set_value(@_) },
			     set_args => [],
			     disp     => 'Value',
			     len      => 256,
			     req      => 0,
			     type     => 'short',
			     props    => { type => 'textarea',
					   cols => 40,
				           rows => 4
					 }
			    },
	      val_name   => {
			     name     => 'val_name',
			     get_meth => sub { shift->get_val_name(@_) },
			     get_args => [],
			     disp     => 'Value Name',
			     len      => 256,
			     req      => 0,
			    }
	     };
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $pref->get_id

Returns the ID of the Bric::Util::Pref object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> If the Bric::Util::Pref object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $name = $pref->get_name

Returns preference name.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $description = $pref->get_description

Returns preference description.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'description' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $default = $pref->get_default

Returns preference default.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'default' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $value = $pref->get_value

Returns the preference value.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'value' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $pref->set_value($value)

Sets the preference value.

B<Throws:>

=over 4

=item *

Incorrect number of args to _set().

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_value {
    my ($self, $val) = @_;
    $self->_set([qw(value _val_ch)], [$val, 1]);
}

=item my $val_name = $pref->get_val_name

Returns preference value's desriptive name. Note that if you've set the value,
this method will return an incorrect value unless and until you instantiate the
object again using lookup() or list().

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Incorrect number of args to _set().

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_val_name {
    my $self = shift;
    my ($id, $name, $value, $ch) = $self->_get(qw(id val_name value _val_ch));
    return $name unless $ch;

    # If we got here, we need to look up the new value name.
    my $sel = prepare_c(qq{
        SELECT description
        FROM   pref_opt
        WHERE  pref__id = ?
               AND value = ?
    });
    $name = col_aref($sel, $id, $value)->[0];
    $self->_set([qw(val_name _val_ch)], [$name, undef]);
    return $name;
}

=item my (@opts || $opts_aref) = $pref->get_opts

Returns a list or anonymous array of options available for filling in the value
of this preference.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_opts { wantarray ? sort keys %{ &$get_opts($_[0]) }
		 : [ sort keys %{ &$get_opts($_[0]) } ];
}

################################################################################

=item my $opts_href = $pref->get_opts_href

Returns a hasref of options available for filling in the value of this
preference. The hash keys are the options, and the values are their
descriptions.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_opts_href { &$get_opts($_[0]) }

################################################################################

=item $self = $pref->save

Saves any changes to the Bric::Util::Pref object. Returns $self on success and
undef on failure.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to instantiate preference cache.

=item *

Unable to populate preference cache.

=item *

Unable to set cache value.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    return unless $self->_get__dirty;
    my ($id, $name, $value) = $self->_get(qw(id name value));
    die $dp->new({ msg => "Cannot create a new preference." }) unless $id;
    my $upd = prepare_c(qq{
        UPDATE pref
        SET    value = ?
        WHERE  id = ?
    });
    # Update the database.
    execute($upd, $value, $id);
    # Update the cache.
    &$cache_val($name, $value);
    $self->SUPER::save;
}

################################################################################

=back 4

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $pref_aref = &$get_em( $pkg, $params )

=item my $pref_ids_aref = &$get_em( $pkg, $params, 1 )

Function used by lookup() and list() to return a list of Bric::Util::Pref objects
or, if called with an optional third argument, returns a listof Bric::Util::Pref
object IDs (used by list_ids()).

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_em = sub {
    my ($pkg, $params, $ids) = @_;
    my (@wheres, @params);
    while (my ($k, $v) = each %$params) {
	if ($k eq 'id') {
	    push @wheres, "p.$k = ?";
	    push @params, $v;
	} elsif ($k eq 'val_name') {
	    push @wheres, "LOWER(o.description) LIKE ?";
	    push @params, lc $v;
	} else {
	    # It's a varchar field.
	    push @wheres, "LOWER(p.$k) LIKE ?";
	    push @params, lc $v;
	}
    }

    # Assemble the WHERE statement.
    my $where = @wheres ? join("\n               AND ", ('', @wheres)) : '';

    # Assemble the query.
    local $" = ', ';
    my $qry_cols = $ids ? ['p.id'] : \@cols;
    my $sel = prepare_ca(qq{
        SELECT @$qry_cols
        FROM   pref p, pref_opt o
        WHERE  p.value = o.value
               AND p.id = o.pref__id $where
        ORDER BY p.name
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my (@d, @prefs);
    bind_columns($sel, \@d[0..$#cols]);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
	my $self = bless {}, $pkg;
	$self->SUPER::new;
	$self->_set(\@props, \@d);
	$self->_set__dirty; # Disables dirty flag.
	push @prefs, $self
    }
    return \@prefs;
};

################################################################################

=item my $action = &$get_opts($self)

Queries this preference's value options from the database.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_opts = sub {
    my $self = shift;
    my ($opts, $id) = $self->_get(qw(_opts id));
    return $opts if $opts;

    # We don't go 'em. So get 'em!
    my $sel = prepare_ca(qq{
        SELECT value, description
        FROM   pref_opt
        WHERE  pref__id = ?
    }, undef, DEBUG);
    execute($sel, $id);
    my ($val, $desc);
    bind_columns($sel, \$val, \$desc);
    while (fetch($sel)) { $opts->{$val} = $desc }
    $self->_set(['_opts'], [$opts]);
    return $opts;
};

################################################################################

=item $cache = &$load_cache()

Loads all the preference keys and values into a Cache::FileCache object.

B<Throws:>

=over 4

=item *

Unable to instantiate preference cache.

=item *

Unable to populate preference cache.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::App::Cache for persistence across processes.

=cut

$load_cache = sub {
    # Return an existing reference, if we've got one.
    return $cache if $cache;

    # Just grab the existing cache, if possible.
    $cache = Bric::App::Cache->new;
    return $cache if $cache->get($prefkey);

    # No existing cache. So set one up.
    my $sel = prepare_ca(qq{
        SELECT name, value
        FROM   pref
    }, undef, DEBUG);
    execute($sel);

    my ($c, $name, $val);
    bind_columns($sel, \$name, \$val);
    while (fetch($sel)) { $c->{$name} = $val }
    $cache->set($prefkey, $c);
    return $cache;
};

################################################################################

=item my $cache = &$cache_val($name, $value)

Sets a value in the cache.

B<Throws:>

=over 4

=item *

Unable to instantiate preference cache.

=item *

Unable to populate preference cache.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Unable to set cache value.

=back

B<Side Effects:> See &$load_cache().

B<Notes:> See &$load_cache().

=cut

$cache_val = sub {
    my ($name, $val) = @_;
    my $cache = &$load_cache;
    my $c = $cache->get($prefkey);
    $c->{$name} = $val;
    $cache->set($prefkey, $c);
    return $cache;
};

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

perl(1),
Bric (2),

=cut
