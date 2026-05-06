package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbTechnicianSchedule;

/**
 * <p>
 * 技师排班表：记录技师可接单时间段，用于冲突检测和前端展示 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface CbTechnicianScheduleMapper extends BaseMapper<CbTechnicianSchedule> {

}
