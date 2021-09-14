public class Microsoft365_Cache {
    public final static String MAIN_PARTITION = 'microsoft365lxsched';
    public final static String KEY_ACCESS_TOKEN = 'accesstoken';
    public final static String KEY_TIMEZONES = 'windowstimezones';

    private static Cache.OrgPartition getPartition() {
        return Cache.Org.getPartition(MAIN_PARTITION);
    }

    private static void setInCache(String key, Object value) {
        Cache.OrgPartition orgPart = getPartition();
        System.debug('Cache STORE key: ' + key);
        orgPart.put(key, value);
    }

    private static Object getFromCache(String key) {
        final Cache.OrgPartition orgPart = getPartition();
        final Object value = orgPart.get(key);
        if (null == value) {
            System.debug('Cache HIT/MISS - MISS on key: ' + key);
        } else {
            System.debug('Cache HIT/MISS - HIT on key: ' + key);
        }
        return value;
    }

    public static String getAccessToken() {
        AccessTokenWrapper atw = (AccessTokenWrapper) getFromCache(KEY_ACCESS_TOKEN);
        if (null == atw || atw.isExpired()) {
            String at = retrieveAccessToken();
            atw = new AccessTokenWrapper(at);
            setInCache(KEY_ACCESS_TOKEN, atw);
        }
        return atw.getAccessToken();
    }

    public static Map<String, Integer> getTimezoneOffsets(Microsoft365_UserData userdata) {
        return getTimezoneOffsets(userdata, false);
    }

    /**
     * Returns a map of Azure timezone alias to minutes of UTC offset.
     *
     * @param userdata User data to use when querying the Microsoft API
     * @param forceRefresh Force refresh the platform cache
     */
    public static Map<String, Integer> getTimezoneOffsets(Microsoft365_UserData userdata, boolean forceRefresh) {
        // get cache
        Map<String, Integer> result = (Map<String, Integer>) getFromCache(KEY_TIMEZONES);
        if (null == result || forceRefresh) {
            // get access token
            final String access_token = Microsoft365_Cache.getAccessToken();

            // load timezones
            final String httpdata = Microsoft365_HttpUtil.get(userdata, '/outlook/supportedTimeZones');
            result = new Map<String, Integer>();
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(httpdata);
            for (Object obj : (List<Object>) data.get('value')) {
                Map<String, Object> objMap = (Map<String, Object>) obj;
                String alias = (String) objMap.get('alias');
                String displayName = (String) objMap.get('displayName');
                Integer offset = 0;
                if (displayName.indexOf('(UTC)') < 0) {
                    boolean add = displayName.substring(4, 5) == '+';
                    Integer hours = Integer.valueOf(displayName.substring(5, 7));
                    Integer minutes = Integer.valueOf(displayName.substring(8, 10));
                    offset = (hours * 60) + minutes;
                }
                result.put(alias, offset);
            }

            // store in cache
            setInCache(KEY_TIMEZONES, result);
        }
        return result;
    }

    private class AccessTokenWrapper {
        private String accessToken;
        private DateTime expiresAt;

        public AccessTokenWrapper(String accessToken) {
            this.accessToken = accessToken;
            String[] parts = accessToken.split('\\.');
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(
                EncodingUtil.base64Decode(parts[1]).toString()
            );
            Long exp = (Long) data.get('exp');
            this.expiresAt = DateTime.newInstance(exp * 1000);
            System.debug('Constructing AccessTokenWrapper - expires at (UTC): ' + this.expiresAt);
        }

        public String getAccessToken() {
            return this.accessToken;
        }

        public boolean isExpired() {
            return this.expiresAt.getTime() <= DateTime.now().getTime();
        }
    }

    private static String retrieveAccessToken() {
        final List<Microsoft_365_Graph_API_Config__mdt> cmds = [
            SELECT Id, MasterLabel, Client_ID__c, Tenant_ID__c, Certificate_Thumbprint__c, Certificate_Name__c
            FROM Microsoft_365_Graph_API_Config__mdt
            WHERE MasterLabel = 'Default'
        ];
        if (cmds.size() != 1)
            throw new Microsoft365_Exception('Unable to find a single record of Microsoft_365_Graph_API_Config__mdt');
        Microsoft_365_Graph_API_Config__mdt cmd = cmds.get(0);
        final String azureClientId = cmd.Client_ID__c;
        final String azureTenantId = cmd.Tenant_ID__c;
        final String azureCertName = cmd.Certificate_Name__c;
        final String azureCertThumbprint = cmd.Certificate_Thumbprint__c;
        final String azureScopes = 'https://graph.microsoft.com/.default';

        // create JWT with certificate from keys mgmt and set the x5t in the header to the
        // thumbprint of the cert as expected by Azure
        AzureJWT jwt = new AzureJWT();
        jwt.cert = azureCertName;
        jwt.iss = azureClientId;
        jwt.sub = azureClientId;
        jwt.aud = 'https://login.microsoftonline.com/' + azureTenantId + '/oauth2/v2.0/token';
        jwt.x5t = azureCertThumbprint;

        // invoke the flow and obtain an access_token
        final String access_token = AzureJWTBearerFlow.getAccessToken(azureClientId, azureTenantId, azureScopes, jwt);
        return access_token;
    }

    public class Microsoft365_Exception extends Exception {
    }
}
