<%perl>
$m->out(join(" ", map { 
    qq{<span class="$type">} . 
    $m->scomp('/widgets/profile/hidden.mc',
        name  => $type . '_id',
        value => $_->get_id
    ) .
    qq{<span class="value">} . $_->get_name . qq{</span>} .
    qq{ (<a href="#" onclick="Element.remove(this.parentNode); return false">remove</a>),</span>}
} @$objects ));
$m->out(qq{<input type="text" class="textInput" name="new_$type" id="new_$type" /><button onclick="addKeyword(this.parentNode, \$F('new_$type')); \$('new_$type').value = ''; return false;">Add</button>});
</%perl>

<%args>
$type       => "object"
$objects
</%args>