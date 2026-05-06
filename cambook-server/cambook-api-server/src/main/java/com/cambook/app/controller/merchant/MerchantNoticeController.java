package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.service.biz.NoticeService;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.db.entity.SysNotice;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.MediaType;

/**
 * 商户端 - 通知公告（薄包装层）
 *
 * <p>复用 {@link NoticeService}，注入 merchantId 实现数据隔离。
 * {@code @RequireMerchant} 切面自动完成身份 + URI 双重安全校验。
 *
 * @author CamBook
 */
@RequireMerchant
@Tag(name = "商户端 - 通知公告")
@RestController
@RequestMapping("/merchant/notice")
public class MerchantNoticeController {

    private final NoticeService noticeService;

    public MerchantNoticeController(NoticeService noticeService) {
        this.noticeService = noticeService;
    }

    @Operation(summary = "公告列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<SysNotice>> list(
            @RequestParam(defaultValue = "1")  int     page,
            @RequestParam(defaultValue = "10") int     size,
            @RequestParam(required = false)    String  keyword,
            @RequestParam(required = false)    Integer type,
            @RequestParam(required = false)    Integer status) {
        return Result.success(noticeService.pageList(requireMerchantId(), page, size, keyword, type, status));
    }

    @Operation(summary = "新增公告")
    @PostMapping(value = "/add", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@RequestParam String  title,
                            @RequestParam String  content,
                            @RequestParam(defaultValue = "1") Integer type) {
        noticeService.add(requireMerchantId(), title, content, type);
        return Result.success();
    }

    @Operation(summary = "编辑公告")
    @PostMapping(value = "/edit", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@RequestParam Long    id,
                             @RequestParam(required = false) String  title,
                             @RequestParam(required = false) String  content,
                             @RequestParam(required = false) Integer type) {
        noticeService.edit(requireMerchantId(), id, title, content, type);
        return Result.success();
    }

    @Operation(summary = "发布/撤回公告")
    @PostMapping(value = "/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(@RequestParam Long id, @RequestParam Integer status) {
        noticeService.updateStatus(requireMerchantId(), id, status);
        return Result.success();
    }

    @Operation(summary = "删除公告")
    @PostMapping(value = "/delete", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@RequestParam Long id) {
        noticeService.delete(requireMerchantId(), id);
        return Result.success();
    }

    private Long requireMerchantId() {
        return MerchantOwnershipGuard.requireMerchantId();
    }
}
