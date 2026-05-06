package com.cambook.app.service.merchant;

import com.cambook.app.domain.dto.AnnouncementSaveDTO;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.MerchantAnnouncement;

import java.util.List;

/**
 * 商户端 公告管理
 */
public interface IMerchantAnnouncementService {

    PageResult<MerchantAnnouncement> list(Long merchantId, int page, int size, Integer type, Integer status, String keyword);

    void add(Long merchantId, String creatorName, AnnouncementSaveDTO dto);

    void edit(Long merchantId, AnnouncementSaveDTO dto);

    void updateStatus(Long merchantId, Long id, Integer status);

    void delete(Long merchantId, Long id);

    long unreadCount(Long merchantId, String mobile);

    List<MerchantAnnouncement> unreadList(Long merchantId, String mobile);

    long markRead(Long merchantId, String mobile, Long id);
}
