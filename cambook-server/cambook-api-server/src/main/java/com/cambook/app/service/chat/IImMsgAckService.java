package com.cambook.app.service.chat;

import com.baomidou.mybatisplus.extension.service.IService;
import com.cambook.db.entity.ImMsgAck;

/**
 * IM 消息 ACK 服务
 */
public interface IImMsgAckService extends IService<ImMsgAck> {

    /** 幂等插入 ACK 记录（忽略重复，等价于 INSERT IGNORE） */
    void insertOrIgnore(ImMsgAck ack);
}
