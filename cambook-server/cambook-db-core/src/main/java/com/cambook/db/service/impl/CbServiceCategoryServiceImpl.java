package com.cambook.db.service.impl;

import com.cambook.db.entity.CbServiceCategory;
import com.cambook.db.mapper.CbServiceCategoryMapper;
import com.cambook.db.service.ICbServiceCategoryService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 服务分类表：两级树形结构，支持六语言名称 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbServiceCategoryServiceImpl extends ServiceImpl<CbServiceCategoryMapper, CbServiceCategory> implements ICbServiceCategoryService {

}
