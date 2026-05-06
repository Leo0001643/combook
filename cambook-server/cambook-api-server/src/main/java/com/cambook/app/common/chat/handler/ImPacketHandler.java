package com.cambook.app.common.chat.handler;

import com.cambook.chat.protocol.ImPacket;
import io.netty.channel.ChannelHandlerContext;

import java.util.Set;

/**
 * IM 消息包处理器 SPI
 *
 * <p>每个实现类负责一种（或一组）命令码的处理逻辑，
 * 通过 {@link #cmds()} 声明感兴趣的命令码。
 * {@link com.cambook.app.common.chat.ImBusinessDispatcher} 启动时自动扫描所有实现 Bean，
 * 构建 {@code Map<cmd, handler>}，新增命令类型只需新增 Handler Bean，符合开闭原则。
 */
public interface ImPacketHandler {

    /** 该 Handler 支持的命令码集合（允许一个 Handler 处理多个相关命令） */
    Set<Integer> cmds();

    /**
     * 处理消息包
     *
     * @param ctx        Netty Channel 上下文（用于回写）
     * @param senderType 发送方用户类型
     * @param senderId   发送方用户 ID
     * @param packet     原始协议包
     */
    void handle(ChannelHandlerContext ctx, String senderType, Long senderId, ImPacket packet);
}
