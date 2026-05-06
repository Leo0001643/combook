package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbTechnician;

/**
 * <p>
 * 技师表：包含认证资料/多语言简介/服务能力/收入统计，合并设计避免连表 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface CbTechnicianMapper extends BaseMapper<CbTechnician> {

}
