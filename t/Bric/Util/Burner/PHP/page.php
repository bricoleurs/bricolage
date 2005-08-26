<div class="page">
<?php
foreach ($BRIC['element']->get_elements() as $e) {
    echo '<p>', $e->get_data(), "</p>\n";
}
?>
</div>
