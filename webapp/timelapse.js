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

    updateStatus();
    loadConfig();

    startCaptureButton.on('click', function () {
        api('startCapture', {}, function (err, status, info) {
            if (err) return;
            handleStatus(status, info);
        });
    });

    stopCaptureButton.on('click', function () {
        api('stopCapture', {}, function (err, status, info) {
            if (err) return;
            handleStatus(status, info);
        });
    });

    saveConfigButton.on('click', function () {
        var config = getConfig();

        api('saveConfig', config, function (err, config) {
            if (err) return;
            setConfig(config);
        });
    });

    resetConfigButton.on('click', function () {
        loadConfig();
    });

    function updateStatus() {
        api('loadStatus', function (err, status, info) {
            setTimeout(updateStatus, 1000);
            if (err) return;

            handleStatus(status, info);
        });
    }

    function handleStatus(status, info) {
        if (info && info.responseTime) {
            status.responseTime = {
                title: 'Response time',
                value: 'network ' + info.responseTime + ' ms' + (info.duration ? ' (+ server ' + info.duration + ' ms)' : ''),
                type: info.responseTime > 500 ? (info.responseTime > 2000 ? 'danger' : 'warning') : 'success'
            }
        }

        isCapturing = status.isCapturing;

        if (status.latestPictureHash) {
            previewImage.attr('src', '/preview?_=' + status.latestPictureHash);
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
            statusNode.addClass('badge badge-' + statusItem.type);
        }

        setBusy(isBusy); // for updated isCapturing
    }

    function loadConfig() {
        api('loadConfig', function (err, config) {
            if (err) return;
            setConfig(config);
        });
    }

    function getConfig() {
        var config = {};

        $('input, select, textarea').each(function (i, node) {
            node = $(node);
            var name = node.attr('id').replace(/^option-/, '');

            if (node.is('input:checkbox')) {
                config[name] = node.prop('checked');
            } else {
                config[name] = node.val();
            }
        });

        return config;
    }

    function setConfig(config) {
        for (var name in config) {
            var node = $('#option-' + name);
            if (node.is('input:checkbox')) {
                node.prop('checked', config[name]);
            } else {
                node.val(config[name]);
            }
        }
    }

    function api(action, data, callback) {
        if (arguments.length === 2 && typeof data === 'function') {
            callback = data;
            data = null;
        }

        if (data) setBusy(true);
        if (window.performance && window.performance.clearResourceTimings)
            window.performance.clearResourceTimings();

        $.ajax('/api?action=' + action, {
            method: data ? 'POST' : 'GET',
            data: data ? JSON.stringify(data) : null,
            contentType: data ? 'application/json' : null,
            timeout: 20000,
            success: function (response, textStatus, jqXHR) {
                var perf = window.performance && window.performance.getEntriesByName &&
                    window.performance.getEntriesByName(location.origin + '/api?action=' + action).pop();
                var duration = parseFloat(jqXHR.getResponseHeader('X-Duration')) || null;
                var info = null;
                if (perf) {
                    info = {
                        responseTime: Math.round((perf.responseEnd - perf.requestStart - (duration || 0)) * 10) / 10,
                        duration: duration
                    };
                }

                if (response.error) {
                    alertBox.html('<strong>Error:</strong> ' + response.error);
                    alertBox.show();
                } else {
                    callback(null, response, info);
                    alertBox.hide();
                }
                if (data) setBusy(false);
            },
            error: function(jqXHR, textStatus, errorThrown) {
                alertBox.html('<strong>Cannot connect to backend</strong> ' + errorThrown);
                alertBox.show();
                if (data) setBusy(false);
                callback(new Error(textStatus + ': ' + errorThrown));
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
