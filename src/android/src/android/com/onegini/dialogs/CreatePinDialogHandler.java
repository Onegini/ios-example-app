package com.onegini.dialogs;

import static com.onegini.responses.OneginiPinResponse.ASK_FOR_NEW_PIN;
import static com.onegini.responses.OneginiPinResponse.PIN_BLACKLISTED;
import static com.onegini.responses.OneginiPinResponse.PIN_SHOULD_NOT_BE_A_SEQUENCE;
import static com.onegini.responses.OneginiPinResponse.PIN_SHOULD_NOT_USE_SIMILAR_DIGITS;
import static com.onegini.responses.OneginiPinResponse.PIN_TOO_SHORT;

import org.apache.cordova.CallbackContext;

import com.onegini.actions.AuthorizeAction;
import com.onegini.mobile.sdk.android.library.handlers.OneginiPinProvidedHandler;
import com.onegini.mobile.sdk.android.library.utils.dialogs.OneginiCreatePinDialog;
import com.onegini.util.CallbackResultBuilder;

public class CreatePinDialogHandler implements OneginiCreatePinDialog {

  private final CallbackResultBuilder callbackResultBuilder;

  public CreatePinDialogHandler() {
    callbackResultBuilder = new CallbackResultBuilder();
  }

  @Override
  public void createPin(final OneginiPinProvidedHandler oneginiPinProvidedHandler) {
    final CallbackContext authorizationCallback = AuthorizeAction.getAuthorizationCallback();
    if (AuthorizeAction.getAuthorizationCallback() == null) {
      //TODO: invalidate pin request on SDK side
      return;
    }

    AuthorizeAction.setAwaitingPinProvidedHandler(oneginiPinProvidedHandler);

    authorizationCallback.sendPluginResult(callbackResultBuilder
        .withSuccessMessage(ASK_FOR_NEW_PIN.getName())
        .withCallbackKept()
        .build());
  }

  /*
  AuthorizationCallback is null-checked only once in #createPin as below methods will become unreachable if check fails.
   */
  @Override
  public void pinBlackListed() {
    AuthorizeAction.getAuthorizationCallback().sendPluginResult(callbackResultBuilder
        .withSuccessMessage(PIN_BLACKLISTED.getName())
        .withCallbackKept()
        .build());
  }

  @Override
  public void pinShouldNotBeASequence() {
    AuthorizeAction.getAuthorizationCallback().sendPluginResult(callbackResultBuilder
        .withSuccessMessage(PIN_SHOULD_NOT_BE_A_SEQUENCE.getName())
        .withCallbackKept()
        .build());
  }

  @Override
  public void pinShouldNotUseSimilarDigits(final int i) {
    AuthorizeAction.getAuthorizationCallback().sendPluginResult(callbackResultBuilder
        .withSuccessMessage(PIN_SHOULD_NOT_USE_SIMILAR_DIGITS.getName())
        .withCallbackKept()
        .build());
  }

  @Override
  public void pinTooShort() {
    AuthorizeAction.getAuthorizationCallback().sendPluginResult(callbackResultBuilder
        .withSuccessMessage(PIN_TOO_SHORT.getName())
        .withCallbackKept()
        .build());
  }
}
