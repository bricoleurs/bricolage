package TestMech;

use strict;
use warnings;

use base 'Test::WWW::Mechanize';

BEGIN {
    print $/;   # fix Test::Harness printing weirdness
}

use Exporter 'import';
our @EXPORT_OK = qw(%STORY %MEDIA %TEMPLATE);
our %STORY = (
    'title' => '!TestMech!Story!',
    'slug'  => 'bangtestmechbangstorybang',
    'story_prof|at_id' => 'Story',
);
our %MEDIA = (
    'title' => '!TestMech!Media!',
    'media_prof|at_id' => 'Illustration',
);
our %TEMPLATE = (

);


# new - constructor wrapper that logs in
# Args: nologin, server, username, password
# Other args are passed straight to Test::WWW::Mechanize::new().
# Usage:
# TestMech->new(nologin => 1);  # don't login
# TestMech->new(server => 'http://localhost');  # override 'server' arg to `login'
sub new {
    my $class = shift;
    my %args = @_;

    # Filter out args for `login'
    my %login_args = grep {defined} delete @args{qw(server username password)};
    my $do_login = delete $args{nologin} ? 0 : 1;

    my $self = $class->SUPER::new(%args);
    bless $self, $class;

    # Almost every test script wants to login first
    $self->login(%login_args) if $do_login;

    return $self;
}

# login - logs in to Bricolage, handling JavaScript redirect
# Args: server, username, password; these default to the
#   BRICOLAGE_SERVER, BRICOLAGE_USERNAME, and BRICOLAGE_PASSWORD
#   environment variables.
# Usage:
# $mech->login(password => 'change me later!');
sub login {
    my $self = shift;
    my %args = (
        server => $ENV{BRICOLAGE_SERVER},
        username => $ENV{BRICOLAGE_USERNAME},
        password => $ENV{BRICOLAGE_PASSWORD},
        @_
    );

    # Get cookie
    $self->get($args{server});

    # Login
    $self->get("$args{server}/login");
    $self->set_visible($args{username}, $args{password});
    $self->click();

    # Redirect from JavaScript...
    # <script>location.href='http://localhost/?BRICOLAGE_AUTH=exp%...';</script>
    if ($self->success) {
        my $content = $self->content;
        if ($content =~ m{location\.href='([^']+)'}) {
            $self->get($1);
        }
    }
}

1;
