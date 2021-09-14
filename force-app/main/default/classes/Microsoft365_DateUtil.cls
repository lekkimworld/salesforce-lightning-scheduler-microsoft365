public class Microsoft365_DateUtil {
    // constants
    public static final Integer SUNDAY = 0;
    public static final Integer MONDAY = 1;
    public static final Integer TUESDAY = 2;
    public static final Integer WEDNESDAY = 3;
    public static final Integer THURSDAY = 4;
    public static final Integer FRIDAY = 5;
    public static final Integer SATURDAY = 6;
    private static final Integer EPOCH_DOW = THURSDAY;
    private static final Integer MS_PER_HOUR = 60 * 60 * 1000;
    private static final Integer MS_PER_DAY = 24 * MS_PER_HOUR;

    /**
     * Returns the constant for the day of the week.
     */
    public static Integer dow(DateTime d) {
        Integer offset = 0;
        Double x = Math.mod((d.getTime() + offset) / MS_PER_DAY + EPOCH_DOW, 7);
        return (Integer) Math.floor(x);
    }

    public static String toUtcString(DateTime dt) {
        return dt.formatGMT('yyyy-MM-dd HH:mm:ss \'Z\'');
    }
}
