<%once>;
my $type = 'category';
my $disp_name = get_disp_name($type);
my $pl_name = get_class_info($type)->get_plural_name;
my $root_id = Bric::Biz::Category->root_category_id;
</%once>
<%args>
$widget
$param
$field
$obj
$class
</%args>
<%init>;
# Grab the category object.
my $cat = $obj;
my $id = $param->{"${type}_id"};
my $name = "&quot;$param->{name}&quot;";
if ($field eq "$widget|save_cb") {
    if ($param->{delete} || $param->{delete_cascade}) {
	if ($id == $root_id) {
	    # You can't deactivate the root category!
	    add_msg("$disp_name $name cannot be deleted.");
	    return $cat;
	}
	my ($arg, $msg, $key);
	if ($param->{delete_cascade}) {
	    # We're going to delete all subcategories, too.
	    $arg = { recurse => 1 };
	    $msg = "$disp_name profile $name and all its $pl_name deleted.";
	    $key = '_deact_cascade';
	} else {
	    # We'll just be deleting this category.
	    $msg = "$disp_name profile $name deleted.";
	    $key = '_deact';
	}
        # Deactivate it.
        $cat->deactivate($arg);
	$cat->save;
	log_event($type . $key, $cat);
	add_msg($msg);
    } else {
	# Roll in the changes.
	$cat->set_name($param->{name});
	$cat->set_description($param->{description});
	$cat->set_ad_string($param->{ad_string});
	$cat->set_ad_string2($param->{ad_string2});

	# Get the parent, if necessary.
	my $par = exists $param->{parent_id} && $param->{parent_id} ne 'none'
	  ? $class->lookup({ id => $param->{parent_id} }) : undef;

	# Add new keywords.
	my $new;
	foreach (@{ mk_aref($param->{keyword}) }) {
	    next unless $_;
	    my $kw = Bric::Biz::Keyword->lookup({ name => $_ });
	    $kw ||= Bric::Biz::Keyword->new({ name => $_})->save;
	    push @$new, $kw;
	}
	$cat->add_keyword($new) if $new;

	# Delete old keywords.
	my $old;
	foreach (@{ mk_aref($param->{del_keyword}) }) {
	    next unless $_;
	    my $kw = Bric::Biz::Keyword->lookup({ id => $_ }) || next;
	    push @$old, $kw;
	}
	$cat->del_keyword($old) if $old;

	# Set the directory.
	unless (! exists $param->{directory} || (defined $id && $id == $root_id) ) {
	    # First, check to make sure that this directory isn't already used.
	    if (my @cats = $class->list({ directory => $param->{directory} })) {
		# There are categories that use the same directory. Let's check
		# their paths.
		my $uri = Bric::Util::Trans::FS->cat_uri($par->get_uri,
							$param->{directory});
		foreach my $c (@cats) {
		    if ($c->get_uri eq $uri) {
			add_msg("URI &quot;$uri&quot; is already in use. Please"
				. " try a different directory name or Parent.");
			return $cat;
		    }
		}
	    } else {
		$cat->set_directory($param->{directory});
	    }
	}

	# Save changes.
	$cat->save;

	# Establish the parent directory.
	if ( defined $param->{parent_id} && (!defined $id || $id != $root_id) ) {
	    # We have a parent ID.
	    if (my $p = $cat->parent) {
		# There's an existing parent.
		if ($p->get_id != $param->{parent_id}) {
		    # It's a new parent. Delete the old and add the new.
		    if ($param->{parent_id} eq 'none') {
			$p->del_child([$cat]);
			$p->save;
		    } else {
			$p = $class->lookup({ id => $param->{parent_id} });
			$p->add_child([$cat]);
			$p->save;
		    }
		}
	    } elsif ($param->{parent_id} ne 'none') {
		# There is no existing parent. Add the new.
		$par->add_child([$cat]);
		$par->save;
	    } else {
		# Nothin'.
	    }
	}
	log_event($type . (defined $param->{category_id} ? '_save' : '_new'),
		  $cat);
	add_msg("$disp_name profile $name saved.");
    }
    # Redirect back to the manager.
    set_redirect('/admin/manager/category');
    return $cat;
} else {
    # Nothing.
}
</%init>
<%doc>
###############################################################################

=head1 NAME

/widgets/profile/category.mc - Processes submits from Category Profile

=head1 VERSION

$Revision: 1.2 $

=head1 DATE

$Date: 2001-10-09 20:54:38 $

=head1 SYNOPSIS

  $m->comp('/widgets/profile/category.mc', %ARGS);

=head1 DESCRIPTION

This element is called by /widgets/profile/callback.mc when the data to be
processed was submitted from the Category Profile page.

</%doc>
