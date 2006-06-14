<%doc>

</%doc>


%#-- Arguments --#
%# pass object or id and type

<%args>
$id => undef
$type => ''
$object => undef
$action
$section
</%args>

<%once>
my $widget = 'asset_meta';
</%once>

<%init>
$id = get_state_data($widget, 'id') unless defined $id;
if ($object) {
    $id   = $object->get_id;
    $type = $object->key_name;
} elsif ($type && defined $id) {
    if ($type eq 'story') {
        $object = get_state_data('story_prof', 'story');
        unless ($object && $object->get_id == $id) {
            $object = Bric::Biz::Asset::Business::Story->lookup({ 'id' => $id });
        }
    } elsif ($type eq 'template') {
        $object = get_state_data('tmpl_prof', 'template');
        unless ($object && $object->get_id == $id) {
            $object = Bric::Biz::Asset::Template->lookup({ 'id' => $id });
        }

    } elsif ($type eq 'media') {
        $object = get_state_data('media_prof', 'media');
        unless ($object && $object->get_id == $id) {
            $object = Bric::Biz::Asset::Business::Media->lookup({ 'id' => $id });
        }
    }

    set_state_data($widget, 'id', $id);
}

if ($section eq 'notes') {
    my $notes = $object->get_notes();

    my $version = $object->get_version();
    set_state_data($widget, 'obj', $object);
    set_state_data($widget, 'notes', $notes);
    set_state_data($widget, 'version', $version);
    $r->pnotes("$widget|name", '&quot;' . $object->get_name . '&quot;');
}

my $comp = $action . '_' . $section . '.html';

$m->comp('/widgets/summary/summary.mc', asset => $object, number => 1);
$m->comp($comp, widget => $widget, number => 2);
</%init>
