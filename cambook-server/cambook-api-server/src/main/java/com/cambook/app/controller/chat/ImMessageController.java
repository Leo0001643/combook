package com.cambook.app.controller.chat;

import com.cambook.app.domain.dto.chat.ImGroupSendDTO;
import com.cambook.app.domain.dto.chat.ImSendDTO;
import com.cambook.app.domain.vo.chat.ImMessageVO;
import com.cambook.app.service.chat.IImMessageService;
import com.cambook.common.context.MemberContext;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * IM 消息接口
 */
@Tag(name = "IM-消息", description = "单聊/群聊发送、历史记录、离线消息拉取、已读标记")
@RestController
@RequestMapping(value = "/app/chat/message", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class ImMessageController {

    private final IImMessageService msgService;

    @Operation(summary = "发送单聊消息")
    @PostMapping(value = "/send", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Long> send(@Valid @RequestBody ImSendDTO dto) {
        return Result.success(msgService.sendMessage(MemberContext.getUserType(), MemberContext.getMemberId(), dto));
    }

    @Operation(summary = "发送群聊消息")
    @PostMapping(value = "/group/send", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Long> groupSend(@Valid @RequestBody ImGroupSendDTO dto) {
        return Result.success(msgService.sendGroupMessage(MemberContext.getUserType(), MemberContext.getMemberId(), dto));
    }

    @Operation(summary = "查询会话历史消息（倒序分页）")
    @GetMapping(value = "/history", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<ImMessageVO>> history(@RequestParam Long conversationId,
                                              @RequestParam(defaultValue = "0") Long beforeMsgId,
                                              @RequestParam(defaultValue = "30") Integer limit) {
        return Result.success(msgService.history(conversationId, beforeMsgId, limit));
    }

    @Operation(summary = "拉取离线消息")
    @GetMapping(value = "/offline", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<ImMessageVO>> offline(@RequestParam(defaultValue = "0") Long lastMsgId,
                                              @RequestParam(defaultValue = "50") Integer limit) {
        return Result.success(msgService.pullOffline(MemberContext.getUserType(), MemberContext.getMemberId(), lastMsgId, limit));
    }

    @Operation(summary = "标记消息已读")
    @PostMapping(value = "/read", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> markRead(@RequestParam Long conversationId, @RequestParam Long lastReadMsgId) {
        msgService.markRead(conversationId, MemberContext.getUserType(), MemberContext.getMemberId(), lastReadMsgId);
        return Result.success();
    }
}
