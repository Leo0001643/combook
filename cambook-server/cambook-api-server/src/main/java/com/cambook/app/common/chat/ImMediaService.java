package com.cambook.app.common.chat;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.cambook.app.domain.vo.chat.ImMediaVO;
import com.cambook.chat.config.ImProperties;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.utils.DateUtils;
import com.cambook.db.entity.ImMedia;
import com.cambook.db.mapper.ImMediaMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * IM 媒体文件服务
 *
 * <p>策略通过 {@code cambook.im.storage-type} 切换：
 * <ul>
 *   <li>{@code local}：本地文件系统，路径 {localStorePath}/{type}/yyyy/MM/dd/uuid.ext</li>
 *   <li>{@code oss}：阿里云 OSS（预留扩展，配置后替换）</li>
 * </ul>
 *
 * <p>上传前校验文件大小和 MIME 类型，防止恶意文件写入。
 */
@Slf4j
@Service
public class ImMediaService extends ServiceImpl<ImMediaMapper, ImMedia> {

    /** 各类型允许的 MIME 前缀 */
    private static final Map<String, Set<String>> ALLOWED_MIMES = Map.of(
        "image", Set.of("image/jpeg", "image/png", "image/gif", "image/webp"),
        "voice", Set.of("audio/mpeg", "audio/mp4", "audio/aac", "audio/ogg", "audio/wav", "audio/amr"),
        "video", Set.of("video/mp4", "video/quicktime", "video/x-msvideo", "video/webm"),
        "file",  Set.of()   // file 类型不限 MIME
    );

    @Autowired private ImProperties props;

    public ImMediaVO upload(MultipartFile file, String fileType,
                            String uploaderType, Long uploaderId) throws IOException {
        validate(file, fileType);
        return "oss".equalsIgnoreCase(props.getStorageType())
            ? uploadToOss(file, fileType, uploaderType, uploaderId)
            : uploadToLocal(file, fileType, uploaderType, uploaderId);
    }


    private void validate(MultipartFile file, String fileType) {
        if (file == null || file.isEmpty()) throw new BusinessException("文件不能为空");

        if (file.getSize() > props.getMediaMaxBytes())
            throw new BusinessException("文件超过最大限制 " + (props.getMediaMaxBytes() / 1024 / 1024) + "MB");

        Set<String> allowed = ALLOWED_MIMES.getOrDefault(fileType, Set.of());
        String mime = file.getContentType();
        if (!allowed.isEmpty() && (mime == null || !allowed.contains(mime.toLowerCase())))
            throw new BusinessException("不支持的文件类型: " + mime + "，允许: " + allowed);
    }


    private ImMediaVO uploadToLocal(MultipartFile file, String fileType, String uploaderType, Long uploaderId) throws IOException {
        String date = LocalDate.now().toString().replace("-", "/");
        String ext = extension(file.getOriginalFilename());
        String filename = UUID.randomUUID().toString().replace("-", "") + (ext.isEmpty() ? "" : "." + ext);
        String relative = fileType + "/" + date + "/" + filename;

        Path dir = Paths.get(props.getLocalStorePath(), fileType, date);
        Files.createDirectories(dir);
        file.transferTo(dir.resolve(filename).toFile());

        String url = props.getLocalStoreUrl() + "/" + relative;
        log.info("[Media] 本地上传成功 {} -> {}", file.getOriginalFilename(), relative);
        return persist(file, fileType, uploaderType, uploaderId, "local", relative, url);
    }

    // ── OSS 存储（预留扩展） ──────────────────────────────────────────────────

    private ImMediaVO uploadToOss(MultipartFile file, String fileType, String uploaderType, Long uploaderId) {
        // TODO: 集成 OSS SDK（配置 endpoint / bucket / accessKey 后替换此实现）
        throw new BusinessException("OSS 存储尚未配置，请设置 cambook.im.storage-type=local 或配置 OSS");
    }

    // ── 私有方法 ──────────────────────────────────────────────────────────────

    private ImMediaVO persist(MultipartFile file, String fileType, String uploaderType, Long uploaderId, String storageType, String path, String url) {
        ImMedia m = new ImMedia();
        m.setUploaderType(uploaderType); m.setUploaderId(uploaderId);
        m.setFileType(fileType); m.setOriginalName(file.getOriginalFilename());
        m.setStorageType(storageType); m.setStoragePath(path);
        m.setFileUrl(url); m.setFileSize(file.getSize());
        m.setMimeType(file.getContentType()); m.setCreateTime(DateUtils.nowSecond());
        save(m);

        ImMediaVO vo = new ImMediaVO();
        vo.setId(m.getId()); vo.setFileType(fileType);
        vo.setOriginalName(m.getOriginalName()); vo.setFileUrl(url);
        vo.setFileSize(m.getFileSize()); vo.setMimeType(m.getMimeType());
        return vo;
    }

    private String extension(String filename) {
        if (filename == null || !filename.contains(".")) return "";
        return filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();
    }
}
