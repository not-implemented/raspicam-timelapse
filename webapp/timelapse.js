jQuery(function($) {
    var isCapturing = false;

    var busyIndicator = $('#busy-indicator');
    var alertBox = $('#alert-box');
    var previewImage = $('#preview-image');
    var startCaptureButton = $('#start-capture');
    var stopCaptureButton = $('#stop-capture');
    var statusTable = $('#status-table');
    var saveConfigButton = $('#save-config');
    var resetConfigButton = $('#reset-config');

    $('[data-toggle="tooltip"]').tooltip();

    setBusy(true);
    updateStatus(function () {
        setBusy(false);
    });
    setInterval(updateStatus, 1000);
    loadConfig();

    startCaptureButton.on('click', function () {
        api('startCapture', {}, function (response) {
            isCapturing = response.isCapturing;
            updateStatus();
        });
    });

    stopCaptureButton.on('click', function () {
        api('stopCapture', {}, function (response) {
            isCapturing = response.isCapturing;
            updateStatus();
        });
    });

    saveConfigButton.on('click', function () {
        var config = getConfig();

        api('saveConfig', config, function (config) {
            setConfig(config);
        });
    });

    resetConfigButton.on('click', function () {
        loadConfig();
    });

    function updateStatus(callback) {
        api('loadStatus', function (status) {
            for (var name in status) {
                var statusId = 'status-' + name;
                var statusItem = status[name];

                var statusNode = $('#' + statusId);

                if (statusNode.length === 0) {
                    statusTable.find('.status-init').remove();
                    statusTable.append('<tr><td>' + statusItem.title + '</td><td><span id="' + statusId + '"></span></td></tr>');
                    statusNode = $('#' + statusId);
                }

                statusNode.text(statusItem.value);
                statusNode.removeClass();
                statusNode.addClass('label label-' + statusItem.type);
            }

            if (callback) callback();
        });
    }

    function loadConfig() {
        api('loadConfig', function (config) {
            setConfig(config);
        });
    }

    function getConfig() {
        var config = {};

        $('input, select, textarea').each(function (i, node) {
            var name = node.id.replace(/^option-/, '');
            config[name] = $(node).val();
        });

        return config;
    }

    function setConfig(config) {
        for (var name in config) {
            $('#option-' + name).val(config[name]);
        }
    }

    function api(action, data, callback) {
        if (arguments.length === 2 && typeof data === 'function') {
            callback = data;
            data = null;
        }

        if (data) setBusy(true);

        setTimeout(function () {
            var response = null;

            if (action === 'startCapture') {
                response = {isCapturing: true};
            } else if (action === 'stopCapture') {
                response = {isCapturing: false};
            } else if (action === 'loadStatus') {
                response = {
                    captureMode: {title: 'Capture Mode', value: isCapturing ? 'Cron active' : 'Not capturing', type: 'danger'},
                    freeDiskSpace: {title: 'Free Disk Space', value: '11.3 GB', type: 'success'},
                    cpuTemp: {title: 'CPU Temperature', value: '48.7°C', type: 'success'},
                    cpuUsage: {title: 'CPU Usage', value: '1.1 %', type: 'success'},
                    uptime: {title: 'Uptime', value: '37 min', type: 'default'}
                };
            } else if (action === 'loadConfig') {
                response = {
                    timelapseInterval: 10,
                    captureMode: 'raspistill',
                    warmupTime: 5,
                    exposure: 'auto',
                    awb: 'auto',
                    iso: 400,
                    width: 1920,
                    height: 1080,
                    thumbnailWidth: 480,
                    thumbnailHeight: 270,
                    jpegQuality: 100
                };
            } else if (action === 'saveConfig') {
                response = data;
            }

            callback(response);

            if (data) setBusy(false);
        }, 500);
    }

    function setBusy(isBusy) {
        if (isBusy) busyIndicator.show();
        else busyIndicator.hide();

        startCaptureButton.prop('disabled', isBusy || isCapturing);
        stopCaptureButton.prop('disabled', isBusy || !isCapturing);

        $('#options-container input, #options-container select').prop('disabled', isBusy);
        saveConfigButton.prop('disabled', isBusy);
        resetConfigButton.prop('disabled', isBusy);
    }
});
