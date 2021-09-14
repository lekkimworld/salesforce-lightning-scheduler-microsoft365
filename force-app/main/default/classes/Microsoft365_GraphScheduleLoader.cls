public class Microsoft365_GraphScheduleLoader {
    public static Map<String, Microsoft365_GraphScheduleParser.Schedule> loadSchedules(
        Microsoft365_DateTimeInterval interval,
        List<Microsoft365_UserData> userdata,
        boolean includeWorkhours
    ) {
        // convert date/times
        final String startDateTimeISO = getIsoDateTime(interval.startDt);
        final String endDateTimeISO = getIsoDateTime(interval.endDt);

        //  create list of federation IDS
        final List<String> federationIds = new List<String>();
        for (Microsoft365_UserData u : userdata)
            federationIds.add(u.federationId);
        final String strUserList = String.join(federationIds, '","');

        // get schedules from Microsoft 365
        final String requestBody =
            '{"Schedules": ["' +
            strUserList +
            '"],"StartTime": {"dateTime": "' +
            startDateTimeISO +
            '","timeZone": "UTC"},"EndTime": {"dateTime": "' +
            endDateTimeISO +
            '","timeZone": "UTC"},"availabilityViewInterval": "15"}';
        final Map<String, String> headers = new Map<String, String>();
        headers.put('Prefer', 'outlook.timezone="UTC"');
        final String responseBody = Microsoft365_HttpUtil.post(
            userdata.get(0),
            '/calendar/getschedule',
            headers,
            requestBody
        );

        // get timezone offsets (using first user as all reuqests run for a user)
        Map<String, Integer> timezoneOffsets = Microsoft365_Cache.getTimezoneOffsets(userdata.get(0));

        // parse schedules (including workhours)
        final Microsoft365_GraphScheduleParser p = new Microsoft365_GraphScheduleParser();
        if (includeWorkhours)
            p.setTimezoneOffsets(timezoneOffsets);
        p.parse(responseBody, includeWorkhours);

        // return
        return p.getSchedules();
    }

    private static String getIsoDateTime(DateTime dt) {
        return dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
    }
}
