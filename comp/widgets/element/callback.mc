<%args>
$param
</%args>
<%init>;
my ($section, $mode, $key) = $m->comp("/lib/util/parseUri.mc");
# HACK - This should be changed in the class table at some point.
my $type = 'element';

# Get the class name.
my $class = get_package_name($type);

# Instantiate the object.
my $id = $param->{$key . '_id'};
my $obj = defined $id ? $class->lookup({ id => $id }) : $class->new;

# Check the permissions.
unless ( chk_authz($obj, $id ? EDIT : CREATE, 1) ) {
    # If we're in here, the user doesn't have permission to do what
    # s/he's trying to do.
    add_msg("Changes not saved: permission denied.");
    set_redirect(last_page());
    return;
}
# Process its data
$param->{obj} = $m->comp("$key.mc", %ARGS, obj => $obj, class => $class);
</%init>

<%doc>
###############################################################################

=head1 NAME

/widgets/formBuilder/callback.mc

=head1 VERSION

$Revision: 1.4 $

=head1 DATE

$Date: 2001-11-29 00:28:51 $

=head1 SYNOPSIS

print STDERR Data::Dumper::Dumper($param);
return;

  $m->comp('/widgets/formBuilder/callback.mc', %ARGS);

=head1 DESCRIPTION

Callback element for formBuilder.

</%doc>
