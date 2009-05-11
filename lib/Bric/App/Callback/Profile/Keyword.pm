package Bric::App::Callback::Profile::Keyword;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'keyword';

use strict;
use Bric::App::Event qw(log_event);

my $disp_name = 'Keyword';
my $class = 'Bric::Biz::Keyword';


sub save : Callback {
    my $self = shift;
    return unless $self->has_perms;

    my $keyword = $self->obj;
    my $widget = $self->class_key;
    my $param = $self->params;
    my $is_saving = defined $param->{"$widget\_id"};

    if ($param->{delete}) {
        # Delete this Profile
        $keyword->deactivate;
        $keyword->save;

        log_event("$widget\_deact", $keyword);
        $self->add_message(
            qq{$disp_name profile "[_1]" deleted.},
            $keyword->get_name,
        );
    } else {
        # Roll in the changes. Assume it's active.
        foreach my $meth ($keyword->my_meths(1)) {
            $meth->{set_meth}->($keyword, @{$meth->{set_args}},
                                $param->{$meth->{name}})
              if defined $meth->{set_meth};
        }
        $keyword->save;

        log_event($widget . ($is_saving ? '_save' : '_new'), $keyword);
        $self->add_message(
            qq{$disp_name profile "[_1]" saved.},
            $keyword->get_name,
        );
    }
    $self->set_redirect("/admin/manager/$widget");
    $param->{'obj'} = $keyword;
    return;
}


1;
