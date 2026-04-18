package com.cambook.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.dao.entity.CbOrderItem;
import org.apache.ibatis.annotations.Mapper;

/**
 * 在线订单服务项明细 Mapper
 *
 * @author CamBook
 */
@Mapper
public interface CbOrderItemMapper extends BaseMapper<CbOrderItem> {
}
