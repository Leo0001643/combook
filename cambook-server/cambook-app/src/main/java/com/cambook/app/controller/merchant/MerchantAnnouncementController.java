package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.MerchantAnnouncement;
import com.cambook.dao.entity.MerchantAnnouncementRead;
import com.cambook.dao.mapper.MerchantAnnouncementMapper;
import com.cambook.dao.mapper.MerchantAnnouncementReadMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.apache.commons.lang3.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 商户端 - 公告管理
 *
 * <p>内部公告（type=1）面向员工；客户公告（type=2）面向会员。
 * 铃铛未读数仅统计内部公告，通过 {@code /unread-count} 轮询。
 *
 * @author CamBook
 */
@RequireMerchant
@Tag(name = "商户端 - 公告管理")
@RestController
@RequestMapping("/merchant/announce")
public class MerchantAnnouncementController {

    private final MerchantAnnouncementMapper     announceMapper;
    private final MerchantAnnouncementReadMapper readMapper;

    public MerchantAnnouncementController(MerchantAnnouncementMapper announceMapper,
                                          MerchantAnnouncementReadMapper readMapper) {
        this.announceMapper = announceMapper;
        this.readMapper     = readMapper;
    }

    // ── CRUD ─────────────────────────────────────────────────────────────────

    @Operation(summary = "公告列表")
    @GetMapping("/list")
    public Result<PageResult<MerchantAnnouncement>> list(
            @RequestParam(defaultValue = "1")  int     page,
            @RequestParam(defaultValue = "15") int     size,
            @RequestParam(required = false)    Integer type,
            @RequestParam(required = false)    Integer status,
            @RequestParam(required = false)    String  keyword) {
        Long merchantId = requireMerchantId();

        LambdaQueryWrapper<MerchantAnnouncement> w = new LambdaQueryWrapper<MerchantAnnouncement>()
                .eq(MerchantAnnouncement::getMerchantId, merchantId)
                .eq(type   != null, MerchantAnnouncement::getType,   type)
                .eq(status != null, MerchantAnnouncement::getStatus, status)
                .and(StringUtils.isNotBlank(keyword), q -> q
                        .like(MerchantAnnouncement::getTitle,   keyword)
                        .or().like(MerchantAnnouncement::getContent, keyword))
                .orderByDesc(MerchantAnnouncement::getCreateTime);

        Page<MerchantAnnouncement> p = announceMapper.selectPage(new Page<>(page, size), w);
        return Result.success(PageResult.of(p.getRecords(), p.getTotal(), page, size));
    }

    @Operation(summary = "新增公告")
    @PostMapping("/add")
    public Result<Void> add(
            @RequestParam          String  title,
            @RequestParam          String  content,
            @RequestParam(defaultValue = "1") Integer type,
            @RequestParam(defaultValue = "2") Integer targetType,
            @RequestParam(defaultValue = "1") Integer status,
            @RequestParam(required = false)   Long    deptId,
            @RequestParam(required = false)   String  deptName) {
        Long   merchantId = requireMerchantId();
        String creator    = MerchantContext.getMerchantName();

        MerchantAnnouncement a = new MerchantAnnouncement();
        a.setMerchantId(merchantId);
        a.setTitle(title);
        a.setContent(content);
        a.setType(type);
        a.setTargetType(targetType);
        a.setStatus(status);
        a.setDeptId(deptId);
        a.setDeptName(deptName);
        a.setCreateBy(creator);
        announceMapper.insert(a);
        return Result.success();
    }

    @Operation(summary = "编辑公告")
    @PostMapping("/edit")
    public Result<Void> edit(
            @RequestParam               Long    id,
            @RequestParam(required = false) String  title,
            @RequestParam(required = false) String  content,
            @RequestParam(required = false) Integer targetType,
            @RequestParam(required = false) Long    deptId,
            @RequestParam(required = false) String  deptName) {
        Long merchantId = requireMerchantId();
        MerchantAnnouncement a = getAndVerify(id, merchantId);

        if (StringUtils.isNotBlank(title))   a.setTitle(title);
        if (StringUtils.isNotBlank(content)) a.setContent(content);
        if (targetType != null) a.setTargetType(targetType);
        if (deptId     != null) a.setDeptId(deptId);
        if (deptName   != null) a.setDeptName(deptName);
        announceMapper.updateById(a);
        return Result.success();
    }

    @Operation(summary = "发布 / 撤回公告")
    @PostMapping("/status")
    public Result<Void> updateStatus(@RequestParam Long id, @RequestParam Integer status) {
        Long merchantId = requireMerchantId();
        MerchantAnnouncement a = getAndVerify(id, merchantId);
        a.setStatus(status);
        announceMapper.updateById(a);
        return Result.success();
    }

    @Operation(summary = "删除公告")
    @PostMapping("/delete")
    public Result<Void> delete(@RequestParam Long id) {
        Long merchantId = requireMerchantId();
        getAndVerify(id, merchantId);
        announceMapper.deleteById(id);
        return Result.success();
    }

    // ── 未读 / 已读 ──────────────────────────────────────────────────────────

    @Operation(summary = "内部公告未读数（铃铛轮询）")
    @GetMapping("/unread-count")
    public Result<Long> unreadCount() {
        Long   merchantId = requireMerchantId();
        String mobile     = requireMobile();

        // 已发布的内部公告总数
        long total = announceMapper.selectCount(
                new LambdaQueryWrapper<MerchantAnnouncement>()
                        .eq(MerchantAnnouncement::getMerchantId, merchantId)
                        .eq(MerchantAnnouncement::getType,   1)
                        .eq(MerchantAnnouncement::getStatus, 1));

        // 已读数
        long readCount = readMapper.selectCount(
                new LambdaQueryWrapper<MerchantAnnouncementRead>()
                        .eq(MerchantAnnouncementRead::getMerchantId,  merchantId)
                        .eq(MerchantAnnouncementRead::getReaderMobile, mobile));

        return Result.success(Math.max(0, total - readCount));
    }

    @Operation(summary = "未读公告列表（铃铛弹窗）")
    @GetMapping("/unread-list")
    public Result<List<MerchantAnnouncement>> unreadList() {
        Long   merchantId = requireMerchantId();
        String mobile     = requireMobile();

        // 获取已读的公告 ID 集合
        Set<Long> readIds = readMapper.selectList(
                new LambdaQueryWrapper<MerchantAnnouncementRead>()
                        .eq(MerchantAnnouncementRead::getMerchantId,   merchantId)
                        .eq(MerchantAnnouncementRead::getReaderMobile, mobile)
                        .select(MerchantAnnouncementRead::getAnnouncementId))
                .stream().map(MerchantAnnouncementRead::getAnnouncementId)
                .collect(Collectors.toSet());

        LambdaQueryWrapper<MerchantAnnouncement> w = new LambdaQueryWrapper<MerchantAnnouncement>()
                .eq(MerchantAnnouncement::getMerchantId, merchantId)
                .eq(MerchantAnnouncement::getType,   1)
                .eq(MerchantAnnouncement::getStatus, 1)
                .orderByDesc(MerchantAnnouncement::getCreateTime)
                .last("LIMIT 20");

        if (!readIds.isEmpty()) {
            w.notIn(MerchantAnnouncement::getId, readIds);
        }

        return Result.success(announceMapper.selectList(w));
    }

    @Operation(summary = "标记公告已读")
    @PostMapping("/read")
    public Result<Long> markRead(@RequestParam Long id) {
        Long   merchantId = requireMerchantId();
        String mobile     = requireMobile();

        // 幂等：已读则忽略
        long exists = readMapper.selectCount(
                new LambdaQueryWrapper<MerchantAnnouncementRead>()
                        .eq(MerchantAnnouncementRead::getAnnouncementId, id)
                        .eq(MerchantAnnouncementRead::getReaderMobile,   mobile));
        if (exists == 0) {
            MerchantAnnouncementRead r = new MerchantAnnouncementRead();
            r.setAnnouncementId(id);
            r.setReaderMobile(mobile);
            r.setMerchantId(merchantId);
            r.setReadTime(System.currentTimeMillis() / 1000L);
            readMapper.insert(r);
        }

        // 返回最新未读数
        long total = announceMapper.selectCount(
                new LambdaQueryWrapper<MerchantAnnouncement>()
                        .eq(MerchantAnnouncement::getMerchantId, merchantId)
                        .eq(MerchantAnnouncement::getType,   1)
                        .eq(MerchantAnnouncement::getStatus, 1));
        long readCount = readMapper.selectCount(
                new LambdaQueryWrapper<MerchantAnnouncementRead>()
                        .eq(MerchantAnnouncementRead::getMerchantId,   merchantId)
                        .eq(MerchantAnnouncementRead::getReaderMobile, mobile));
        return Result.success(Math.max(0, total - readCount));
    }

    // ── private ──────────────────────────────────────────────────────────────

    private Long requireMerchantId() {
        return MerchantOwnershipGuard.requireMerchantId();
    }

    private String requireMobile() {
        String mobile = MerchantContext.getMobile();
        if (StringUtils.isBlank(mobile)) throw new BusinessException("无法识别当前用户身份");
        return mobile;
    }

    private MerchantAnnouncement getAndVerify(Long id, Long merchantId) {
        MerchantAnnouncement a = announceMapper.selectById(id);
        MerchantOwnershipGuard.assertOwnershipNonNull(a, a != null ? a.getMerchantId() : null, "公告", id);
        return a;
    }
}
