#!/usr/bin/perl
# print a tree of elements and their subelements,
# using a bric_soap export of elements
# $ bric_soap element list_ids | bric_soap element export - > elements.xml
# $ ./element-tree.pl elements.xml
# Handles 1.6 or 1.8 versions of bric_soap.

use strict;
use warnings;
use XML::Twig;

my $CHILDMARKER = '. ';   # what's in front of subelements
my $WITHFIELDS = 1;       # whether to display fields
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

# get all elements with their subelements, and fields;
# put this in %ELEMENT
sub parse_xml_elements {
    my $xmlfile = shift(@ARGV) || 'elements.xml';
    XML::Twig->new(
        twig_roots => {'assets/element' => \&get_element_info}
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

    # subelements
    my @children = sort $node->first_child('subelements')->children_text;
    $ELEMENT{$name}{children} = [@children];

    # fields
    my @fields = $node->first_child('fields')->children('field');
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
    $ELEMENT{$name}{fields} = [sort @fieldnames];

    # output channels
    if ($ELEMENT{$name}{top_level}) {
        my @ocs = $node->first_child('output_channels')->children('output_channel');
        $ELEMENT{$name}{output_channels} = [];
        foreach my $oc (@ocs) {
            my $ocname = $oc->text;
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
                die "All the elements aren't there: element=$element, child=$child\n";
            }
        }
    }
}

# recursively print subelements
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
    print ' (', join(', ', @{ $ELEMENT{$element}{fields} }), ')'
      if $WITHFIELDS;
}

sub print_ocs {
    my $element = shift;
    print '> ', join(', ', @{ $ELEMENT{$element}{output_channels} }), $/;
}

# display parent-less elements and recursively their subelements
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
