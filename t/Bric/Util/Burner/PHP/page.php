<div class="page">
<?php
foreach ($element->get_elements() as $e) {
    echo '<p>', $e->get_value(), "</p>\n";
}
?>
</div>
