package Bric::Biz::Keyword;
###############################################################################

=head1 NAME

Bric::Biz::Keyword - A general class to manage keywords.

=head1 VERSION

$Revision: 1.7 $

=cut

our $VERSION = (qw$Revision: 1.7 $ )[-1];

=head1 DATE

$Date: 2001-12-04 18:17:44 $

=head1 SYNOPSIS

 use Bric::Biz::Keyword;

 # Create a new keyword object.
 my $key = new Bric::Biz::Keyword($init);

 # Lookup an existing keyword.
 my $key = new Bric::Biz::Keyword($key_id);

 # Create a list of keyword objects.
 my $key = list Bric::Biz::Keyword($param);

 # Get/set the keyword name. 
 $name    = $key->get_name();
 $success = $key->set_name($name);

 # Get/set the screen (display) name.
 $screen  = $key->get_screen_name();
 $success = $key->set_screen_name($screen);

 # Get/set the meaning of this keyword
 $meaning = $key->get_meaning();
 $success = $key->set_meaning($meaning);

 # Get/set the prefered flag 
 $bool    = $key->get_prefered();
 $success = $key->set_prefered();

 # Get/set the state State can be 'pending', 'rejected' or 'accepted'.
 $state = $key->get_state();
 $state = $key->set_state();

 # Add a keyword to a list of synonyms..
 $sets = $key->make_synonymous($keyword_id || $keyword_obj);

 # Save this asset to the database.
 $success = $key->save();
 
 # Delete this asset from the database.
 $success = $key->delete();

=head1 DESCRIPTION

The Keyword module allows assets to be characterized by a set of topical 
keywords.  These keywords can be used to group assets or during a search on a 
particular topic.

Keywords can have synonyms which can be used to determine sets of assets that are
categorically similar.  Out of a group of synonymous keywords one can be 
marked as preferred which means that all other synonyms will behave as if they 
were the preferred keyword.

Additionally keys associated with an asset can be weighted according to 
relevance.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies                 

use strict;

#--------------------------------------#
# Programatic Dependencies              
 
use Bric::Util::DBI qw(:standard);
use Bric::Util::Grp::Keyword;

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#



#==============================================================================#
# Constants                            #
#======================================#

use constant PENDING  => 1;
use constant ACCEPTED => 2;
use constant REJECTED => 3;

use constant TABLE  => 'keyword';
use constant COLS   => qw(name screen_name sort_name meaning prefered active 
			  synonym_grp_id);

#==============================================================================#
# FIELDS                               #
#======================================#

#--------------------------------------#
# Public Class Fields                   

our $METH;

#--------------------------------------#
# Private Class Fields                  



#--------------------------------------#
# Instance Fields                       

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
			 # Public Fields
			 'id'             => Bric::FIELD_RDWR,
			 'name'           => Bric::FIELD_RDWR,
			 'screen_name'    => Bric::FIELD_RDWR,
			 'sort_name'      => Bric::FIELD_RDWR,
			 'meaning'        => Bric::FIELD_RDWR,
			 'prefered'       => Bric::FIELD_RDWR,
			 'active'         => Bric::FIELD_RDWR,
			 'synonym_grp_id' => Bric::FIELD_READ,
			 
			 # Private Fields
			 '_synonym_grp_obj'   => Bric::FIELD_NONE,
			});
}

#==============================================================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors                          

#------------------------------------------------------------------------------#

=item $obj = new Bric::Biz::Keyword($init);

Keys for $init are:

=over 4

=item *

name

The name of this keyword

=item *

screen_name

The way this name should be displayed on screen (ie name='George', 
screen name='George Washington')

=item *

meaning

The specific meaning of this keyword to differentiate it from different 
synonyms.

=item *

prefered

Whether this is the prefered synonym when this keyword has synonyms.

=back

Creates a new keyword and keyword object.  Takes either a keyword ID or the 
keyword itself.

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

    # Create the object via fields which returns a blessed object.
    my $self = bless {}, $class;
    
    # Map state to active since state is just overriding active's role.
    $init->{'active'} = exists $init->{'state'} ? delete $init->{'state'} 
                                                : 1;
    $init->{'prefered'} = exists $init->{'prefered'} ? $init->{'prefered'} 
                                                     : 1;

    # Call the parent's constructor.
    $self->SUPER::new($init);

    # Initialize some instance variables.
    $self->set_state(PENDING);

    # Return the object.
    return $self;
}

#------------------------------------------------------------------------------#

=item $obj = lookup Bric::Biz::Keyword($key_id);

Retrieves an existing keyword from the database.  Takes either a keyword ID or 
the keyword itself.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub lookup {
    my $class = shift;
    my ($init) = @_;

    # Create the object via fields which returns a blessed object.
    my $self = bless {}, $class;

    # Call the parent's constructor.
    $self->SUPER::new();

    my $ret;

    if (exists $init->{'id'}) {
	$ret = _select_keyword('id=?', [$init->{'id'}]);
    } elsif (exists $init->{'name'}) {
	$ret = _select_keyword('LOWER(name) = ?', [lc($init->{'name'})]);
    } else {
	my $err_msg = 'Bad parameters passed to \'lookup\'';
	die Bric::Util::Fault::Exception::GEN->new({'msg' => $err_msg});
    }

    # Return nothing if we don't get an ID.
    return unless defined $ret->[0];

    # Set the columns selected as well as the passed ID.
    $self->_set(['id', COLS], $ret->[0]);

    # Return the object.
    return $self;
}

#------------------------------------------------------------------------------#

=item @objs = list Bric::Biz::Keyword($param);

The possible keys to $param are the following;

=over 4

=item *

synonyms

Returns all the synonyms for the given keyword or keyword ID.

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
    
    if ($param->{'synonyms'}) {
	my $kw_param = $param->{'synonyms'};
	my $kw;
	my $syn;
	
	$kw = ref $kw_param ? $kw_param 
                            : Bric::Biz::Keyword->lookup({'id' => $kw_param});
	# Return nothing if the lookup fails.
	return unless $kw;

	$syn = $kw->_get_synonym_grp;
	# Return nothing if there is no group object.
	return unless $syn;
	
	return wantarray ? $syn->all_synonyms : scalar $syn->all_synonyms;
    } else {
	# Make sure to set active explictly if its not passed.
	$param->{'active'} = exists $param->{'active'} ? $param->{'active'} : 1;
       
	my @num = grep($_ =~ /^(?:id|active)$/, keys %$param);
	my @txt = grep($_ !~ /^(?:id|active)$/, keys %$param);
	
	my $where = join(' AND ', (map { "$_=?" }      @num),
			          (map { "$_ LIKE ?" } @txt));

	my $ret = _select_keyword($where, [@$param{@num,@txt}]);
	my @all;

	foreach my $d (@$ret) {
	    # Create the object via fields which returns a blessed object.
	    my $self = bless {}, $class;
	    
	    # Call the parent's constructor.
	    $self->SUPER::new();
	    
	    # Set the columns selected as well as the passed ID.
	    $self->_set(['id', COLS], $d);
	    
	    $self->_set__dirty(0);

	    push @all, $self;
	}

	return wantarray ? @all : \@all;
    }
}


#--------------------------------------#

=head2 Destructors

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#------------------------------------------------------------------------------#

=item $success = $key->delete;

Deletes the keyword from the database.

B<Throws:>

"Delete Failed"

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub remove {
    my $self = shift;

    $self->_set(['_remove'], [1]);

    $self->_set__dirty(1);

    return $self;
}

#--------------------------------------#

=head2 Public Class Methods

=cut

#------------------------------------------------------------------------------#

=item $val = my_meths->{$key}->[0]->($obj);

Introspect this object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub my_meths {
    # Load field members.
    return $METH if $METH;

    $METH = {'name'        => {'get_meth' => sub {shift->get_name(@_)},
			       'get_args' => [], 
			       'set_meth' => sub {shift->set_name(@_)},
			       'set_args' => [],
			       'disp'     => 'Keyword Name',
			       'search'   => 1,
			       'len'      => 256,
			       'type'     => 'short',
			       'props'    => {'type'       => 'text',
					      'length'     => 32,
					      'max_length' => 256,}
			      },
	     'screen_name' => {'get_meth' => sub {shift->get_screen_name(@_)}, 
			       'get_args' => [],
			       'set_meth' => sub {shift->set_screen_name(@_)},
			       'set_args' => [],
			       'disp'     => 'Keyword screen name',
			       'search'   => 0,
			       'len'      => 256,
			       'type'     => 'short',
			       'props'    => {'type'       => 'text',
					      'length'     => 64,
					      'max_length' => 256,}
			      },
	     'sort_name'   => {'get_meth' => sub {shift->get_sort_name(@_)},
			       'get_args' => [], 
			       'set_meth' => sub {shift->set_sort_name(@_)},
			       'set_args' => [],
			       'disp'     => 'Sort order name',
			       'search'   => 0,
			       'len'      => 256,
			       'type'     => 'short',
			       'props'    => {'type'       => 'text',
					      'length'     => 64,
					      'max_length' => 256,}
			      },
	     'meaning'     => {'get_meth' => sub {shift->get_meaning(@_)},
			       'get_args' => [],
			       'set_meth' => sub {shift->set_meaning(@_)},
			       'set_args' => [],
			       'disp'     => 'Keyword meaning',
			       'search'   => 0,
			       'len'      => 512,
			       'type'     => 'short',
			       'props'    => {'type'       => 'text',
					      'length'     => 64,
					      'max_length' => 256,}
			      },
	     'prefered'    => {'get_meth' => sub {shift->get_prefered(@_)},
			       'get_args' => [],
			       'set_meth' => sub {shift->set_prefered(@_)},
			       'set_args' => [],
			       'disp' => 'Prefered keyword status',
			       'search'   => 0,
			       'len'      => 1,
			       'type'     => 'short',
			       'props'    => {'type' => 'checkbox'}
			      },
	    };
    $METH->{keyword} = $METH->{name};
    # Load attributes.
    # NONE
    
    return $METH;
}

#--------------------------------------#

=head2 Public Instance Methods

=cut

#------------------------------------------------------------------------------#

=item $name = $key->get_name();

Returns the name of this synonym

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $name = $key->set_name($name);

Sets the name of this synonym

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $name = $key->get_screen_name();

Returns the screen name of this synonym.  The screen name is how the synonym should be displayed on screen (i.e. name='george' screen_name='Washington, George')

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $name = $key->set_screen_name($name);

Sets the screen name of this synonym.  If no meaning is given, the default 
meaning '_default' will be used.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $meaning = $key->get_meaning();

Sets the screen name of this synonym

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $meaning = $key->set_screen_name($name);

Sets the screen name of this synonym

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $bool = $key->get_prefered();

A keyword can be marked as preferred.  A preferred keyword is a keyword in a list 
of synonyms that should be used in preference to any other synonymous keywords.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $success = $key->set_prefered(1 || 0);

Set the preferred flag for this keyword.  See the 'is_preferred' method for more 
information on preferred keywords.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item $state = $key->get_state();

Get the state of this keyword.  The state can be one of 'pending', 'rejected',
'accepted' or 'active'.

A state of 'pending' means that the keyword has been suggested, but has not yet
been confirmed to be an accepted keyword by the asset owner.

A state of 'rejected' means that the keyword has been rejected as a possible 
keyword for this asset.  However, at any point up until the asset finishes 
passing through the workflow, it can be promoted to 'accepted' by another owner 
of the asset.

A state of 'accepted' means that the keyword has been accepted as a valid 
keyword.  At any point up until the asset finishes passing through the workflow,
this keyword can still be marked as 'rejected' by another owner of the asset.

A state of 'active' means that the keyword has been accepted and cannot be 
marked as 'accepted' or 'rejected' during the workflow.  The state of a keyword
becomes 'active' if its state is 'accepted' when the asset with which it was 
associated reaches the end of the workflow.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_state {
    my $self = shift;

    # state is just an alias for active.
    return $self->get_active;
}

#------------------------------------------------------------------------------#

=item $state = $key->set_state();

Sets the state of this keyword.  See method 'get_state' for list of the possible
states and their descriptions.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_state {
    my $self = shift;

    # state is just an alias for active.
    return $self->set_active(@_);
}

#------------------------------------------------------------------------------#

=item $sets = $key->make_synonymous([$kw_id]);

Make the current keyword a synonym of other keywords by passing keys:

=over 4

=item *

keyword_id

A keyword object ID

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub make_synonymous {
    my $self = shift;
    my ($kw) = @_;
    my $syn_obj = $self->_get_synonym_grp;
    
    # Add the synonym.
    $syn_obj->add_synonym($kw);
 
    $self->_set__dirty(1);
   
    return $self;
}

#------------------------------------------------------------------------------#

=item $success = $key->save;

Save the keyword and/or all changes to the database.

B<Throws:>

"Unable to save";

B<Side Effects:>

Will give default values to screen_name and sort_name if they are not set.

B<Notes:>

NONE

=cut

sub save {
    my $self = shift;
    my $id = $self->get_id;

    return unless $self->_get__dirty;

    # Save the synonym group.
    $self->_sync_synonym_grp;

    # Set some defaults if these values aren't already set.
    my ($name, $scrn, $sort) = $self->_get('name', 'screen_name', 'sort_name');
    $scrn ||= $name;
    $sort ||= $name;
    $self->_set(['screen_name', 'sort_name'], [$scrn, $sort]);

    if ($id) {
	$self->_update_keyword();
    } else {
	$self->_insert_keyword();
    }

    # Now that we are guaranteed to have an ID add ourselves to the synonym grp.
    my $syn_obj = $self->_get_synonym_grp;
    unless ($syn_obj->has_member($self)) {
	$syn_obj->add_synonym([$self]);
	$syn_obj->save;
    }

    $self->_set__dirty(0);

    return $self;
}

#==============================================================================#

=head2 Private Methods

=cut

#--------------------------------------#

=head2 Private Class Methods

NONE

=cut


# Add methods here that do not require an object be instantiated, and should not
# be called outside this module (e.g. utility functions for class methods).
# Use same POD comment style as above for 'new'.

#--------------------------------------#

=head2 Private Instance Methods

NONE

=cut

sub _select_keyword {
    my ($where, $bind) = @_;
    my (@d, @ret);

    my $sql = 'SELECT '.join(',','id',COLS).' FROM '.TABLE;
    $sql   .= ' WHERE '.$where if $where;
    $sql   .= ' ORDER BY sort_name';

    my $sth = prepare_c($sql);
    execute($sth, @$bind);
    bind_columns($sth, \@d[0..(scalar COLS)]);
    
    while (fetch($sth)) {
	push @ret, [@d];
    }
    
    finish($sth);

    return \@ret;
}

sub _update_keyword {
    my $self = shift;
    
    my $sql = 'UPDATE '.TABLE.
              ' SET '.join(',', map {"$_=?"} COLS).' WHERE id=?';


    my $sth = prepare_c($sql);
    execute($sth, $self->_get(COLS), $self->get_id);
    
    return 1;
}

sub _insert_keyword {
    my $self = shift;
    my $nextval = next_key(TABLE);

    # Create the insert statement.
    my $sql = 'INSERT INTO '.TABLE." (id,".join(',',COLS).") ".
              "VALUES ($nextval,".join(',', ('?') x COLS).')';
    
    my $sth = prepare_c($sql);
    execute($sth, $self->_get(COLS));
  
    # Set the ID of this object.
    $self->_set(['id'],[last_key(TABLE)]);

    return 1;
}

sub _get_synonym_grp {
    my $self = shift;
    my $syn_id  = $self->get_synonym_grp_id;
    my $syn_obj = $self->_get('_synonym_grp_obj');

    unless ($syn_obj) {
	if ($syn_id) {
	    $syn_obj = Bric::Util::Grp::Keyword->lookup({'id' => $syn_id});
	} else {
	    my $desc = "Synonyms for keyword";
	    $syn_obj = Bric::Util::Grp::Keyword->new({'name'        => 'synonym',
						    'description' => $desc});
	}

	$self->_set(['_synonym_grp_obj'], [$syn_obj]);

	$self->_set__dirty(0);
    }

    return $syn_obj;
}

sub _sync_synonym_grp {
    my $self = shift;
    my $syn_obj = $self->_get('_synonym_grp_obj');

    # Return unless we've got an object.
    return unless $syn_obj;

    # Save the object.
    $syn_obj->save;
    
    # Save the ID.
    $self->_set(['synonym_grp_id'], [$syn_obj->get_id]);

    return $self;
}

1;
__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

"Garth Webb" <garth@perijove.com>
Bricolage Engineering

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Util::Grp::Keyword>, L<Bric::Biz::Category>

=cut
