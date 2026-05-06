package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbFinanceSalary;

/**
 * <p>
 * 薪资单：覆盖员工工资和技师提成，支持按月汇总发放 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface CbFinanceSalaryMapper extends BaseMapper<CbFinanceSalary> {

}
