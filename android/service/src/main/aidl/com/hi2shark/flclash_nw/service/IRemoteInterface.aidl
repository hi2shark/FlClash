// IRemoteInterface.aidl
package com.hi2shark.flclash_nw.service;

import com.hi2shark.flclash_nw.service.ICallbackInterface;
import com.hi2shark.flclash_nw.service.IEventInterface;
import com.hi2shark.flclash_nw.service.IResultInterface;
import com.hi2shark.flclash_nw.service.IVoidInterface;
import com.hi2shark.flclash_nw.service.models.VpnOptions;
import com.hi2shark.flclash_nw.service.models.NotificationParams;

interface IRemoteInterface {
    void invokeAction(in String data, in ICallbackInterface callback);
    void quickSetup(in String initParamsString, in String setupParamsString, in ICallbackInterface callback, in IVoidInterface onStarted);
    void updateNotificationParams(in NotificationParams params);
    void updateSuspendOnWifiSsids(in String[] ssids);
    void startService(in VpnOptions options, in long runTime, in IResultInterface result);
    void stopService(in IResultInterface result);
    void setSuspended(in boolean suspended, in IResultInterface result);
    void setEventListener(in IEventInterface event);
    void setCrashlytics(in boolean enable);
    long getRunTime();
    boolean getSuspended();
    String getWifiWatchState();
}
