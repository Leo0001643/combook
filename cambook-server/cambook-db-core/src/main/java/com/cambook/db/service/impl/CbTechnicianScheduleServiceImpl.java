package com.cambook.db.service.impl;

import com.cambook.db.entity.CbTechnicianSchedule;
import com.cambook.db.mapper.CbTechnicianScheduleMapper;
import com.cambook.db.service.ICbTechnicianScheduleService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 技师排班表：记录技师可接单时间段，用于冲突检测和前端展示 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbTechnicianScheduleServiceImpl extends ServiceImpl<CbTechnicianScheduleMapper, CbTechnicianSchedule> implements ICbTechnicianScheduleService {

}
