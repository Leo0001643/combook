package com.cambook.app.service.chat.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.cambook.app.service.chat.IImMsgAckService;
import com.cambook.db.entity.ImMsgAck;
import com.cambook.db.mapper.ImMsgAckMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * IM 消息 ACK 服务实现
 */
@Service
@RequiredArgsConstructor
public class ImMsgAckServiceImpl extends ServiceImpl<ImMsgAckMapper, ImMsgAck>
    implements IImMsgAckService {

    private final ImMsgAckMapper ackMapper;

    @Override
    public void insertOrIgnore(ImMsgAck ack) {
        ackMapper.insertOrIgnore(ack);
    }
}
