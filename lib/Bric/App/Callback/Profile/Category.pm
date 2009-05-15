package Bric::App::Callback::Profile::Category;

use base qw(Bric::App::Callback::Profile);
__PACKAGE__->register_subclass;
use constant CLASS_KEY => 'category';

use strict;
use Bric::App::Authz qw(:all);
use Bric::App::Event qw(log_event);
use Bric::App::Util qw(:aref);
use Bric::Biz::Category;
use Bric::Biz::Keyword;
use Bric::Util::Fault qw(throw_forbidden);
use Bric::Util::Grp;
use Bric::Util::Trans::FS;

my $type = 'category';
my $disp_name = 'Category';
my $pl_name = 'categories';
my $class = 'Bric::Biz::Category';


sub save : Callback {
    my $self = shift;

    return unless $self->has_perms;

    my $param = $self->params;
    my $cat = $self->obj;

    my $id = $param->{"${type}_id"};
    my $name = $param->{name};

    # This will fail if for some bad reason site_id has not yet been set on $cat
    my $root_id = Bric::Biz::Category->site_root_category_id($param->{site_id});

    if ($param->{delete} || $param->{delete_cascade}) {
        if ($id == $root_id) {
            # You can't deactivate the root category!
            $self->raise_conflict("$disp_name \"[_1]\" cannot be deleted.", $name);
            $param->{'obj'} = $cat;
            return;
        }
        my ($arg, $msg, $key);
        if ($param->{delete_cascade}) {
            # We're going to delete all subcategories, too.
            $arg = { recurse => 1 };
            $msg = "$disp_name profile \"[_1]\" and all its $pl_name deleted.";
            $key = '_deact_cascade';
        } else {
            # We'll just be deleting this category.
            $msg = "$disp_name profile \"[_1]\" deleted.";
            $key = '_deact';
        }
        # Deactivate it.
        $cat->deactivate($arg);
        $cat->save;
        log_event($type . $key, $cat);
        $self->add_message($msg, $name);
    } else {
        # Roll in the changes.
        $cat->set_name($param->{name});
        $cat->set_description($param->{description});
        $cat->set_ad_string($param->{ad_string});
        $cat->set_ad_string2($param->{ad_string2});
        $cat->set_site_id($param->{site_id})
          if exists $param->{site_id};

        # if this is not ROOT, we have work to do
        if (((defined $id and $id != $root_id) or not defined $id)
            and defined $param->{parent_id}) {

            # get and set the parent
            my $par = $class->lookup({id => $param->{parent_id}});
            $par->add_child([$cat]);

            # make sure the directory name does not
            # already exist as a child of the parent
            if (exists $param->{directory}) {
                my $p_id = $par->get_id;

                if (defined($id) and $id == $p_id
                    or grep $_->get_id == $p_id, $cat->children) {
                    $self->raise_conflict(
                        'Parent cannot choose itself or its child as its parent. Try a different parent.'
                    );
                    $param->{'obj'} = $cat;
                    return;
                }

                if (@{ $class->list({ directory => $param->{directory},
                                      site_id   => $cat->get_site_id,
                                      active    => 'all',
                                      parent_id => $p_id}) }) {
                    my $uri = Bric::Util::Trans::FS->cat_uri(
                        $par->get_uri,
                        $param->{directory}
                    ) . '/';
                    $self->raise_conflict(
                        'URI "[_1]" is already in use. Please try a different directory name or parent category.',
                        $uri,
                    );
                    $param->{'obj'} = $cat;
                    return;
                }
                if ($param->{directory} =~ /[^\w.-]+/) {
                    $self->raise_conflict(
                        'Directory name "[_1]" contains invalid characters. Please try a different directory name.',
                        $param->{directory},
                    );
                    $param->{'obj'} = $cat;
                    return;
                } else {
                    $cat->set_directory($param->{directory});
                }
            }
        }

        # Delete old keywords.
        my $old;
        my $keywords = { map { $_ => 1 } @{ mk_aref($param->{keyword_id}) } };
        foreach ($cat->get_keywords) {
            push @$old, $_ unless $keywords->{$_->get_id};
        }
        $cat->del_keywords(@$old) if $old;

        # Add new keywords.
        my $new;
        foreach (@{ mk_aref($param->{new_keyword}) }) {
            next unless $_;
            my $kw = Bric::Biz::Keyword->lookup({ name => $_ });
            if ($kw) {
                chk_authz($kw, READ);
            } else {
                if (chk_authz('Bric::Biz::Keyword', CREATE, 1)) {
                    $kw = Bric::Biz::Keyword->new({ name => $_ })->save;
                    log_event('keyword_new', $kw);
                } else {
                    throw_forbidden(
                        maketext => [
                            'Could not create keyword, "[_1]", as you have not been granted permission to create new keywords.',
                            $_,
                        ],
                    );
                }
            }
            push @$new, $kw;
        }
        $cat->add_keywords(@$new) if $new;

        log_event($type . (defined $param->{category_id} ? '_save' : '_new'),
                  $cat);

        # Save changes.
        $cat->save;

        # Take care of group managment.
        if ($param->{add_grp} or $param->{rem_grp}) {
            # Set up an array of all child categories if permissions
            # should cascade.
            $self->obj( scalar $cat->list({uri => $cat->get_uri . '%'}) )
              if $param->{grp_cascade};
            # Manage the group memberships.
            $self->manage_grps;
            # Reset the object.
            $self->obj($cat) if $param->{grp_cascade};
        }

        $self->add_message("$disp_name profile \"[_1]\" saved.", $name);
    }
    # Redirect back to the manager.

    $self->set_redirect('/admin/manager/category');
    $param->{'obj'} = $cat;
    return;
}


1;
