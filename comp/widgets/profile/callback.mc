<%args>
$param
</%args>
<%perl>;
my ($section, $mode, $type) = $m->comp("/lib/util/parseUri.mc");

# Get the class name.
my $key = $type eq 'contrib' && ! defined $param->{contrib_id} ? 'person'
  : $type;

my $class = get_package_name($key);
$class = $param->{grp_type} || $class if $type eq 'grp';

# Instantiate the object.
my $id = defined $param->{$type . '_id'} && $param->{$type . '_id'} ne ''
  ? $param->{$type . '_id'} : undef;
my $obj = defined $id ? $class->lookup({ id => $id }) : $class->new;

# Check the permissions.
unless ( $excl->{$type} || chk_authz($obj, (defined $id ? EDIT : CREATE), 1)
	 || ($type eq 'user' && $obj->get_id == get_user_id()) ) {
    # If we're in here, the user doesn't have permission to do what
    # s/he's trying to do.
    add_msg("Changes not saved: permission denied.");
    set_redirect(last_page());
    return;
}

# Process its data
$param->{obj} = $m->comp("$type.mc", %ARGS, obj => $obj, class => $class);
</%perl>
<%once>;
my $excl = { desk => 1, action => 1, server => 1 };
</%once>
<%doc>
###############################################################################

=head1 NAME

=head1 VERSION

$Revision: 1.5 $

=head1 DATE

$Date: 2001-12-04 18:17:41 $

=head1 SYNOPSIS

=head1 DESCRIPTION

</%doc>
