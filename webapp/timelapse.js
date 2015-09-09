jQuery(function($) {
    var isBusy = false;
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
            isCapturing = status.isCapturing;

            if (status.latestPictureHash) {
                previewImage.attr('src', 'preview.php?_=' + status.latestPictureHash);
            } else {
                previewImage.removeAttr('src');
            }

            for (var name in status) {
                var statusId = 'status-' + name;
                var statusItem = status[name];
                if (statusItem === null || typeof statusItem !== 'object') continue;

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

            setBusy(isBusy); // for updated isCapturing
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

        $.ajax('api.php?action=' + action, {
            method: data ? 'POST' : 'GET',
            data: data,
            timeout: 10000,
            success: function (response) {
                if (response.error) {
                    alertBox.html('<strong>Error:</strong> ' + response.error);
                    alertBox.show();
                } else {
                    callback(response);
                    alertBox.hide();
                }
                if (data) setBusy(false);
            },
            error: function(jqXHR, textStatus, errorThrown) {
                alertBox.html('<strong>' + textStatus + ':</strong> ' + errorThrown);
                alertBox.show();
                if (data) setBusy(false);
            }
        });
    }

    function setBusy(busy) {
        isBusy = busy;

        if (isBusy) busyIndicator.show();
        else busyIndicator.hide();

        startCaptureButton.prop('disabled', isBusy || isCapturing);
        stopCaptureButton.prop('disabled', isBusy || !isCapturing);

        $('#options-container input, #options-container select').prop('disabled', isBusy);
        saveConfigButton.prop('disabled', isBusy);
        resetConfigButton.prop('disabled', isBusy);
    }
});
