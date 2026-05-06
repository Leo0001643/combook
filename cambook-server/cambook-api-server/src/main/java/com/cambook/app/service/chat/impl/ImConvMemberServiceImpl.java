package com.cambook.app.service.chat.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.cambook.app.service.chat.IImConvMemberService;
import com.cambook.db.entity.ImConvMember;
import com.cambook.db.mapper.ImConvMemberMapper;
import org.springframework.stereotype.Service;

/**
 * IM 会话成员服务实现
 */
@Service
public class ImConvMemberServiceImpl extends ServiceImpl<ImConvMemberMapper, ImConvMember>
    implements IImConvMemberService {
}
