package com.cambook.db.service.impl;

import com.cambook.db.entity.CbMember;
import com.cambook.db.mapper.CbMemberMapper;
import com.cambook.db.service.ICbMemberService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 会员表：账号+钱包+等级三合一设计，避免频繁连表 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbMemberServiceImpl extends ServiceImpl<CbMemberMapper, CbMember> implements ICbMemberService {

}
