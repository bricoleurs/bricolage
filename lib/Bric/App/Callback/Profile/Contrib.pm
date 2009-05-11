package Bric::App::Callback::Profile::Contrib;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'contrib';

use strict;
use Bric::App::Callback::Util::Contact qw(update_contacts);
use Bric::App::Event qw(log_event);
use Bric::App::Session qw(:state);
use Bric::App::Util qw(:aref);
use Bric::Util::Attribute::Grp;
use Bric::Util::Grp::Parts::Member::Contrib;
use Bric::Util::Grp::Person;

my $type = CLASS_KEY;
my $disp_name = 'Contributor';

sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->params;
    my $contrib = $self->obj;

    if ($param->{delete}) {
        # Deactivate it.
        $contrib->deactivate;
        $contrib->save;
        log_event("${type}_deact", $contrib);
        $self->add_message("$disp_name profile \"[_1]\" deleted.", $contrib->get_name);
        $self->set_redirect('/admin/manager/contrib');
        return;
    } else {                    # Roll in the changes.
        # update name elements
        my $meths = $contrib->my_meths;
        $meths->{fname}{set_meth}->($contrib, $param->{fname});
        $meths->{lname}{set_meth}->($contrib, $param->{lname});
        $meths->{mname}{set_meth}->($contrib, $param->{mname});
        $meths->{prefix}{set_meth}->($contrib, $param->{prefix});
        $meths->{suffix}{set_meth}->($contrib, $param->{suffix});
        my $name = $contrib->get_name;

        if ($param->{mode} eq 'new') {
            # add person object to the selected group
            my $group = Bric::Util::Grp::Person->lookup({ id => $param->{group} });
            $contrib->save;
            my $member = $group->add_member({ obj => $contrib });
            $group->save;
            @{$param}{qw(mode contrib_id)} = ('edit', $member->get_id);
            # We need a contrib object, not just a member oject. So look it up.
            $member = Bric::Util::Grp::Parts::Member::Contrib->lookup({
                id => $param->{contrib_id}
            });

            # Log that we've created a new contributor.
            log_event("${type}_new", $member);
            $self->set_redirect('/admin/profile/contrib/edit/' . $param->{contrib_id});
            $param->{'obj'} = $member;
            return;
        } elsif ($param->{mode} eq "edit") {
            # We must be dealing with an existing contributor object

            # get handle to underlying person object
            my $obj = $contrib->get_obj;

            # update contacts on this person object
            update_contacts($param, $obj);
            $obj->save;

            # Update attributes.
            # We'll need these to get the SQL type and max length of attributes.
            my $all = $contrib->all_for_subsys;
            my $mem_attr = Bric::Util::Attribute::Grp->new({
                id => $contrib->get_grp_id,
                susbsys => '_MEMBER_SUBSYS'
            });

            foreach my $aname (@{ mk_aref($param->{attr_name}) } ) {
                my ($subsys, $name) = split /\|/, $aname;

                # Grab the SQL type.
                my $sqltype = $mem_attr->get_sqltype({ name => $name,
                                                       subsys => '_MEMBER_SUBSYS' });
                # Truncate the value, if necessary.
                my $max = $all->{$aname}{meta}{maxlength}{value};
                my $value = $param->{"attr|$aname"};

                $value = join('__OPT__', @$value)
                  if $all->{$aname}{meta}{multiple}{value} && ref $value;
                $value = substr($value, 0, $max) if $max && length $value > $max;

                # Set the attribute.
                $contrib->set_attr({ subsys   => $subsys,
                                     name     => $name,
                                     value    => $value,
                                     sql_type => $sqltype });
            }

            # Save the contributor
            $contrib->save;
            $param->{contrib_id} = $contrib->get_id;

            if ($self->cb_key eq 'save') {
                # Record a message and redirect if we're saving
                $self->add_message("$disp_name profile \"[_1]\" saved.", $name);
                log_event("${type}_save", $contrib);
                clear_state("contrib_profile");
                $self->set_redirect('/admin/manager/contrib');
            }
        } elsif ($param->{mode} eq "extend") {
            # We're creating a new contributor based on an existing one.
            # Change the mode for the next screen.
            $param->{mode} = 'edit';
            set_state_data("contrib_profile", { extending => 1 } );
            log_event("${type}_ext", $contrib);
            $param->{'obj'} = $contrib;
            return;
        } elsif ($param->{mode} eq 'preEdit') {
            $param->{mode} = 'edit';
            set_state_data("contrib_profile", { extending => 0 } );
            $param->{'obj'} = $contrib;
            return;
        }
    }
}


1;
