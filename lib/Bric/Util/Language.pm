package Bric::Util::Language;
###############################################################################

=head1 NAME

Bric::Util::Language - A way of registering Languages

=head1 VERSION

$Revision: 1.8 $

=cut

our $VERSION = (qw$Revision: 1.8 $ )[-1];

=head1 DATE

$Date: 2003-01-29 06:46:04 $

=head1 SYNOPSIS

To follow

=head1 DESCRIPTION

To follow

=cut


#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies                 

use strict;

#--------------------------------------#
# Programatic Dependencies              

use Bric::Util::DBI qw(:all);

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#

# NONE

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields                   

# NONE

#--------------------------------------#
# Private Class Fields                  

# NONE

#--------------------------------------#
# Instance Fields                       

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
        Bric::register_fields({

                # Public Fields

                # the name of the language ( i.e. American English )
                'name'                  => Bric::FIELD_RDWR,

                # The desc ( i.e. What we ment when we said You talk funny American,
                # y'aint from round here no? )
                'description'   => Bric::FIELD_RDWR,

                # The character set that will be output for all instances of this
                # language
                'char_set'              => Bric::FIELD_RDWR,

                # The id from the database
                'id'                    => Bric::FIELD_READ,


                # Private Fields

                # the active Flag
                '_active'               => Bric::FIELD_NONE

        });
}

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 INTERFACE

=head2 Public Methods

=over 4

=cut

#--------------------------------------#
# Constructors                          

#------------------------------------------------------------------------------#


=item $lang = Bric::Util::Language->new( $init );

Will create a new language object with the initial params supplied to init

Supported Keys:

=over 4

=item *

name

=item *

description

=item *

char_set

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub new {
        my $class = shift;
        my ($init) = @_;

        my $self = fields::new($class);

        # call super and pass it the initial args
        $self->SUPER::new($init);

        $self->_set( { _active => 1 } );

        # return the object
        return $self;

}


=item $lang = Bric::Util::Language->lookup( { id => $id } );

Returns the language object after looking it up from the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub lookup {
        my $class = shift;
        my ($params) = @_;

        return if !$params->{'id'};

        my $self = fields::new($class);

        $self->SUPER::new();

        my $select = prepare_c(qq{
                SELECT 
                        name, description, char_set, active
                FROM 
                        $Bric::Cust.language 
                WHERE
                        id = ?
        }, undef, DEBUG);

        my $row = row_aref($select, $params->{'id'});

        # Set all of the info
        $self->_set( { id => $params->{'id'} } );

        $self->_set( { name => $row->[0] });
        $self->_set( { description => $row->[1] } );
        $self->_set( { char_set => $row->[2] } );
        $self->_set( { _active => $row->[3] } );

        return $self;

}

=item ($lang_aref || @langs) = Bric::Util::Language->list( $param )

will return a list or list ref of language objects that match the given criteria

Supported Keys:

=over 4

=item *

char_set

=item *

active

=back

B<Throws:>
NONE 

B<Side Effects:>
NONE 

B<Notes:>
NONE 

=cut


sub list { 
        my $class = shift;
        my ($param) = @_;

        # send the the list processor, undef states that we want objects 
        # and not just ids
        _do_list($class,$param, undef);
}

#--------------------------------------#
# Destructors                           

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#
# Public Class Methods                  

#------------------------------------------------------------------------------#


=item ($lang_aref || @langs) = Bric::Util::Language->list_ids($param )

will return a list or list ref of language object ids that match the 
given criteria

Supported Keys:

=over 4

=item *

char_set

=item *

active

=back

B<Throws:>
NONE 

B<Side Effects:>
NONE 

B<Notes:>
NONE 

=cut

sub list_ids {
        my $class = shift;
        my ($param) = @_;

        # send to the list processor the one states that we want ids returned
        _do_list($class,$param, 1);

}


#--------------------------------------#
# Public Instance Methods               

#------------------------------------------------------------------------------#

=item $lang = $lang->set_name( $name );

Sets the name field, this is required

B<Throws:>
NONE 

B<Side Effects:>
NONE 

B<Notes:>
NONE 

=cut

=item $name = $lang->get_name()

returns the name field

B<Throws:>
NONE 

B<Side Effects:>
NONE 

B<Notes:>
NONE 

=cut

=item $lang = $lang->set_description( $description );

Sets the description field

B<Throws:>
NONE 

B<Side Effects:>
NONE 

B<Notes:>
NONE 

=cut

=item $description = $lang->get_description();

Returns the description Field

B<Throws:>
NONE 

B<Side Effects:>
NONE 

B<Notes:>
NONE 

=cut

=item $lang = $lang->set_char_set( $char_set );

sets the character set field

B<Throws:>
NONE 

B<Side Effects:>
NONE 

B<Notes:>
NONE 

=cut

=item $char_set = $lang->get_char_set();

returns the character set for this language

B<Throws:>
NONE 

B<Side Effects:>
NONE 

B<Notes:>
NONE 

=cut

=item $lang = $lang->activate()

Sets the active flag, default is active

B<Throws:>
NONE 

B<Side Effects:>
NONE 

B<Notes:>
NONE 

=cut

sub activate {
        my Bric::Util::Language $self = shift;

        $self->_set( { _active => 1 });

        return $self;
}

=item $lang = $lanf->deactivate()

Unsets the active flag for the language object

B<Throws:>
NONE 

B<Side Effects:>
NONE 

B<Notes:>
NONE 

=cut

sub deactivcate {
        my Bric::Util::Language $self = shift;

        $self->_set( { _active => 0 });

        return $self;
}

=item $bool = $lang->is_active()

returns 1 if the item is active undef otherwise

B<Throws:>
NONE 

B<Side Effects:>
NONE 

B<Notes:>
NONE 

=cut

sub is_active {
        my Bric::Util::Language $self = shift;

        $self->_get('_active') ? 1 : undef;
}

=item $id = $lang->get_id()

returns the database id of this language object

B<Throws:>
NONE 

B<Side Effects:>
Will Return undef if the language has not been saved yet

B<Notes:>
NONE 

=cut


=item $lang = $lang->save()

Saves the changes to the database

B<Throws:>
NONE 

B<Side Effects:>
NONE 

B<Notes:>
NONE 

=cut
 

sub save {
        my Bric::Util::Language $self = shift;

        my $id = $self->_get('id');

        if ($id) {
                # An ID exists so this is an update

                return unless $self->_get__dirty();

                eval {
                        my $update = prepare_c(qq{
                                UPDATE
                                        language
                                SET 
                                        name=?,
                                        description=?,
                                        char_set=?,
                                        active=?
                                WHERE 
                                        id=?
                        }, undef, DEBUG);
        
                        $update->execute($self->_get('name'), $self->_get('description'),
                                        $self->_get('char_set'), $self->_get('_active'),
                                        $self->_get_id() );
                };
                if ($@) {
                        die "Error Doing Update in Lang Save:\n Error: $@\n\n";
                }

        } else {
                # NO id so this is an insert

                eval {
                        my $insert = prepare_c( qq{
                                INSERT into $Bric::Cust.language
                                        (id, name, description, char_set, active) 
                                VALUES
                                        (${\next_key('language')},?,?,?,?)
                                }, undef, DEBUG);

                        $insert->execute($self->_get('name'),$self->_get('description'),
                                $self->_get('char_set'), $self->_get('_active') );
                };
                if ($@) {
                        die "Error doing language save insert.\n Error: $@\n\n";
                }

                eval {
                        # FIX HERE
                        #$self->_set( { id => last_key('language') } );

                        my $select = prepare_c( qq{ 
                                        SELECT $Bric::Cust.seq_language.currval FROM dual
                                }, undef, DEBUG);
                        my $row = row_aref($select);
                        $self->_set( { id => $row->[0] });
                };

                if ($@) {
                        die "Error doing language lase_key.\n Error: $@ \n\n";
                }

        }
        $self->_set__dirty(0);
}

#==============================================================================#
# Private Methods                      #
#======================================#

=head1 PRIVATE

=cut

#--------------------------------------#

=head2 Private Class Methods                 

NONE

=cut

#--------------------------------------#

=head2 Private Instance Methods      

=cut

#--------------------------------------#

=head2 Private Functions



=item _do_list($class, $params, $ids)

Will do the database query and return a list or listref of objects or ids
for the list and list_ids methods

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _do_list {
        my $class = shift;
        my ($params, $ids) = @_;

        my $sql = qq{
                SELECT 
                        id, name, description, char_set, active 
                FROM 
                        $Bric::Cust.language
                };

        my @where;
        my @sel_params;
        if ($params->{'active'}) {
                push @where, "active=? ";
                push @sel_params, $params->{'active'};
        }
        if ($params->{'char_set'}) {
                push @where, "char_set=? ";
                push @sel_params, $params->{'char_set'}
        }

        if (@where) {
                $sql .= "WHERE " . join ' AND ', @where;
        }

        my $select;
        eval {

                $select = prepare_c($sql, undef, DEBUG);
        };
        if ( $@) {
                die "Error doing prepare in language _do_list.\n Error: $@\n\n";
        }

        if ($ids) {
                my $return;
                eval {
                        $return = col_aref($select,@sel_params);
                };
                if ( $@ ) {
                        die "Error doing col_aref in language _do_list.\nError: $@ \n\n";
                }

                return wantarray ? @{ $return } : $return;
        };

        my @objs;
        eval {
                my $select = prepare_c($sql, undef, DEBUG);

                $select->execute(@sel_params);

                while (my $row = $select->fetch() ) {
                        
                        my $self = fields::new($class);

                        $self->SUPER::new();

                        $self->_set( { 'id' => $row->[0] } );
                        $self->_set( { 'name' => $row->[1] } );
                        $self->_set( { 'description' => $row->[2] } );
                        $self->_set( { 'char_set' => $row->[3] } );
                        $self->_set( { '_active' => $row->[4] } );

                        push @objs, $self;
                }
        };
        if ( $@ ) {
                die "Error doing fetch in language _do_list.\n Error: $@\n\n";
        }

        return wantarray ? @objs : \@objs;
}

=cut
 
1;
__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

michael soderstrom ( miraso@pacbell.net )

=head1 SEE ALSO

L<Bric.pm>

=cut


