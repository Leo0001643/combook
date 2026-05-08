package com.cambook.app.controller.chat;

import com.cambook.app.common.context.ImCaller;
import com.cambook.app.domain.dto.chat.ImGroupSendDTO;
import com.cambook.app.domain.dto.chat.ImSendDTO;
import com.cambook.app.domain.vo.chat.ImMessageVO;
import com.cambook.app.service.chat.IImMessageService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "IM-消息")
@RestController
@RequestMapping("/chat/messages")
@RequiredArgsConstructor
public class ImMessageController {

    private final IImMessageService msgService;

    @Operation(summary = "发送单聊消息")
    @PostMapping("/send")
    public Result<Long> send(@Valid @RequestBody ImSendDTO dto) {
        ImCaller caller = ImCaller.current();
        return Result.success(msgService.sendMessage(caller.userType(), caller.userId(), dto));
    }

    @Operation(summary = "发送群聊消息")
    @PostMapping("/group/send")
    public Result<Long> groupSend(@Valid @RequestBody ImGroupSendDTO dto) {
        ImCaller caller = ImCaller.current();
        return Result.success(msgService.sendGroupMessage(caller.userType(), caller.userId(), dto));
    }

    @Operation(summary = "查询会话历史消息（倒序分页）")
    @GetMapping("/history")
    public Result<List<ImMessageVO>> history(
            @RequestParam Long conversationId,
            @RequestParam(defaultValue = "0") Long beforeMsgId,
            @RequestParam(defaultValue = "30") Integer limit) {
        return Result.success(msgService.history(conversationId, beforeMsgId, limit));
    }

    @Operation(summary = "拉取离线消息")
    @GetMapping("/offline")
    public Result<List<ImMessageVO>> offline(
            @RequestParam(defaultValue = "0") Long lastMsgId,
            @RequestParam(defaultValue = "50") Integer limit) {
        ImCaller caller = ImCaller.current();
        return Result.success(msgService.pullOffline(caller.userType(), caller.userId(), lastMsgId, limit));
    }

    @Operation(summary = "标记消息已读")
    @PostMapping("/read")
    public Result<Void> markRead(@RequestParam Long conversationId, @RequestParam Long lastReadMsgId) {
        ImCaller caller = ImCaller.current();
        msgService.markRead(conversationId, caller.userType(), caller.userId(), lastReadMsgId);
        return Result.success();
    }
}
