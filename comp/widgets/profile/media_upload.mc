<table cellspacing="0" border="0" width="100%" cellpadding="0">
  <tr>
    <td align="right"><span class="label required"><% $lang->maketext('Or upload as:') %></span>&nbsp;</td>
    <td><& '/widgets/select_object/select_object.mc',
    disp       => undef,
    name       => "media_prof|at_id",
    object     => 'element',
    field      => 'name',
    req        => 1,
    objs       => \@elems,
    useTable   => 0,
&></td>
    <td><input type="file" name="<% $file_widget %>|file" /></td>
    <td align="right">
     <& /widgets/profile/imageSubmit.mc,
        formName => $formName,
        callback => "$widget|create_related_media_cb",
        image    => "create_red",
        vspace   => 4,
        alt      => 'Create',
      &>&nbsp;</td>
  </tr>
</table>
<%args>
$widget   => 'container_prof'
$formName => 'theForm'
$file_widget => 'media_prof'
$site_id
</%args>
<%init>;
# Just return unless they have CREATE permission to a desk in a media workflow
# in this site.
return unless find_desk(find_workflow($site_id, MEDIA_WORKFLOW, READ), CREATE);
my @elems = grep { chk_authz($_, READ, 1) }
  Bric::Biz::ElementType->list({
      top_level => 1,
      media => 1,
      site_id => $site_id,
  }) or return;
</%init>
