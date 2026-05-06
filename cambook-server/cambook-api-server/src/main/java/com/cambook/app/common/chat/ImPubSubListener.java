package com.cambook.app.common.chat;

import com.cambook.chat.config.ImProperties;
import com.cambook.chat.protocol.ImPacket;
import com.cambook.chat.registry.ChannelRegistry;
import com.cambook.chat.routing.UserRouter;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.connection.Message;
import org.springframework.data.redis.connection.MessageListener;
import org.springframework.data.redis.listener.PatternTopic;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * Redis Pub/Sub 跨节点消息监听器
 *
 * <p>每个 Netty 节点订阅自己的频道 {@code im:pubsub:{nodeId}}，
 * 收到其他节点发布的消息后直接转发给本节点在线用户。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ImPubSubListener implements MessageListener {

    private final RedisMessageListenerContainer listenerContainer;
    private final ImProperties props;
    private final ChannelRegistry registry;
    private final ObjectMapper mapper;

    @PostConstruct
    public void subscribe() {
        String channel = UserRouter.pubSubChannel(props.getNodeId());
        listenerContainer.addMessageListener(this, new PatternTopic(channel));
        log.info("[PubSub] 订阅跨节点频道 {}", channel);
    }

    @Override
    @SuppressWarnings("unchecked")
    public void onMessage(Message message, byte[] pattern) {
        try {
            Map<String, Object> body = mapper.readValue(message.getBody(), Map.class);
            String toUserType = (String) body.get("toUserType");
            Long toUserId = ((Number) body.get("toUserId")).longValue();
            ImPacket packet = ImPacket.fromJson((String) body.get("packet"));
            if (packet == null) return;

            boolean sent = registry.send(toUserType, toUserId, packet);
            log.debug("[PubSub] 转发 {}:{} sent={}", toUserType, toUserId, sent);
        } catch (Exception e) {
            log.error("[PubSub] 消息处理异常: {}", e.getMessage());
        }
    }
}
