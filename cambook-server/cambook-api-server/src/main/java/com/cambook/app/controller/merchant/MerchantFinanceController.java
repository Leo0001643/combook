package com.cambook.app.controller.merchant;

import com.cambook.app.service.merchant.IMerchantFinanceService;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 商户端 - 财务管理
 */
@Tag(name = "商户端 - 财务管理")
@RestController
@RequestMapping(value = "/merchant/finance", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class MerchantFinanceController {

    private final IMerchantFinanceService merchantFinanceService;

    @Operation(summary = "财务概览")
    @GetMapping(value = "/overview", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Map<String, Object>> overview() {
        return Result.success(merchantFinanceService.overview(MerchantContext.getMerchantId()));
    }
}
