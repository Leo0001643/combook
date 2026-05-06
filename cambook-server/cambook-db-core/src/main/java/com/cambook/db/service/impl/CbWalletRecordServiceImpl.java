package com.cambook.db.service.impl;

import com.cambook.db.entity.CbWalletRecord;
import com.cambook.db.mapper.CbWalletRecordMapper;
import com.cambook.db.service.ICbWalletRecordService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 钱包流水表：记录会员/技师/商户每笔资金变动，含余额快照 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbWalletRecordServiceImpl extends ServiceImpl<CbWalletRecordMapper, CbWalletRecord> implements ICbWalletRecordService {

}
