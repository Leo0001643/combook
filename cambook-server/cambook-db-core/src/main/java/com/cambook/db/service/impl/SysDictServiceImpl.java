package com.cambook.db.service.impl;

import com.cambook.db.entity.SysDict;
import com.cambook.db.mapper.SysDictMapper;
import com.cambook.db.service.ISysDictService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 字典数据表：存储各字典类型的字典项及其多语言标签 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class SysDictServiceImpl extends ServiceImpl<SysDictMapper, SysDict> implements ISysDictService {

}
