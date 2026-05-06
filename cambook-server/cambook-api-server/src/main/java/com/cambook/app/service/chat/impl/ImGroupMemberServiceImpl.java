package com.cambook.app.service.chat.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.cambook.app.service.chat.IImGroupMemberService;
import com.cambook.db.entity.ImGroupMember;
import com.cambook.db.mapper.ImGroupMemberMapper;
import org.springframework.stereotype.Service;

/**
 * IM 群成员服务实现
 */
@Service
public class ImGroupMemberServiceImpl extends ServiceImpl<ImGroupMemberMapper, ImGroupMember>
    implements IImGroupMemberService {
}
