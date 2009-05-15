package Bric::Util::AlertType::Parts::Rule;

=head1 Name

Bric::Util::AlertType::Parts::Rule - Interface to AlertType Rules.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Util::AlertType::Parts::Rule;

  # Constructors.
  my $rule = Bric::Util::AlertType::Parts::Rule->new($init);
  $rule = Bric::Util::AlertType::Parts::Rule->lookup({ id => 1 });
  my @rules = Bric::Util::AlertType::Parts::Rule->list($params);
  my $rules_href = Bric::Util::AlertType::Parts::Rule->href($params);

  # Class Methods.
  my @rule_ids = Bric::Util::AlertType::Parts::Rule->list_ids($params);

  # Instance Methods.
  my $id = $rule->get_id;
  my $at_id = $rule->get_at_id;
  my $attr = $rule->get_attr;
  $rule = $rule->set_attr($attr);
  my $operator = $rule->get_operator;
  $rule = $rule->set_operator($operator);
  my $value = $rule->get_value;
  $rule = $rule->set_value($value);

  $rule->save;

=head1 Description

Bric::Util::AlertType::Parts::Rule objects are strictly associated with
Bric::Util::AlertType objects. They constitute the rules which must evaluate to
true in order for an alert of that type to be sent. See Bric::Util::AlertType for
more information.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:standard col_aref);
use Bric::Util::Fault qw(throw_dp);

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $op = [[qw(eq =)], [qw(ne <>)], [qw(gt >)], [qw(lt <)], [qw(ge >=)],
          [qw(le <=)], [qw(=~ =~)], [qw(!~ !~)]];
my %op = map {$_ => 1} qw(eq ne gt lt ge le =~ !~); # Legal operators.
my @cols = qw(id alert_type__id attr operator value);
my @props = qw(id alert_type_id attr operator value);
my $meths;
my @ord = qw(alert_type_id attr operator value);

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id =>  Bric::FIELD_READ,
                         alert_type_id => Bric::FIELD_RDWR,
                         attr => Bric::FIELD_RDWR,
                         operator => Bric::FIELD_RDWR,
                         value => Bric::FIELD_RDWR,

                         # Private Fields
                         _del => Bric::FIELD_NONE # Flag for deleting rule.
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $rule = Bric::Util::AlertType::Parts::Rule->new()

=item my $rule = Bric::Util::AlertType::Parts::Rule->new($init)

Instantiates a Bric::Util::AlertType::Parts::Rule object. An anonymous hash of
initial values may be passed. The supported initial value keys are:

=over 4

=item *

alert_type_id

=item *

attr

=item *

operator

=item *

value

=back

Call $rule->save() to save the new object.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;
    my $self = bless {}, ref $pkg || $pkg;
    $self->SUPER::new($init);
}

################################################################################

=item my $rule = Bric::Util::AlertType::Parts::Rule->lookup({ id => $id })

Looks up and instantiates a new Bric::Util::AlertType::Parts::Rule object based on
the Bric::Util::AlertType::Parts::Rule object ID passed. If $id is not found in
the database, lookup() returns undef.

B<Throws:>

=over

=item *

Too many Bric::Util::AlertType::Parts::Rule objects found.

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

B<Side Effects:> If $id is found, populates the new
Bric::Util::AlertType::Parts::Rule object with data from the database before
returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;
    my $rule = $pkg->cache_lookup(@_);
    return $rule if $rule;

    $rule = $get_em->($pkg, @_);
    # We want @$rule to have only one value.
    throw_dp(error => 'Too many Bric::Util::AlertType::Parts::Rule objects found.')
      if @$rule > 1;
    return @$rule ? $rule->[0] : undef;
}

################################################################################

=item my (@rules || $rules_aref) = Bric::Util::AlertType::Parts::Rule->list($params)

Returns a list or anonymous array of Bric::Util::AlertType::Parts::Rule objects
based on the search parameters passed via an anonymous hash. The supported
lookup keys are:

=over 4

=item id

AlertType Rule ID. May use C<ANY> for a list of possible values.

=item alert_type_id

A Bric::Util::AlertType ID. May use C<ANY> for a list of possible values.

=item attr

Attribute against which a rule matches. May use C<ANY> for a list of possible
values.

=item operator

Operator used to compare attributes to values. May use C<ANY> for a list of
possible values.

=item value

Value to compare against event and object attributes. May use C<ANY> for a
list of possible values.

=back

B<Throws:>

=over 4

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

=back

B<Side Effects:> Populates each Bric::Util::AlertType::Parts::Rule object with
data from the database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=item my $rules_href = Bric::Util::AlertType::Parts::Rule->href($params)

Works the same as list(), with the same arguments, except it returns a hash or
hashref of Bric::Util::AlertType::Parts::Rule objects, where the keys are the
contact IDs, and the values are the contact objects.

B<Throws:>

=over 4

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

=back

B<Side Effects:> Populates each Bric::Util::AlertType::Parts::Rule object with
data from the database before returning them all.

B<Notes:> NONE.

=cut

sub href { &$get_em(@_, 0, 1) }

################################################################################

=item $meths = Bric::Util::AlertType::Parts::Rule->my_meths

=item (@meths || $meths_aref) = Bric::Util::AlertType::Parts::Rule->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Util::AlertType->my_meths(0, TRUE)

Returns an anonymous hash of introspection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
introspection data. If a second true argument is passed instead of a first,
then a list or anonymous array of introspection data will be returned for
properties that uniquely identify an object (excluding C<id>, which is
assumed).

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item name

The name of the property or attribute. Is the same as the hash key when an
anonymous hash is returned.

=item disp

The display name of the property or attribute.

=item get_meth

A reference to the method that will retrieve the value of the property or
attribute.

=item get_args

An anonymous array of arguments to pass to a call to get_meth in order to
retrieve the value of the property or attribute.

=item set_meth

A reference to the method that will set the value of the property or
attribute.

=item set_args

An anonymous array of arguments to pass to a call to set_meth in order to set
the value of the property or attribute.

=item type

The type of value the property or attribute contains. There are only three
types:

=over 4

=item short

=item date

=item blob

=back

=item len

If the value is a 'short' value, this hash key contains the length of the
field.

=item search

The property is searchable via the list() and list_ids() methods.

=item req

The property or attribute is required.

=item props

An anonymous hash of properties used to display the property or
attribute. Possible keys include:

=over 4

=item type

The display field type. Possible values are

=over 4

=item text

=item textarea

=item password

=item hidden

=item radio

=item checkbox

=item select

=back

=item length

The Length, in letters, to display a text or password field.

=item maxlength

The maximum length of the property or value - usually defined by the SQL DDL.

=back

=item rows

The number of rows to format in a textarea field.

=item cols

The number of columns to format in a textarea field.

=item vals

An anonymous hash of key/value pairs reprsenting the values and display names
to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_meths {
    my ($pkg, $ord, $ident) = @_;
    return if $ident;

    # Return 'em if we got em.
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}]
      if $meths;

    # We don't got 'em. So get 'em!
    $meths = {
              alert_type_id => {
                             name     => 'alert_type_id',
                             get_meth => sub { shift->get_alert_type_id(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_alert_type_id(@_) },
                             set_args => [],
                             disp     => 'Alert Type',
                             len      => 10,
                             req      => 1,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 10,
                                             maxlength => 10
                                         }
                            },
              attr      => {
                             name     => 'attr',
                             get_meth => sub { shift->get_attr(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_attr(@_) },
                             set_args => [],
                             disp     => 'Attribute',
                             search   => 1,
                             len      => 64,
                             req      => 0,
                             type     => 'short',
                             props    => { type      => 'text',
                                           length    => 32,
                                           maxlength => 64
                                         }
                            },
              operator      => {
                             name     => 'operator',
                             get_meth => sub { shift->get_operator(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_operator(@_) },
                             set_args => [],
                             disp     => 'Operator',
                             len      => 3,
                             req      => 1,
                             type     => 'short',
                             props    => {   type => 'select',
                                             vals => $op,
                                         }
                            },
              value      => {
                             name     => 'value',
                             get_meth => sub { shift->get_value(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_value(@_) },
                             set_args => [],
                             disp     => 'Value',
                             search   => 1,
                             len      => 256,
                             req      => 0,
                             type     => 'short',
                             props    => { type      => 'text',
                                           length    => 24,
                                           maxlength => 256
                                         }
                            },
             };
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=back

=head2 Destructors

=over 4

=item $p->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

=over 4

=item my (@rule_ids || $rule_ids_aref) =
Bric::Util::AlertType::Parts::Rule->list_ids($params)

Returns a list or anonymous array of Bric::Util::AlertType::Parts::Rule object IDs
based on the search parameters passed via an anonymous hash. The supported
lookup keys are the same as those for list().

B<Throws:>

=over 4

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

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_ids { wantarray ? @{ &$get_em(@_, 1) } : &$get_em(@_, 1) }

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $rule->get_id

Returns the ID of the Bric::Util::AlertType::Parts::Rule object.

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

B<Notes:> If the Bric::Util::AlertType::Parts::Rule object has been instantiated
via the new() constructor and has not yet been C<save>d, the object will not yet
have an ID, so this method call will return undef.

=item my $alert_type_id = $rule->get_alert_type_id

Returns the ID of the Bric::Util::AlertType object to which this rule belongs.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'alert_type_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $attr = $rule->get_attr

Returns the name of the attribute or property to be retreived by the method
returned by get_meth().

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'attr' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $rule->set_attr($attr)

Sets the name of the attribute or property to be retrieved by the method
returned by get_meth().

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'attr' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $operator = $rule->get_operator

Returns the operator that will compare the value specifed via $rule->set_value()
to the value returned from the event on which the alert is based.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'operator' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $rule->set_operator($operator)

Sets the operator that will compare the value specifed via $rule->set_value() to
the value returned from the event on which the alert is based. Acceptable values
are only 'eq', 'ne', 'gt', 'lt', 'ge', 'le', '=~', and '!~'. Any other values
will trigger a fatal error.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_operator {
    my $self = shift;
    my $op = shift;
    $self->_set(['operator'], [$op]) if $op{$op};
}

=item my $value = $rule->get_value

Returns the value for the rule.

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

=item $self = $rule->set_value($value, $is_date)

Sets the value for the rule. This value must match the value from the event or
the object on which the event is based--as returned a call to the method
returned from get_meth()--in order for the alert to be sent. Currently, any
value can be put in here, but there must be an I<exact, case-senstive> match in
order for the evaluation to return true. Only short and date datatypes will be
supported, though either will be stored in the database in a short datafield
[VARCHAR2(256)] for this rule. If the value is a date, be sure that $is_date is
true. Supply dates in ISO-8601 format; use Bric::Util::Time::local_date() to
ensure proper formatting of dates.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_value {
    my ($self, $val, $d) = @_;
    $self->_set(['value'], [$d ? db_date($val) : $val]);
}

=item $self = $rule->remove

Deletes the rule. Be sure to call $rul->save to delete it from the database.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub remove {
    my $self = shift;
    $self->_set(['_del'], [1]);
}

################################################################################

=item $self = $rule->save

Saves any changes to the Bric::Util::AlertType::Parts::Rule object. Returns $self
on success and undef on failure.

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

Unable to select row.

=item *

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    return unless $self->_get__dirty;
    my ($id, $del) = $self->_get('id', '_del');
    if (defined $id && $del) {
        # Delete the rule.
        my $del = prepare_c(qq{
            DELETE FROM alert_type_rule
            WHERE  id = ?
        }, undef);
        execute($del, $id);
        $self->_set(['id'], [undef]);
    } elsif (defined $id) {
        # It's an existing rule. Update it.
        local $" = ' = ?, '; # Simple way to create placeholders with an array.
        my $upd = prepare_c(qq{
            UPDATE alert_type_rule
            SET   @cols = ?
            WHERE  id = ?
        }, undef);
        execute($upd, $self->_get(@props), $id);
    } else {
        # It's a new rule. Insert it.
        local $" = ', ';
        my $fields = join ', ', next_key('alert_type_rule'), ('?') x $#cols;
        my $ins = prepare_c(qq{
            INSERT INTO alert_type_rule (@cols)
            VALUES ($fields)
        }, undef);
        # Don't try to set ID - it will fail!
        execute($ins, $self->_get(@props[1..$#props]));
        # Now grab the ID.
        $id = last_key('alert_type_rule');
        $self->_set(['id'], [$id]);
    }
    $self->SUPER::save;
    return $self;
}

################################################################################

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $rules_aref = &$get_em( $pkg, $params )

=item my $rules_ids_aref = &$get_em( $pkg, $params, 1 )

=item my $rules_href = &$get_em( $pkg, $params, 0, 1 )

Function used by lookup() and list() to return a list of Bric::Util::AlertType::Parts::Rule objects
or, if called with an optional third argument, returns a listof Bric::Util::AlertType::Parts::Rule
object IDs (used by list_ids()).

B<Throws:>

=over 4

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
    my ($pkg, $params, $ids, $href) = @_;
    my (@wheres, @params);
    my %map = (
        id => 'id = ?',
        alert_type_id => 'alert_type__id = ?',
        operator      => 'operator = ?',
        attr          => 'LOWER(attr)  LIKE LOWER(?)',
        value         => 'LOWER(value) LIKE LOWER(?)',
    );
    while (my ($k, $v) = each %$params) {
        push @wheres, any_where $v, $map{$k}, \@params
            if $map{$k};
    }

    my $where = @wheres ? 'WHERE  ' . join(' AND ', @wheres) : '';
    my $qry_cols = $ids ? 'id' : join ', ', @cols;
    my $sel = prepare_c(qq{
        SELECT $qry_cols
        FROM   alert_type_rule
        $where
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my (@d, @rules, %rules);
    bind_columns($sel, \@d[0..$#cols]);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
        my $self = bless {}, $pkg;
        $self->SUPER::new;
        $self->_set(\@props, \@d);
        $self->_set__dirty; # Disables dirty flag.
        $href ? $rules{$d[0]} = $self->cache_me :
          push @rules, $self->cache_me;
    }
    finish($sel);
    return $href ? \%rules : \@rules;
};

################################################################################

1;
__END__

=back

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Util::AlertType|Bric::Util::AlertType>,
L<Bric::Util::Event|Bric::Util::Event>

=cut
