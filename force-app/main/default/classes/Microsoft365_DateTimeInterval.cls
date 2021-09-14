public class Microsoft365_DateTimeInterval {
    public DateTime startDt;
    public DateTime endDt;

    public Microsoft365_DateTimeInterval(DateTime s, DateTime e) {
        this.startDt = s;
        this.endDt = e;
    }

    public boolean contains(DateTime dt) {
        final Long dtLong = dt.getTime();
        return this.startDt.getTime() <= dtLong && this.endDt.getTime() > dtLong;
    }

    public override String toString() {
        return formatDt(this.startDt) + ' - ' + formatDt(this.endDt);
    }

    /**
     * Format date/time to string
     */
    private String formatDt(DateTime dt) {
        return dt.format('yyyy-MM-dd HH:mm', 'UTC');
    }
}
