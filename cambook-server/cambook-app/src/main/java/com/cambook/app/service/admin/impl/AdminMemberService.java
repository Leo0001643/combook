package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.domain.dto.MemberQueryDTO;
import com.cambook.app.domain.dto.MemberStatusDTO;
import com.cambook.app.domain.vo.MemberVO;
import com.cambook.app.service.admin.IAdminMemberService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.dao.entity.CbMember;
import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.mapper.CbMemberMapper;
import com.cambook.dao.mapper.CbOrderMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Admin 端会员管理服务实现
 *
 * <p>支持商户范围隔离：query.merchantId 非空时仅返回在该商户下有过订单的会员。
 * <p>所有过滤条件均在数据库层处理，不做客户端二次过滤。
 *
 * @author CamBook
 */
@Service
public class AdminMemberService implements IAdminMemberService {

    private final CbMemberMapper memberMapper;
    private final CbOrderMapper  orderMapper;

    public AdminMemberService(CbMemberMapper memberMapper, CbOrderMapper orderMapper) {
        this.memberMapper = memberMapper;
        this.orderMapper  = orderMapper;
    }

    @Override
    public PageResult<MemberVO> pageList(MemberQueryDTO query) {
        LambdaQueryWrapper<CbMember> wrapper = Wrappers.<CbMember>lambdaQuery()
                // 关键词：同时模糊匹配手机号 OR 昵称
                .and(StringUtils.hasText(query.getKeyword()), w -> w
                        .like(CbMember::getMobile,   query.getKeyword())
                        .or()
                        .like(CbMember::getNickname, query.getKeyword()))
                // Telegram 模糊
                .like(StringUtils.hasText(query.getTelegram()), CbMember::getTelegram, query.getTelegram())
                // 地址模糊
                .like(StringUtils.hasText(query.getAddress()),  CbMember::getAddress,  query.getAddress())
                // 状态精确
                .eq(query.getStatus() != null, CbMember::getStatus, query.getStatus())
                // 性别精确
                .eq(query.getGender() != null, CbMember::getGender, query.getGender())
                // 等级精确
                .eq(query.getLevel()  != null, CbMember::getLevel,  query.getLevel())
                // 语言精确
                .eq(StringUtils.hasText(query.getLang()), CbMember::getLang, query.getLang())
                // 注册时间范围
                .ge(query.getStartDate() != null, CbMember::getRegisterTime, query.getStartDate() != null ? query.getStartDate().atStartOfDay()      : null)
                .le(query.getEndDate()   != null, CbMember::getRegisterTime, query.getEndDate()   != null ? query.getEndDate().atTime(23, 59, 59) : null)
                .eq(CbMember::getDeleted, 0)
                .orderByDesc(CbMember::getCreateTime);

        // 商户视角：仅显示在该商户下有过订单的会员
        if (query.getMerchantId() != null) {
            Set<Long> memberIds = orderMapper.selectList(
                            Wrappers.<CbOrder>lambdaQuery()
                                    .eq(CbOrder::getMerchantId, query.getMerchantId())
                                    .select(CbOrder::getMemberId))
                    .stream().map(CbOrder::getMemberId).filter(id -> id != null).collect(Collectors.toSet());
            if (memberIds.isEmpty()) {
                return PageResult.of(Collections.emptyList(), 0L, query.getPage(), query.getSize());
            }
            wrapper.in(CbMember::getId, memberIds);
        }

        IPage<CbMember> page = memberMapper.selectPage(new Page<>(query.getPage(), query.getSize()), wrapper);
        List<MemberVO>  vos  = page.getRecords().stream().map(MemberVO::from).toList();
        return PageResult.of(page, vos);
    }

    @Override
    public MemberVO getDetail(Long id) {
        CbMember member = memberMapper.selectById(id);
        if (member == null) throw new BusinessException(CbCodeEnum.MEMBER_NOT_FOUND);
        return MemberVO.from(member);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateStatus(Long id, MemberStatusDTO dto) {
        CbMember member = memberMapper.selectById(id);
        if (member == null) throw new BusinessException(CbCodeEnum.MEMBER_NOT_FOUND);
        memberMapper.update(
                Wrappers.<CbMember>lambdaUpdate()
                        .set(CbMember::getStatus, dto.getStatus())
                        .eq(CbMember::getId, id));
    }
}
