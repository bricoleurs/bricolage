package Bric::App::Callback::Profile::Org;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'org';

use strict;
use Bric::App::Event qw(log_event);

my $disp_name = 'Org';
my $class = 'Bric::Biz::Org';


sub save : Callback {
    my $self = shift;
    return unless $self->has_perms;

    my $org = $self->obj;
    my $name = $org->get_name;

    my $widget = $self->class_key;
    my $param = $self->params;
    my $is_saving = defined $param->{"$widget\_id"};

    if ($param->{delete}) {
        # Delete this Profile
        $org->deactivate;
        $org->save;

        log_event("$widget\_deact", $org);
        $self->add_message(qq{$disp_name profile "[_1]" deleted.}, $name);
    } else {
        # Roll in the changes. Assume it's active.
        foreach my $meth ($org->my_meths(1)) {
            $meth->{set_meth}->($org, @{$meth->{set_args}},
                                $param->{$meth->{name}})
              if defined $meth->{set_meth};
        }
        $org->save;

        log_event($widget . ($is_saving ? 'save' : 'new'), $org);
        $self->add_message(qq{$disp_name profile "[_1]" saved.}, $name);
    }
    $self->set_redirect("/admin/manager/$widget");
    $param->{'obj'} = $org;
    return;
}


1;
