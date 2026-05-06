package com.cambook.db.service.impl;

import com.cambook.db.entity.CbFinanceExpense;
import com.cambook.db.mapper.CbFinanceExpenseMapper;
import com.cambook.db.service.ICbFinanceExpenseService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 支出记录：覆盖店租、车辆、水电、工资、采购、营销等全类目 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbFinanceExpenseServiceImpl extends ServiceImpl<CbFinanceExpenseMapper, CbFinanceExpense> implements ICbFinanceExpenseService {

}
