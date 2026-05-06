package com.cambook.db.service.impl;

import com.cambook.db.entity.CbTechnician;
import com.cambook.db.mapper.CbTechnicianMapper;
import com.cambook.db.service.ICbTechnicianService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 技师表：包含认证资料/多语言简介/服务能力/收入统计，合并设计避免连表 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbTechnicianServiceImpl extends ServiceImpl<CbTechnicianMapper, CbTechnician> implements ICbTechnicianService {

}
