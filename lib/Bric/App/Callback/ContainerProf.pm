package Bric::App::Callback::ContainerProf;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'container_prof';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:msg :aref :history);
use Bric::App::Event qw(log_event);
use Bric::Biz::AssetType;
use Bric::Biz::AssetType::Parts::Data;
use Bric::Biz::Asset::Business::Parts::Tile::Container;
use Bric::Biz::Asset::Business::Parts::Tile::Data;
use Bric::Util::Fault qw(:all);
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
#    my $field = $self->trigger_key;

    my $tile = get_state_data($self->class_key, 'tile');
    my $tile_id = $self->value;
    # Update the existing fields and get the child tile matching ID $tile_id
    my $edit_tile = $self->_update_parts($param);

    # Push the current tile onto the stack.
    $self->_push_tile_stack($edit_tile);

    # Get the name of the field to bulk edit
    my $field = $param->{$self->class_key.'|bulk_edit_tile_field-'.$tile_id};

    # Save the bulk edit field name
    set_state_data($self->class_key, 'field', $field);
    set_state_data($self->class_key, 'view_flip', 0);

    my $state_name = $field eq '_super_bulk_edit' ? 'edit_super_bulk'
                                                  : 'edit_bulk';
    set_state_name($self->class_key, $state_name);

    my $uri  = $tile->get_object_type eq 'media' ? $MEDIA_CONT : $CONT_URL;
    $self->set_redirect("$uri/$state_name.html");
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
    if (Bric::Biz::AssetType->lookup({id => $tile->get_element_id()})->get_top_level()) {
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
    $tile->set_related_instance_id($self->value);
    $self->_handle_related_up;
}

sub unrelate_story : Callback {
    my ($self) = @_;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $tile = get_state_data($self->class_key, 'tile');
    $tile->set_related_instance_id(undef);
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

sub resize : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};
    my $widget = $self->class_key;

    if ( get_state_name($widget) eq 'edit_bulk' ) {
	$self->_split_fields($param->{$widget . '|text'});
    } else {
	$self->_split_super_bulk($param->{$widget . '|text'});
    }

    set_state_data($widget, 'rows', $param->{$widget . '|rows'});
    set_state_data($widget, 'cols', $param->{$widget . '|cols'});
}

sub change_default_field : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $def  = $self->params->{$self->class_key.'|default_field'};
    my $tile = get_state_data($self->class_key, 'tile');
    my $at   = $tile->get_element();

    my $key = 'container_prof.' . $at->get_id . '.def_field';
    set_state_data('_tmp_prefs', $key, $def);
}

sub change_sep : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my ($data, $sep);

    # Save off the custom separator in case it changes.
    set_state_data($self->class_key, 'custom_sep', $param->{$self->class_key.'|custom_sep'});

    # First split the fields along the old boundary character.
    $self->_split_fields($param->{$self->class_key.'|text'});

    # Now load the new separator
    $sep = $param->{$self->class_key.'|separator'};

    if ($sep ne 'custom') {
        set_state_data($self->class_key, 'separator', $sep);
        set_state_data($self->class_key, 'use_custom_sep', 0);
    } else {
        set_state_data($self->class_key, 'separator', $param->{$self->class_key.'|custom_sep'});
        set_state_data($self->class_key, 'use_custom_sep', 1);
    }

    # Get the data and pass it back to be resplit against the new separator
    $data = get_state_data($self->class_key, 'data');
    $sep  = get_state_data($self->class_key, 'separator');
    $self->_split_fields(join("\n$sep\n", @$data));
    add_msg("Separator Changed.");
}

sub recount : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    $self->_split_fields($self->params->{$self->class_key.'|text'});
}

sub bulk_edit_this : Callback {
    my $self = shift;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    my $be_field = $self->params->{$self->class_key . '|bulk_edit_field'};

    # Save the bulk edit field name
    set_state_data($self->class_key, 'field', $be_field);
    # Note that we are just 'flipping' the current view of this tile.  That is,
    # it's the same tile, same data, but different view of it.
    set_state_data($self->class_key, 'view_flip', 1);

    my $state_name = $be_field eq '_super_bulk_edit' ? 'edit_super_bulk'
                                                     : 'edit_bulk';
    set_state_name($self->class_key, $state_name);

    my $tile = get_state_data($self->class_key, 'tile');
    my $uri  = $tile->get_object_type eq 'media' ? $MEDIA_CONT : $CONT_URL;

    $self->set_redirect("$uri/$state_name.html");
}

sub bulk_save : Callback {
    my ($self) = @_;
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    $self->_handle_bulk_save;
}

sub bulk_up : Callback {
    my ($self) = @_;     # @_ for &$handle_bulk_up
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{'_inconsistent_state_'};

    $self->_handle_bulk_up;
}

sub bulk_save_and_up : Callback {
    my ($self) = @_;     # @_ for &$handle_bulk_*
    $self->_drift_correction;
    my $param = $self->params;
    return if $param->{_inconsistent_state_};
    $self->_handle_bulk_save;
    return if $param->{_super_bulk_error_};
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
        my $id      = $t->get_id;
        my $is_cont = $t->is_container;

        # Grab the tile we're looking for
        {
            local $^W = undef;
            $locate_tile = $t if $id == $locate_id and $is_cont;
        }
        if ($do_delete
            && (($is_cont && $param->{$widget . "|delete_cont$id"})
                || (!$is_cont && $param->{$widget . "|delete_data$id"}))
        ) {
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
                    eval { $t->set_data($val) };
                    if (my $err = $@) {
                        if (isa_bric_exception($err, 'Error')) {
                            $err->rethrow;
                        }
                        elsif (ref $err) {
                            throw_invalid $err->error;
                        }
                        else {
                            throw_invalid $err
                        }
                    }
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

#------------------------------------------------------------------------------#
# save_data
#
# Split out the text entered into the bulk edit text box into chuncks and save
# each chunk into its own element, reusing existing elements if possible and
# creating new ones otherwise.

sub _save_data {
    my ($self) = @_;
    my $widget = $self->class_key;

    # The tile currently being edited by container_prof
    my $tile   = get_state_data($widget, 'tile');
    # The field within the tile being edited via bulk edit
    my $field  = get_state_data($widget, 'field');
    # Data tiles already created while editing the field in bulk_edit
    my $dtiles = get_state_data($widget, 'dtiles') || [];
    # The most recent data entered into bulk edit
    my $data   = get_state_data($widget, 'data');

    # Get the asset type data object.
    my $at_id = $tile->get_element_id;
    my $at    = Bric::Biz::AssetType->lookup({'id' => $at_id});
    my $atd   = $at->get_data($field);

    foreach my $d (@$data) {
        my $dt;

        if (@$dtiles) {
            # Fill the existing tiles first.
            $dt = shift @$dtiles;
        } else {
            # Otherwise create new tiles.
            $dt = Bric::Biz::Asset::Business::Parts::Tile::Data->new
              ({ 'element_data' => $atd,
                 'object_type'  => 'story' });
            $tile->add_tile($dt);
        }

        # Set the data on this tile.
        $dt->set_data($d);
    }

    # Delete any remaining tiles that haven't been filled.
    $tile->delete_tiles($dtiles) if scalar(@$dtiles);

    # Save the tile
    $tile->save;

    # Grab only the tiles that have the name $field
    my @dtiles = grep($_->get_key_name eq $field, $tile->get_tiles());

    set_state_data($widget, 'dtiles', \@dtiles);
}

sub _handle_bulk_up {
    my ($self) = @_;

    # Set the state back to edit mode.
    set_state_name($self->class_key, 'edit');

    # Clear some values.
    set_state_data($self->class_key, 'dtiles',   undef);
    set_state_data($self->class_key, 'data',     undef);
    set_state_data($self->class_key, 'field',    undef);

    # If the view has been flipped, just flip it back.
    if (get_state_data($self->class_key, 'view_flip')) {
        # Set flip back to false.
        set_state_data($self->class_key, 'view_flip', 0);
        $self->_pop_and_redirect(1);
    } else {
        $self->_pop_and_redirect(0);
    }
}

sub _handle_bulk_save {
    my ($self) = @_;
    my $param = $self->params;

    my $state_name = get_state_name($self->class_key);

    if ($state_name eq 'edit_bulk') {
        $self->_split_fields($param->{$self->class_key.'|text'});
        $self->_save_data;
        my $data_field = get_state_data($self->class_key, 'field');
        add_msg('"[_1]" Elements saved.', $data_field);
    } else {
        $self->_split_super_bulk($param->{$self->class_key.'|text'});
        unless (num_msg() > 0) {
            $self->_super_save_data;
        }
    }
}

#------------------------------------------------------------------------------#
# super_save_data
#
# Like save_data above, but recognize the POD style commands that allow the user
# to specify what element goes with each chunk of text

sub _super_save_data {
    my ($self) = @_;
    my $widget = $self->class_key;

    # The tile currently being edited by container_prof
    my $tile   = get_state_data($widget, 'tile');
    my $at     = $tile->get_element;
    # The field within the tile being edited via bulk edit
    my $field  = get_state_data($widget, 'field');
    # Data tiles already created while editing the field in bulk_edit
    my $dtiles = get_state_data($widget, 'dtiles') || [];
    # The most recent data entered into bulk edit
    my $data   = get_state_data($widget, 'data');

    # Arrange these tiles by type
    my $tpool;
    while (my $t = shift @$dtiles) {
        push @{$tpool->{$t->get_key_name}}, $t;
    }

    # Fill the data into the objects in our tpool
    foreach my $d (@$data) {
        my ($name, $text) = @$d;

        my $t;
        # If we have an existing object with this name, then use it.
        if ($tpool->{$name} and scalar(@{$tpool->{$name}})) {
            $t = shift @{$tpool->{$name}};
        } else {
            # If there is no object then create one
            my ($atc, $atd);
            if ($atd = $at->get_data($name)) {
                $t = Bric::Biz::Asset::Business::Parts::Tile::Data->new
                  ({ 'element_data' => $atd,
                     'object_type'  => 'story' });
            } else {
                $atc = $at->get_containers($name);
                # Make sure they have permission to add elements of this type.
                unless (chk_authz($atc, READ, 1)) {
                    add_msg('You do not have permission to add "[_1]" objects',
                            $atc->get_name);
                    next;
                }
                $t = Bric::Biz::Asset::Business::Parts::Tile::Container->new
                  ({ element     => $atc,
                     object_type => 'story' });
            }

            # Add this new tile.
            $tile->add_tile($t);
        }

        # Don't update the contents of containers, just data the elements
        $t->set_data($text) unless $t->is_container;
        push @$dtiles, $t;
    }

    # Delete any remaining tiles that haven't been filled.
    while (my ($n,$p) = each %$tpool) {
        next unless $p and scalar(@$p);

        if ($p->[0]->is_container) {
            add_msg('Note: Container element "[_1]" removed in bulk edit but will not be deleted.', $n);
            # Put these container tiles back in the list
            push @$dtiles, @$p;
            next;
        } else {
            my $atd = $at->get_data($n);

            if ($atd->get_required()) {
                unless (grep { $_->get_key_name eq $n } @$dtiles) {
                    add_msg('Note: Data element "[_1]" is required and cannot be completely removed.  Will delete all but one.', $n);
                    push @$dtiles, shift @$p;
                }
            }
        }
        $tile->delete_tiles($p) if scalar(@$p);
    }

    $tile->reorder_tiles($dtiles) if $dtiles;

    # Save the tile
    $tile->save;

    set_state_data($widget, 'dtiles', $dtiles);
}

#------------------------------------------------------------------------------#
# split_fields
#
# Splits a bulk edit text area into chunks based on the separator the user has
# choosen.  The default separator is "\n\n".

sub _split_fields {
    my ($self, $text) = @_;
    my $widget = $self->class_key;
    my $sep = get_state_data($widget, 'separator');
    my @data;

    # Change Windows newlines to Unix newlines.
    $text =~ s/\r\n/\n/g;

    # Grab the split regex.
    my $re = $regex->{$sep} ||= qr/\s*\Q$sep\E\s*/;

    # Split 'em up.
    @data = map { s/^\s+//;         # Strip out beginning spaces.
                  s/\s+$//;         # Strip out ending spaces.
                  s/[\n\t\r\f]/ /g; # Strip out unwanted characters.
                  s/\s{2,}/ /g;     # Strip out double-spaces.
                  $_;
              } split(/$re/, $text);

    # Save 'em.
    set_state_data($widget, 'data', \@data);
}

#------------------------------------------------------------------------------#
# compare_soundex
#
# Compare two words using the Soundex algorithm and then subtracting the result
# to find the nearest matching word.

sub _compare_soundex {
    my ($a, $b) = @_;

    ($a, $b) = Text::Soundex::soundex($a, $b);

    return (abs(ord(substr($a, 0, 1)) - ord(substr($b, 0, 1))) +
            abs((substr($a, 1, 1)) - (substr($b, 1, 1))) +
            abs((substr($a, 2, 1)) - (substr($b, 2, 1))) +
            abs((substr($a, 3, 1)) - (substr($b, 3, 1))))
}

#------------------------------------------------------------------------------#
# compare_levenshtein
#
# Compare two words using the levenshtein algorithm which returns a single
# comparable number.

sub _compare_levenshtein {
    my ($a, $b) = @_;
    return Text::Levenshtein::distance($a, $b);
}

#------------------------------------------------------------------------------#
# compare
#
# Alias to the comparison method to use.  First check for Text::levenshtein and
# then the less effective Text::Soundex

my $compare = $Text::Levenshtein::VERSION ? \&_compare_levenshtein : \&_compare_soundex;

#------------------------------------------------------------------------------#
# closest
#
# Given a list of words and a target word, return the word from the list that
# most closely matches the target word.

sub _closest {
    my ($words, $w) = @_;
    my ($lowest, $score);

    foreach my $test_word (@$words) {
        my $cur_score = $compare->($test_word, $w);

        if ((not defined $score) or ($cur_score < $score)) {
            $score  = $cur_score;
            $lowest = $test_word;
        }
    }

    return $lowest;
}

#------------------------------------------------------------------------------#
# split_super_bulk
#
# Splits out chunks of text from the bulk edit textarea box as well as the
# element name associated with it

sub _split_super_bulk {
    my ($self, $text) = @_;
    my $widget = $self->class_key;

    # Get the tile so we can figure out what the repeatable elements are
    my $tile      = get_state_data($widget, 'tile');
    my $at        = $tile->get_element;
    my %poss_names;

    # Get the default data type
    my $def_field = get_state_data('_tmp_prefs',
                                   'container_prof.' . $at->get_id . '.def_field');

    # Create hash of possible names from the data elements
    foreach my $p ($at->get_data) {
        $poss_names{$p->get_key_name} = 'd';
    }

    # Add to the hash of possible names with container elements
    foreach my $p ($at->get_containers) {
        $poss_names{$p->get_key_name} = 'c';
    }

    # A checked text accumulator, and the element type for that text
    my ($acc, $type);

    # Check each line of the text
    my @chunks;
    my %seen;
    my $blanks = 0;

    foreach my $l (split(/\r?\n|\r/, $text)) {
        chomp($l);

        # See if we have a blank line
        if ($l =~ /^\s*$/) {
            $blanks++;

            # If we have any accumulated text or if we have more than two
            # blank lines in a row, then save it off
            if ($acc or $blanks > 1) {
                $type ||= $def_field or next;
                push @chunks, [$type, $acc];
                $acc  = '';
                $type = '';
                $blanks = 0;
            }
        }
        # This line starts with a '=' marking a new element
        elsif ($l =~ /^=(\S+)\s*$/) {
            # If someone neglects to add a double space after a data element
            # with no content, make sure not to delete that element.  We can
            # only do this when the two fields involved are not the default
            # field and are explicitly listed using the '=tag' syntax.
            if ($type) {
                push @chunks, [$type, $acc];
            }

            $type = $1;

            # See if this field is repeatable.
            my $repeatable;
            if (my $atd = $at->get_data($type)) {
                $repeatable = $atd->get_quantifier || 0;
            } elsif (my $atc = $at->get_containers($type)) {
                # Containers are currently always repeatable
                $repeatable = 1;    #$at->is_repeatable($atc) || 0;
            }

            # If this field is not repeatable and we already have one of these
            # fields, then complain to the user
            if (not $repeatable and $seen{$type}) {
                $self->params->{_super_bulk_error_} = 1;
                add_msg('Field "[_1]" appears more than once but it is not a '
                        . 'repeatable element.  Please remove all but one.',
                        $type);
                next;
            }

            # Note that we've seen this element type
            $seen{$type} = 1;

            if (not exists $poss_names{$type}) {
                $self->params->{_super_bulk_error_} = 1;
                my $new_type = _closest([keys %poss_names], $type);
                add_msg('Bad element name "[_1]". Did you mean "[_2]"?',
                        $type, $new_type);
            }

            # If this is a container field, then reset everything
            if ($poss_names{$type} eq 'c') {
                push @chunks, [$type, $acc];
                $acc  = '';
                $type = '';
            }

            $blanks = 0;
        }
        # Nothing special about this line, push it into the accumulator
        else {
            $type ||= $def_field || $chunks[-1]->[0];
            $acc .= $acc ? " $l" : $l;
            $blanks = 0;
        }
    }

    # Add any leftover data
    if ($acc or $type) {
        $type = $def_field if not $type;

        push @chunks, [$type, $acc];
    }

    set_state_data($widget, 'data', \@chunks);
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
