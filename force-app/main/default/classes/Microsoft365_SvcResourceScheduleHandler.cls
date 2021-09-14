public class Microsoft365_SvcResourceScheduleHandler implements lxscheduler.ServiceResourceScheduleHandler {
    public List<lxscheduler.ServiceResourceSchedule> getUnavailableTimeslots(
        lxscheduler.ServiceAppointmentRequestInfo requestInfo
    ) {
        // define dst rule set
        //FIXME DstRuleSet should be able to figure out the year itself
        final Microsoft365_WorkHours.DstRuleSet dstRuleSet = new Microsoft365_WorkHours.DstRuleSet(
            2021,
            new Microsoft365_WorkHours.DstRule(3, -1),
            new Microsoft365_WorkHours.DstRule(10, -1)
        );

        // get user data for requested service resources
        final Set<String> userIds = new Set<String>();
        for (lxscheduler.ServiceResourceInfo info : requestInfo.getServiceResources()) {
            userIds.add(info.getUserId());
        }
        final Map<Id, User> users = new Map<Id, User>([SELECT Id, FederationIdentifier FROM User WHERE Id IN :userIds]);

        // build translation table
        final Map<String, Microsoft365_UserData> userdata = new Map<String, Microsoft365_UserData>();
        for (lxscheduler.ServiceResourceInfo info : requestInfo.getServiceResources()) {
            User u = users.get(info.getUserId());
            Microsoft365_UserData d = new Microsoft365_UserData()
                .setFederationId(u.FederationIdentifier)
                .setUserId(u.Id)
                .setServiceResourceId(info.getServiceResourceId());
            System.debug('Processing Service Resource: ' + d);
            userdata.put(info.getServiceResourceId(), d);
        }

        //  load schedules
        final Microsoft365_DateTimeInterval interval = new Microsoft365_DateTimeInterval(
            requestInfo.getStartDate(),
            requestInfo.getEndDate()
        );
        final Map<String, Microsoft365_GraphScheduleParser.Schedule> schedules = Microsoft365_GraphScheduleLoader.loadSchedules(
            interval,
            userdata.values(),
            true
        );

        // define result
        final List<lxscheduler.ServiceResourceSchedule> results = new List<lxscheduler.ServiceResourceSchedule>();

        // loop schedules and return
        for (lxscheduler.ServiceResourceInfo info : requestInfo.getServiceResources()) {
            Microsoft365_UserData d = userdata.get(info.getServiceResourceId());

            // convert and add as result
            Microsoft365_GraphScheduleParser.Schedule s = schedules.get(d.federationId);
            if (null != s.error) {
                // error for schedule
                System.debug(
                    'Error for service resource (' +
                    d +
                    '): ' +
                    s.error.message +
                    ' (' +
                    s.error.responseCode +
                    ')'
                );
            } else {
                // found schedule for service resource - convert to a service resource schedule
                lxscheduler.ServiceResourceSchedule result = s.convert(d.serviceResourceId);

                // if working hours found add those as unavailable
                if (null != s.workingHours) {
                    final List<Microsoft365_DateTimeInterval> workhoursUnavailable = Microsoft365_WorkHours.workhoursToUnavailable(
                        s.workingHours,
                        new Microsoft365_DateTimeInterval(requestInfo.getStartDate(), requestInfo.getEndDate()),
                        dstRuleSet
                    );
                    for (Microsoft365_DateTimeInterval dt : workhoursUnavailable) {
                        result.unavailableTimeslots.add(new lxscheduler.UnavailableTimeslot(dt.startDt, dt.endDt));
                    }
                }

                // add result
                results.add(result);
            }
        }

        // return
        return results;
    }
}
