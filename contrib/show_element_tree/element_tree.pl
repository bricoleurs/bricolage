#!/usr/bin/perl
# print a tree of elements and their subelements,
# using a bric_soap export of elements
# $ bric_soap element list_ids | bric_soap element export - > elements.xml
# $ ./element-tree.pl elements.xml
# Handles 1.6 or 1.8 version of bric_soap. Has the option to
# not display the fields (see $WITHFIELDS).

use strict;
use warnings;
use XML::Twig;

my $CHILDMARKER = '. ';   # what's in front of subelements
my $WITHFIELDS = 1;       # whether to display fields
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

    my $name = $node->first_child_text('key_name');
    # (before 1.8 we didn't have key_name)
    $name = $node->first_child_text('name') unless $name;
    die "wtf version of bricolage are you running?" unless $name;

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
        push @fieldnames, $fieldname;
    }
    $ELEMENT{$name}{fields} = [sort @fieldnames];
}

# determine each element's parent (if it has one)
sub get_parent_info {
    foreach my $element (keys %ELEMENT) {
        foreach my $child (@{ $ELEMENT{$element}{children} }) {
            if (exists $ELEMENT{$child}) {
                $ELEMENT{$child}{parent} = $element;
            } else {
                # should never happen
                die "element=$element, child=$child\n";
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

# display parent-less elements and recursively their subelements
sub print_parents {
    my @parents = grep {!exists $ELEMENT{$_}{parent}}
      sort {lc($a) cmp lc($b)} keys %ELEMENT;
    foreach my $element (@parents) {
        print "\n$element";
        print_fields($element);
        print $/;
        my @parentstack = ($element);
        print_children($element, \@parentstack);
    }
}
