public class Microsoft365_UserData {
    public String federationId;
    public String userId;
    public String serviceResourceId;

    public Microsoft365_UserData() {
    }
    public Microsoft365_UserData setFederationId(String id) {
        this.federationId = id;
        return this;
    }
    public Microsoft365_UserData setUserId(String id) {
        this.userId = id;
        return this;
    }
    public Microsoft365_UserData setServiceResourceId(String id) {
        this.serviceResourceId = id;
        return this;
    }

    public override String toString() {
        return '[USERDATA - userId: ' + userId + ', federationId: ' + federationId + ']';
    }
}
