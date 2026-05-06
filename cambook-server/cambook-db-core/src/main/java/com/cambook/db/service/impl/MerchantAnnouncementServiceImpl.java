package com.cambook.db.service.impl;

import com.cambook.db.entity.MerchantAnnouncement;
import com.cambook.db.mapper.MerchantAnnouncementMapper;
import com.cambook.db.service.IMerchantAnnouncementService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 商户公告 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service("merchantAnnouncementDataService")
public class MerchantAnnouncementServiceImpl extends ServiceImpl<MerchantAnnouncementMapper, MerchantAnnouncement> implements IMerchantAnnouncementService {

}
