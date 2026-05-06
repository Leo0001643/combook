package com.cambook.db.service.impl;

import com.cambook.db.entity.CbIcon;
import com.cambook.db.mapper.CbIconMapper;
import com.cambook.db.service.ICbIconService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 图标资源表：统一管理 URL/Base64/字体图标，按 key 引用 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbIconServiceImpl extends ServiceImpl<CbIconMapper, CbIcon> implements ICbIconService {

}
