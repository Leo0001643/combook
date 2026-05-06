package com.cambook.db.service.impl;

import com.cambook.db.entity.CbServiceItem;
import com.cambook.db.mapper.CbServiceItemMapper;
import com.cambook.db.service.ICbServiceItemService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 服务项目表：含多语言名称/描述、时长、分级定价 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbServiceItemServiceImpl extends ServiceImpl<CbServiceItemMapper, CbServiceItem> implements ICbServiceItemService {

}
