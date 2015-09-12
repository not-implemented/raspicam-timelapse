<?php

class Timelapse {
    private $configFilename;
    private $daemonFilename;
    private $daemonConfigFilename;

    public function __construct() {
        $this->configFilename = dirname(__DIR__) . '/config/timelapse.json';
        $this->daemonFilename = dirname(__DIR__) . '/camera/camera-daemon.sh';
        $this->daemonConfigFilename = dirname(__DIR__) . '/config/camera-daemon.conf';
    }

    public function startCapture() {
        $config = $this->saveConfig(['isCapturing' => true, 'captureFolder' => date('Y-m-d_H.i.s')]);
        $this->generateDaemonConfig($config);

        if ($config->captureMode === 'raspistill') {
            shell_exec($this->daemonFilename . ' start 2>&1');
        }

        return $config;
    }

    public function stopCapture() {
        $config = $this->saveConfig(['isCapturing' => false]);
        $this->generateDaemonConfig($config);

        if ($config->captureMode === 'raspistill') {
            shell_exec($this->daemonFilename . ' stop 2>&1');
        }

        return $config;
    }

    private function generateDaemonConfig($config) {
        $raspistillOptions = [
            'width' => $config->width,
            'height' => $config->height,
            'encoding' => 'jpg',
            'quality' => $config->jpegQuality,
            'thumb' => $config->thumbnailWidth . ':' . $config->thumbnailHeight . ':70',
            'output' => $config->capturePath . '/' . $config->captureFolder . '/img_%04d.jpg',
            'latest' => $config->capturePath . '/latest.jpg',

            'exposure' => $config->exposure,
            'ev' => 0,
            'awb' => $config->awb,
            'ISO' => $config->iso,

            'timelapse' => round($config->timelapseInterval * 1000),
            'timeout' => $config->captureMode === 'cron' ? $config->warmupTime : 10 * 365 * 24 * 3600,
            'verbose' => null,
        ];

        $raspistillOptionsRaw = [];
        foreach ($raspistillOptions as $name => $value) {
            $raspistillOptionsRaw[] = '--' . $name . ' ' . $value;
        }

        $options = [
            'TIMELAPSE_IS_CAPTURING' => $config->isCapturing ? 1 : 0,
            'TIMELAPSE_TIMELAPSE_INTERVAL' => $config->timelapseInterval,
            'TIMELAPSE_CAPTURE_MODE' => $config->captureMode,
            'TIMELAPSE_CAPTURE_PATH' => $config->capturePath,
            'TIMELAPSE_CAPTURE_FOLDER' => $config->captureFolder,
            'TIMELAPSE_RASPISTILL_OPTIONS' => escapeshellarg(implode(' ', $raspistillOptionsRaw)),
        ];

        $daemonConfig = '';
        foreach ($options as $name => $value) {
            $daemonConfig .= $name . '=' . $value . PHP_EOL;
        }

        if (file_put_contents($this->daemonConfigFilename, $daemonConfig) === false) {
            throw new Exception('Error writing daemon config - please see README.md for setting permissions correctly');
        }
    }

    public function loadStatus() {
        $status = (object) [];
        $config = $this->loadConfig();

        $status->isCapturing = $config->isCapturing;

        $latestPictureTime = @filemtime($config->capturePath . '/latest.jpg');
        $latestPictureSize = @filesize($config->capturePath . '/latest.jpg');

        if ($latestPictureTime !== false && $latestPictureSize !== false) {
            $status->latestPictureHash = md5($latestPictureTime . '#' . $latestPictureSize);
        } else {
            $status->latestPictureHash = null;
        }

        $captureMode = $config->isCapturing ? $config->captureMode : 'Not capturing';
        $status->captureMode = (object) [
            'title' => 'Capture Mode',
            'value' => $captureMode,
            'type' => $config->isCapturing ? 'success' : 'danger',
        ];

        $status->latestPicture = (object) [
            'title' => 'Latest Picture',
            'value' => $status->latestPictureHash !== null ?
                (date('Y-m-d H:i:s', $latestPictureTime) .
                ' (' . round($latestPictureSize / 1024 / 1024, 2) . ' MB)') :
                '(none)',
            'type' => $status->latestPictureHash !== null ? 'success' : 'danger',
        ];

        $freeDiskSpace = round(disk_free_space($config->capturePath) / 1024 / 1024 / 1024, 2);
        $status->freeDiskSpace = (object) [
            'title' => 'Free Disk Space',
            'value' => $freeDiskSpace . ' GB',
            'type' => $freeDiskSpace <= 1 ? ($freeDiskSpace <= 0.2 ? 'danger' : 'warning') : 'success',
        ];

        $cpuTemp = shell_exec('vcgencmd measure_temp');
        $cpuTemp = (float) preg_replace('/^temp=/', '', $cpuTemp);
        $status->cpuTemp = (object) [
            'title' => 'CPU Temperature',
            'value' => $cpuTemp . '°C',
            'type' => $cpuTemp >= 60 ? ($cpuTemp >= 70 ? 'danger' : 'warning') : 'success',
        ];

        $systemLoad = sys_getloadavg();
        $currentSystemLoad = $systemLoad[0];
        foreach ($systemLoad as $key => $item) $systemLoad[$key] = sprintf('%.02f', $item);
        $systemLoad = implode(' - ', $systemLoad);
        $status->systemLoad = (object) [
            'title' => 'System Load',
            'value' => $systemLoad,
            'type' => $currentSystemLoad >= 1 ? ($currentSystemLoad >= 2 ? 'danger' : 'warning') : 'success',
        ];

        $uptime = file_get_contents('/proc/uptime');
        $uptime = explode(' ', $uptime)[0];

        $days = floor($uptime / (3600 * 24)); $uptime -= $days * (3600 * 24);
        $hours = floor($uptime / 3600); $uptime -= $hours * 3600;
        $minutes = floor($uptime / 60); $uptime -= $minutes * 60;
        $seconds = $uptime;

        $uptime = ($days > 0 ? $days . 'd ' : '') . sprintf('%02d:%02d:%02d', $hours, $minutes, $seconds);

        $status->uptime = (object) [
            'title' => 'Uptime',
            'value' => $uptime,
            'type' => 'default'
        ];

        if (isset($GLOBALS['startTime'])) {
            $status->duration = round((microtime(true) - $GLOBALS['startTime']) * 1000);
        }

        return $status;
    }

    public function loadConfig() {
        // default config:
        $config = (object) [
            'isCapturing' => false,
            'capturePath' => '/home/pi/capture',
            'captureFolder' => 'default',
            'timelapseInterval' => 1,
            'captureMode' => 'raspistill',
            'warmupTime' => 5,
            'exposure' => 'auto',
            'awb' => 'auto',
            'iso' => 400,
            'width' => 1920,
            'height' => 1080,
            'thumbnailWidth' => 480,
            'thumbnailHeight' => 270,
            'jpegQuality' => 100,
        ];

        if (file_exists($this->configFilename)) {
            $currentConfig = file_get_contents($this->configFilename);
            $currentConfig = json_decode($currentConfig);

            if ($currentConfig) {
                foreach ($config as $name => $value) {
                    if (property_exists($currentConfig, $name)) {
                        $config->$name = $currentConfig->$name;
                    }
                }
            }
        }

        return $config;
    }

    public function saveConfig($newOptions = null) {
        $config = $this->loadConfig();

        if ($newOptions === null) {
            $newOptions = $_POST;
        }

        foreach ($config as $name => $value) {
            if (array_key_exists($name, $newOptions)) {
                $config->$name = $newOptions[$name];
            }
        }

        if (file_put_contents($this->configFilename, json_encode($config)) === false) {
            throw new Exception('Error writing config - please see README.md for setting permissions correctly');
        }

        return $config;
    }
}
