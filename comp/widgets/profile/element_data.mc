<%doc>
###############################################################################

=head1 NAME

/widgets/profile/element_data.mc - Processes submits from Field Profile

=head1 VERSION

$Revision: 1.1.2.2 $

=head1 DATE

$Date: 2003/11/26 02:02:41 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/element_data.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the Field Profile page.

Note that this only handles existing Fields; so for example, the 'name'
won't be set and a new Field won't be created.

=cut

</%doc>
<%once>;
my $type = 'element_data';
my $class = get_package_name($type);
my $disp_name = get_disp_name($type);
</%once>
<%args>
$widget
$param
$field
$obj
</%args>
<%init>;
return unless $field eq "$widget|save_cb";
# Grab the element type object and its name.
my $ed = $obj;
my $name = "&quot;" . $ed->get_name . "&quot;";

my $elem = Bric::Biz::AssetType->lookup({ id => $ed->get_element__id });
unless (chk_authz($elem, EDIT, 1)) {
    # If we're in here, the user doesn't have permission to do what
    # s/he's trying to do.
    add_msg("Changes not saved: permission denied.");
    set_redirect(last_page());
    return;
}

if ($param->{delete}) {
    # Deactivate it.
    $ed->deactivate();
    # XXX: not ${type}_del
    log_event('element_data_del', $ed);
    add_msg($lang->maketext("$disp_name profile [_1] deleted.",$name));
} else {
    my $numregex = qr{^\s*\d+\s*$};

    # Roll in the changes.
    $ed->set_description($param->{'description'});
    $ed->set_max_length($param->{'max_length'})
        if defined $param->{'max_length'} && $param->{'max_length'} =~ $numregex;
    $ed->set_required(defined $param->{'required'} ? 1 : 0);
    # Note: here's another place I assume quantifier is boolean
    $ed->set_quantifier(defined $param->{'quantifier'} ? 1 : 0);

    # Save metadata/display attributes
    my $set_meta_string = sub {
        my ($ed, $f, $param) = @_;
        $ed->set_meta('html_info', $f, $param->{$f}) if defined $param->{$f};
    };
    my $set_meta_number = sub {
        my ($ed, $f, $param) = @_;
        $ed->set_meta('html_info', $f, $param->{$f})
          if defined($param->{$f}) && $param->{$f} =~ $numregex;
    };
    my $set_meta_boolean = sub {
        my ($ed, $f, $param) = @_;
        if (defined $param->{$f}) {
            $ed->set_meta('html_info', $f, 1);
        } else {
            $ed->set_meta('html_info', $f, 0);
        }
    };

    my $f = 'size';
    $set_meta_number->($ed, $f, $param);
    $f = 'disp';
    $set_meta_string->($ed, $f, $param);
    $f = 'maxlength';
    $set_meta_number->($ed, $f, $param);
    $f = 'value';
    $set_meta_string->($ed, $f, $param);
    $f = 'vals';
    $set_meta_string->($ed, $f, $param);
    $f = 'multiple';
    $set_meta_boolean->($ed, $f, $param);
    $f = 'rows';
    $set_meta_number->($ed, $f, $param);
    $f = 'cols';
    $set_meta_number->($ed, $f, $param);

    add_msg($lang->maketext("$disp_name profile [_1] saved.",$name));
    # XXX: not ${type}_save
    log_event('element_data_save', $ed);
}

# Save changes and redirect back to the manager.
$ed->save();

# something like this if the Element Datum Manager is ever used
# (XXX: not working)
#set_redirect(defined $param->{"${type}_id"}
#               ? "/admin/manager/$type/" . $param->{"${type}_id"}
#               : last_page());

set_redirect(last_page());
</%init>
