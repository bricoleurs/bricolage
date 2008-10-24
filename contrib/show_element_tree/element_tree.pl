#!/usr/bin/perl
# print a tree of element types and their subelement types,
# using a bric_soap export of elements
# $ bric_soap element list_ids | bric_soap element export - > elements.xml
# $ ./element_tree.pl elements.xml
# Handles bric_soap for Bricolage version 1.10 (not 1.8 or before).

use strict;
use warnings;
use XML::Twig;

my $CHILDMARKER = '. ';   # what's in front of subelements
my $WITHFIELDS = 1;       # whether to display field_types
my $WITHOCS = 1;          # whether to display output channels
my $TOPLEVEL_ONLY = 1;    # whether to only show toplevel elements
my %ELEMENT;

main();


sub main {
    $|++;
    parse_xml_elements();
    get_parent_info();
    print_parents();
}

# get all elements with their subelement_types, and field_types;
# put this in %ELEMENT
sub parse_xml_elements {
    my $xmlfile = shift(@ARGV) || 'element_types.xml';
    XML::Twig->new(
        twig_roots => {'assets/element_type' => \&get_element_info}
    )->parsefile($xmlfile);
}

# twig handler
sub get_element_info {
    my ($t, $node) = @_;

    # name
    my $name = $node->first_child_text('key_name');
    # (before 1.8 we didn't have key_name)
    $name = $node->first_child_text('name') unless $name;
    die "wtf version of bricolage are you running?" unless $name;

    # top-level
    $ELEMENT{$name}{top_level} = $node->first_child_text('top_level');

    # subelement_types
    my @children = sort $node->first_child('subelement_types')->children_text;
    $ELEMENT{$name}{children} = [@children];

    # field_types
    my @fields = $node->first_child('field_types')->children('field_type');
    my @fieldnames = ();
    foreach my $field (@fields) {
        my $fieldname = $field->first_child_text('key_name');
        # (before 1.8 we had name instead of key_name)
        $fieldname = $field->first_child_text('name') unless $fieldname;

        my $repeatable = $field->first_child_text('repeatable') ? '*' : '';
        my $required = $field->first_child_text('required') ? '!' : '';
        $fieldname .= "$repeatable$required";

        push @fieldnames, $fieldname;
    }
    $ELEMENT{$name}{field_types} = [sort @fieldnames];

    # output channels
    if ($ELEMENT{$name}{top_level}) {
        my @ocs = $node->first_child('output_channels')->children('output_channel');
        $ELEMENT{$name}{output_channels} = [];
        foreach my $oc (@ocs) {
            my $ocname = $oc->text;
            # xxx: this isn't handled properly - needs to get primary oc from site
            my $is_primary = exists($oc->{att}{primary}) ? 1 : 0;
            if ($is_primary) {
                unshift @{ $ELEMENT{$name}{output_channels} }, $ocname;
            } else {
                push @{ $ELEMENT{$name}{output_channels} }, $ocname;
            }
        }
    }
}

# determine each element's parent (if it has one)
sub get_parent_info {
    foreach my $element (keys %ELEMENT) {
        foreach my $child (@{ $ELEMENT{$element}{children} }) {
            if (exists $ELEMENT{$child}) {
                $ELEMENT{$child}{parent} = $element;
            } else {
                # should never happen
                die "All the elements aren't there: element_type=$element, child=$child\n";
            }
        }
    }
}

# recursively print subelement_types
sub print_children {
    my ($element, $parents) = @_;

    CHILD: foreach my $child (@{ $ELEMENT{$element}{children} }) {
        print $CHILDMARKER x @$parents, $child;
        print_fields($child);

        # (prevent infinite recursion)
        foreach my $parent (@$parents) {
            if ($parent eq $child) {
                print " ...\n";
                next CHILD;
            }
        }
        print $/;

        push @$parents, $child;
        print_children($child, $parents);
        pop @$parents;
    }
}

sub print_fields {
    my $element = shift;
    return unless exists $ELEMENT{$element}{field_types};
    print ' (', join(', ', @{ $ELEMENT{$element}{field_types} }), ')'
      if $WITHFIELDS;
}

sub print_ocs {
    my $element = shift;
    return unless exists $ELEMENT{$element}{output_channels};
    print '> ', join(', ', @{ $ELEMENT{$element}{output_channels} }), $/;
}

# display parent-less elements and recursively their subelement_types
sub print_parents {
    my @parents = grep {!exists $ELEMENT{$_}{parent}}
      sort {lc($a) cmp lc($b)} keys %ELEMENT;
    foreach my $element (@parents) {
        next if $TOPLEVEL_ONLY and not $ELEMENT{$element}{top_level};

        print "\n$element";
        print_fields($element);
        print $/;
        my @parentstack = ($element);
        print_children($element, \@parentstack);
        print_ocs($element) if $ELEMENT{$element}{top_level};
    }
}
