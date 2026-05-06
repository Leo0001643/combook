package com.cambook.chat.spi;

import com.cambook.chat.protocol.ImPacket;
import io.netty.channel.ChannelHandlerContext;

/**
 * IM 业务分发接口（SPI）
 *
 * <p>cambook-chat-server 只负责网络层（连接/编解码/路由），
 * 具体业务（消息持久化、ACK、群组等）由 cambook-api-server 实现此接口。
 *
 * <p>实现类应标注 {@code @Component} 以便注入到 Netty Handler。
 */
public interface ImDispatcher {

    /**
     * 用户鉴权成功，上线通知（可拉取离线消息）
     *
     * @param ctx      Netty 上下文
     * @param userType 用户类型（member/technician/merchant）
     * @param userId   用户 ID
     */
    void onUserOnline(ChannelHandlerContext ctx, String userType, Long userId);

    /**
     * 用户断线下线
     */
    void onUserOffline(String userType, Long userId);

    /**
     * 处理客户端发送的消息（单聊/群聊/信令等）
     *
     * @param ctx    Netty 上下文
     * @param sender 发送者（userType:userId）
     * @param packet 原始协议包
     */
    void onMessage(ChannelHandlerContext ctx, String sender, ImPacket packet);
}
