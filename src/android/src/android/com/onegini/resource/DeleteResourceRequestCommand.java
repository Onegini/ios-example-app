package com.onegini.resource;

import org.apache.cordova.CallbackContext;

import android.content.Context;
import com.onegini.mobile.sdk.android.library.OneginiClient;

public class DeleteResourceRequestCommand implements ResourceRequestCommand {

  private final ResourceRequestCallback resourceRequestCallback;
  private final RequestAdapterFactory requestAdapterFactory;

  public DeleteResourceRequestCommand(final ResourceRequestCallback resourceRequestCallback, final RequestAdapterFactory restAdapterFactory) {
    this.resourceRequestCallback = resourceRequestCallback;
    this.requestAdapterFactory = restAdapterFactory;
  }

  public void send(final OneginiClient oneginiClient, final ResourceRequest resourceRequest, final CallbackContext callbackContext, final Context context) {
    requestAdapterFactory
        .buildDeleteRequestAdapter()
        .call(resourceRequest.getPath(), resourceRequestCallback.buildResponseCallback());
  }

}
