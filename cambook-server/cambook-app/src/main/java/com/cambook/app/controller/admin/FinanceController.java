package com.cambook.app.controller.admin;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbWallet;
import com.cambook.dao.entity.CbWalletRecord;
import com.cambook.dao.mapper.CbWalletMapper;
import com.cambook.dao.mapper.CbWalletRecordMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

/**
 * Admin 端 - 财务管理
 */
@Tag(name = "Admin - 财务管理")
@RestController
@RequestMapping("/admin/finance")
public class FinanceController {

    private final CbWalletMapper       walletMapper;
    private final CbWalletRecordMapper recordMapper;

    public FinanceController(CbWalletMapper walletMapper, CbWalletRecordMapper recordMapper) {
        this.walletMapper = walletMapper;
        this.recordMapper = recordMapper;
    }

    @RequirePermission("finance:list")
    @Operation(summary = "财务统计概览")
    @GetMapping("/overview")
    public Result<Map<String, Object>> overview() {
        BigDecimal totalBalance = walletMapper.selectList(null)
                .stream().map(CbWallet::getBalance)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        long totalRecords  = recordMapper.selectCount(null);
        long rechargeCount = recordMapper.selectCount(
                new LambdaQueryWrapper<CbWalletRecord>().eq(CbWalletRecord::getRecordType, 1));
        long withdrawCount = recordMapper.selectCount(
                new LambdaQueryWrapper<CbWalletRecord>().eq(CbWalletRecord::getRecordType, 3));

        BigDecimal totalRecharge = recordMapper.selectList(
                new LambdaQueryWrapper<CbWalletRecord>().eq(CbWalletRecord::getRecordType, 1))
                .stream().map(CbWalletRecord::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Object> data = new HashMap<>();
        data.put("totalBalance", totalBalance);
        data.put("totalRecords", totalRecords);
        data.put("rechargeCount", rechargeCount);
        data.put("withdrawCount", withdrawCount);
        data.put("totalRecharge", totalRecharge);
        return Result.success(data);
    }

    @RequirePermission("finance:list")
    @Operation(summary = "流水记录分页列表")
    @GetMapping("/records")
    public Result<PageResult<CbWalletRecord>> records(
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) Integer userType,
            @RequestParam(required = false) Integer recordType) {
        IPage<CbWalletRecord> page = recordMapper.selectPage(new Page<>(current, size),
                new LambdaQueryWrapper<CbWalletRecord>()
                        .eq(recordType != null, CbWalletRecord::getRecordType, recordType)
                        .orderByDesc(CbWalletRecord::getCreateTime));
        return Result.success(PageResult.of(page));
    }

    @RequirePermission("finance:list")
    @Operation(summary = "钱包列表")
    @GetMapping("/wallets")
    public Result<PageResult<CbWallet>> wallets(
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) Integer userType) {
        IPage<CbWallet> page = walletMapper.selectPage(new Page<>(current, size),
                new LambdaQueryWrapper<CbWallet>()
                        .eq(userType != null, CbWallet::getUserType, userType)
                        .orderByDesc(CbWallet::getBalance));
        return Result.success(PageResult.of(page));
    }
}
