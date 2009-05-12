package Bric::Mech;

require 5.006001;
our $VERSION = '0.04';

use strict;
use warnings;

use Carp;
# (can also require HTML::TokeParser::Simple)

=head1 Name

Bric::Mech - browse Bricolage using WWW::Mechanize

=head1 Synopsis

  use Bric::Mech;

  # Login
  my $mech = Bric::Mech->new();
  $mech->login(server => 'http://example.com');

  # Open the 'Story' workflow
  $mech->open_workflow_menu(name => 'Story');

  # Click on 'New Story' in that workflow
  $mech->follow_action_link(action => 'new');

  ...

  $mech->logout();

=head1 Description

This class subclasses L<WWW::Mechanize|WWW::Mechanize> to provide
convenience methods for navigating the Bricolage browser interface.

=head1 Class Methods

=head2 new

  my $self = Bric::Mech->new();

Constructs a new Bric::Mech object. The object's attributes are
described in the L</ATTRIBUTE METHODS> section.

=head3 Args:

=over 4

=item version (optional)

Indicate which version of Bricolage the server you're connecting to is.
You can either give the exact version (e.g. '1.10.2') or the "series"
(e.g. '1.10'). Defaults to '1.10', which is nominally the earliest
supported version (though I hope to make it work with 1.8, too;
I know that currently it doesn't with some methods).

=item base (optional)

Set this object's base class, which should have an interface compatible
with L<WWW::Mechanize|WWW::Mechanize>, which is the default base class.
You might use another subclass of WWW::Mechanize or even
L<Win32::IE::Mechanize|Win32::IE::Mechanize> (not tried yet).

=back

All other arguments are passed directly to $self->SUPER::new.

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $version = delete($args{version});
    my $base = delete($args{base}) || 'WWW::Mechanize';

    our @ISA = ($base);
    eval "require $base";
    croak("new failed: requiring base class, ERROR = $@") if $@;
    my $self = $class->SUPER::new(%args);
    bless $self, $class;

    $self->{bric_version} = $version || '1.10';
    $self->{_base} = $base;

    foreach my $attr (qw(server username password lang_key)) {
        $self->{$attr} = '';
    }
    foreach my $attr (qw(logged_in workflow site debug)) {
        $self->{$attr} = 0;
    }
    foreach my $attr (qw(_double_lists)) {
        $self->{$attr} = {};
    }

    return $self;
}


=head1 Object Methods

Something to keep in mind with these methods is that the
Bricolage UI is divided into two parts: the left nav and
the main content. The left nav is included through an <iframe>,
so it's almost like it's not really part of the HTML for a
particular page. In order to manipulate the menus in the left nav,
you have to "go into" the left nav; that is you follow the link
specified by the "src" attribute of the <iframe>. When this happens,
the $self object's content only contains the left nav HTML, so
it's impossible to call some methods while in the left nav. (Some methods
ignore this, however; for example, you can call L</logout> even from
within the left nav, even though technically there is no Logout button
in the left nav.) In order to tell if you're in the left nav, you can
call the L</in_leftnav> attribute method. Any documentation below that
says something like "if you're in the left nav" really means
"if $self->in_leftnav returns true".

In addition to the methods listed here, you can also use
any of L<WWW::Mechanize|WWW::Mechanize>'s methods.
L<WWW::Mechanize|WWW::Mechanize> is itself a subclass of
L<LWP::UserAgent|LWP::UserAgent>, so you can use any of
its methods as well (except the ones overridden by
L<WWW::Mechanize|WWW::Mechanize>).

When an error occurs, these methods generally C<croak>.
The croak message will be something of the form "$sub: some reason",
where $sub is the subroutine in which the error occurred.

Most of the methods happen to return $self when they succeed,
but you probably shouldn't rely on that since it might change.

=cut


### LOGIN METHODS ################################################

=head1 Login Methods

=head2 login

  $self->login();

Logs in to Bricolage: brings up the login page, fills in the
username and password, then clicks the Log In button.

=head3 Args:

=over 4

=item server (optional)

The URL for the Bricolage server. Defaults to $ENV{BRICOLAGE_SERVER}
or 'http://localhost'. This will be put into the format 'http://hostname'
if only the hostname (including an optional port number) is passed in.

=item username (optional)

The username to login as. Defaults to $ENV{BRICOLAGE_USERNAME} or 'admin'.

=item password (optional)

The password to login with. Defaults to $ENV{BRICOLAGE_PASSWORD}
or 'change me now!'.

=back

=head3 Returns:

Returns C<true> on success. $self->in_leftnav will return C<false>.

=cut

sub login {
    my $self = shift;
    my %args = @_;
    $self->_init_login(%args);

    # Get cookie
    $self->get($self->get_server);
    unless ($self->success) {
        my $status = $self->status;
        $self->_croak("couldn't get cookie (status=$status)");
    }

    # Login
    $self->get($self->get_server . '/login');
    unless ($self->success && $self->content =~ /bricolage_login/) {
        $self->_croak("couldn't get login page");
    }

    $self->set_visible($self->get_username, $self->get_password);
    $self->click();

    if ($self->success) {
        if ($self->content =~ m{location\.href='([^']+)'}) {
            # Redirect from JavaScript...
            # <script>location.href='http://localhost/?BRICOLAGE_AUTH=exp%...';</script>
            $self->get($1);
        }
        if ($self->success) {
            my $content = $self->content;
            if ($content =~ /bricolage_login/ && $content =~ /errorMsg/) {
                $self->_croak("invalid username or password");
            }
        } else {
            $self->_croak("couldn't redirect from JavaScript");
        }
    } else {
        $self->_croak("clicking Log In button");
    }

    my $link = $self->find_link(tag => 'link');

    $self->{logged_in} = 1;
    return $self;
}


=head2 logout

  $self->logout();

Logs out of Bricolage: clicks the Log Out button
(even if you're actually in the left nav). This will
close the left nav menus, for one thing (it will not,
however, change the site context).

=cut

sub logout {
    my $self = shift;

    if ($self->logged_in) {
        $self->get($self->get_server . '/logout');
        # I just assume it succeeded, since you'd have to login
        # again anyway.
    } else {
        carp "wasn't logged in, so didn't logout\n";
    }

    $self->{logged_in} = 0;
    $self->{workflow} = 0;
    return $self;
}


### LEFT NAV METHODS #############################################

=head1 Left Nav Methods

=head2 my_workspace

  $self->my_workspace();

Clicks the 'My Workspace' button. You can do this whether or not
you're in the left nav. This method is kind of the inverse
of L</enter_leftnav>.

=head3 Args:

None.

=head3 Returns:

$self->in_leftnav will return false.

=cut

sub my_workspace {
    my $self = shift;

    $self->enter_leftnav();

    my $url = '/workflow/profile/workspace/';
    unless ($self->follow_link(url => $url)) {
        $self->_croak("didn't find link $url");  # huh?
    }

    return $self;
}


=head2 enter_leftnav

  $self->enter_leftnav();

Enters the left nav <iframe>, i.e. it gets the page that the
'src' attribute of the <iframe> tag points to. You can call this
even if you're already in the left nav (though it won't do anything).

=head3 Args:

None.

=head3 Returns:

$self->in_leftnav will return C<true>, naturally.

=cut

sub enter_leftnav {
    my $self = shift;

    $self->follow_link(tag => 'iframe') unless $self->in_leftnav;
    unless ($self->in_leftnav) {
        $self->_croak("getting left nav");
    }

    return $self;
}


=head2 open_workflow_menu

  $self->open_workflow_menu(name => 'Story');

Expands a workflow menu (under 'MY WORKSPACE') and sets it as the
current workflow menu. The menu stays expanded if it is already.
The idea of an open workflow menu is just so that you can repeatedly
call methods which, say, create a new story using the currently
opened workflow menu. You can call this whether or not you're already
in the left nav.

=head3 Args:

One of 'id' or 'name' must be given.

=over 4

=item id

The workflow's ID.

=item name

The workflow's name. This will match case-insensitively. If 'id' is
also given, this argument will be ignored.

=item expand_only (optional)

Passing this boolean argument a C<true> value will cause the menu
to expand, but the menu won't be set as the currently open workflow menu.

=back

=head3 Returns:

$self->in_leftnav will return <true>.
$self->get_workflow_menu will return the ID of the opened workflow.

=cut

sub open_workflow_menu {
    my $self = shift;
    my %args = @_;
    delete $args{name} if exists $args{id};

    $self->enter_leftnav();

    # Get ID
    my $link;
    my $id = exists($args{id}) ? $args{id} : 0;
    if ($id) {
        $link = $self->find_link(url_regex => qr/navwfid=$id\b/);
    } else {
        $link = $self->find_link(url_regex => qr/workflow_cb/,
                                 text_regex => /^$args{name}$/i);
    }
    $self->_croak("couldn't find workflow menu link") unless defined $link;
    if ($link->url =~ /navwfid=(\d+)\b/) {
        $id = $1;
    } else {
        $self->_croak("couldn't find ID in URL");
    }

    # Open the menu if necessary
    if ($link->url =~ /workflow_cb=1/) {
        $self->get($link);
        unless ($self->success && $self->in_leftnav) {
            $self->_croak("couldn't open link " . $link->url);
        }
    }

    $self->{workflow} = $id unless exists $args{expand_only} && $args{expand_only};
    return $self;
}


=head2 close_workflow_menu

  $self->close_workflow_menu();

Close a workflow menu that was opened with L</open_workflow_menu>.
If the menu was already collapsed, it stays collapsed. You can call
this whether or not you're already in the left nav.

=head3 Args:

=over 4

=item id (optional)

A workflow ID. If no ID is given, closes the current workflow
menu ($self->get_workflow_menu). If an ID is given which isn't the
currently open workflow menu, it will just collapse the menu,
but it will not affect $self->get_workflow_menu.

=item name (optional)

XXX: Not yet implemented.

=item expand_only (optional)

XXX: Not yet implemented.

=back

=head3 Returns:

$self->in_leftnav will return C<true>. $self->get_workflow_menu
will return 0.

=cut

sub close_workflow_menu {
    my $self = shift;
    my %args = @_;
    my $id = $self->get_workflow_menu;
    $id = $args{id} if exists $args{id};

    $self->enter_leftnav();

    if ($id) {
        my $link = $self->find_link(url_regex => qr/navwfid=$id\b/);
        $self->_croak("couldn't find workflow menu link") unless defined $link;

        # Close the menu if necessary
        if ($link->url =~ /workflow_cb=0/) {
            $self->get($link);
            unless ($self->success && $self->in_leftnav) {
                $self->_croak("couldn't open link " . $link->url);
            }
        }
    }

    $self->{workflow} = 0 if $id == $self->get_workflow_menu;
    return $self;
}


=head2 expand_workflow_menus

  $self->expand_workflow_menus();

Expands all workflow menus in the left nav (the things under 'MY WORKSPACE').
Already expanded menus will stay expanded. Any profile or manager that you
were visiting will be lost. You can expand menus whether or not you're already
in the left nav.

Note: this method does B<not> set the current workflow.

=head3 Args:

None.

=head3 Returns:

$self->in_leftnav will return C<true> since this goes into the left nav.

=cut

sub expand_workflow_menus {
    my $self = shift;

    $self->enter_leftnav();

    while (my $link = $self->find_link(url_regex => qr/workflow_cb=1/)) {
        $self->get($link);
        unless ($self->success && $self->in_leftnav) {
            my $url = $link->url;
            my $err = 'expanding workflow menu';
            if ($url =~ /navwfid=(\d+)/) {
                $err .= " ($1)";
            }
            $self->_croak($err);
        }
    }

    return $self;
}


=head2 collapse_workflow_menus

  $self->collapse_workflow_menus();

Collapses all workflow menus in the left nav (the things under 'MY WORKSPACE').
Already collapsed collapsed menus will stay collapsed. Any profile or manager
that you were visiting will be lost. You can collapse menus whether or not
you're already in the left nav.

Note: this method does B<not> set the current workflow.

=head3 Args:

None.

=head3 Returns:

$self->in_leftnav will return C<true> since this goes into the left nav.

=cut

sub collapse_workflow_menus {
    my $self = shift;

    $self->enter_leftnav();

    while (my $link = $self->find_link(url_regex => qr/workflow_cb=0/)) {
        $self->get($link);
        unless ($self->success && $self->in_leftnav) {
            my $url = $link->url;
            my $err = 'collapsing workflow menu';
            if ($url =~ /navwfid=(\d+)/) {
                $err .= " ($1)";
            }
            $self->_croak($err);
        }
    }

    return $self;
}


=head2 expand_admin_menus

  $self->expand_admin_menus();

Expands all ADMIN menus in the left nav (SYSTEM, PUBLISHING, DISTRIBUTION).
Already expanded menus will stay that way. Any profile or manager that you
were visiting will be lost. You can expand menus whether or not you're
already in the left nav.

Note: you might just want to use L</follow_admin_link>,
which will call this method internally before clicking the link.

=head3 Args:

None.

=head3 Returns:

$self->in_leftnav will return C<true> since this goes into the left nav.

=cut

sub expand_admin_menus {
    my $self = shift;

    $self->enter_leftnav();
    $self->_expand_admin();

    foreach my $submenu (qw(adminSystem adminPublishing distSystem)) {
        next if $self->find_link(url_regex => qr/$submenu\_cb=0/);
        my $link = $self->find_link(url_regex => qr/$submenu\_cb=1/);
        next unless defined $link; # user might not have perm for an ADMIN menu
        $self->get($link);
        unless ($self->success && $self->in_leftnav) {
            $self->_croak("expanding $submenu menu");
        }
    }

    return $self;
}


=head2 collapse_admin_menus

  $self->collapse_admin_menus();

Collapses all ADMIN menus in the left nav (SYSTEM, PUBLISHING, DISTRIBUTION).
Already collapsed menus will stay that way. Any profile or manager that you
were visiting will be lost. You can collapse menus whether or not you're
already in the left nav.

=head3 Args:

None.

=head3 Returns:

$self->in_leftnav will return C<true> since this goes into the left nav.

=cut

sub collapse_admin_menus {
    my $self = shift;

    $self->enter_leftnav();
    $self->_expand_admin();

    foreach my $submenu (qw(adminSystem adminPublishing distSystem)) {
        next if $self->find_link(url_regex => qr/$submenu\_cb=1/);
        my $link = $self->find_link(url_regex => qr/$submenu\_cb=0/);
        next unless defined $link; # user might not have perm for an ADMIN menu
        $self->get($link);
        unless ($self->success && $self->in_leftnav) {
            $self->_croak("collapsing $submenu menu");
        }
    }

    $self->_collapse_admin();

    return $self;
}


=head2 follow_action_link

  $self->follow_action_link();

In a workflow menu, follow one of the links under 'Actions'
('New Media', 'New Alias', 'Find Stories', 'Active Templates'...)

This expands the workflow menu internally before following a link,
but it won't set the current open workflow menu. Since it calls
L</open_workflow_menu>, it will also enter the left nav.

=head3 Args:

=over 4

=item action (required)

One of 'new', 'alias', 'find', or 'active',
corresponding to (for example) 'New Story', 'New Alias', 'Find Stories',
and 'Active Stories', respectively. The 'alias' argument will cause an
error if used for a template workflow since there is no 'New Alias'
link in template workflows.

=item workflow_id (optional)

A workflow ID. If not given, defaults to the current workflow ID
($self->get_workflow_menu); if there isn't a current workflow,
then it will croak.

=item workflow_name (optional)

XXX: Not implemented yet.

=back

=head3 Returns:

$self->in_leftnav will return C<true> since this goes into the left nav.

=cut

sub follow_action_link {
    my $self = shift;
    my %args = @_;

    # Validate arguments
    $self->_croak("missing required 'action' argument")
      unless exists $args{action};
    $self->_croak("'action' argument invalid")  # (XXX: template + alias)
      unless $args{action} =~ /^(new|alias|find|active)$/;
    my $id = exists($args{workflow_id}) ? $args{workflow_id} : $self->get_workflow_menu;
    $self->_croak("invalid workflow ID ($id)") unless $id;

    # Make sure the menu is expanded
    $self->open_workflow_menu(id => $id, expand_only => 1);

    my %action_url = (
        'new'    => qr{/workflow/profile/(media|story|templates)/new/$id$},
        'alias'  => qr{/workflow/profile/alias/(media|story)/new/$id$},
        'find'   => qr{/workflow/manager/(media|story|templates)/$id$},
        'active' => qr{/workflow/active/(media|story|templates)/$id$},
    );
    if ($self->follow_link(url_regex => $action_url{$args{action}})) {
        $self->_croak("follow_link unsuccessful (action='$args{action}', id='$id')")
          unless $self->success && !$self->in_leftnav;
    } else {
        $self->_croak("link not found (action='$args{action}', id='$id')");
    }

    return $self;
}


=head2 follow_desk_link

  $self->follow_desk_link(name => 'Edit');

In a workflow menu, follow one of the links under 'Desks'.

This expands the workflow menu internally before following a link,
but it won't set the current open workflow menu. Since it calls
L</open_workflow_menu>, it will also enter the left nav.

=head3 Args:

=over 4

=item name (required)

A desk name.

=item workflow_id (optional)

A workflow ID. If not given, defaults to the current workflow menu
($self->get_workflow_menu); if there isn't a current workflow,
then it will croak.

=item workflow_name (optional)

XXX: Not implemented yet.

=back

=head3 Returns:

$self->in_leftnav will return C<true> since this goes into the left nav.

=cut

sub follow_desk_link {
    my $self = shift;
    my %args = @_;

    # Validate arguments
    $self->_croak("missing required 'name' argument")
      unless exists $args{name};
    my $id = exists($args{workflow_id}) ? $args{workflow_id} : $self->get_workflow_menu;
    $self->_croak("invalid workflow ID ($id)") unless $id;

    # Make sure the menu is expanded
    $self->open_workflow_menu(id => $id, expand_only => 1);

    if ($self->follow_link(url_regex => qr{/workflow/profile/desk/\d+/\d+},
                           text => $args{name})) {
        $self->_croak("follow_link unsuccessful (name='$args{name}', id='$id')")
          unless $self->success && !$self->in_leftnav;
    } else {
        $self->_croak("link not found (name='$args{name}', id='$id')");
    }

    return $self;
}


=head2 follow_admin_link

  $self->follow_admin_link();

Follow one of the links under the ADMIN->SYSTEM, ADMIN->PUBLISHING,
or ADMIN->DISTRIBUTION. These links are generally Managers.

This calls L</expand_admin_menus> internally before following a link.

=head3 Args:

One of 'manager' or 'text' must be given. In case both are given,
'manager' takes precedence.

=over 4

=item manager

The URLs of the admin links are usually like "/admin/manager/$something"
(an exception is 'Bulk Publish'). This argument lets you specify $something,
that is what follows '/admin/manager/' (or '/admin/control/' for
'Bulk Publish') in the URL. Can be one of the following:

pref, user, grp, site, alert_type, output_channel, contrib, contrib_type,
workflow, category, element, element_type, media_type, source, keyword,
publish, dest, job

=item text

The text of the link. If Bricolage's language is set to English,
this would be one of the following:

Preferences, Users, Groups, Sites, Alert Types,
Output Channels, Contributors, Contributor Types, Workflows,
Categories, Elements, Element Types, Media Types, Sources,
Keywords, Bulk Publish, Destinations, Jobs

=back

=head3 Returns:

$self->in_leftnav will return C<false>. All ADMIN submenus will
be expanded.

=cut

sub follow_admin_link {
    my $self = shift;
    my %args = @_;

    unless (exists $args{manager} or exists $args{text}) {
        $self->_croak("one of 'manager' or 'text' is required as an argument");
    }

    # Make sure the menu is expanded
    $self->expand_admin_menus();

    if (exists $args{manager}) {
        my $manager = $args{manager};
        unless ($self->follow_link(url_regex => qr{^/admin/(?:manager|control)/$manager$})) {
            $self->_croak("link not found (manager=$manager)");
        }
    } else {
        unless ($self->follow_link(text => $args{text})) {
            $self->_croak("link not found (text=$args{text})");
        }
    }
    unless ($self->success && !$self->in_leftnav) {
        $self->_croak("follow_link unsuccessful");
    }

    return $self;
}


### MANAGER METHODS ##############################################

=head1 Manager Methods

=head2 search

XXX: Yet to be implemented.

=head2 manager_add_new

XXX: Yet to be implemented.

=head2 paged results

XXX: Yet to be implemented. How to handle them?

=head2 edit, delete

XXX: Yet to be implemented.

=cut


### PROFILE METHODS ##############################################

=head1 Profile Methods

=head2 add_to_list

XXX: Yet to be implemented. The docs here might change.

Click on an 'Add to List' button. (The button probably says something
different if you set the language other than en_us, but that doesn't
matter.)

=for comment
comp/media/js/lib.js - see confirmChanges function, search for "2xLM"
to see how it selects the _new_ items in each list. These are handled
in the Bric::App::Callback::Profile manage_grps callback.
Destinations Profile seems to be the only page with two double-lists.
The rest seem to be from comp/widgets/grp_membership/grp_membership.mc.
A good example to look at is the User Profile.

=cut

sub add_to_list {
    my $self = shift;
    $self->_croak("not yet implemented");

    my %args = @_;

    $self->_croak('in left nav') if $self->in_leftnav;


}


=head2 remove_from_list

XXX: Yet to be implemented. The docs here might change.

Click on a 'Remove from List' button. (The button probably says something
different if you set the language other than en_us, but that doesn't
matter.)

=cut

sub remove_from_list {
    my $self = shift;
    $self->_croak("not yet implemented");

    my %args = @_;

    $self->_croak('in left nav') if $self->in_leftnav;


}


=head2 common buttons like Save, Save-and-Stay, Cancel/Return

=head2 formBuilder widget

XXX: Yet to be implemented.

=cut


### WORKSPACE METHODS ############################################

=head1 WORKSPACE/DESK METHODS

=head2 site_context

  $self->site_context(name => 'New Site');

Select a site from the drop-down menu in the upper-right hand corner.

Note: site context is preserved even when you log out and back in.

=head3 Args:

=over 4

=item id

A site ID.

=item name

A site name. If both 'id' and 'name' are given, 'id' takes precedence.

=back

=head3 Returns:

If you pass an argument, the selected site is returned
as a hash reference; if you pass no arguments, all sites
are returned as a list of hash references. In either case,
the selected site will have an extra 'selected' element,
e.g. {id => 1024, name => 'New Site', selected => 1}.

=cut

sub site_context {
    my $self = shift;
    my %args = @_;

    my $sites = $self->_get_sites();
    $self->_croak("couldn't find sites") unless defined $sites;

    unless (exists $args{id} or exists $args{name}) {
        # Return current sites
        delete $_->{url} for @$sites;
        return $sites;
    }

    foreach my $arg (qw(id name)) {
        if (exists $args{$arg}) {
            my ($site) = grep { $_->{$arg} eq $args{$arg} } @$sites;
            $self->_croak("invalid $arg '" . $args{$arg} . "'")
              unless defined $site;

            $self->get($site->{url});
            $self->_croak("selecting site context ($site->{id}, $site->{name})")
              unless $self->success;
            $site->{selected} = 1;
            return $site;
        }
    }
}


=head2 XXX: More to be implemented.

=cut


### ATTRIBUTE METHODS ############################################

=head1 Attribute Methods

These are mostly read-only attributes. C<server>, C<username>,
and C<password> are set through the L</login> method.

=head2 get_server (string, read-only)

The server URL, e.g. 'http://localhost'.

=head2 get_username (string, read-only)

Username used to login, e.g. 'admin'.

=head2 get_password (string, read-only)

Password used to login, e.g. 'change me now!'.

=head2 logged_in (boolean, read-only)

Returns C<true> if we're logged in.

=head2 in_leftnav (boolean, read-only)

Returns C<true> when we're in the left nav.
When we get the <iframe> for the left navigation, the rest of the
user interface won't be in $self->content.

=head2 get_workflow_menu (integer, read-only)

Workflow ID of the currently open workflow menu.
If no workflow menu is open, this will be 0.

=head2 get_lang_key (string, read-only)

The language key, such as 'en_us' for English or 'pt_pt' for Portuguese.
I (try to) never rely on any localized text in pages so that this
module can be as general as possible. However, you might have a situation
where you want to do something different depending on what the language
is set to.

=head2 debug (boolean, settable)

If you pass a true value as the only argument, any errors output will
include a stack trace, and some other extra information will be printed
to STDERR. With no argument, just returns the current value.

=cut

sub get_server { $_[0]->{server} }

sub get_username { $_[0]->{username} }

sub get_password { $_[0]->{password} }

sub logged_in { $_[0]->{logged_in} }

sub in_leftnav {
    my $self = shift;
    # In 1.10, this shows
    # <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN"
    # "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">
    # but in 1.8 it's apparently showing
    # <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    # "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    # (though I swear it wasn't before).
    return $self->content =~ /id="navFrame"/;
}

sub get_workflow_menu { $_[0]->{workflow} }

sub get_lang_key { $_[0]->{lang_key} }

sub debug {
    my $self = shift;
    my $arg = shift;
    $self->{debug} = $arg if defined $arg;
    return $self->{debug};
}


### PRIVATE ######################################################

# Overridden from WWW::Mechanize -- not to update the HTML,
# but rather to initialize data obtained from certain pages,
# for example double lists on Profile pages. WWW::Mechanize
# calls this within its overridden 'request' method (via _update_page).
sub update_html {
    my ($self, $html) = @_;
    my $res = $self->SUPER::update_html($html);

    # Initialize double lists once at the beginning so that you can
    # call add_to_list or remove_from_list more than once.
    $self->_init_double_lists($html);

    # Set the lang key
    $self->_init_lang_key($html);

    return $res;  # I think this will always be undef, but just to be safe..
}

sub _init_login {
    my $self = shift;
    my %args = (
        server   => $ENV{BRICOLAGE_SERVER}   || 'http://localhost',
        username => $ENV{BRICOLAGE_USERNAME} || 'admin',
        password => $ENV{BRICOLAGE_PASSWORD} || 'change me now!',
        @_
    );

    $args{server} =~ s{/$}{};
    unless ($args{server} =~ m{^https?://}) {
        $args{server} = 'http://' . $args{server};
    }

    foreach my $param (qw(server username password)) {
        $self->{$param} = $args{$param};
    }
}

sub _init_double_lists {
    my ($self, $html) = @_;
    return unless defined $html && $html;

    # assume there are double lists _only_ on profile pages
    unless ($self->uri =~ m{/admin/profile/}) {
        $self->{_double_lists} = {};
        return;
    }

    require HTML::TokeParser::Simple;

    # Manually parsing <script> elements - ick.
    # This is to get the read-only items in the left and right lists.
    # There might be more than one double list (e.g. Destination Profile).
    my $p = HTML::TokeParser::Simple->new(\$html);
    while (my $token = $p->get_token) {
        next unless $token->is_start_tag('script');
        my $text = $p->get_text();

        # e.g.: doubleLists[doubleLists.length] = "rem_grp:add_grp"
        if ($text =~ /doubleLists\[doubleLists\.length\]\s*=\s*"([^:]+):([^"]+)"/) {
            my ($left, $right) = ($1, $2);
            my $dlist = "$left:$right";

            # get list of IDs of 4 vars
            foreach my $side ($left, $right) {
                foreach my $type (qw(readOnly values)) {
                    # e.g.: var add_grp_readOnly = new Array("2", "6")
                    if ($text =~ /($side\_$type)\s*=\s*new Array\(([^)]*)\)/) {
                        my ($var, $list) = ($1, $2);
                        $list =~ s/^\s*"//;  $list =~ s/"\s*$//;
                        my @ids = split /",\s*"/, $list;
                        $self->{_double_lists}{$dlist}{$var} = \@ids;
                    } else {
                        $self->_croak("didn't find \<script> var $side\_$type", 1);
                    }
                }
            }
        }
    }
}

sub _init_lang_key {
    my ($self, $html) = @_;
    return unless defined $html;
    return if $self->in_leftnav;

    # didn't want to fire up HTML::TokeParser::Simple just for this
    if ($html =~ m{href="/media/css/(?!style)(.+)\.css"}) {
        $self->{lang_key} = $1;
    }
}

sub _get_sites {
    my $self = shift;
    $self->_croak("can't get sites from left nav", 1)
      if $self->in_leftnav;

    my @sites = ();

    require HTML::TokeParser::Simple;

    # Get dropdown list - unfortunately, the <select> isn't within
    # a <form> (is that legal?); otherwise, we could've done $self->forms
    # and gotten the select with an HTML::Form method. Instead,
    # have to uglily parse HTML (sigh).
    # if there's no menu:
    # <div class="siteContext"></div>
    # if there is a menu:
    # <div class="siteContext">
    # <select name="site_context|change_context_cb" size="1" onChange="location.href='/admin/profile/user/0?' + this.name + '=' +this.options[this.selectedIndex].value">
    #  <option value="100" selected="selected">Default Site</option>
    #  <option value="1024">New Site</option>
    # </select>
    # </div>
    my $html = $self->content;
    my $p = HTML::TokeParser::Simple->new(\$html);
    HTML: while (my $token = $p->get_token) {
        next HTML unless $token->is_start_tag('div');

        if ($token->get_attr('class') eq 'siteContext') {
            my $url = '';
            DIV: while ($token = $p->get_token) {
                if ($token->is_end_tag('div')) {
                    if (@sites == 0) {
                        push @sites, {id => '100', name => 'Default Site',
                                      selected => 1};
                    }
                    last HTML;
                }
                if ($token->is_start_tag('select')) {
                    # get the URL to redirect to, minus the "selected" part at the end
                    my $name = $token->get_attr('name');
                    $url = $token->get_attr('onChange');
                    $url =~ s/^location[^']+'//;
                    $url =~ s/\?.+/?$name=/;  # XXX: add selected ID below
                }
                if ($token->is_start_tag('option')) {
                    my %site;
                    $site{id} = $token->get_attr('value');
                    $site{name} = $p->get_text();
                    $site{selected} = 1 if $token->get_attr('selected');
                    # For 'url', we pretend all the sites are selected,
                    # then in the 'site_context' we'll delete the 'url' attribute
                    # and use only the actually selected one
                    $site{url} = $url . $site{id};
                    push @sites, \%site;
                }
            }
        }
    }

    return \@sites;
}

sub _expand_admin {
    my $self = shift;

    # assumes already entered leftnav
    unless ($self->find_link(url_regex => qr/admin_cb=0/)) {
        # XXX: is it possible for ADMIN menu not to exist?
        $self->follow_link(url_regex => qr/admin_cb=1/);
        unless ($self->success && $self->in_leftnav) {
            $self->_croak('expanding ADMIN menu', 1);
        }
    }
}

sub _collapse_admin {
    my $self = shift;

    # assumes already entered leftnav
    unless ($self->find_link(url_regex => qr/admin_cb=1/)) {
        # XXX: is it possible for ADMIN menu not to exist?
        $self->follow_link(url_regex => qr/admin_cb=0/);
        unless ($self->success && $self->in_leftnav) {
            $self->_croak('collapsing ADMIN menu', 1);
        }
    }
}

sub _croak {
    my ($self, $err, $frames_up) = @_;
    $frames_up = 0 unless defined $frames_up;
    my $sub = (caller(1 + $frames_up))[3];
    $err = "$sub failed: $err\n";
    if ($self->debug) {
        confess($err);
    } else {
        croak($err);
    }
}


1;
__END__

=head1 See Also

L<WWW::Mechanize|WWW::Mechanize>,
http://bricolage.cc/

=head1 Copyright and License

Copyright 2005 Scott Lanning. This library is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty
of merchantability or fitness for a particular purpose.

=head1 Author

Scott Lanning <lannings@who.int>

=cut
