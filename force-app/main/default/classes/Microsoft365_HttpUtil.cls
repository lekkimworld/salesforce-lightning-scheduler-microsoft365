public class Microsoft365_HttpUtil {
    public static final String METHOD_GET = 'GET';
    public static final String METHOD_POST = 'POST';
    public static final String ENDPOINT_GRAPH_BASE = 'https://graph.microsoft.com/v1.0';

    public static String makeRequest(String method, String endpoint, Map<String, String> headers, String body) {
        // get access token
        final String access_token = Microsoft365_Cache.getAccessToken();

        // setup request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        if (null != headers) {
            for (String key : headers.keySet()) {
                String value = headers.get(key);
                req.setHeader(key, value);
            }
        }
        req.setHeader('Authorization', 'Bearer ' + access_token);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        if (null != body && supportsBody(method)) {
            req.setBody(body);
        }

        // make request
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res.getBody();
    }

    public static String get(Microsoft365_UserData userdata, String path) {
        String endpoint = Microsoft365_HttpUtil.ENDPOINT_GRAPH_BASE + '/users/' + userdata.federationId + path;
        return makeRequest(METHOD_GET, endpoint, null, null);
    }

    public static String get(String endpoint) {
        return makeRequest(METHOD_GET, endpoint, null, null);
    }

    public static String post(Microsoft365_UserData userdata, String path, Map<String, String> headers, String body) {
        String endpoint = Microsoft365_HttpUtil.ENDPOINT_GRAPH_BASE + '/users/' + userdata.federationId + path;
        return post(endpoint, headers, body);
    }
    public static String post(String endpoint, Map<String, String> headers, String body) {
        return makeRequest(METHOD_POST, endpoint, headers, body);
    }

    private static boolean supportsBody(String method) {
        return METHOD_POST.equals(method);
    }
}
