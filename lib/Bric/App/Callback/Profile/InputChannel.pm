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
        my @ics = $class->list_ids({ key_name    => $param->{key_name},
                                     site_id => $ic->get_site_id });
        if (@ics > 1) {
            $used = 1;
        } elsif (@ics == 1 && !defined $ic_id) {
            $used = 1;
        } elsif (@ics == 1 && defined $ic_id && $ics[0] != $ic_id) {
            $used = 1;
        }

        add_msg("The key name \"[_1]\" is already used by another $disp_name.", $name) if $used;

        # Set the basic properties.
        $ic->set_description( $param->{description} );
        $ic->activate;

        if ($used) {
            $param->{'obj'} = $ic;
            return;
        }
        $ic->set_key_name($param->{key_name});
        
        $ic->set_name($param->{name});

        if ($ic_id) {
            if ($param->{include_id}) {
                # Take care of deleting included ICs, if necessary.
                my $del = mk_aref($param->{include_ic_id_del});
                my %del_ids = map { $_ => 1 } @$del;
                $ic->del_includes(@$del) if @$del;

                # Process all existing included ICs and save the changes.
                my @inc_ord;
                my $pos = mk_aref($param->{include_pos});
                my $i = 0;
                # Put the included IC IDs in the desired order.
                foreach my $inc_id (@{ mk_aref($param->{include_id}) }) {
                    $inc_ord[$pos->[$i++]] = $inc_id;
                }

                # Cull out all the deleted ICs.
                @inc_ord = map { $del_ids{$_} ? () : $_ } @inc_ord
                  if $param->{include_ic_id_del};

                # Now, compare their positions with what's currently in the IC.
                $i = 0;
                my @cur_inc = $ic->get_includes;
                foreach (@cur_inc) {
                    next if $_->get_id == $inc_ord[$i++];

                    # If we're here, we have to reorder.
                    $ic->set_includes($ic->get_includes(@inc_ord));
                    last;
                }
            }

            # Now append any new includes.
            if ($self->cb_key eq 'include_ic_id' && $self->value ne '') {
                # Add includes.
                $ic->add_includes($class->lookup({ id => $self->value }));
                $ic->save;
                $param->{'obj'} = $ic;
                return;
            }

            $ic->save;
            log_event('input_channel_save', $ic);
            add_msg("$disp_name profile \"[_1]\" saved.", $name);
            $self->set_redirect('/admin/manager/input_channel');
        } else {
            $ic->save;
            log_event('input_channel_new', $ic);
            $param->{'obj'} = $ic;
            return;
        }
    }
};


1;
