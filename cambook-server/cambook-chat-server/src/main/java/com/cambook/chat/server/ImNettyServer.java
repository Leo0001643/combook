package com.cambook.chat.server;

import com.cambook.chat.config.ImProperties;
import com.cambook.chat.handler.ImWsHandler;
import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.*;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.codec.http.HttpObjectAggregator;
import io.netty.handler.codec.http.HttpServerCodec;
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler;
import io.netty.handler.stream.ChunkedWriteHandler;
import io.netty.handler.timeout.IdleStateHandler;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.concurrent.TimeUnit;

/**
 * Netty WebSocket IM 网关（随 Spring Boot 启动，监听独立端口，默认 9090）
 *
 * <p>Pipeline：HttpServerCodec → HttpObjectAggregator → ChunkedWriteHandler
 *              → IdleStateHandler → WebSocketServerProtocolHandler → ImWsHandler
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ImNettyServer {

    private final ImProperties props;
    private final ImWsHandler  wsHandler;

    private EventLoopGroup bossGroup;
    private EventLoopGroup workerGroup;
    private Channel        serverChannel;

    @PostConstruct
    public void start() throws InterruptedException {
        bossGroup   = new NioEventLoopGroup(1);
        workerGroup = new NioEventLoopGroup();

        ChannelFuture future = new ServerBootstrap()
            .group(bossGroup, workerGroup)
            .channel(NioServerSocketChannel.class)
            .option(ChannelOption.SO_BACKLOG, 1024)
            .childOption(ChannelOption.TCP_NODELAY, true)
            .childOption(ChannelOption.SO_KEEPALIVE, true)
            .childHandler(new ChannelInitializer<SocketChannel>() {
                @Override
                protected void initChannel(SocketChannel ch) {
                    ch.pipeline()
                        .addLast(new HttpServerCodec())
                        .addLast(new HttpObjectAggregator(65536))
                        .addLast(new ChunkedWriteHandler())
                        .addLast(new IdleStateHandler(props.getHeartbeatSeconds() * 2, 0, 0, TimeUnit.SECONDS))
                        .addLast(new WebSocketServerProtocolHandler(props.getPath()))
                        .addLast(wsHandler);
                }
            })
            .bind(props.getPort()).sync();

        serverChannel = future.channel();
        log.info("[ImNetty] IM 网关启动 port={} path={} nodeId={}",
            props.getPort(), props.getPath(), props.getNodeId());
    }

    @PreDestroy
    public void stop() {
        log.info("[ImNetty] 关闭 IM 网关...");
        if (serverChannel != null) serverChannel.close();
        if (bossGroup   != null) bossGroup.shutdownGracefully();
        if (workerGroup != null) workerGroup.shutdownGracefully();
    }
}
