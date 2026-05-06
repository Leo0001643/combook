package com.cambook.chat.registry;

import com.cambook.chat.protocol.ImPacket;
import io.netty.channel.Channel;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.concurrent.ConcurrentHashMap;

/**
 * 本地节点 Channel 注册表
 *
 * <p>Key: {@code "{userType}:{userId}"}，同一用户新连接自动踢掉旧连接（单点登录）。
 */
@Slf4j
@Component
public class ChannelRegistry {

    private final ConcurrentHashMap<String, Channel> channels = new ConcurrentHashMap<>(1024);

    /** 注册 Channel，若已有旧连接则踢下线 */
    public void register(String userType, Long userId, Channel channel) {
        String key = key(userType, userId);
        Channel old = channels.put(key, channel);
        if (old != null && old.isActive()) {
            old.writeAndFlush(new TextWebSocketFrame(ImPacket.kick("other device login").toJson()));
            old.close();
            log.info("[Registry] 踢出旧连接 key={}", key);
        }
        log.info("[Registry] 注册 key={} channelId={}", key, channel.id());
    }

    /** 注销 Channel（仅当 channel 与已注册的一致时才移除，防止新连接被旧断开事件误清除） */
    public void unregister(String userType, Long userId, Channel channel) {
        channels.remove(key(userType, userId), channel);
    }

    /** 推送消息，返回是否成功（用户离线返回 false） */
    public boolean send(String userType, Long userId, ImPacket packet) {
        Channel ch = channels.get(key(userType, userId));
        if (ch == null || !ch.isActive()) return false;
        ch.writeAndFlush(new TextWebSocketFrame(packet.toJson()));
        return true;
    }

    public boolean isOnline(String userType, Long userId) {
        Channel ch = channels.get(key(userType, userId));
        return ch != null && ch.isActive();
    }

    public int onlineCount() { return channels.size(); }

    public static String key(String userType, Long userId) { return userType + ":" + userId; }
}
