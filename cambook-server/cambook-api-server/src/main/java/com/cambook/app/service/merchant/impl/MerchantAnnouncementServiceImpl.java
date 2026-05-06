package com.cambook.app.service.merchant.impl;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.domain.dto.AnnouncementSaveDTO;
import com.cambook.app.service.merchant.IMerchantAnnouncementService;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.MerchantAnnouncement;
import com.cambook.db.entity.MerchantAnnouncementRead;
import com.cambook.db.service.IMerchantAnnouncementReadService;
import lombok.RequiredArgsConstructor;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import com.cambook.common.utils.DateUtils;

/**
 * 商户端 公告管理实现
 */
@Service
@RequiredArgsConstructor
public class MerchantAnnouncementServiceImpl implements IMerchantAnnouncementService {

    private static final int TYPE_INTERNAL = 1;
    private static final int STATUS_ACTIVE = 1;

    private final com.cambook.db.service.IMerchantAnnouncementService merchantAnnouncementService;
    private final IMerchantAnnouncementReadService                    merchantAnnouncementReadService;

    @Override
    public PageResult<MerchantAnnouncement> list(Long merchantId, int page, int size, Integer type, Integer status, String keyword) {
        Page<MerchantAnnouncement> p = merchantAnnouncementService.lambdaQuery()
                .eq(MerchantAnnouncement::getMerchantId, merchantId)
                .eq(type != null, MerchantAnnouncement::getType, type)
                .eq(status != null, MerchantAnnouncement::getStatus, status)
                .and(StringUtils.isNotBlank(keyword), q -> q.like(MerchantAnnouncement::getTitle, keyword).or().like(MerchantAnnouncement::getContent, keyword))
                .orderByDesc(MerchantAnnouncement::getCreateTime).page(new Page<>(page, size));
        return PageResult.of(p.getRecords(), p.getTotal(), page, size);
    }

    @Override
    public void add(Long merchantId, String creatorName, AnnouncementSaveDTO dto) {
        MerchantAnnouncement a = new MerchantAnnouncement();
        a.setMerchantId(merchantId); a.setTitle(dto.getTitle()); a.setContent(dto.getContent());
        a.setType(dto.getType() != null ? dto.getType().byteValue() : null);
        a.setTargetType(dto.getTargetType() != null ? dto.getTargetType().byteValue() : null);
        a.setStatus(dto.getStatus() != null ? dto.getStatus().byteValue() : null);
        a.setDeptId(dto.getDeptId()); a.setDeptName(dto.getDeptName()); a.setCreateBy(creatorName);
        merchantAnnouncementService.save(a);
    }

    @Override
    public void edit(Long merchantId, AnnouncementSaveDTO dto) {
        MerchantAnnouncement a = getAndVerify(dto.getId(), merchantId);
        if (StringUtils.isNotBlank(dto.getTitle()))   a.setTitle(dto.getTitle());
        if (StringUtils.isNotBlank(dto.getContent())) a.setContent(dto.getContent());
        if (dto.getTargetType() != null) a.setTargetType(dto.getTargetType().byteValue());
        if (dto.getDeptId()     != null) a.setDeptId(dto.getDeptId());
        if (dto.getDeptName()   != null) a.setDeptName(dto.getDeptName());
        merchantAnnouncementService.updateById(a);
    }

    @Override
    public void updateStatus(Long merchantId, Long id, Integer status) {
        MerchantAnnouncement a = getAndVerify(id, merchantId);
        a.setStatus(status != null ? status.byteValue() : null);
        merchantAnnouncementService.updateById(a);
    }

    @Override
    public void delete(Long merchantId, Long id) {
        getAndVerify(id, merchantId);
        merchantAnnouncementService.removeById(id);
    }

    @Override
    public long unreadCount(Long merchantId, String mobile) {
        long total = merchantAnnouncementService.lambdaQuery()
                .eq(MerchantAnnouncement::getMerchantId, merchantId)
                .eq(MerchantAnnouncement::getType, TYPE_INTERNAL)
                .eq(MerchantAnnouncement::getStatus, STATUS_ACTIVE).count();
        long readCount = merchantAnnouncementReadService.lambdaQuery()
                .eq(MerchantAnnouncementRead::getMerchantId, merchantId)
                .eq(MerchantAnnouncementRead::getReaderMobile, mobile).count();
        return Math.max(0, total - readCount);
    }

    @Override
    public List<MerchantAnnouncement> unreadList(Long merchantId, String mobile) {
        Set<Long> readIds = merchantAnnouncementReadService.lambdaQuery()
                .eq(MerchantAnnouncementRead::getMerchantId, merchantId)
                .eq(MerchantAnnouncementRead::getReaderMobile, mobile)
                .select(MerchantAnnouncementRead::getAnnouncementId).list()
                .stream().map(MerchantAnnouncementRead::getAnnouncementId).collect(Collectors.toSet());
        return merchantAnnouncementService.lambdaQuery()
                .eq(MerchantAnnouncement::getMerchantId, merchantId)
                .eq(MerchantAnnouncement::getType, TYPE_INTERNAL)
                .eq(MerchantAnnouncement::getStatus, STATUS_ACTIVE)
                .notIn(!readIds.isEmpty(), MerchantAnnouncement::getId, readIds)
                .orderByDesc(MerchantAnnouncement::getCreateTime).last("LIMIT 20").list();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public long markRead(Long merchantId, String mobile, Long id) {
        boolean exists = merchantAnnouncementReadService.lambdaQuery()
                .eq(MerchantAnnouncementRead::getAnnouncementId, id)
                .eq(MerchantAnnouncementRead::getReaderMobile, mobile).exists();
        if (!exists) {
            MerchantAnnouncementRead r = new MerchantAnnouncementRead();
            r.setAnnouncementId(id); r.setReaderMobile(mobile);
            r.setMerchantId(merchantId); r.setReadTime(DateUtils.nowSeconds());
            merchantAnnouncementReadService.save(r);
        }
        return unreadCount(merchantId, mobile);
    }

    private MerchantAnnouncement getAndVerify(Long id, Long merchantId) {
        MerchantAnnouncement a = Optional.ofNullable(merchantAnnouncementService.getById(id))
                .orElseThrow(() -> new BusinessException("公告不存在"));
        if (!merchantId.equals(a.getMerchantId())) throw new BusinessException(CbCodeEnum.NO_PERMISSION);
        return a;
    }
}
