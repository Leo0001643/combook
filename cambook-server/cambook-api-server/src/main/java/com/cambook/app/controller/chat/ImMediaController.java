package com.cambook.app.controller.chat;

import com.cambook.app.common.chat.ImMediaService;
import com.cambook.app.domain.vo.chat.ImMediaVO;
import com.cambook.common.context.MemberContext;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * IM 媒体文件上传接口
 *
 * <p>客户端先上传媒体文件拿到 URL，再将 URL 写入消息 content 发送；
 * IM 链路本身只传文本（URL），不传二进制数据。
 */
@Tag(name = "IM-媒体", description = "图片/语音/视频文件上传，返回 URL 供消息引用")
@RestController
@RequestMapping(value = "/app/chat/media", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class ImMediaController {

    private final ImMediaService mediaService;

    @Operation(summary = "上传图片")
    @PostMapping(value = "/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<ImMediaVO> image(@RequestParam("file") MultipartFile file) throws Exception {
        return Result.success(mediaService.upload(file, "image", MemberContext.getUserType(), MemberContext.getMemberId()));
    }

    @Operation(summary = "上传语音")
    @PostMapping(value = "/voice", consumes = MediaType.MULTIPART_FORM_DATA_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<ImMediaVO> voice(@RequestParam("file") MultipartFile file) throws Exception {
        return Result.success(mediaService.upload(file, "voice", MemberContext.getUserType(), MemberContext.getMemberId()));
    }

    @Operation(summary = "上传视频")
    @PostMapping(value = "/video", consumes = MediaType.MULTIPART_FORM_DATA_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<ImMediaVO> video(@RequestParam("file") MultipartFile file) throws Exception {
        return Result.success(mediaService.upload(file, "video", MemberContext.getUserType(), MemberContext.getMemberId()));
    }

    @Operation(summary = "上传文件")
    @PostMapping(value = "/file", consumes = MediaType.MULTIPART_FORM_DATA_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<ImMediaVO> file(@RequestParam("file") MultipartFile file) throws Exception {
        return Result.success(mediaService.upload(file, "file", MemberContext.getUserType(), MemberContext.getMemberId()));
    }
}
