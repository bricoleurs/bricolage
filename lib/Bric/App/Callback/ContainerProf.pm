package Bric::App::Callback::ContainerProf;

use base qw(Bric::App::Callback);
__PACKAGE__->register_subclass(class_key => 'container_prof');
use strict;
use Bric::App::Session;

# XXX: this is bad because the cb_key contains data....
# I think I might have to change that, like with a hidden key
# for the tile ID. In that case, this will become a arg-triggered Callback
sub default : PostCallback {
    my $self = shift;

#    my ($param, $field) = @{ $self->request_args }['param', 'field'];
    # parse $param for field I guess

    my $tile = get_state_data(CLASS_KEY, 'tile');

    if ($field =~ /^container_prof\|edit(\d+)_cb/ ) {
        # Update the existing fields and get the child tile matching ID $1
        my $edit_tile = $update_parts->(CLASS_KEY, $param, $1);

        # Push this child tile on top of the stack
        $push_tile_stack->(CLASS_KEY, $edit_tile);

        # Don't redirect if we're already on the right page.
        if ($tile->get_object_type eq 'media') {
            unless ($r->uri eq "$MEDIA_CONT/edit.html") {
                set_redirect("$MEDIA_CONT/edit.html");
            }
        } else {
            unless ($r->uri eq "$CONT_URL/edit.html") {
                set_redirect("$CONT_URL/edit.html");
            }
        }

    } elsif ($field =~ /^container_prof\|view(\d+)_cb/ ) {
        my ($view_tile) = grep(($_->get_id == $1), $tile->get_containers);

        # Push this child tile on top of the stack
        $push_tile_stack->(CLASS_KEY, $view_tile);

        if ($tile->get_object_type eq 'media') {
            set_redirect("$MEDIA_CONT/") unless $r->uri eq "$MEDIA_CONT/";
        } else {
            set_redirect("$CONT_URL/") unless $r->uri eq "$CONT_URL/";
        }
    } elsif ($field =~ /^container_prof\|bulk_edit-(\d+)_cb/) {
        my $tile_id   = $1;
        # Update the existing fields and get the child tile matching ID $tile_id
        my $edit_tile = $update_parts->(CLASS_KEY, $param, $tile_id);

        # Push the current tile onto the stack.
        $push_tile_stack->(CLASS_KEY, $edit_tile);

        # Get the name of the field to bulk edit
        my $field = $param->{CLASS_KEY.'|bulk_edit_tile_field-'.$tile_id};

        # Save the bulk edit field name
        set_state_data(CLASS_KEY, 'field', $field);
        set_state_data(CLASS_KEY, 'view_flip', 0);

        my $state_name = $field eq '_super_bulk_edit' ? 'edit_super_bulk'
                                                      : 'edit_bulk';

        set_state_name(CLASS_KEY, $state_name);

        my $uri  = $tile->get_object_type eq 'media' ? $MEDIA_CONT : $CONT_URL;

        set_redirect("$uri/$state_name.html");
    }
}


sub clear : Callback {
    my $self = shift;


}

sub add_element : Callback {
    my $self = shift;


}

sub update : Callback {
    my $self = shift;


}

sub reorder : Callback {
    my $self = shift;


}

sub pick_related_media : Callback {
    my $self = shift;


}

sub relate_media : Callback {
    my $self = shift;


}

sub unrelate_media : Callback {
    my $self = shift;


}

sub pick_related_story : Callback {
    my $self = shift;


}

sub relate_story : Callback {
    my $self = shift;


}

sub unrelate_story : Callback {
    my $self = shift;


}

sub related_up : Callback {
    my $self = shift;


}

sub lock_val : Callback {
    my $self = shift;


}

sub delete : Callback {
    my $self = shift;


}

sub save_and_up : Callback {
    my $self = shift;


}

sub save_and_stay : Callback {
    my $self = shift;


}

sub up : Callback {
    my $self = shift;


}

# bulk edit callbacks

sub resize : Callback {
    my $self = shift;


}

sub change_default_field : Callback {
    my $self = shift;


}

sub change_sep : Callback {
    my $self = shift;


}

sub recount : Callback {
    my $self = shift;


}

sub bulk_edit_this : Callback {
    my $self = shift;


}

sub bulk_save : Callback {
    my $self = shift;


}

sub bulk_up : Callback {
    my $self = shift;


}

sub bulk_save_and_up : Callback {
    my $self = shift;


}


1;
