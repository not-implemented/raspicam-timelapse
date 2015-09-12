<?php

$GLOBALS['startTime'] = microtime(true);

require_once 'Timelapse.php';

$allowedActions = ['startCapture', 'stopCapture', 'loadStatus', 'loadConfig', 'saveConfig'];

try {
    $action = !empty($_GET['action']) ? $_GET['action'] : null;
    if (in_array($action, $allowedActions)) {
        $timelapse = new Timelapse();
        $response = $timelapse->$action();
    } else {
        throw new Exception('Unknown action "' . $action . '"');
    }
} catch (\Exception $e) {
    $response = (object) ['error' => $e->getMessage()];
}

header('Content-Type: application/json; charset=utf-8');
echo json_encode($response);
