package Bric::App::Callback::Profile::InputChannel;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'input_channel';

use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref :msg);
use Bric::Biz::InputChannel;

my $type = CLASS_KEY;
my $disp_name = 'Input Channel';
my $class = 'Bric::Biz::InputChannel';

my ($do_callback);


sub save : Callback {
    return unless $_[0]->has_perms;
    &$do_callback;
}

sub include_ic_id : Callback {
    return unless $_[0]->has_perms && $_[0]->value ne '';
    &$do_callback;
}


###

$do_callback = sub {
    my $self = shift;
    my $param = $self->params;
    my $ic = $self->obj;

    my $name = $param->{name};
    my $used;

    if ($param->{delete}) {
        # Deactivate it.
        $ic->deactivate;
        log_event('input_channel_deact', $ic);
        add_msg("$disp_name profile \"[_1]\" deleted.", $name);
        $ic->save;
        $self->set_redirect('/admin/manager/input_channel');
    } else {
        my $ic_id = $param->{"${type}_id"};
        $ic->set_site_id($param->{site_id})
          if $param->{site_id};
        # Make sure the name isn't already in use.
        my @ics = $class->list_ids({ name    => $param->{name},
                                     site_id => $ic->get_site_id });
        if (@ics > 1) {
            $used = 1;
        } elsif (@ics == 1 && !defined $ic_id) {
            $used = 1;
        } elsif (@ics == 1 && defined $ic_id && $ics[0] != $ic_id) {
            $used = 1;
        }

        add_msg("The name \"[_1]\" is already used by another $disp_name.", $name) if $used;

        # Set the basic properties.
        $ic->set_description( $param->{description} );
        $ic->activate;

        if ($used) {
            $param->{'obj'} = $ic;
            return;
        }
        $ic->set_name($param->{name});

        $ic->save;

        if ($ic_id) {
            log_event('input_channel_save', $ic);
            add_msg("$disp_name profile \"[_1]\" saved.", $name);
            $self->set_redirect('/admin/manager/input_channel');
        } else {
            log_event('input_channel_new', $ic);
            $param->{'obj'} = $ic;
            return;
        }
    }
};


1;
