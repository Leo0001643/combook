package com.cambook.app.controller.chat;

import com.cambook.app.domain.vo.chat.ImConversationVO;
import com.cambook.app.service.chat.IImConversationService;
import com.cambook.common.context.MemberContext;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * IM 会话接口
 */
@Tag(name = "IM-会话", description = "会话列表、会话详情")
@RestController
@RequestMapping(value = "/app/chat/conversation", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class ImConversationController {

    private final IImConversationService convService;

    @Operation(summary = "获取我的会话列表（按最后消息时间倒序）")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<ImConversationVO>> list() {
        return Result.success(convService.listConversations(MemberContext.getUserType(), MemberContext.getMemberId()));
    }

    @Operation(summary = "获取单个会话详情")
    @GetMapping(value = "/{conversationId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<ImConversationVO> get(@PathVariable Long conversationId) {
        return Result.success(convService.getConversation(conversationId, MemberContext.getUserType(), MemberContext.getMemberId()));
    }
}
