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
        $config = $this->saveConfig(['isCapturing' => true]);
        $this->generateDaemonConfig($config);

        if ($config->captureMode === 'raspistill') {
            // TODO:
            //shell_exec($this->daemonFilename . ' start 2>&1');
        }

        return $config;
    }

    public function stopCapture() {
        $config = $this->saveConfig(['isCapturing' => false]);
        $this->generateDaemonConfig($config);

        if ($config->captureMode === 'raspistill') {
            // TODO:
            //shell_exec($this->daemonFilename . ' stop 2>&1');
        }

        return $config;
    }

    private function generateDaemonConfig($config) {
        $options = [
        // TODO:
        /*
            'RASPICAM_OUTPUTDIR' => $_REQUEST['outputDir'],
            'RASPICAM_TIMELAPSE' => $config-> * 1000,
            'RASPICAM_TIMEOUT' => $config-> 10 * 365 * 24 * 3600,
            'RASPICAM_EXPOSURE' => $config-> 'auto',
            'RASPICAM_ISO' => $config-> 400,
            'RASPICAM_AWB' => $config-> 'auto',
        */
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

        $captureMode = $config->isCapturing ? $config->captureMode : 'Not capturing';
        $status->captureMode = (object) [
            'title' => 'Capture Mode',
            'value' => $captureMode,
            'type' => $config->isCapturing ? 'success' : 'danger',
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

        return $status;
    }

    public function loadConfig() {
        // default config:
        $config = (object) [
            'isCapturing' => false,
            'capturePath' => '/home/pi/capture',
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
