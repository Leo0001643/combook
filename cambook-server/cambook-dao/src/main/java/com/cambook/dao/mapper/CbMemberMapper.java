package com.cambook.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.dao.entity.CbMember;
import org.apache.ibatis.annotations.Mapper;

/**
 * 会员 Mapper
 * <p>
 * 全部使用 MyBatis-Plus Lambda 查询，不写 XML。
 * 复杂查询通过 lambdaQuery() / lambdaUpdate() 链式调用实现。
 *
 * @author CamBook
 */
@Mapper
public interface CbMemberMapper extends BaseMapper<CbMember> {
}
