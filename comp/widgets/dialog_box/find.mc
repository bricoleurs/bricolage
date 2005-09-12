</%perl>
<&| /widgets/dialog_box/dialog_box.mc,
    id    => $dialog_id,
    title => 'Find and Replace',
    close_label => 'Done',
    buttons => [
        {
            label     => 'Search',
            title     => 'Search for next occurrence of find string',
            onclick   => "return searchField($field);",
            accesskey => 's',
        },
        {
            label     => 'Replace All',
            title     => 'Replace all instances of Find string with Replace string',
            onclick   => "return replaceAll($field);",
            accesskey => 'a',
        },
        {
            label     => 'Find Next',
            title     => 'Search for next occurrence of Find string',
            onclick   => "return findNext($field);",
            accesskey => 'n',
        },
    ],
&><dl>
<dt>Find: </dt><dd><input type="text" id="searchfind" size="32" /></dd>
<dt>Replace: </dt><dd><input type="text" id="searchreplace" size="32" /></dd>
<dt>Regex: </dt><dd><input type="checkbox" id="searchregex" /></dd>
</dl>
</&>
<%args>
$dialog_id => 'finddialog'
$field_id
</%args>
<%init>;
my $field = qq{document.getElementById('$field_id')};
</%init>

