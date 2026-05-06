package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbAddress;

/**
 * <p>
 * 用户服务地址表：支持多地址管理，下单时快照至订单 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface CbAddressMapper extends BaseMapper<CbAddress> {

}
