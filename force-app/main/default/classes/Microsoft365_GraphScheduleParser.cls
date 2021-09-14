public class Microsoft365_GraphScheduleParser {
    // constants
    public static final String STATE_TENTATIVE = 'tentative';
    public static final String STATE_BUSY = 'busy';
    public static final String STATE_FREE = 'free';

    private List<String> validStates = null;
    private Map<String, Integer> timezoneOffsets = null;
    private Map<String, Microsoft365_GraphScheduleParser.Schedule> results = new Map<String, Microsoft365_GraphScheduleParser.Schedule>();

    public Microsoft365_GraphScheduleParser() {
        this.validStates = new List<String>();
        this.validStates.add(STATE_TENTATIVE);
        this.validStates.add(STATE_BUSY);
    }

    public Microsoft365_GraphScheduleParser(List<String> validStates) {
        this.validStates = validStates;
    }

    public Microsoft365_GraphScheduleParser setTimezoneOffsets(Map<String, Integer> offsets) {
        this.timezoneOffsets = offsets;
        return this;
    }

    public void parse(String input, boolean parseWorkhours) {
        final Map<String, Object> parsedData = (Map<String, Object>) JSON.deserializeUntyped(input);
        final List<Object> values = (List<Object>) parsedData.get('value');

        for (Object value : values) {
            final Map<String, Object> scheduleObj = (Map<String, Object>) value;
            final String scheduleId = (String) scheduleObj.get('scheduleId');

            // create schedule
            final Schedule result = new Schedule(scheduleId);
            this.results.put(scheduleId, result);

            // see if an error
            final ScheduleError err = this.parseError(scheduleObj);
            if (null != err) {
                result.error = err;
                continue;
            }

            // get schedule items
            final List<Object> scheduleItems = (List<Object>) scheduleObj.get('scheduleItems');
            for (Object itemObj : scheduleItems) {
                final Map<String, Object> itemData = (Map<String, Object>) itemObj;
                final String status = (String) itemData.get('status');
                final DateTime startDt = this.getStartDateTime(itemData);
                final DateTime endDt = this.getEndDateTime(itemData);
                if (this.isStatusValid(status)) {
                    // add to result
                    result.items.add(new ScheduleItem(status, startDt, endDt));
                }
            }

            // see if we need to parse work hours from response
            if (parseWorkhours && null != this.timezoneOffsets) {
                // we do
                Map<String, Object> workingHours = (Map<String, Object>) scheduleObj.get('workingHours');
                if (null != workingHours) {
                    Integer startHour = Integer.valueOf(((String) workingHours.get('startTime')).substring(0, 2));
                    Integer endHour = Integer.valueOf(((String) workingHours.get('endTime')).substring(0, 2));
                    String timezone = (String) ((Map<String, Object>) workingHours.get('timeZone')).get('name');
                    Integer offset = this.timezoneOffsets.get(timezone);

                    Microsoft365_WorkHours.WorkHourSet whs = new Microsoft365_WorkHours.WorkHourSet();
                    whs.offsetMinutes = offset;
                    List<Object> daysOfWeek = (List<Object>) workingHours.get('daysOfWeek');
                    if (daysOfWeek.contains('monday'))
                        whs.put(Microsoft365_DateUtil.MONDAY, new Microsoft365_WorkHours.WorkHours(startHour, endHour));
                    if (daysOfWeek.contains('tuesday'))
                        whs.put(
                            Microsoft365_DateUtil.TUESDAY,
                            new Microsoft365_WorkHours.WorkHours(startHour, endHour)
                        );
                    if (daysOfWeek.contains('wednesday'))
                        whs.put(
                            Microsoft365_DateUtil.WEDNESDAY,
                            new Microsoft365_Workhours.WorkHours(startHour, endHour)
                        );
                    if (daysOfWeek.contains('thursday'))
                        whs.put(
                            Microsoft365_DateUtil.THURSDAY,
                            new Microsoft365_Workhours.WorkHours(startHour, endHour)
                        );
                    if (daysOfWeek.contains('friday'))
                        whs.put(Microsoft365_DateUtil.FRIDAY, new Microsoft365_Workhours.WorkHours(startHour, endHour));
                    if (daysOfWeek.contains('saturday'))
                        whs.put(
                            Microsoft365_DateUtil.SATURDAY,
                            new Microsoft365_Workhours.WorkHours(startHour, endHour)
                        );
                    if (daysOfWeek.contains('sunday'))
                        whs.put(Microsoft365_DateUtil.SUNDAY, new Microsoft365_Workhours.WorkHours(startHour, endHour));

                    // set in result
                    result.workingHours = whs;
                }
            }
        }
    }

    public Map<String, Microsoft365_GraphScheduleParser.Schedule> getSchedules() {
        return this.results;
    }

    public Microsoft365_GraphScheduleParser.Schedule getSchedule(String scheduleId) {
        return this.results.get(scheduleId);
    }

    private ScheduleError parseError(Map<String, Object> scheduleObj) {
        Map<String, Object> errorObj = (Map<String, Object>) scheduleObj.get('error');
        if (null == errorObj)
            return null;
        ScheduleError err = new ScheduleError((String) errorObj.get('responseCode'), (String) errorObj.get('message'));
        return err;
    }
    private boolean isStatusValid(String status) {
        return this.validStates == null || this.validStates.contains(status);
    }
    private DateTime getStartDateTime(Map<String, Object> itemData) {
        return this.getDateTime(itemData, 'start');
    }
    private DateTime getEndDateTime(Map<String, Object> itemData) {
        return this.getDateTime(itemData, 'end');
    }
    private DateTime getDateTime(Map<String, Object> itemData, String key) {
        final String strDt = (String) ((Map<String, Object>) itemData.get(key)).get('dateTime');
        final String strDate = strDt.substring(0, 10);
        final String strTime = strDt.substring(11, 19);
        final DateTime dt = DateTime.valueOfGmt(strDate + ' ' + strTime);
        return dt;
    }

    /**
     * Represents a schedule for a Service Resource as loaded from Microsoft 365
     */
    public class Schedule {
        public String scheduleId;
        public ScheduleError error;
        public List<ScheduleItem> items = new List<ScheduleItem>();
        public Microsoft365_Workhours.WorkHourSet workingHours;

        public Schedule(String scheduleId) {
            this.scheduleId = scheduleId;
        }

        public lxscheduler.ServiceResourceSchedule convert(String serviceResourceId) {
            // convert ScheduleItems to slots
            final Set<lxscheduler.UnavailableTimeslot> slots = new Set<lxscheduler.UnavailableTimeslot>();
            for (ScheduleItem item : this.items) {
                slots.add(item.convert());
            }

            // create result
            final lxscheduler.ServiceResourceSchedule result = new lxscheduler.ServiceResourceSchedule(
                serviceResourceId,
                slots
            );
            return result;
        }
    }

    /**
     * An individual item in a schedule.
     *
     */
    public class ScheduleItem {
        public String status;
        public DateTime startDt;
        public DateTime endDt;

        public ScheduleItem(String status, DateTime startDt, DateTime endDt) {
            this.status = status;
            this.startDt = startDt;
            this.endDt = endDt;
        }

        public lxscheduler.UnavailableTimeslot convert() {
            return new lxscheduler.UnavailableTimeslot(this.startDt, this.endDt);
        }

        public override String toString() {
            return '[SCHEDULEITEM - status <' +
                this.status +
                '> <' +
                Microsoft365_DateUtil.toUtcString(this.startDt) +
                '>-<' +
                Microsoft365_DateUtil.toUtcString(this.endDt) +
                '>]';
        }
    }

    public class ScheduleError {
        public String message;
        public String responseCode;

        public ScheduleError(String responseCode, String message) {
            this.responseCode = responseCode;
            this.message = message;
        }
    }
}
