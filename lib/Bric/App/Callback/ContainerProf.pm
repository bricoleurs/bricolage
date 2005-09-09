package Bric::App::Callback::ContainerProf;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'container_prof';

use strict;
use Bric::Config qw(:time);
use Bric::App::Authz qw(:all);
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:msg :aref :history :wf);
use Bric::App::Event qw(log_event);
use Bric::App::Callback::Desk;
use Bric::App::Callback::Profile::Media;
use Bric::Biz::AssetType;
use Bric::Biz::AssetType::Parts::Data;
use Bric::Biz::Asset::Business::Parts::Tile::Container;
use Bric::Biz::Asset::Business::Parts::Tile::Data;
use Bric::Biz::Workflow qw(:wf_const);
eval { require Text::Levenshtein };
require Text::Soundex if $@;

my $STORY_URL = '/workflow/profile/story';
my $CONT_URL  = '/workflow/profile/story/container';
my $MEDIA_URL = '/workflow/profile/media';
my $MEDIA_CONT = '/workflow/profile/media/container';

my $regex = {
    "\n" => qr/\s*\n\n|\r\r\s*/,
    '<p>' => qr/\s*<p>\s*/,
    '<br>' => qr/\s*<br>\s*/,
};

my %pkgs = (
    story => 'Bric::Biz::Asset::Business::Story',
    media => 'Bric::Biz::Asset::Business::Media',
);

sub edit : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $r = $self->apache_req;

    my $tile = get_state_data($self->class_key, 'tile');

    # Update the existing fields and get the child tile matching ID
    my $edit_tile = $self->_update_parts($param);

    # Push this child tile on top of the stack
    $self->_push_tile_stack($edit_tile);

    # Don't redirect if we're already on the right page.
    if ($tile->get_object_type eq 'media') {
        unless ($r->uri eq "$MEDIA_CONT/edit.html") {
            $self->set_redirect("$MEDIA_CONT/edit.html");
        }
    } else {
        unless ($r->uri eq "$CONT_URL/edit.html") {
            $self->set_redirect("$CONT_URL/edit.html");
        }
    }
}

sub bulk_edit : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $r = $self->apache_req;

    my $tile = get_state_data($self->class_key, 'tile');
    my $edit_tile = $self->_update_parts($param);

    # Push the current tile onto the stack.
    $self->_push_tile_stack($edit_tile);
    set_state_data($self->class_key, 'view_flip', 0);

    my $uri  = $tile->get_object_type eq 'media' ? $MEDIA_CONT : $CONT_URL;
    $self->set_redirect("$uri/edit_bulk.html");
}

sub view : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $r = $self->apache_req;
    my $field = $self->trigger_key;

    my $tile = get_state_data($self->class_key, 'tile');
    my $tile_id = $self->value;
    my ($view_tile) = grep(($_->get_id == $tile_id), $tile->get_containers);

    # Push this child tile on top of the stack
    $self->_push_tile_stack($view_tile);

    if ($tile->get_object_type eq 'media') {
        $self->set_redirect("$MEDIA_CONT/") unless $r->uri eq "$MEDIA_CONT/";
    } else {
        $self->set_redirect("$CONT_URL/") unless $r->uri eq "$CONT_URL/";
    }
}

sub reorder : Callback {
    # don't do anything, handled by the update_parts code now
}

sub delete : Callback {
    # don't do anything, handled by the update_parts code now
}

sub clear : Callback(priority => 1) {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    clear_state($self->class_key);
}

sub add_element : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $r = $self->apache_req;

    # get the tile
    my $tile = get_state_data($self->class_key, 'tile');
    my $key = $tile->get_object_type();
    # Get this tile's asset object if it's a top-level asset.
    my $a_obj;
    if (Bric::Biz::AssetType->lookup({id => $tile->get_element_type_id})->get_top_level()) {
        $a_obj = $pkgs{$key}->lookup({id => $tile->get_object_instance_id()});
    }
    my $fields = mk_aref($self->params->{$self->class_key . '|add_element'});

    foreach my $f (@$fields) {
        my ($type,$id) = unpack('A5 A*', $f);
        my $at;
        if ($type eq 'cont_') {
            $at = Bric::Biz::AssetType->lookup({id=>$id});
            my $cont = $tile->add_container($at);
            $tile->save();
            $self->_push_tile_stack($cont);

            if ($key eq 'story') {
                # Don't redirect if we're already at the edit page.
                $self->set_redirect("$CONT_URL/edit.html")
                  unless $r->uri eq "$CONT_URL/edit.html";
            } else {
                $self->set_redirect("$MEDIA_CONT/edit.html")
                  unless $r->uri eq "$MEDIA_CONT/edit.html";
            }

        } elsif ($type eq 'data_') {
            $at = Bric::Biz::AssetType::Parts::Data->lookup({id=>$id});
            $tile->add_data($at, $at->get_meta('html_info')->{value});
            $tile->save();
            set_state_data($self->class_key, 'tile', $tile);
        }
        log_event($key.'_add_element', $a_obj, {Element => $at->get_key_name})
          if $a_obj;
    }
}

sub update : Callback(priority => 1) {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    my $widget = $self->class_key;
    return if $param->{'_inconsistent_state_'} || $param->{"$widget|up_cb"};

    $self->_update_parts($self->params);

    # Don't save the element; that's handled by the callback for the button
    # that was actually clicked (e.g., "Save")--or not (e.g., "Cancel"), as
    # the case may be.
#    my $tile = get_state_data($self->class_key, 'tile');
#    $tile->save;
}

sub pick_related_media : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $tile = get_state_data($self->class_key, 'tile');
    my $object_type = $tile->get_object_type();
    my $uri = $object_type eq 'media' ? $MEDIA_CONT : $CONT_URL;
    $self->set_redirect("$uri/edit_related_media.html");
}

sub create_related_media : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $widget = $self->class_key;

    my $tile =  get_state_data($self->class_key, 'tile');
    my $type  = $tile->get_object_type;
    my $asset = get_state_data($type.'_prof', $type);

    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};
    return unless $param->{"media_prof|file"};

    # Get the workflow for media files.
    my $media_wf = find_workflow($asset->get_site_id, MEDIA_WORKFLOW, READ);
    unless (find_desk($media_wf, CREATE)) {
        add_msg("You do not have sufficient permission to create a media "
                . "document for this site");
        return;
    }

    set_state_data('media_prof', 'work_id', $media_wf->get_id);

    # Set up the parameters to create a new media document.
    my $m_param = {
        "title"                   => $param->{"media_prof|file"},
        "cover_date"              => $asset->get_cover_date(ISO_8601_FORMAT),
        "priority"                => $asset->get_priority,
        "media_prof|category__id" => $asset->get_primary_category->get_id,
        "media_prof|source__id"   => $asset->get_source__id,
        "media_prof|at_id"        => $param->{"media_prof|at_id"},
        "media_prof|file"         => $param->{"media_prof|file"},
    };

    my $media_cb = Bric::App::Callback::Profile::Media->new(
        cb_request => $self->cb_request,
        pkg_key    => 'media_prof',
        apache_req => $self->apache_req,
        params     => $m_param
    );

    # Cache the container prof state.
    my $state = get_state($widget);

    $media_cb->create;
    $media_cb->update;
    my $media = get_state_data('media_prof', 'media');
    $media_cb->save;

    # Now check the media document in to a desk.
    my $desk_cb = Bric::App::Callback::Desk->new(
        cb_request => $self->cb_request,
        pkg_key    => 'desk_asset',
        apache_req => $self->apache_req,
        value      => $media->get_id,
        params     => { "desk_asset|asset_class" => $media->key_name },
    );
    $desk_cb->checkin;

    # Stay where we are! This cancels any redirects set up by the Media
    # callback object.
    $self->set_redirect($self->apache_req->uri);
    $tile->set_related_media($media->get_id);
    # Restore the state.
    set_state($widget, @$state);
}

sub relate_media : Callback {
    my ($self) = @_;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $tile = get_state_data($self->class_key, 'tile');
    $tile->set_related_media($self->value);
    $self->_handle_related_up;
}

sub unrelate_media : Callback {
    my ($self) = @_;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $tile = get_state_data($self->class_key, 'tile');
    $tile->set_related_media(undef);
    $self->_handle_related_up;
}

sub pick_related_story : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $tile = get_state_data($self->class_key, 'tile');
    my $object_type = $tile->get_object_type();
    my $uri = $object_type eq 'media' ? $MEDIA_CONT : $CONT_URL;
    $self->set_redirect("$uri/edit_related_story.html");
}

sub relate_story : Callback {
    my ($self) = @_;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $tile = get_state_data($self->class_key, 'tile');
    $tile->set_related_story_id($self->value);
    $self->_handle_related_up;
}

sub unrelate_story : Callback {
    my ($self) = @_;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $tile = get_state_data($self->class_key, 'tile');
    $tile->set_related_story_id(undef);
    $self->_handle_related_up;
}

sub related_up : Callback {
    my ($self) = @_;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    $self->_handle_related_up;
}

sub lock_val : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $value = $self->value;
    my $autopop = ref $self->value ? $self->value : [$self->value];
    my $tile    = get_state_data($self->class_key, 'tile');

    # Map all the data tiles into a hash keyed by Tile::Data ID.
    my $data = { map { $_->get_id() => $_ } 
                 grep(not($_->is_container()), $tile->get_tiles()) };

    foreach my $id (@$autopop) {
        my $lock_set = $self->params->{$self->class_key.'|lock_val_'.$id} || 0;
        my $dt = $data->{$id};

        # Skip if there is no data tile here.
        next unless $dt;
        if ($lock_set) {
            $dt->lock_val();
        } else {
            $dt->unlock_val();
        }
    }
}

sub save_and_up : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    if ($self->params->{$self->class_key . '|delete_element'}) {
        $self->_delete_element;;
        return;
    }

    if (get_state_data($self->class_key, '__NO_SAVE__')) {
        # Do nothing.
        set_state_data($self->class_key, '__NO_SAVE__', undef);
    } else {
        # Save the tile we are working on.
        my $tile = get_state_data($self->class_key, 'tile');
        $tile->save();
        add_msg('Element "[_1]" saved.', $tile->get_name);
        $self->_pop_and_redirect;
    }
}

sub save_and_stay : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    if ($self->params->{$self->class_key . '|delete_element'}) {
        $self->_delete_element;;
        return;
    }

    if (get_state_data($self->class_key, '__NO_SAVE__')) {
        # Do nothing.
        set_state_data($self->class_key, '__NO_SAVE__', undef);
    } else {
        # Save the tile we are working on
        my $tile = get_state_data($self->class_key, 'tile');
        $tile->save();
        add_msg('Element "[_1]" saved.', $tile->get_name);
    }
}

sub up : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    $self->_pop_and_redirect;
}

# bulk edit callbacks

sub change_default_field : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $def  = $self->params->{$self->class_key.'|default_field'};
    my $tile = get_state_data($self->class_key, 'tile');
    my $at   = $tile->get_element_type();

    my $key = 'container_prof.' . $at->get_id . '.def_field';
    set_state_data('_tmp_prefs', $key, $def);
}

# XXX Remove?
sub change_preserve : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};
    my $widget = $self->class_key;

    set_state_data($widget, 'preserve', $param->{$widget . '|preserve'});
}

sub bulk_edit_this : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    # Note that we are just 'flipping' the current view of this tile.  That is,
    # it's the same tile, same data, but different view of it.
    set_state_data($self->class_key, 'view_flip', 1);
    set_state_name($self->class_key, 'edit_bulk');

    my $tile = get_state_data($self->class_key, 'tile');
    my $uri  = $tile->get_object_type eq 'media' ? $MEDIA_CONT : $CONT_URL;

    $self->set_redirect("$uri/edit_bulk.html");
}

sub bulk_save : Callback {
    my ($self) = @_;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};
    $self->_handle_bulk_save;
}

sub bulk_up : Callback {
    my ($self) = @_;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};
    $self->_handle_bulk_up;
}

sub bulk_save_and_up : Callback {
    my ($self) = @_;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{_inconsistent_state_};
    $self->_handle_bulk_save;
    $self->_handle_bulk_up;
}


####################
## Misc Functions ##

sub _push_tile_stack {
    my ($self, $new_tile) = @_;
    my $widget = $self->class_key;

    # Push the current tile onto the stack.
    my $tiles    = get_state_data($widget, 'tiles');
    my $cur_tile = get_state_data($widget, 'tile');
    push @$tiles, $cur_tile;

    my $crumb = '';
    foreach my $t (@$tiles[1..$#$tiles]) {
        $crumb .= ' &quot;' . $t->get_name . '&quot;' . ' |';
    }
    $crumb .= ' &quot;' . $new_tile->get_name . '&quot;';

    set_state_data($widget, 'crumb', $crumb);
    set_state_data($widget, 'tiles', $tiles);
    set_state_data($widget, 'tile', $new_tile);
}

sub _pop_tile_stack {
    my ($widget) = @_;

    my $tiles = get_state_data($widget, 'tiles');
    my $parent_tile = pop @$tiles;

    my $crumb = '';
    foreach my $t (@$tiles[1..$#$tiles]) {
        $crumb .= ' &quot;' . $t->get_name . '&quot;' . ' |';
    }
    $crumb .= ' &quot;' . $parent_tile->get_name . '&quot;';

    set_state_data($widget, 'crumb', $crumb);
    set_state_data($widget, 'tile', $parent_tile);
    set_state_data($widget, 'tiles', $tiles);
    return $parent_tile;
}

sub _pop_and_redirect {
    my ($self, $flip) = @_;
    my $widget = $self->class_key;
    my $r = $self->apache_req;

    # Get the tile stack and pop off the current tile.
    my $tile = $flip ? get_state_data($widget, 'tile')
                     : _pop_tile_stack($widget);

    my $object_type = $tile->get_object_type;

    # If our tile has parents, show the regular edit screen.
    if ($tile->get_parent_id) {
        my $uri = $object_type eq 'media' ? $MEDIA_CONT : $CONT_URL;
        my $page = get_state_name($widget) eq 'view' ? '' : 'edit.html';

        #  Don't redirect if we're already at the right URI
        $self->set_redirect("$uri/$page") unless $r->uri eq "$uri/$page";
    }
    # If our tile doesn't have parents go to the main story edit screen.
    else {
        my $uri = $object_type eq 'media' ? $MEDIA_URL : $STORY_URL;
        $self->set_redirect($uri);
    }
}

sub _delete_element {
    my $self = shift;
    my $r = $self->apache_req;
    my $widget = $self->class_key;

    my $tile = get_state_data($widget, 'tile');
    my $parent = _pop_tile_stack($widget);
    $parent->delete_tiles( [ $tile ]);
    $parent->save();
    my $object_type = $parent->get_object_type;

    # if our tile has parents, show the regular edit screen.
    if ($parent->get_parent_id) {
        my $uri = $object_type eq 'media' ? $MEDIA_CONT : $CONT_URL;
        my $page = get_state_name($widget) eq 'view' ? '' : 'edit.html';

        #  Don't redirect if we're already at the right URI
        $self->set_redirect("$uri/$page") unless $r->uri eq "$uri/$page";
    }
    # If our tile doesn't have parents go to the main story edit screen.
    else {
        my $uri = $object_type eq 'media' ? $MEDIA_URL : $STORY_URL;
        $self->set_redirect($uri);
    }

    add_msg('Element "[_1]" deleted.', $tile->get_name);
    return;
}


sub _update_parts {
    my ($self, $param) = @_;
    my (@curr_tiles, @delete, $locate_tile);

    my $widget = $self->class_key;
    my $locate_id = $self->value;
    my $tile = get_state_data($widget, 'tile');
    my $object_type = $tile->get_object_type;

    # Don't delete unless either the 'Save...' or 'Delete' buttons were pressed
    # in the element profile or the document profile.
    my $do_delete = $param->{$widget.'|delete_cb'} ||
                    $param->{$widget.'|save_and_up_cb'} ||
                    $param->{$widget.'|save_and_stay_cb'} ||
                    $param->{$object_type .'_prof|save_cb'} ||
                    $param->{$object_type .'_prof|save_and_stay_cb'};

    # Save data to tiles and put them in a usable order
    foreach my $t ($tile->get_tiles) {
        my $id = $t->get_id();

        # Grab the tile we're looking for
        local $^W = undef;
        $locate_tile = $t if $id == $locate_id and $t->is_container;
        if ($do_delete && ($param->{$widget . "|delete_cont$id"} ||
                           $param->{$widget . "|delete_data$id"})) {
            add_msg('Element "[_1]" deleted.', $t->get_name);
            push @delete, $t;
            next;
        }

        my ($order, $redir);
        if ($t->is_container) {
            $order = $param->{$widget . "|reorder_con$id"};
        } else {
            $order = $param->{$widget . "|reorder_dat$id"};
            if (! $t->is_autopopulated or exists
                $param->{$widget . "|lock_val_$id"}) {
                my $val = $param->{$widget . "|$id"};
                $val = '' unless defined $val;
                if ( $param->{$widget . "|${id}-partial"} ) {
                    # The date is only partial. Send them back to to it again.
                    add_msg('Invalid date value for "[_1]" field.', $t->get_name);
                    set_state_data($widget, '__NO_SAVE__', 1);
                } else {
                    # Truncate the value, if necessary, then set it.
                    my $info = $t->get_element_data_obj->get_meta('html_info');
                    $val = join('__OPT__', @$val) if $info->{multiple} && ref $val;
                    my $max = $info->{maxlength};
                    $val = substr($val, 0, $max) if $max && length $val > $max;
                    $t->set_data($val);
                }
            }
        }

        $curr_tiles[$order] = $t;
    }

    # Delete tiles as necessary.
    $tile->delete_tiles(\@delete) if $do_delete && @delete;

    if (@curr_tiles) {
        eval { $tile->reorder_tiles([ grep { defined } @curr_tiles ]) };
        if ($@) {
            add_msg("Warning! State inconsistent: Please use the buttons "
                    . "provided by the application rather than the 'Back'/"
                    . "'Forward' buttons.");
            return $locate_tile;
        }
    }

    set_state_data($widget, 'tile', $tile);
    return $locate_tile;
}

sub _handle_related_up {
    my ($self) = @_;
    my $r = $self->apache_req;

    my $tile = get_state_data($self->class_key, 'tile');
    my $object_type = $tile->get_object_type();

    # If our tile has parents, show the regular edit screen.
    if ($tile->get_parent_id()) {
        my $uri = $object_type eq 'media' ? $MEDIA_CONT : $CONT_URL;
        my $page = get_state_name($self->class_key) eq 'view' ? '' : 'edit.html';

        #  Don't redirect if we're already at the right URI
        $self->set_redirect("$uri/$page") unless $r->uri eq "$uri/$page";
    }
    # If our tile doesn't have parents go to the main story edit screen.
    else {
        my $uri = $object_type eq 'media' ? $MEDIA_URL : $STORY_URL;
        $self->set_redirect($uri);
    }
    pop_page();
}


################################################################################
## Bulk Edit Helper Functions

sub _handle_bulk_up {
    my $self = shift;
    my $widget = $self->class_key;

    # Set the state back to edit mode.
    set_state_name($widget => 'edit');

    # If the view has been flipped, just flip it back.
    if (get_state_data($widget => 'view_flip')) {
        # Set flip back to false.
        set_state_data($widget, view_flip => 0);
        $self->_pop_and_redirect(1);
    } else {
        $self->_pop_and_redirect(0);
    }
}

sub _handle_bulk_save {
    my $self   = shift;
    my $params = $self->params;
    my $widget = $self->class_key;
    my $tile   = get_state_data($widget => 'tile');

    my $def_field = $params->{"$widget|default_field"};
    eval {
        $tile->update_from_pod($params->{"$widget|text"}, $def_field);
        $tile->save;
    };
    if (my $err = $@) {
        # Let the UI know that it should use the content entered by the user.
        $params->{__use_text__} = 1;
        $err->rethrow;
    }
}

###

sub _drift_correction {
    my ($self) = @_;
    my $param = $self->params;

    # Don't do anything if we've already corrected ourselves.
    return if $param->{'_drift_corrected_'};

    # Update the state name
    set_state_name($self->class_key, $param->{$self->class_key.'|state_name'});

    # Get the tile ID this page thinks its displaying.
    my $tile_id = $param->{$self->class_key.'|top_stack_tile_id'};

    # Return if the page doesn't send us a tile_id
    return unless $tile_id;

    my $tile  = get_state_data($self->class_key, 'tile');
    # Return immediately if everything is already in sync.
    if ($tile->get_id == $tile_id) {
        $param->{'_drift_corrected_'} = 1;
        return;
    }

    my $stack = get_state_data($self->class_key, 'tiles');
    my @tmp_stack;

    while (@$stack > 0) {
        # Get the next tile on the stack.
        $tile = pop @$stack;
        # Finish this loop if we find our tile.
        last if $tile->get_id == $tile_id;
        # Push this tile on our temp stack just in case we can't find our ID.
        unshift @tmp_stack, $tile;
        # Undef the tile since its not the one we're looking for.
        $tile = undef;
    }

    # If we found the tile, make it the head tile and save the remaining stack.
    if ($tile) {
        set_state_data($self->class_key, 'tile', $tile);
        set_state_data($self->class_key, 'tiles', $stack);
    }
    # If we didn't find the tile, abort, and restore the tile stack
    else {
        add_msg("Warning! State inconsistent: Please use the buttons "
                . "provided by the application rather than the 'Back'/"
                . "'Forward' buttons");

        # Set this flag so that nothing gets changed on this request.
        $param->{'_inconsistent_state_'} = 1;

        set_state_data($self->class_key, 'tiles', \@tmp_stack);
    }

    # Drift has now been corrected.
    $param->{'_drift_corrected_'} = 1;
}


1;
