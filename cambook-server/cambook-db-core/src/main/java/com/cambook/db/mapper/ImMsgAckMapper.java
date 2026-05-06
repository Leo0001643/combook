package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.ImMsgAck;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ImMsgAckMapper extends BaseMapper<ImMsgAck> {

    /**
     * INSERT IGNORE：msg_id + user_type + user_id 复合主键已存在时静默跳过，
     * 天然实现 ACK 幂等，无需先 select 再 insert。
     */
    @Insert("INSERT IGNORE INTO im_msg_ack(msg_id, user_type, user_id, ack_type, ack_time) " +
            "VALUES(#{msgId}, #{userType}, #{userId}, #{ackType}, #{ackTime})")
    int insertOrIgnore(ImMsgAck ack);
}
