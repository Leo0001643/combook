package com.cambook.db.service.impl;

import com.cambook.db.entity.CbTag;
import com.cambook.db.mapper.CbTagMapper;
import com.cambook.db.service.ICbTagService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 标签表：多语言标签，区分技师/服务/商户类型，支持彩色展示 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbTagServiceImpl extends ServiceImpl<CbTagMapper, CbTag> implements ICbTagService {

}
