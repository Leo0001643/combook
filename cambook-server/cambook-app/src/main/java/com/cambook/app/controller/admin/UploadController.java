package com.cambook.app.controller.admin;

import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.time.LocalDate;
import java.util.UUID;

/**
 * 文件上传接口 - 本地存储
 *
 * <p>上传图片/视频到服务器本地磁盘，返回可访问的 URL。
 * 生产环境可替换为 OSS/S3 存储，只需替换本类实现即可（OCP）。
 *
 * @author CamBook
 */
@Tag(name = "Admin - 文件上传")
@RestController
@RequestMapping("/admin/upload")
public class UploadController {

    @Value("${cambook.upload.path}")
    private String uploadPath;

    @Value("${cambook.upload.url-prefix}")
    private String urlPrefix;

    private static final long MAX_IMAGE_SIZE = 10 * 1024 * 1024L; // 10MB
    private static final long MAX_VIDEO_SIZE = 200 * 1024 * 1024L; // 200MB

    @Operation(summary = "上传图片（头像/封面/证件等）")
    @PostMapping("/image")
    public Result<String> uploadImage(@RequestParam("file") MultipartFile file) {
        validateFile(file, MAX_IMAGE_SIZE, new String[]{"jpg", "jpeg", "png", "gif", "webp"});
        String url = saveFile(file, "images");
        return Result.success(url);
    }

    @Operation(summary = "上传视频（技师/商户展示视频）")
    @PostMapping("/video")
    public Result<String> uploadVideo(@RequestParam("file") MultipartFile file) {
        validateFile(file, MAX_VIDEO_SIZE, new String[]{"mp4", "mov", "avi", "webm"});
        String url = saveFile(file, "videos");
        return Result.success(url);
    }

    // ── private ─────────────────────────────────────────────────────────────

    private void validateFile(MultipartFile file, long maxSize, String[] allowedExts) {
        if (file == null || file.isEmpty()) {
            throw new com.cambook.common.exception.BusinessException("文件不能为空");
        }
        if (file.getSize() > maxSize) {
            throw new com.cambook.common.exception.BusinessException(
                    "文件大小超限，最大允许 " + (maxSize / 1024 / 1024) + "MB");
        }
        String ext = getExtension(file.getOriginalFilename());
        boolean ok = false;
        for (String a : allowedExts) {
            if (a.equalsIgnoreCase(ext)) { ok = true; break; }
        }
        if (!ok) {
            throw new com.cambook.common.exception.BusinessException("不支持的文件格式: " + ext);
        }
    }

    private String saveFile(MultipartFile file, String subDir) {
        // 按日期分目录，避免单目录文件过多
        String dateDir = LocalDate.now().toString().replace("-", "/");
        String ext     = getExtension(file.getOriginalFilename());
        String filename = UUID.randomUUID().toString().replace("-", "") + "." + ext;
        String relativePath = subDir + "/" + dateDir + "/" + filename;

        File dest = new File(uploadPath + "/" + relativePath);
        dest.getParentFile().mkdirs();
        try {
            file.transferTo(dest);
        } catch (IOException e) {
            throw new com.cambook.common.exception.BusinessException("文件保存失败: " + e.getMessage());
        }
        return urlPrefix + "/" + relativePath;
    }

    private String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) return "";
        return filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();
    }
}
