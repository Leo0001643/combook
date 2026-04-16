package com.cambook.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.dao.entity.SysUser;
import org.apache.ibatis.annotations.Mapper;

/**
 * 管理员账号 Mapper
 *
 * @author CamBook
 */
@Mapper
public interface SysUserMapper extends BaseMapper<SysUser> {
}
