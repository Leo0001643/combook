package com.cambook.app.controller.chat;

import com.cambook.app.common.context.ImCaller;
import com.cambook.app.domain.vo.chat.ImContactGroupVO;
import com.cambook.app.domain.vo.chat.ImContactVO;
import com.cambook.app.service.chat.IImContactService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * IM 通讯录接口 — 无需加好友，基于权限矩阵自动生成可沟通对象列表。
 */
@Tag(name = "IM-通讯录")
@RestController
@RequestMapping("/chat/contacts")
@RequiredArgsConstructor
public class ImContactController {

    private final IImContactService contactService;

    @Operation(summary = "获取通讯录（按角色分组）")
    @GetMapping
    public Result<List<ImContactGroupVO>> contacts() {
        ImCaller caller = ImCaller.current();
        return Result.success(contactService.contacts(caller.userType(), caller.userId(), caller.merchantId()));
    }

    @Operation(summary = "搜索通讯录")
    @GetMapping("/search")
    public Result<List<ImContactVO>> search(@RequestParam String keyword) {
        ImCaller caller = ImCaller.current();
        return Result.success(contactService.search(caller.userType(), caller.userId(), caller.merchantId(), keyword));
    }

    @Operation(summary = "触发自动建会话（业务系统调用）")
    @PostMapping("/auto-conv")
    public Result<Long> autoConv(@RequestParam String senderType,
                                  @RequestParam Long senderId,
                                  @RequestParam String receiverType,
                                  @RequestParam Long receiverId,
                                  @RequestParam(required = false) String sysNote) {
        Long convId = contactService.autoCreateConversation(
                senderType, senderId, receiverType, receiverId,
                ImCaller.current().merchantId(), sysNote);
        return Result.success(convId);
    }
}
