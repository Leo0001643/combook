package com.cambook.chat.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * IM 配置属性（application.yml: cambook.im.*)
 */
@Data
@ConfigurationProperties(prefix = "cambook.im")
public class ImProperties {

    /** Netty WebSocket 监听端口 */
    private int port = 9090;

    /** WebSocket 路径 */
    private String path = "/ws/im";

    /** 当前节点 ID（建议配置为 hostname:port，用于跨节点路由） */
    private String nodeId = "node-1";

    /** 心跳超时（秒），超时未收到 PING 则断开 */
    private int heartbeatSeconds = 60;

    /** ACK 超时（秒），超时未收到 ACK 则重试 */
    private int ackTimeoutSeconds = 30;

    /** ACK 最大重试次数 */
    private int ackMaxRetry = 3;

    /** 上线时离线消息最大拉取条数 */
    private int offlinePullLimit = 50;

    /** ACK 重试批次大小（每次扫描最多处理条数） */
    private int ackRetryBatchSize = 200;

    /** 雪花算法数据中心 ID（0-31） */
    private int datacenterId = 1;

    /** 雪花算法机器 ID（0-31） */
    private int machineId = 1;

    /** 媒体单文件最大大小（字节，默认 100MB） */
    private long mediaMaxBytes = 100L * 1024 * 1024;

    /** 媒体存储类型：local / oss */
    private String storageType = "local";

    /** 本地存储根目录 */
    private String localStorePath = "/data/cambook/media";

    /** 本地存储访问 URL 前缀 */
    private String localStoreUrl = "http://127.0.0.1:8080/media";
}
