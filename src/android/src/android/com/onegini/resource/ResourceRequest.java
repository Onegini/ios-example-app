package com.onegini.resource;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.onegini.scope.ScopeParser;

public class ResourceRequest {

  public static final int PARAMETERS_WITHOUT_HEADERS_LENGTH = 5;
  public static final int PARAMETERS_WITH_HEADERS_LENGTH = 6;

  private final String path;
  private final String[] scopes;
  private final String requestMethodString;
  private final String paramsEncodingString;
  private final JSONObject params;
  private final JSONObject headers;

  public static ResourceRequest buildRequestFromArgs(final JSONArray args) {
    try {
      if (args.length() == PARAMETERS_WITHOUT_HEADERS_LENGTH) {
        return new ResourceRequest(args.getString(0), args.getJSONArray(1), args.getString(2), args.getString(3), args.getJSONObject(4));
      } else {
        return new ResourceRequest(args.getString(0), args.getJSONArray(1), args.getString(2), args.getString(3), args.getJSONObject(4), args.getJSONObject(5));
      }
    } catch (JSONException e) {
      e.printStackTrace();
      return null;
    }
  }

  public static String[] parseScopes(final JSONArray scopes) {
    final ScopeParser scopeParser = new ScopeParser();
    try {
      return scopeParser.getScopesAsArray(scopes);
    } catch (JSONException e) {
      e.printStackTrace();
      return null;
    }
  }

  public ResourceRequest(final String path, final JSONArray scopes, final String requestMethodString, final String paramsEncodingString,
                         final JSONObject params) {
    this(path, scopes, requestMethodString, paramsEncodingString, params, null);
  }

  public ResourceRequest(final String path, final JSONArray scopes, final String requestMethodString, final String paramsEncodingString,
                         final JSONObject params, final JSONObject headers) {
    this.path = formatPaht(path);
    this.scopes = parseScopes(scopes);
    this.requestMethodString = requestMethodString;
    this.paramsEncodingString = paramsEncodingString;
    this.params = params;
    this.headers = headers;
  }

  public String getPath() {
    return path;
  }

  public String[] getScopes() {
    return scopes;
  }

  public String getRequestMethodString() {
    return requestMethodString;
  }

  public String getParamsEncodingString() {
    return paramsEncodingString;
  }

  public JSONObject getParams() {
    return params;
  }

  public boolean hasHeaders() {
    return headers != null;
  }

  public JSONObject getHeaders() {
    return headers;
  }

  private String formatPaht(String path) {
    if (path.startsWith("/")) {
      return path.replaceFirst("/", "");
    }
    return path;
  }

  public static Map<String, String> toMap(final JSONObject object) {
    final Map<String, String> map = new HashMap<>();
    final Iterator<String> keysItr = object.keys();

    try {
      while(keysItr.hasNext()) {
        final String key = keysItr.next();
        final String value;
          value = object.getString(key);
        map.put(key, value);
      }
    }
    catch (JSONException e) {
      return null;
    }
    return map;
  }
}