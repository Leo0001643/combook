package com.cambook.db.service.impl;

import com.cambook.db.entity.SysI18n;
import com.cambook.db.mapper.SysI18nMapper;
import com.cambook.db.service.ISysI18nService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 国际化枚举消息表：存储接口响应消息的多语言内容，启动时加载入内存 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class SysI18nServiceImpl extends ServiceImpl<SysI18nMapper, SysI18n> implements ISysI18nService {

}
