package Bric::App::Callback::Profile::MediaType;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'media_type';

use strict;
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:all);
use Bric::Util::MediaType;

my $type = 'media_type';
my $disp_name = 'Media Type';
my $class = 'Bric::Util::MediaType';


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->request_args;
    my $mt = $self->obj;

    my $name = $param->{name};

    # If 'delete' box is checked, deactivate the Media Type;
    # otherwise, save the profile.
    if ($param->{delete}) {
        my @old_exts = $mt->get_exts();
        $mt->del_exts(@old_exts);
        $mt->deactivate;
        $mt->save;
        log_event("${type}_deact", $mt);
        add_msg("$disp_name profile \"[_1]\" deleted.", $name);
        set_redirect("/admin/manager/$type");
        return;
    } else {
        my $mt_id = $param->{"${type}_id"};

        # Make sure the name isn't already taken.
        my $used = 0;
        unless (defined $name && $name =~ /\S/) {
            # Should $meths->{name}{req} == 1 in Bric::Util::MediaType ?
            add_msg('Name is required.');
            $used = 1;
        } else {
            my @mts = ($class->list_ids({ name => $name }),
                       $class->list_ids({ name => $name, active => 0 }) );
            $used = 1 if (@mts > 1)
              || (@mts == 1 && !defined $mt_id)
                || (@mts == 1 && defined $mt_id && $mts[0] != $mt_id);
            add_msg("The name \"[_1]\" is already used by another $disp_name.", $name) if $used;
        }

        # Process add_more widget.
        my (@old_exts, @new_exts, $mtids, $used_ext, $addext_sub);
        @old_exts = $mt->get_exts();
        $mtids = mk_aref($param->{media_type_ext_id});
        $used_ext = 0;
        $addext_sub = sub {
            my ($mt, $extension, $name) = @_;
            my $usedext = 0;
            unless ($extension =~ /^\s*$/) {
                if ($extension =~ /^\w{1,10}$/) {
                    my $mt_name = Bric::Util::MediaType->get_name_by_ext($extension);
                    if (defined $mt_name && $mt_name ne $name) {
                        $usedext = 1;
                        add_msg('Extension "[_1]" is already used by media type "[_2]".', $extension, $mt_name);
                    } else {
                        my @addexts = @{[$extension]};
                        unless ($mt->add_exts(@addexts)) {
                            add_msg('Problem adding "[_1]"', "@addexts");
                        }
                    }
                } else {
                    add_msg('Extension "[_1]" ignored.', $extension);
                }
            }
            $param->{'obj'} = $usedext;
            return;
        };

        $used_ext = 0;
        for (my $i = 0; $i < @{$param->{extension}}; $i++) {
            if (my $ext = $mtids->[$i]) {
                my @delexts = @{[$ext]};
                unless ($mt->del_exts(@delexts)) {
                    add_msg('Problem deleting "[_1]"', "@delexts");
                }
                my $extension = $param->{extension}[$i];
                $used_ext += $addext_sub->($mt, $extension, $name);
            } else {
                next unless $param->{extension}[$i];
                my $extension = $param->{extension}[$i];
                $used_ext += $addext_sub->($mt, $extension, $name);
            }
        }
        if ($param->{del_media_type_ext}) {
            $mt->del_exts(@{ mk_aref($param->{del_media_type_ext}) });
        }
        @new_exts = $mt->get_exts();
        unless (@new_exts) {
            # Revert the extensions
            $mt->add_exts(@old_exts);
            add_msg('At least one extension is required.');
            $used_ext = 1;
        }

        # Roll in the changes.
        $mt->set_name($name) unless $used;
        $mt->set_description($param->{description});

        # Save changes and redirect back to the manager.
        if ($used || $used_ext) {
            $param->{'obj'} = $mt;
            return;
        } else {
            $mt->activate();
            $mt->save();
            add_msg("$disp_name profile \"[_1]\" saved.", $name);
            unless (defined $mt_id) {
                log_event($type . '_new', $mt);
            } else {
                log_event($type . '_save', $mt);
            }
            set_redirect("/admin/manager/$type");
            return;
        }
    }
}


1;
