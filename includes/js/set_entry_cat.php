<?php
  global $type;
?><script type="text/javascript">
<!-- <![CDATA[
function editCats (  evt ) {
  if (document.getElementById) {
    mX = evt.clientX   +150;
    mY = evt.clientY  + 150;
  }
  else {
    mX = evt.pageX  +150;
    mY = evt.pageY + 150;
  }
  var MyPosition = 'scrollbars=no,toolbar=no,left=' + mX + ',top=' + mY + ',screenx=' + mX + ',screeny=' + mY ;
  var cat_ids = document.selectcategory.elements['cat_id'].value;
  url = "catsel.php?form=selectcategory&type=<?php echo $type ?>&cats=" + cat_ids;
  var catWindow = window.open(url,"EditCat","width=365,height=200,"  + MyPosition);
}
//]]> -->
</script>