package com.cambook.db.service.impl;

import com.cambook.db.entity.CbNotification;
import com.cambook.db.mapper.CbNotificationMapper;
import com.cambook.db.service.ICbNotificationService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 站内通知表：系统主动推送，多语言内容，含关联业务跳转 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbNotificationServiceImpl extends ServiceImpl<CbNotificationMapper, CbNotification> implements ICbNotificationService {

}
