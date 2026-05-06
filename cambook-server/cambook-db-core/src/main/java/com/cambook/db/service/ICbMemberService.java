package com.cambook.db.service;

import com.cambook.db.entity.CbMember;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 会员表：账号+钱包+等级三合一设计，避免频繁连表 服务类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface ICbMemberService extends IService<CbMember> {

}
