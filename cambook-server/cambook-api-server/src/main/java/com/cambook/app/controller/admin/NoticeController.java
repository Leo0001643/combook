package com.cambook.app.controller.admin;

import com.cambook.app.service.biz.NoticeService;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.db.entity.SysNotice;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.MediaType;

/**
 * Admin 端 - 通知公告管理
 * 委托 {@link NoticeService} 统一处理，merchantId=null 表示平台级公告。
 */
@Tag(name = "Admin - 通知公告")
@RestController
@RequestMapping("/admin/notice")
public class NoticeController {

    private final NoticeService noticeService;

    public NoticeController(NoticeService noticeService) {
        this.noticeService = noticeService;
    }

    @RequirePermission("notice:list")
    @Operation(summary = "公告分页列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<SysNotice>> list(
            @RequestParam(defaultValue = "1")  int     current,
            @RequestParam(defaultValue = "10") int     size,
            @RequestParam(required = false)    String  title,
            @RequestParam(required = false)    Integer type,
            @RequestParam(required = false)    Integer status) {
        return Result.success(noticeService.pageList(null, current, size, title, type, status));
    }

    @RequirePermission("notice:add")
    @Operation(summary = "新增公告")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@RequestParam String  title,
                            @RequestParam Integer type,
                            @RequestParam(required = false)        String  content,
                            @RequestParam(defaultValue = "1")      Integer status) {
        noticeService.add(null, title, content, type);
        return Result.success();
    }

    @RequirePermission("notice:edit")
    @Operation(summary = "修改公告")
    @PutMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@RequestParam Long    id,
                             @RequestParam(required = false) String  title,
                             @RequestParam(required = false) Integer type,
                             @RequestParam(required = false) String  content) {
        noticeService.edit(null, id, title, content, type);
        return Result.success();
    }

    @RequirePermission("notice:delete")
    @Operation(summary = "删除公告")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        noticeService.delete(null, id);
        return Result.success();
    }
}
