package com.cambook.app.controller.chat;

import com.cambook.app.domain.dto.chat.ImCreateGroupDTO;
import com.cambook.app.domain.vo.chat.ImGroupVO;
import com.cambook.app.service.chat.IImGroupService;
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
 * IM 群组接口
 */
@Tag(name = "IM-群组", description = "创建群、加入/退出群、解散群、群详情")
@RestController
@RequestMapping(value = "/app/chat/group", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class ImGroupController {

    private final IImGroupService groupService;

    @Operation(summary = "创建群组")
    @PostMapping(value = "/create", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Long> create(@Valid @RequestBody ImCreateGroupDTO dto) {
        return Result.success(groupService.createGroup(MemberContext.getUserType(), MemberContext.getMemberId(), dto));
    }

    @Operation(summary = "加入群组")
    @PostMapping(value = "/{groupId}/join", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> join(@PathVariable Long groupId) {
        groupService.joinGroup(groupId, MemberContext.getUserType(), MemberContext.getMemberId());
        return Result.success();
    }

    @Operation(summary = "退出群组")
    @PostMapping(value = "/{groupId}/quit", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> quit(@PathVariable Long groupId) {
        groupService.quitGroup(groupId, MemberContext.getUserType(), MemberContext.getMemberId());
        return Result.success();
    }

    @Operation(summary = "解散群组（仅群主）")
    @PostMapping(value = "/{groupId}/dismiss", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> dismiss(@PathVariable Long groupId) {
        groupService.dismissGroup(groupId, MemberContext.getUserType(), MemberContext.getMemberId());
        return Result.success();
    }

    @Operation(summary = "获取群组详情（含成员列表）")
    @GetMapping(value = "/{groupId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<ImGroupVO> info(@PathVariable Long groupId) {
        return Result.success(groupService.getGroupInfo(groupId));
    }

    @Operation(summary = "查询我加入的群组列表")
    @GetMapping(value = "/my", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<ImGroupVO>> myGroups() {
        return Result.success(groupService.listMyGroups(MemberContext.getUserType(), MemberContext.getMemberId()));
    }
}
