// ICallbackInterface.aidl
package com.hi2shark.flclash_nw.service;

import com.hi2shark.flclash_nw.service.IAckInterface;

interface ICallbackInterface {
    oneway void onResult(in byte[] data,in boolean isSuccess, in IAckInterface ack);
}