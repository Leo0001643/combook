package com.cambook.db.service;

import com.cambook.db.entity.CbTechnicianSchedule;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 技师排班表：记录技师可接单时间段，用于冲突检测和前端展示 服务类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface ICbTechnicianScheduleService extends IService<CbTechnicianSchedule> {

}
