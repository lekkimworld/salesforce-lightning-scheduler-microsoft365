public class Microsoft365_WorkHours {
    public static List<Microsoft365_DateTimeInterval> workhoursToUnavailable(
        Microsoft365_Workhours.WorkHourSet whs,
        Microsoft365_DateTimeInterval interval,
        DstRuleSet dstRuleSet
    ) {
        final DateTime startDateTimeLocal = interval.startDt.addMinutes(whs.offsetMinutes);
        final DateTime endDateTimeLocal = interval.endDt.addMinutes(whs.offsetMinutes);
        final List<Microsoft365_DateTimeInterval> results = new List<Microsoft365_DateTimeInterval>();

        DateTime workDt = DateTime.newInstance(startDateTimeLocal.getTime());
        while (workDt.getTime() < endDateTimeLocal.getTime()) {
            final Integer workDow = Microsoft365_DateUtil.dow(workDt);
            WorkHours wh = whs.get(workDow);
            if (null == wh) {
                // user does not work this day
                DateTime dtStart = DateTime.newInstanceGmt(workDt.date(), Time.newInstance(0, 0, 0, 0))
                    .addMinutes(-1 * whs.offsetMinutes);
                if (null != dstRuleSet && dstRuleSet.isDst(dtStart)) {
                    dtStart = dtStart.addHours(-1);
                }
                DateTime dtEnd = DateTime.newInstanceGmt(workDt.date(), Time.newInstance(0, 0, 0, 0))
                    .addDays(1)
                    .addMinutes(-1 * whs.offsetMinutes);
                if (null != dstRuleSet && dstRuleSet.isDst(dtEnd)) {
                    dtEnd = dtEnd.addHours(-1);
                }
                results.add(new Microsoft365_DateTimeInterval(dtStart, dtEnd));
            } else {
                // user works on this day
                WorkHours whTomorrow = whs.get(Math.mod((workDow + 1), 7));

                DateTime dtMorningStart = DateTime.newInstanceGmt(workDt.date(), Time.newInstance(0, 0, 0, 0))
                    .addMinutes(-1 * whs.offsetMinutes);
                if (null != dstRuleSet && dstRuleSet.isDst(dtMorningStart))
                    dtMorningStart = dtMorningStart.addHours(-1);

                DateTime dtMorningEnd = DateTime.newInstanceGmt(
                        workDt.date(),
                        Time.newInstance(null == whTomorrow ? 0 : whTomorrow.startHour, 0, 0, 0)
                    )
                    .addMinutes(-1 * whs.offsetMinutes);
                if (null != dstRuleSet && dstRuleSet.isDst(dtMorningEnd))
                    dtMorningEnd = dtMorningEnd.addHours(-1);

                DateTime dtAfternoonStart = DateTime.newInstanceGmt(
                        workDt.date(),
                        Time.newInstance(wh.endHour, 0, 0, 0)
                    )
                    .addMinutes(-1 * whs.offsetMinutes);
                if (null != dstRuleSet && dstRuleSet.isDst(dtAfternoonStart))
                    dtAfternoonStart = dtAfternoonStart.addHours(-1);

                DateTime dtAfternoonEnd = DateTime.newInstanceGmt(workDt.date(), Time.newInstance(0, 0, 0, 0))
                    .addDays(1)
                    .addMinutes(-1 * whs.offsetMinutes);
                if (null != dstRuleSet && dstRuleSet.isDst(dtAfternoonEnd))
                    dtAfternoonEnd = dtAfternoonEnd.addHours(-1);

                results.add(new Microsoft365_DateTimeInterval(dtMorningStart, dtMorningEnd));
                results.add(new Microsoft365_DateTimeInterval(dtAfternoonStart, dtAfternoonEnd));
            }

            workDt = workDt.addDays(1);
        }
        return results;
    }

    public class WorkHourSet {
        public Integer offsetMinutes = 0;
        public Map<Integer, Microsoft365_WorkHours.WorkHours> workhours = new Map<Integer, Microsoft365_WorkHours.WorkHours>();

        public Microsoft365_WorkHours.WorkHours get(Integer dow) {
            return this.workhours.get(dow);
        }

        public void put(Integer dow, Microsoft365_WorkHours.WorkHours wh) {
            this.workhours.put(dow, wh);
        }

        public override String toString() {
            return '[WorkHourSet - offsetMinutes <' +
                this.offsetMinutes +
                '> SUN <' +
                this.workhours.get(Microsoft365_DateUtil.SUNDAY) +
                '> MON <' +
                this.workhours.get(Microsoft365_DateUtil.MONDAY) +
                '> TUES <' +
                this.workhours.get(Microsoft365_DateUtil.TUESDAY) +
                '> WED <' +
                this.workhours.get(Microsoft365_DateUtil.WEDNESDAY) +
                '> THUR <' +
                this.workhours.get(Microsoft365_DateUtil.THURSDAY) +
                '> FRI <' +
                this.workhours.get(Microsoft365_DateUtil.FRIDAY) +
                '> SAT <' +
                this.workhours.get(Microsoft365_DateUtil.SATURDAY) +
                '>]';
        }
    }

    public class WorkHours {
        public Integer startHour;
        public Integer endHour;

        public WorkHours(Integer startHour, Integer endHour) {
            this.startHour = startHour;
            this.endHour = endHour;
        }
    }

    public class DstRule {
        public Integer dow = Microsoft365_DateUtil.SUNDAY;
        public Integer offset = -1;
        public Integer hour = 2;
        public Integer month;
        public DstRule(Integer month) {
            this.month = month;
        }
        public DstRule(Integer month, Integer offset) {
            this(month);
            this.offset = offset;
        }
    }
    public class DstRuleSet {
        public Microsoft365_DateTimeInterval interval;

        public DstRuleSet(Integer year, DstRule ruleStart, DstRule ruleEnd) {
            DateTime dtStart = this.dstDateTimeFromRule(year, ruleStart);
            DateTime dtEnd = this.dstDateTimeFromRule(year, ruleEnd);
            this.interval = new Microsoft365_DateTimeInterval(dtStart, dtEnd);
        }

        public boolean isDst(DateTime dt) {
            return this.interval.contains(dt);
        }

        private DateTime dstDateTimeFromRule(Integer year, DstRule rule) {
            DateTime dtResult = null;
            if (rule.offset < 0) {
                // start from behind
                dtResult = DateTime.newInstanceGmt(year, rule.month, 1, rule.hour, 0, 0).addMonths(1).addDays(-1);
                while (Microsoft365_DateUtil.dow(dtResult) != rule.dow)
                    dtResult = dtResult.addDays(-1);
                dtResult = dtResult.addDays((rule.offset + 1) * 7);
            } else {
                // start from beginning
                dtResult = DateTime.newInstanceGmt(year, rule.month, 1, rule.hour, 0, 0);
                while (Microsoft365_DateUtil.dow(dtResult) != rule.dow)
                    dtResult = dtResult.addDays(1);
                dtResult = dtResult.addDays((rule.offset - 1) * 7);
            }
            return dtResult;
        }
    }
}
