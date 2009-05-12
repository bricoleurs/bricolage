package Bric::Util::Grp::Parts::Member::Contrib;

=head1 Name

Bric::Util::Grp::Parts::Member::Contrib - Manages Contributors (members of
Bric::Util::Grp::Person groups, that is).

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

See Bric::Util::Grp::Parts::Member.

=head1 Description

See Bric::Util::Grp::Parts::Member.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);
use Bric::Util::Fault qw(throw_dp);
use Bric::Util::Grp;
use Bric::Biz::Person;

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Util::Grp::Parts::Member);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant INST_GROUP_ID => 1;
use constant GRP_PKG => 'Bric::Util::Grp::Person';

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my $dp = 'Bric::Util::Fault::Exception::DP';
my @cols = qw(m.id m.grp__id m.class__id m.active pm.object_id);
my @props = qw(id grp_id _object_class_id _active obj_id);
my $meths;
my @ord = qw(prefix fname mname lname suffix);

################################################################################

################################################################################
# Instance Fields
BEGIN { Bric::register_fields() }

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

See Bric::Util::Grp::Parts::Member. Only lookup() is implemented here.

=over 4

=item my $contrib = Bric::Util::Grp::Parts::Member::Contrib->lookup({ id => $id })

Looks up and instantiates a new Bric::Util::Grp::Parts::Member::Contrib object
based on the Bric::Util::Grp::Parts::Member::Contrib object ID passed. If $id is
not found in the database, lookup() returns undef.

B<Throws:>

=over

=item *

Too many Bric::Util::Grp::Parts::Member::Contrib objects found.

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
Bric::Util::Grp::Parts::Member::Contrib object with data from the database before
returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;
    my $contrib = $pkg->cache_lookup(@_);
    return $contrib if $contrib;

    $contrib = $pkg->_do_list(@_);
    # We want @$contrib to have only one value.
    throw_dp(error => 'Too many Bric::Util::Grp::Parts::Member::Contrib'
                    . ' objects found.')
      if @$contrib > 1;
    return @$contrib ? $contrib->[0] : undef;
}

=back

=head2 Destructors

=over 4

=item $contrib->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

See Bric::Util::Grp::Parts::Member. Only my_meths() is overridden here.

=over 4

=item $meths = Bric::Util::Grp::Parts::Member::Contrib->my_meths

=item (@meths || $meths_aref) =
 Bric::Util::Grp::Parts::Member::Contrib->my_meths(TRUE)

=item my (@meths || $meths_aref) =
 Bric::Util::Grp::Parts::Member::Contrib->my_meths(0, TRUE)

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

An anonymous hash of properties used to display the property or attribute.
Possible keys include:

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
              prefix     => {
                             name     => 'prefix',
                             get_meth => sub { shift->get_object->get_prefix(@_) },
                             get_args => [],
                             set_meth => sub { shift->get_object->set_prefix(@_) },
                             set_args => [],
                             disp     => 'Prefix',
                             type     => 'short',
                             len      => 32,
                             props    => {   type       => 'text',
                                             length     => 32,
                                             maxlength => 32
                                         }
                            },
              fname      => {
                             name     => 'fname',
                             get_meth => sub { shift->get_object->get_fname(@_) },
                             get_args => [],
                             set_meth => sub { shift->get_object->set_fname(@_) },
                             set_args => [],
                             disp     => 'First',
                             len      => 64,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 32,
                                             maxlength => 64
                                         }
                            },
              mname      => {
                             name     => 'mname',
                             get_meth => sub { shift->get_object->get_mname(@_) },
                             get_args => [],
                             set_meth => sub { shift->get_object->set_mname(@_) },
                             set_args => [],
                             disp     => 'Middle',
                             len      => 64,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 32,
                                             maxlength => 64
                                         }
                            },
              lname      => {
                             name     => 'lname',
                             get_meth => sub { shift->get_object->get_lname(@_) },
                             get_args => [],
                             set_meth => sub { shift->get_object->set_lname(@_) },
                             set_args => [],
                             disp     => 'Last',
                             search   => 1,
                             len      => 64,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 32,
                                             maxlength => 64
                                         }
                            },
              suffix     => {
                             name     => 'suffix',
                             get_meth => sub { shift->get_object->get_suffix(@_) },
                             get_args => [],
                             set_meth => sub { shift->get_object->set_suffix(@_) },
                             set_args => [],
                             disp     => 'Suffix',
                             len      => 32,
                             type     => 'short',
                             props    => {   type       => 'text',
                                             length     => 32,
                                             maxlength => 32
                                         }
                            },
              type      => {
                             name     => 'type',
                             get_meth => sub { shift->get_grp->get_name(@_) },
                             get_args => [],
                             disp     => 'Contributor Type',
                             len      => 64,
                             type     => 'short',
                            }
             };
    foreach my $meth (__PACKAGE__->SUPER::my_meths(1)) {
        if ($meth->{name} eq 'name') {
            # Copy name property.
            $meth = { %$meth };
            delete $meth->{search};
        }
        $meths->{$meth->{name}} = $meth;
        push @ord, $meth->{name};
    }
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=back

=head2 Public Instance Methods

See Also Bric::Util::Grp::Parts::Member.

=over 4

=item $roles = $contrib->get_roles

Return the roles for this contributor

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_roles {
    my $self = shift;

    return $self->subsys_names;
}

################################################################################

=item $info = $contrib->get_role_info

Return information for a particular role

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_role_info {
    my $self = shift;
    my ($role) = @_;

    return $self->all_for_subsys($role);
}

################################################################################

=item $person = $contrib->get_person

Return the person object behind this contributor

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_person { shift->get_object }

sub get_name { shift->get_object->format_name(@_) }

=item my $val = $contrib->get_data($attr);

Shortcut for the default method of getting attributes from a group
member, which is

  $member->get_attr({ name => $attr });

By including this convenience method, contributor objects act more like story
elements, so it'll be easier for template writers to use.

=cut

sub get_data { $_[0]->get_attr( { name => $_[1] }) }

=item $ids = $obj->get_grp_ids();

Get a list of grp IDs of groups this object belongs to. Overrides the default
implementation because it needs the group memeberships of the underlying person
object, rather than of the contributor object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_grp_ids {
    my $self = shift;
    return ! ref $self ? INST_GROUP_ID
      : GRP_PKG->list_ids({ package => 'Bric::Biz::Person',
                            obj_id => $self->get_obj_id })
}

sub save {
    # We'll need to make sure we save any changes to the underlying
    # Bric::Biz::Person object itself.
    $_[0]->get_object->save;
    $_[0]->SUPER::save;
}

=back

=head1 Private

=head2 Private Class Methods

See Bric::Util::Grp::Parts::Member.

=head2 Private Instance Methods

=over 4

=item my (@contribs || $contribs_aref) = $member->_do_list($params)

Returns a list or anonymous array of members of a Bric::Util::Grp::Person group
or groups. The supported keys for the $params anonymous hash are:

=over 4

=item *

lname

=item *

fname

=item *

mname

=item *

prefix

=item *

suffix

=item *

no_grp_id - Excludes members of the group with this ID.

=item *

grp

=item *

grp_id

=item *

active

=back

B<Throws:>

=over 4

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

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_list {
    my ($pkg, $params, $ids) = @_;
    my (@wheres, @args);
    while (my ($k, $v) = each %$params) {
        if ($k eq 'grp') {
            push @wheres, "m.grp__id = ?";
            push @args, $params->{grp}->get_id;
        } elsif ($k eq 'grp_id') {
            push @wheres, any_where($v, "m.grp__id = ?", \@args);
        } elsif ($k eq 'id') {
            push @wheres, any_where($v, "m.id = ?", \@args);
        } elsif ($k eq 'active') {
            push @wheres, "m.active = ?";
            push @args, $v;
        } elsif ($k eq 'person_id') {
            push @wheres, any_where($v, "p.id = ?", \@args);
        } elsif ($k eq 'no_grp_id') {
            push @wheres, any_where($v, "m.grp__id <> ?", \@args);
        } else {
            push @wheres, "LOWER(p.$k) LIKE ?";
            push @args, lc $v;
        }
    }

    # Make sure we do something with the active flag.
    unless (exists $params->{active} || exists $params->{id}) {
            push @wheres, "m.active = ?";
            push @args, 1
    }

    # Assemble the WHERE clause.
    local $" = ' AND ';
    my $where = @wheres ? " AND @wheres" : '';

    # Assemble the query.
    $" = ', ';
    my $qry_cols = $ids ? ['id'] : \@cols;
    my $sel = prepare_ca(qq{
        SELECT @$qry_cols
        FROM   member m, person_member pm, person p, grp g
        WHERE  m.id = pm.member__id
               AND m.grp__id = g.id
               AND g.active = '1'
               AND pm.object_id = p.id$where
        ORDER BY p.lname, p.fname, p.mname
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @args) if $ids;

    # Get the objects together.
    execute($sel, @args);
    my (@d, @contribs, %grps);
    bind_columns($sel, \@d[0..4]);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
        my $grp = $grps{$d[1]} ||= Bric::Util::Grp->lookup({ id => $d[1] });
        my $self = bless {object_package => 'Bric::Biz::Person', grp => $grp},
          $pkg;
        $self->_set(\@props, \@d);
        $self->_set__dirty; # Disables dirty flag.
        push @contribs, $self->cache_me;
    }
    return wantarray ? @contribs : \@contribs;
}

=back

=head2 Private Functions

=cut

1;
__END__

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Util::Grp|Bric::Util::Grp>,
L<Bric::Util::Grp::Person|Bric::Util::Grp::Person>,
L<Bric::Util::Grp::Parts::Member|Bric::Util::Grp::Parts::Member>

=cut
