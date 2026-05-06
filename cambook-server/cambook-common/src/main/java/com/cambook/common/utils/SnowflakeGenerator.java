package com.cambook.common.utils;

/**
 * 雪花算法 ID 生成器（线程安全）
 *
 * <p>64-bit layout:
 * <pre>
 * | sign(1) | timestamp(41) | datacenterId(5) | machineId(5) | sequence(12) |
 * </pre>
 * 理论 QPS：4096 * 1000 = 4,096,000/s（每毫秒最多 4096 个 ID）
 */
public class SnowflakeGenerator {

    private static final long EPOCH          = 1700000000000L; // 2023-11-15 基准时间
    private static final long DC_BITS        = 5L;
    private static final long MACHINE_BITS   = 5L;
    private static final long SEQ_BITS       = 12L;

    private static final long MAX_DC      = ~(-1L << DC_BITS);
    private static final long MAX_MACHINE = ~(-1L << MACHINE_BITS);
    private static final long MAX_SEQ     = ~(-1L << SEQ_BITS);

    private static final long MACHINE_SHIFT = SEQ_BITS;
    private static final long DC_SHIFT      = SEQ_BITS + MACHINE_BITS;
    private static final long TS_SHIFT      = SEQ_BITS + MACHINE_BITS + DC_BITS;

    private final long datacenterId;
    private final long machineId;

    private long lastTs  = -1L;
    private long sequence = 0L;

    public SnowflakeGenerator(long datacenterId, long machineId) {
        if (datacenterId < 0 || datacenterId > MAX_DC) throw new IllegalArgumentException("datacenterId out of range");
        if (machineId    < 0 || machineId    > MAX_MACHINE) throw new IllegalArgumentException("machineId out of range");
        this.datacenterId = datacenterId;
        this.machineId    = machineId;
    }

    public synchronized long nextId() {
        long ts = System.currentTimeMillis();
        if (ts < lastTs) throw new RuntimeException("Clock moved backwards, refusing to generate id");
        if (ts == lastTs) {
            sequence = (sequence + 1) & MAX_SEQ;
            if (sequence == 0) ts = waitNextMs(lastTs);
        } else {
            sequence = 0L;
        }
        lastTs = ts;
        return ((ts - EPOCH) << TS_SHIFT) | (datacenterId << DC_SHIFT) | (machineId << MACHINE_SHIFT) | sequence;
    }

    private long waitNextMs(long lastTs) {
        long ts;
        do { ts = System.currentTimeMillis(); } while (ts <= lastTs);
        return ts;
    }
}
