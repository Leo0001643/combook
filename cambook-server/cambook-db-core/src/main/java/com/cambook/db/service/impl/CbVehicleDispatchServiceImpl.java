package com.cambook.db.service.impl;

import com.cambook.db.entity.CbVehicleDispatch;
import com.cambook.db.mapper.CbVehicleDispatchMapper;
import com.cambook.db.service.ICbVehicleDispatchService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 派车记录：记录每次车辆使用情况，支持多维度查询 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbVehicleDispatchServiceImpl extends ServiceImpl<CbVehicleDispatchMapper, CbVehicleDispatch> implements ICbVehicleDispatchService {

}
