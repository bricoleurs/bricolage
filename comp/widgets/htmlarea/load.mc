<script type="text/javascript">
  _editor_url = "/media/htmlarea/";
  _editor_lang = "<% $lang_key %>";
  var editors = new Array();

  function inithtmlareas() {
    var tmp;
    while (tmp = editors.pop()){
      tmp.generate();
    }
  }
  inithtmlareas();
</script>
<script type="text/javascript" src="/media/htmlarea/htmlarea.js"></script>
<script type="text/javascript" src="/media/htmlarea/lang/en.js"></script>
<script type="text/javascript" src="/media/htmlarea/dialog.js"></script>
<script type="text/javascript">
  HTMLArea.loadPlugin("SpellChecker");
</script>
