package Bric::Util::WebDav;
###############################################################################

=head1 NAME

Bric::Util::WebDav - Placeholder for Bricolage DAV support.

=head1 DATE

$Date: 2003/08/11 09:33:36 $

=head1 VERSION

$Revision: 1.7 $

=cut

our $VERSION = (qw$Revision: 1.7 $ )[-1];

=pod

=head1 DESCRIPTION

In general, to implement Bric::Util::WebDav, one must write a module that
overwrites all the methods of Bric::Dav. It should be registered in the
httpd.conf file with the location mapping to a key in the %HANDLER hash. When
a request comes in, an object from the implementing class is instantiated,
with the Apache Request Object, the method, the uri, the element from the
location match, and the path following that. The handler method then calls the
various methods for the WebDav request (PUT, DELETE, etc.). It expects data to
be returned in the following format:

=head2 Return Data Structure

 $return = {
 'special'  => Used for returning DECLINED
              and the like. If 'special' is sent, all
              other information will be
              ignored.

 'error'  => Used for returning simply 
                the error code, i.e., 404.
                As with 'special,' if 'error' is sent, 
                all other information 
                will be ignored.

 'header'=> {
       'header to add' =>  Val 
                    if any additional headers 
                    are needed they should be 
                    sent like so
       },

 'status' =>  200 or 207 etc.,

 'type'   =>  Content-Type header text/html, 
              text/xml etc.

 'body'   =>  Body to be sent

 };

 The module you are writing should implement the following methods:

=head2 new 

Accepts the Apache request object, the uri, the uri with the first element
stripped out, the first element, and the method. Returns a blessed object.

=head2 get

Returns a body, type, and status from the proper uri in the format described
above.

=head2 put

Receives a body of a document and places it in the appropriate
location. Returns status_code and body or error code.

=head2 delete

For a given uri, returns status_code and body, or error_code, or 207
Multi-Status with XML body.

=head2 mkcol

Receives a body and creates a collection for a given uri. Returns status_code
and body or error code.

=head2 do_copy

Receives a Destination, Depth, Overwrite, and Body and makes a duplicate
resource at a given destination. Returns status_code and body, or error_code,
or 207 Multi-Status with XML body.

=head2 move

'Move' is the equivalent of 'copy' followed by a 'delete' of the initial
resource. The rules that apply for 'copy' and 'delete' apply to 'move.'

=head2 lock

Receives Depth, Timeout, If, Lock-Token Headers and XML from Body Attempt to
Lock Resource. If there is no Body it is an attempt to refresh the
lock. Should return errors_code, 200 Success with an XML body, or 207
Multi-Status with XML body.

=head2 unlock

Receives Lock-Token and attempts to unlock resource held by said
token. Returns success_code and body or error_code.

=cut

#=============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies                 

use strict;
#--------------------------------------#
# Programatic Dependencies
use Bric::Util::Fault qw(rethrow_exception throw_mni);

#=============================================================================#
# Inheritance                          #
#======================================#

use base qw(Bric);

#=============================================================================#
# Constants                            #
#======================================#

# Register Handlers Here 
my %HANDLER;
BEGIN {
	%HANDLER = (
	);
	foreach my $pkg (values %HANDLER){
            eval " require $pkg ";
            rethrow_exception($@) if $@;
	}
}

# the Methods allowed and the corresponding subroutines that 
# handle them
my %ALLOWED = (
	'OPTIONS'	=> 'options',
	'GET'		=> 'get',
	'COPY'		=> 'copy',
	'MOVE'		=> 'move',
	'PUT'		=> 'put',
	'DELETE'	=> 'delete',
	'MKCOL'		=> 'mkcol',
	'PROPFIND'	=> 'propfind',
	'PROPPATCH'	=> 'proppatch',
	'LOCK'		=> 'lock',
	'UNLOCK'	=> 'unlock'
);


#=============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields                   

use vars qw();

#--------------------------------------#
# Private Class Fields                  


#--------------------------------------#
# Instance Fields   
BEGIN {
	Bric::RegisterFields({
		'r' 	 => Bric::FIELD_RDWR,
		'uri' 	 => Bric::FIELD_RDWR,
		'method' => Bric::FIELD_RDWR,
		'caller' =>	Bric::FIELD_RDWR,
		'path'	 => Bric::FIELD_RDWR
	});
}

=pod

=head1 HANDLER

The handler takes the request, processes the uri, and determines what class
handles the backend based upon the Handler hash. It then dispatches the valid
request to the subroutines laid out in the Allowed hash. These will do a
little more information gathering from the request, then dispatch the request
to the proper methods within the class initiated earlier. The methods return
the appropriate codes, body, headers, etc.

=cut

sub handler {
	my $r = shift;

	# Construct webdav object from apache request object
	my $wd = Bric::Util::WebDav->new ($r);

	# Check to see if method is supported and get webdav method
	# to handle or send Not Implemented Error

	my $method = $ALLOWED{ $wd->get_method() } || return 501;

	# If supported, get handler object
	my $handler = $HANDLER{ $wd->get_caller() }->new ($wd) || return 501;

	# Run the appropriate method and get returned hash-ref
	my $return = $wd->$method ($handler);

	# Return special if it exists
	return $return->{'special'} if $return->{'special'};
	# Return error code if it exists
	return $return->{'error'} if $return->{'error'};

	# No special scenarios registered 
	## Set headers

	my %known_headers = (
		'Status' 		=> $return->{'status'},
		'Content-Type'	=> $return->{'type'}
	);

	# Send headers to the client
	map { $r->header_out( $_ => $return->{'header'}->{$_} ) 
			} keys %{ $return->{'header'} }, keys %known_headers;

	## Send headers and leave
    $r->send_http_header;
    $r->print ($return->{'body'});
}

#--------------------------------------#
# Constructors                          

#------------------------------------------------------------------------------#

=over 4

=item $wd = new Bric::Util::WebDav($r);

throws:

None

side effects:

None

notes:

processes $r to pull Dav specific info out

=cut

sub new {
	my $class = shift;
	my ($r) = @_;

	# Err, What should I do with these???
	my ($initial_state, $raiseError);

	my $self = fields::new($class);

	$self->SUPER::new($initial_state, $raiseError);
	# Extract first (no slashes) and remaining (leading 
	# and trailing slashes) elements from path info
	$r->uri =~ m#^/([^/]+)(.*)$#;

	$self->set_r ($r);
	$self->set_uri ($r->uri);
	$self->set_method ($r->method);
	$self->set_caller ($1);
	$self->set_path ($2);

	$self;
}

sub list {
    throw_mni(error => 'Method Not implemented');
}

#--------------------------------------#
# Destructors                           

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#
# Public Class Methods                  

# None

#--------------------------------------#
# Public Instance Methods               

=pod

=item $return = $self->options();

throws:

None

side effects:

None

notes:

Accepts a Webdav Object. Returns a Hashref containing a hashref whose keys are
the Allow Header Values and the Dav Header value. When called it provides a
client with a list of the allowed methods and establishes this as a Dav
compliant Server.

=cut

sub options {

	my $self = shift;

	# Return the Allowed methods and the WebDav Enabled Header
	my $return = {};
	$return->{'header'}->{'Allow'} = join(' ,', (keys %ALLOWED));
	$return->{'header'}->{'Dav'} = 1;

	return $return;
}

=pod

=item $return = $self->proppatch($impl_obj);

throws:

None

side effects:

None

notes:

Accepts a Webdav object and an implementation object. Returns a hash ref of
return info. Sends the Depth Header and the body to the implementation
object's propfind method. Returns the value returned for that call which
should be a 207 status code with an XML formatted response body or an error
code.

=cut

sub propfind {

	my ($self, $handler) = @_;

	# send handler Depth Header and Body
	$handler->propfind ($self->_get_headers('Depth'),
						$self->_get_body);
}

=pod

=item $self->proppatch($impl_obj);

throws:

None

side effects:

None

notes:

Accepts a Webdav object and an implementation object. Returned values: a hash
ref of return info. Sends the body to the implementation object's proppatch
method. Returns the value returned for that method which should be a 207
status code with an XML formatted response body or an error code.

=cut

sub proppatch {

	my ($self,$handler) = @_;

	# send Body to handler
	$handler->proppatch ($self->_get_body);
}

=pod

=item $return = $self->get($impl_obj);

throws:

None

side effects:

None

notes:

Accepts a Webdav object and an implementation object. Returned values: a hash
ref of return info. Passes no additional data. Expects to receive a status and
body, an error_code or a special.

=cut

sub get {

	my ($self,$handler) = @_;


	$handler->get();
}

=pod

=item $return = $self->put($impl_obj);

throws:

None

side effects:

None

notes:

Accepts a Webdav object and an implementation object. Returned values: a hash
ref of return info. Passes the data contained in the body. Expects to receive
a status and body, an error code, a 207 and XML body or a special. Places or
replaces an element at said uri. If PUT tries to place an item without proper
parentage it should return a 409 Conflict Code. So as not to override the
MKCOL command, put may not be a col resource.

=cut

sub put {

	my ($self,$handler) = @_;

	# send Handler Body
	$handler->put ($self->_get_body);
}

=pod

=item $return = $self->do_delete($impl_obj);

throws:

None

side effects:

None

notes:

Accepts a Webdav object and an implementation object. Returned values: a hash
ref of return info. Passes no additional data to the implementation
object. Expects to receive a status of 204, an error code, a 207 and XML body
or a special. Removes the resource of a given uri if called on a collection
(dir). It is a Depth=Infinity Request if error response in 207 Fashion unless
424 Failed Dependency. If there is a failure here it should be returned in XML
data, unless it is a not found or Failed Discrepancy Error.

=cut

sub do_delete {

	my ($self,$handler) = @_;

	$handler->do_delete();
}

=pod

=item $return = $self->mkcol($impl_obj);

throws:

None

side effects:

None

notes:

Accepts a Webdav object and an implementation object. Returned values: a hash
ref of return info. Passes the body of the request (if any) if expects to
receive a 201 with a body, or an error code. mkcol is a handler for MKCOL
requests will respond with the following status codes: 201 (Created) - On
Success 403 (Forbidden) - On Failure Not Allowed 405 (Method Not Allowed) -
Name already Taken 409 (Conflict) The ancestors do not exist 415 (Unsupported
Media Type) Body info type not supported 507 (Insufficient Storage) All
ancestors must exist for this to succeed and the uri cannot already be taken.

=cut

sub mkcol {

	my ($self,$handler) = @_;

	# send handler body
	$handler->mkcol ($self->_get_body);
}

=pod

=item  $return = $self->copy($impl_obj);

throws:

None

side effects:

None

notes:

Accepts a Webdav object and an implementation object. Returned values: a hash
ref of return info. Sends the values of the Destination, Depth, and Override
Headers and the body of the request. Expects to receive a 201 with a body, an
error code, a 207 with an XML Body, or a special. Copies a resource and all
its properties at x uri to y uri. Copy should work for depth headers of 0 and
infinity. Infinity gets a full recursive copy. 0 copies the collection and its
resources but not its members. Copy can also contain an overwrite header. If
so, a delete is performed first.

=cut

sub copy {

	my ($self,$handler) = @_;

	# Get Destination, Depth, Overwrite Headers and the Body
	# and send to Handler
	$handler->do_copy (	
		$self->_get_headers('Destination','Depth','Overwrite'),
			$self->_get_body
					);
}

=pod

=item $return = $self->move($impl_obj);

throws:

None

side effects:

None

notes:

Accepts a Webdav object and an implementation object. Returned values: a hash
ref of return info. Move is the equivalent of a Copy request followed by a
Delete request. All the rules governing both apply here.

=cut

sub move {

	my ($self,$handler) = @_;

	# get dest, depth, Overwrite headers as list and the body and send
	# to handler
	$handler->move (
		$self->_get_headers('Destination','Depth','Overwrite'),
			$self->_get_body
		);
}

=pod

=item $return = $self->lock($impl_obj);

throws:

None

side effects:

None

notes:

Accepts a Webdav object and an implementation object. Returned values: a hash
ref of return info. Sends the Values of the Depth, Timeout, If, and Lock-Token
Headers. Expects to receive a 200 with XML body, error code, a 207 with XML,
or a special. Performs a lock at said uri. Accepts Depth, Timeout, If,
Lock-Token Headers, XML in the Body.

=cut

sub lock {
	my ($self,$handler) = @_;

	# Get the Headers as list and body and send to client
	$handler->lock (
		$self->_get_headers('Depth','Timeout','If','Lock-Token'),
				$self->_get_body
		);
}

=pod

=item $self->unlock($impl_obj);

throws:

None

side effects:

None

notes:

Accepts a Webdav object and an implementation object. Returned values: a hash
ref of return info. Sends the Lock-Token header. Expects to receive a 204
success code or an error_code or a 207 with XML body. Unlocks resource at said
uri with associated lock-token.

=cut

sub unlock {
	my ($self,$handler) = @_;

	# Get lock token and send to handler
	$handler->unlock ($self->_get_headers('Lock-Token'));
}


#==============================================================================#
# Private Methods                      #
#======================================#

=pod

=back

=head1 PRIVATE FUNCTIONS

None

=cut

#--------------------------------------#
# Private Class Methods                 

=pod

=head1 PRIVATE CLASS METHODS

None

=cut

#--------------------------------------#
# Private Instance Methods              

=pod

=head1 PRIVATE INSTANCE METHODS

=over 4

=item $body = $wd->_get_body();

throws:

None

side effects:

None

notes:

Accepts a WebDav object Returns a Scalar of the contents of the body of the
request

=cut

sub _get_body {
	my $self = shift;

	my $body;
	$self->get_r()->read(
			$body, $self->get_r()->header_in(
						'Content-length'
					)
		);
	return $body;
}

=pod

=item @header_values = $wd->_get_headers(@header_names);

throws:

None

side effects:

None

notes:

Accepts a WebDav object and a list of Named headers Returns a list of their
values

=cut

sub _get_headers {
	my ($self,@headers) = @_;

	# For each of the requested headers, look up its value
	# and return them as a list
	@headers = map { $self->get_r()->header_in($_) } @headers;

}

1;
__END__

=back

=head1 AUTHOR

michael soderstrom (miraso@pacbell.net)

=cut

