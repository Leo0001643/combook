package com.cambook.db.service.impl;

import com.cambook.db.entity.CbFinanceSalary;
import com.cambook.db.mapper.CbFinanceSalaryMapper;
import com.cambook.db.service.ICbFinanceSalaryService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 薪资单：覆盖员工工资和技师提成，支持按月汇总发放 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbFinanceSalaryServiceImpl extends ServiceImpl<CbFinanceSalaryMapper, CbFinanceSalary> implements ICbFinanceSalaryService {

}
