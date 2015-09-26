'use strict';

var https = require('https');
var urlModule = require('url');
var querystring = require('querystring');
var fs = require('fs');
var os = require('os');
var st = require('st');
var vcgencmd = require('vcgencmd');
var diskusage = require('diskusage');

var config = {
    capturePath: __dirname + '/../capture',
}

var serverOptions = {
    key: fs.readFileSync(__dirname + '/config/timelapse.key'),
    cert: fs.readFileSync(__dirname + '/config/timelapse.crt')
};

var mounts = [st({
    path: __dirname + '/node_modules/bootstrap/dist',
    url: '/bootstrap'
}), st({
    path: __dirname + '/node_modules/jquery/dist',
    url: '/jquery'
}), st({
    path: __dirname + '/webapp',
    index: 'index.html'
})];

var status = {
    isCapturing: false,
    latestPictureHash: null,
    captureMode: {title: 'Capture Mode', value: 'unknown', type: 'default'},
    latestPicture: {title: 'Latest Picture', value: 'unknown', type: 'default'},
    freeDiskSpace: {title: 'Free Disk Space', value: 'unknown', type: 'default'},
    cpuTemp: {title: 'CPU Temperature', value: 'unknown', type: 'default'},
    systemLoad: {title: 'System Load', value: 'unknown', type: 'default'},
    uptime: {title: 'Uptime', value: 'unknown', type: 'default'}
};

function updateStatus(partial) {
    function formatBytes(bytes) {
        return '' + (Math.round(bytes / 1024 / 1024 / 1024 * 100) / 100) + ' GB';
    }

    if (!partial) {
        if (!vcgencmd.getCamera().detected) {
            status.captureMode.value = 'No camera detected';
            status.captureMode.type = 'danger';
        } else {
            status.captureMode.value = 'unknown';
            status.captureMode.type = 'default';
        }

        diskusage.check(config.capturePath, function(err, info) {
            if (err) {
                status.freeDiskSpace.value = 'error';
                status.freeDiskSpace.type = 'danger';
                return;
            }

            var freePercent = Math.round(info.free / info.total * 10) * 10;
            status.freeDiskSpace.value = formatBytes(info.free) + ' (' + freePercent + ' %)';
            status.freeDiskSpace.type = freePercent < 10 ? (freePercent < 3 ? 'danger' : 'warning') : 'success';
        });

        var cpuTemp = vcgencmd.measureTemp();
        status.cpuTemp.value = '' + cpuTemp + '°C';
        status.cpuTemp.type = cpuTemp >= 65 ? (cpuTemp >= 75 ? 'danger' : 'warning') : 'success';
    }

    var systemLoad = os.loadavg();
    // TODO: format float numbers correctly:
    status.systemLoad.value = systemLoad.map(function (load) {return Math.round(load * 100) / 100;}).join(' - ');
    status.systemLoad.type = systemLoad[0] >= 2 ? (systemLoad[0] >= 5 ? 'danger' : 'warning') : 'success';

    var uptime = os.uptime();
    var days = Math.floor(uptime / (3600 * 24)); uptime -= days * (3600 * 24);
    var hours = Math.floor(uptime / 3600); uptime -= hours * 3600;
    var minutes = Math.floor(uptime / 60); uptime -= minutes * 60;
    var seconds = uptime;
    // TODO: format digits correctly:
    status.uptime.value = (days > 0 ? days + 'd ' : '') + hours + ':' + minutes + ':' + seconds;
}

setInterval(updateStatus, 10000);
updateStatus();

var apiActions = {
    startCapture: function (data, callback) {
        callback({error: 'Action startCapture not implemented'}, 501);
    },
    stopCapture: function (data, callback) {
        callback({error: 'Action stopCapture not implemented'}, 501);
    },
    loadStatus: function (data, callback) {
        updateStatus(true);
        callback(status, 200);
    },
    loadConfig: function (data, callback) {
        callback({error: 'Action loadConfig not implemented'}, 501);
    },
    saveConfig: function (data, callback) {
        callback({error: 'Action saveConfig not implemented'}, 501);
    },
    unknown: function (data, callback) {
        callback({error: 'Unknown API-Action'}, 404);
    }
};

https.createServer(serverOptions, function (request, response) {
    var startTime = process.hrtime();
    var url = urlModule.parse(request.url);

    // TODO: authentication

    if (url.pathname === '/api.php') {
        var query = querystring.parse(url.query);
        var action = query.action;
        var requestData = null; // TODO: process POST data

        if (!apiActions[action]) action = 'unknown';

        apiActions[action](requestData, function (data, statusCode) {
            var json = JSON.stringify(data);
            var duration = process.hrtime(startTime);

            response.writeHead(statusCode || 200, {
                'Content-Type': 'application/json',
                'X-Duration': Math.round((duration[0] * 1000 + duration[1] / 1000000) * 10) / 10
            });
            response.end(json);
        });
        return;
    }

    // serve static files:
    for (var i = 0; i < mounts.length; i++) {
        if (mounts[i](request, response)) break;
    }
}).listen(8000);
