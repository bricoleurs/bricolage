package Bric::App::Callback::Profile::MediaType;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'media_type';

use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref);
use Bric::Util::MediaType;

my $type = 'media_type';
my $disp_name = 'Media Type';
my $class = 'Bric::Util::MediaType';

sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->params;
    my $mt = $self->obj;

    my $name = lc $param->{name};

    # If 'delete' box is checked, deactivate the Media Type;
    # otherwise, save the profile.
    if ($param->{delete}) {
        my @old_exts = $mt->get_exts();
        $mt->del_exts(@old_exts);
        $mt->deactivate;
        $mt->save;
        log_event("${type}_deact", $mt);
        $self->add_message(qq{$disp_name profile "[_1]" deleted.}, $name);
        $self->set_redirect("/admin/manager/$type");
        return;
    } else {
        my $mt_id = $param->{"${type}_id"};

        # Make sure the name isn't already taken.
        my $used = 0;
        if (!defined $name || $name !~ /\S/) {
            $self->raise_conflict('Name is required.');
            $used = 1;
        } elsif ($name !~ m|^\S+/\S+$|) {
            $self->raise_conflict(
                qq{Name "[_1]" is not a valid media name. The name must be of the form "type/subtype".},
                $name,
            );
            $used = 1;
        } else {
            my @mts = ($class->list_ids({ name => $name }),
                       $class->list_ids({ name => $name, active => 0 }) );
            $used = 1 if @mts > 1
              || (@mts == 1 && !defined $mt_id)
              || (@mts == 1 && defined $mt_id && $mts[0] != $mt_id);
            $self->raise_conflict(
                qq{The name "[_1]" is already used by another $disp_name.},
                $name,
            ) if $used;
        }

        # Process add_more widget.
        my $used_ext = 0;
        my %old_exts = map { $_ => 1 } my @orig_exts = $mt->get_exts;
        for my $extension (@{ mk_aref( $param->{extension} ) } ) {
            next unless $extension && $extension !~ /^\s+$/;
            next if delete $old_exts{ lc $extension };
            if ($extension !~ /^\w{1,10}$/) {
                $self->raise_conflict('Extension "[_1]" ignored.', $extension);
                next;
            }
            my $mt_id = Bric::Util::MediaType->get_id_by_ext($extension);
            if ( $mt_id && $mt_id != $mt->get_id ) {
                $self->raise_conflict(
                    'Extension "[_1]" is already used by media type "[_2]".',
                    $extension,
                    Bric::Util::MediaType->get_name_by_ext($extension)
                );
                $used_ext += 1;
            } else {
                $self->raise_conflict(
                    'Problem adding "[_1]"',
                    $extension,
                ) unless $mt->add_exts($extension);
            }
        }

        $mt->del_exts( keys %old_exts ) if %old_exts;
        unless (($mt->get_exts)[0]) {
            # Revert the extensions
            $mt->add_exts(@orig_exts);
            $self->raise_conflict('At least one extension is required.');
            $used_ext = 1;
        }

        # Roll in the changes.
        $mt->set_name($name) unless $used;
        $mt->set_description($param->{description});

        # Save changes and redirect back to the manager.
        if ($used || $used_ext) {
            $param->{obj} = $mt;
            return;
        } else {
            $mt->activate();
            $mt->save();
            $self->add_message(qq{$disp_name profile "[_1]" saved.}, $name);
            unless (defined $mt_id) {
                log_event($type . '_new', $mt);
            } else {
                log_event($type . '_save', $mt);
            }
            $self->set_redirect("/admin/manager/$type");
            return;
        }
    }
}

1;
