package com.cambook.app.controller.chat;

import com.cambook.app.common.context.ImCaller;
import com.cambook.app.domain.vo.chat.ImConversationVO;
import com.cambook.app.service.chat.IImConversationService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "IM-会话")
@RestController
@RequestMapping("/chat/conversations")
@RequiredArgsConstructor
public class ImConversationController {

    private final IImConversationService convService;

    @Operation(summary = "获取我的会话列表（按最后消息时间倒序）")
    @GetMapping
    public Result<List<ImConversationVO>> list() {
        ImCaller caller = ImCaller.current();
        return Result.success(convService.listConversations(caller.userType(), caller.userId()));
    }

    @Operation(summary = "获取单个会话详情")
    @GetMapping("/{conversationId}")
    public Result<ImConversationVO> get(@PathVariable Long conversationId) {
        ImCaller caller = ImCaller.current();
        return Result.success(convService.getConversation(conversationId, caller.userType(), caller.userId()));
    }
}
