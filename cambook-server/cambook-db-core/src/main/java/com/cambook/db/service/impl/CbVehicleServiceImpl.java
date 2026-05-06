package com.cambook.db.service.impl;

import com.cambook.db.entity.CbVehicle;
import com.cambook.db.mapper.CbVehicleMapper;
import com.cambook.db.service.ICbVehicleService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 车辆表：记录车辆资产信息，状态跟踪，支持派单车辆管理 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbVehicleServiceImpl extends ServiceImpl<CbVehicleMapper, CbVehicle> implements ICbVehicleService {

}
