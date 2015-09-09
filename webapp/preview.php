<?php

require_once 'Timelapse.php';

$timelapse = new Timelapse();
$config = $timelapse->loadConfig();

$previewImage = $config->capturePath . '/latest.jpg';

if (file_exists($previewImage)) {
    $thumbnail = exif_thumbnail($previewImage);
    $thumbnail = rtrim($thumbnail, "\x00"); // thumbnail is padded to 24KB by raspistill

    header('Content-Length: ' . strlen($thumbnail));
    header('Content-Type: image/jpeg');
    header('Cache-Control: must-revalidate');
    header('Expires: 0');

    echo $thumbnail;
} else {
    header('HTTP/1.0 404 Not Found');
    echo 'No preview image available';
}
