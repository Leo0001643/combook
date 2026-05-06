package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.domain.dto.AnnouncementSaveDTO;
import com.cambook.app.service.merchant.IMerchantAnnouncementService;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.db.entity.MerchantAnnouncement;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.apache.commons.lang3.StringUtils;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 商户端 - 公告管理
 */
@RequireMerchant
@Tag(name = "商户端 - 公告管理")
@RestController
@RequestMapping(value = "/merchant/announce", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class MerchantAnnouncementController {

    private final IMerchantAnnouncementService merchantAnnouncementBizService;

    @Operation(summary = "公告列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<MerchantAnnouncement>> list(
            @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "15") int size,
            @RequestParam(required = false) Integer type, @RequestParam(required = false) Integer status,
            @RequestParam(required = false) String keyword) {
        return Result.success(merchantAnnouncementBizService.list(MerchantOwnershipGuard.requireMerchantId(), page, size, type, status, keyword));
    }

    @Operation(summary = "新增公告")
    @PostMapping(value = "/add", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@Valid @RequestBody AnnouncementSaveDTO dto) {
        merchantAnnouncementBizService.add(MerchantOwnershipGuard.requireMerchantId(), MerchantContext.getMerchantName(), dto);
        return Result.success();
    }

    @Operation(summary = "编辑公告")
    @PostMapping(value = "/edit", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@Valid @RequestBody AnnouncementSaveDTO dto) {
        merchantAnnouncementBizService.edit(MerchantOwnershipGuard.requireMerchantId(), dto);
        return Result.success();
    }

    @Operation(summary = "发布 / 撤回公告")
    @PostMapping(value = "/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(@RequestParam Long id, @RequestParam Integer status) {
        merchantAnnouncementBizService.updateStatus(MerchantOwnershipGuard.requireMerchantId(), id, status);
        return Result.success();
    }

    @Operation(summary = "删除公告")
    @PostMapping(value = "/delete", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@RequestParam Long id) {
        merchantAnnouncementBizService.delete(MerchantOwnershipGuard.requireMerchantId(), id);
        return Result.success();
    }

    @Operation(summary = "内部公告未读数（铃铛轮询）")
    @GetMapping(value = "/unread-count", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Long> unreadCount() {
        return Result.success(merchantAnnouncementBizService.unreadCount(MerchantOwnershipGuard.requireMerchantId(), requireMobile()));
    }

    @Operation(summary = "未读公告列表（铃铛弹窗）")
    @GetMapping(value = "/unread-list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<MerchantAnnouncement>> unreadList() {
        return Result.success(merchantAnnouncementBizService.unreadList(MerchantOwnershipGuard.requireMerchantId(), requireMobile()));
    }

    @Operation(summary = "标记公告已读")
    @PostMapping(value = "/read", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Long> markRead(@RequestParam Long id) {
        return Result.success(merchantAnnouncementBizService.markRead(MerchantOwnershipGuard.requireMerchantId(), requireMobile(), id));
    }

    private String requireMobile() {
        String mobile = MerchantContext.getMobile();
        if (StringUtils.isBlank(mobile)) throw new BusinessException(CbCodeEnum.TOKEN_INVALID);
        return mobile;
    }
}
