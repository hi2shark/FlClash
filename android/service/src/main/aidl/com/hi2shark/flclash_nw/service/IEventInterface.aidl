// IEventInterface.aidl
package com.hi2shark.flclash_nw.service;

import com.hi2shark.flclash_nw.service.IAckInterface;

interface IEventInterface {
    oneway void onEvent(in String id, in byte[] data,in boolean isSuccess, in IAckInterface ack);
}