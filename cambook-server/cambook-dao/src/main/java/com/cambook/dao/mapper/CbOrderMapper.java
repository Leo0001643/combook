package com.cambook.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.dao.entity.CbOrder;
import org.apache.ibatis.annotations.Mapper;

/**
 * 订单 Mapper
 *
 * @author CamBook
 */
@Mapper
public interface CbOrderMapper extends BaseMapper<CbOrder> {
}
