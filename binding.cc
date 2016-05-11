#include <nan.h>

#include <sys/socket.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <sys/ioctl.h>
#include <linux/wireless.h>


NAN_METHOD(GetInterfaceInfo) {
    if (info.Length() < 1 || !info[0]->IsString()) {
        Nan::ThrowTypeError("getInterfaceInfo() expects 1 string argument"); return;
    }
    Nan::Utf8String interfaceName(info[0]);
    v8::Local<v8::Object> interfaceInfo = Nan::New<v8::Object>();

    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);

    struct ifreq ifr;
    strcpy(ifr.ifr_name, *interfaceName);
    struct iwreq iwr;
    strcpy(iwr.ifr_name, *interfaceName);

    // up, running, loopback:
    if (ioctl(sockfd, SIOCGIFFLAGS, &ifr) == -1) {
        interfaceInfo->Set(Nan::New("up").ToLocalChecked(), Nan::Null());
        interfaceInfo->Set(Nan::New("running").ToLocalChecked(), Nan::Null());
        interfaceInfo->Set(Nan::New("loopback").ToLocalChecked(), Nan::Null());
    } else {
        interfaceInfo->Set(Nan::New("up").ToLocalChecked(), ifr.ifr_flags & IFF_UP ? Nan::True() : Nan::False());
        interfaceInfo->Set(Nan::New("running").ToLocalChecked(), ifr.ifr_flags & IFF_RUNNING ? Nan::True() : Nan::False());
        interfaceInfo->Set(Nan::New("loopback").ToLocalChecked(), ifr.ifr_flags & IFF_LOOPBACK ? Nan::True() : Nan::False());
    }

    // essid:
    char essid[1024];
    iwr.u.essid.pointer = essid;
    iwr.u.essid.length = sizeof(essid);

    if (ioctl(sockfd, SIOCGIWESSID, &iwr) == -1) {
        interfaceInfo->Set(Nan::New("essid").ToLocalChecked(), Nan::Null());
    } else {
        essid[iwr.u.essid.length] = '\0';
        interfaceInfo->Set(Nan::New("essid").ToLocalChecked(), Nan::New(essid).ToLocalChecked());
    }

    // accessPoint:
    if (ioctl(sockfd, SIOCGIWAP, &iwr) == -1) {
        interfaceInfo->Set(Nan::New("accessPoint").ToLocalChecked(), Nan::Null());
    } else {
        char buf[32];
        snprintf(buf, sizeof(buf), "%02X:%02X:%02X:%02X:%02X:%02X",
            (uint8_t)iwr.u.ap_addr.sa_data[0], (uint8_t)iwr.u.ap_addr.sa_data[1],
            (uint8_t)iwr.u.ap_addr.sa_data[2], (uint8_t)iwr.u.ap_addr.sa_data[3],
            (uint8_t)iwr.u.ap_addr.sa_data[4], (uint8_t)iwr.u.ap_addr.sa_data[5]);
        interfaceInfo->Set(Nan::New("accessPoint").ToLocalChecked(), Nan::New(buf).ToLocalChecked());
    }

    // frequency:
    if (ioctl(sockfd, SIOCGIWFREQ, &iwr) == -1) {
        interfaceInfo->Set(Nan::New("frequency").ToLocalChecked(), Nan::Null());
    } else {
        interfaceInfo->Set(Nan::New("frequency").ToLocalChecked(), Nan::New(((double) iwr.u.freq.m) * pow(10, iwr.u.freq.e)));
    }

    // bitRate:
    if (ioctl(sockfd, SIOCGIWRATE, &iwr) == -1) {
        interfaceInfo->Set(Nan::New("bitRate").ToLocalChecked(), Nan::Null());
    } else {
        interfaceInfo->Set(Nan::New("bitRate").ToLocalChecked(), Nan::New((uint32_t) iwr.u.bitrate.value));
    }

    // linkQuality, signalLevel, noiseLevel:
    struct iw_statistics stats;
    iwr.u.data.pointer = &stats;
    iwr.u.data.length = sizeof(stats);

    if (ioctl(sockfd, SIOCGIWSTATS, &iwr) == -1) {
        interfaceInfo->Set(Nan::New("linkQuality").ToLocalChecked(), Nan::Null());
        interfaceInfo->Set(Nan::New("signalLevel").ToLocalChecked(), Nan::Null());
        interfaceInfo->Set(Nan::New("noiseLevel").ToLocalChecked(), Nan::Null());
    } else {
        interfaceInfo->Set(Nan::New("linkQuality").ToLocalChecked(), Nan::New((uint32_t) stats.qual.qual));
        interfaceInfo->Set(Nan::New("signalLevel").ToLocalChecked(), Nan::New((uint32_t) stats.qual.level));
        interfaceInfo->Set(Nan::New("noiseLevel").ToLocalChecked(), Nan::New((uint32_t) stats.qual.noise));
    }

    close(sockfd);

    info.GetReturnValue().Set(interfaceInfo);
}

NAN_MODULE_INIT(Init) {
    Nan::Set(target, Nan::New("getInterfaceInfo").ToLocalChecked(),
        Nan::GetFunction(Nan::New<v8::FunctionTemplate>(GetInterfaceInfo)).ToLocalChecked());
}

NODE_MODULE(binding, Init)
