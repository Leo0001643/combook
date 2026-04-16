package com.cambook.app.service.biz;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.dao.entity.SysNotice;
import com.cambook.dao.mapper.SysNoticeMapper;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

/**
 * 通知公告公共服务
 *
 * <p>Admin 和 Merchant 共用同一服务，区别仅在于：
 * <ul>
 *   <li>merchantId = null → Admin：查看/管理平台全局公告</li>
 *   <li>merchantId = X    → Merchant：查看/管理该商户自有公告</li>
 * </ul>
 *
 * @author CamBook
 */
@Service
public class NoticeService {

    private final SysNoticeMapper noticeMapper;

    public NoticeService(SysNoticeMapper noticeMapper) {
        this.noticeMapper = noticeMapper;
    }

    /** 分页列表 */
    public PageResult<SysNotice> pageList(Long merchantId,
                                           int page, int size,
                                           String keyword, Integer type, Integer status) {
        LambdaQueryWrapper<SysNotice> w = new LambdaQueryWrapper<SysNotice>()
                .eq(merchantId != null, SysNotice::getMerchantId, merchantId)
                .isNull(merchantId == null, SysNotice::getMerchantId)  // admin只看平台公告
                .eq(type   != null, SysNotice::getType,   type)
                .eq(status != null, SysNotice::getStatus, status)
                .and(StringUtils.isNotBlank(keyword), q -> q
                        .like(SysNotice::getTitle, keyword)
                        .or().like(SysNotice::getContent, keyword))
                .orderByDesc(SysNotice::getCreateTime);

        Page<SysNotice> p = noticeMapper.selectPage(new Page<>(page, size), w);
        return PageResult.of(p.getRecords(), p.getTotal(), page, size);
    }

    /** 新增 */
    public void add(Long merchantId, String title, String content, Integer type) {
        SysNotice n = new SysNotice();
        n.setMerchantId(merchantId);
        n.setTitle(title);
        n.setContent(content);
        n.setType(type != null ? type : 1);
        n.setStatus(1);
        noticeMapper.insert(n);
    }

    /** 编辑 */
    public void edit(Long merchantId, Long id, String title, String content, Integer type) {
        SysNotice n = getAndVerify(id, merchantId);
        if (title   != null) n.setTitle(title);
        if (content != null) n.setContent(content);
        if (type    != null) n.setType(type);
        noticeMapper.updateById(n);
    }

    /** 更新状态 */
    public void updateStatus(Long merchantId, Long id, Integer status) {
        SysNotice n = getAndVerify(id, merchantId);
        n.setStatus(status);
        noticeMapper.updateById(n);
    }

    /** 删除 */
    public void delete(Long merchantId, Long id) {
        getAndVerify(id, merchantId);
        noticeMapper.deleteById(id);
    }

    // ── private ──────────────────────────────────────────────────────────────

    private SysNotice getAndVerify(Long id, Long merchantId) {
        SysNotice n = noticeMapper.selectById(id);
        if (n == null) throw new BusinessException("公告不存在");
        if (merchantId != null && !merchantId.equals(n.getMerchantId())) {
            throw new BusinessException("无权操作该公告");
        }
        return n;
    }
}
