package Bric::App::Callback::Profile::Source;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'source';

use strict;
use Bric::App::Event qw(log_event);
use Bric::Biz::Org;
use Bric::Biz::Org::Source;

my $type = CLASS_KEY;
my $disp_name = 'Source';
my $class = 'Bric::Biz::Org::Source';


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->params;
    my $source = $self->obj;

    my $used;
    my $name = $param->{source_name};
    if ($param->{delete}) {
        # Deactivate it.
        $source->deactivate;
        log_event("${type}_deact", $source);
        $self->add_message(qq{$disp_name profile "[_1]" deleted.}, $name);
        $source->save;
    } else {
        my $source_id = $param->{"${type}_id"};
        # Make sure the name isn't already in use.
        my @sources = $class->list_ids({ source_name => $param->{source_name},
                                         all         => 1});
        if (@sources > 1) {
            $used = 1;
        } elsif (@sources == 1 && !defined $source_id) {
            $used = 1;
        } elsif (@sources == 1 && defined $source_id
       && $sources[0] != $source_id) {
            $used = 1;
        }
        $self->raise_conflict(
            qq{The name "[_1]" is already used by another $disp_name.},
            $name,
        ) if $used;

        # Roll in the changes.
        if ($param->{org}) {
            $source->set_org(Bric::Biz::Org->lookup({ id => $param->{org} }) );
        } elsif ($param->{name}) {
            $source->set_name($param->{name});
            $source->set_long_name($param->{long_name});
            log_event("org_new", $source);
        } else {
            # Nothing, bucko - it's an existing source!
        }
        $source->set_description($param->{description});
        $source->set_expire($param->{expire});
        if ($used) {
            $param->{'obj'} = $source;
            return;
        } else {
            $source->set_source_name($param->{source_name});
            $source->save;
            log_event($type . (defined $param->{source_id} ? '_save' : '_new'), $source);
            $self->add_message(qq{$disp_name profile "[_1]" saved.}, $name);
        }
    }
    # Save changes and redirect back to the manager.
    $self->set_redirect('/admin/manager/source');
}


1;
