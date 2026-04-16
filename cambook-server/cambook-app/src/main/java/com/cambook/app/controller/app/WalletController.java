package com.cambook.app.controller.app;

import com.cambook.app.domain.dto.RechargeDTO;
import com.cambook.app.domain.dto.WithdrawDTO;
import com.cambook.app.domain.vo.WalletVO;
import com.cambook.app.service.app.IWalletService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * App 端 - 钱包
 *
 * @author CamBook
 */
@Tag(name = "App - 钱包")
@RestController
@RequestMapping("/app/wallet")
public class WalletController {

    private final IWalletService walletService;

    public WalletController(IWalletService walletService) {
        this.walletService = walletService;
    }

    @Operation(summary = "余额查询")
    @GetMapping
    public Result<WalletVO> balance() {
        return Result.success(walletService.getBalance());
    }

    @Operation(summary = "充值发起")
    @PostMapping("/recharge")
    public Result<String> recharge(@Valid @ModelAttribute RechargeDTO dto) {
        return Result.success(walletService.recharge(dto));
    }

    @Operation(summary = "提现申请")
    @PostMapping("/withdraw")
    public Result<Void> withdraw(@Valid @ModelAttribute WithdrawDTO dto) {
        walletService.withdraw(dto);
        return Result.success();
    }
}
