package Bric::App::Callback::Profile::ElementType;

use base qw(Bric::App::Callback::Package);
__PACKAGE__->register_subclass(class_key => 'element_type');
use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);
use Bric::Biz::ATType;

my $type = CLASS_KEY;
my $class = get_package_name($type);
my $disp_name = get_disp_name($type);
my $story_pkg_id = get_class_info('story')->get_id;
my $media_pkg_id = get_class_info('media')->get_id;


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $ct = $self->obj;

    my $name = "&quot;$param->{name}&quot;";
    my $used;
    if ($param->{delete}) {
        # Deactivate it.
        $ct->deactivate;
        log_event("${type}_deact", $ct);
        add_msg($self->lang->maketext("$disp_name profile [_1] deleted.",$name));
    } else {
        # Make sure the name isn't already in use.
        my @cts = $class->list_ids({ name => $param->{name}, active => 'all' });
        if (@cts > 1) {
            $used = 1;
        } elsif (@cts == 1 && !defined $param->{element_type_id}) {
            $used = 1;
        } elsif (@cts == 1 && defined $param->{element_type_id}
                   && $cts[0] != $param->{element_type_id}) {
            $used = 1;
        }
        add_msg($self->lang->maketext("The name [_1] is already used by another $disp_name.",$name)) if $used;

        # Roll in the changes.
        $ct->set_name($param->{name}) unless $used;
        $ct->set_description($param->{description});
        if (! defined $param->{element_type_id}) {
            # It's a new element. Just set the type, save, and return.
            $ct->set_top_level($param->{elem_type} eq 'Element' ? 0 : 1);
            if ($param->{elem_type} eq 'Media') {
                $ct->set_media(1);
                $ct->set_biz_class_id($media_pkg_id);
            } else {
                $ct->set_media(0);
                $ct->set_biz_class_id($story_pkg_id);
            }
            unless ($used) {
                $ct->save;
                log_event($type . '_new', $ct);
            }
            return $ct;
        } else {
            # If we get here, it's an existing type.
            $ct->set_paginated(defined $param->{paginated} ? 1 : 0);
            $ct->set_fixed_url(defined $param->{fixed_url} ? 1 : 0);
            $ct->set_related_story(defined $param->{related_story} ? 1 : 0);
            $ct->set_related_media(defined $param->{related_media} ? 1 : 0);
            $ct->set_biz_class_id($param->{biz_class_id})
              if defined $param->{biz_class_id};
            add_msg($self->lang->maketext("$disp_name profile [_1] saved.",$name)) unless $used;
            log_event($type . '_save', $ct);
        }
    }
    # Save changes and redirect back to the manager.
    return $ct if $used;
    $ct->save;
    $param->{"${type}_id"} = $ct->get_id unless defined $param->{"${type}_id"};
    set_redirect('/admin/manager/element_type');
}


1;
