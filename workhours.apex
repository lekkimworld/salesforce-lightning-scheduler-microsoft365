final DateTime startDateTimeUtc = DateTime.valueOfGmt('2021-04-30 7:00:00');
final DateTime endDateTimeUtc = DateTime.valueOfGmt('2021-05-07 15:00:00');

List<Microsoft365_UserData> userdata = new List<Microsoft365_UserData>();
userdata.add(new Microsoft365_UserData().setFederationId('mheisterberg@snlxscheddemo.onmicrosoft.com'));
Map<String, Microsoft365_GraphScheduleParser.Schedule> schedules = Microsoft365_GraphScheduleLoader.loadSchedules(
    new Microsoft365_DateTimeInterval(startDateTimeUtc, endDateTimeUtc),
    userdata,
    true
);
Microsoft365_GraphScheduleParser.Schedule sched = schedules.get('mheisterberg@snlxscheddemo.onmicrosoft.com');
System.debug(sched.workingHours);
for (Microsoft365_GraphScheduleParser.ScheduleItem item : sched.items) {
    System.debug(item);
}
