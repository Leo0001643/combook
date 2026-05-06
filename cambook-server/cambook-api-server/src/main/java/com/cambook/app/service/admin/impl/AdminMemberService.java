package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.domain.dto.MemberQueryDTO;
import com.cambook.app.domain.dto.MemberStatusDTO;
import com.cambook.app.domain.dto.MemberUpdateDTO;
import com.cambook.app.domain.vo.MemberVO;
import com.cambook.app.service.admin.IAdminMemberService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.CbMember;
import com.cambook.db.entity.CbOrder;
import com.cambook.db.service.ICbMemberService;
import com.cambook.db.service.ICbOrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
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
@RequiredArgsConstructor
public class AdminMemberService implements IAdminMemberService {

    private final ICbMemberService cbMemberService;
    private final ICbOrderService  cbOrderService;

    @Override
    public PageResult<MemberVO> pageList(MemberQueryDTO query) {
        // 商户视角：仅显示在该商户下有过订单的会员
        if (query.getMerchantId() != null) {
            Set<Long> memberIds = cbOrderService.lambdaQuery().eq(CbOrder::getMerchantId, query.getMerchantId()).select(CbOrder::getMemberId).list()
                    .stream().map(CbOrder::getMemberId).filter(id -> id != null).collect(Collectors.toSet());
            if (memberIds.isEmpty()) {
                return PageResult.of(Collections.emptyList(), 0L, query.getPage(), query.getSize());
            }
            IPage<CbMember> page = cbMemberService.lambdaQuery()
                    .in(CbMember::getId, memberIds)
                    .and(StringUtils.hasText(query.getKeyword()), w -> w
                            .like(CbMember::getMobile,   query.getKeyword())
                            .or()
                            .like(CbMember::getNickname, query.getKeyword()))
                    .eq(CbMember::getDeleted, 0)
                    .orderByDesc(CbMember::getCreateTime)
                    .page(new Page<>(query.getPage(), query.getSize()));
            List<MemberVO> vos = page.getRecords().stream().map(MemberVO::from).toList();
            return PageResult.of(page, vos);
        }

        IPage<CbMember> page = cbMemberService.lambdaQuery()
                .and(StringUtils.hasText(query.getKeyword()), w -> w.like(CbMember::getMobile,   query.getKeyword()).or().like(CbMember::getNickname, query.getKeyword()))
                .like(StringUtils.hasText(query.getTelegram()), CbMember::getTelegram, query.getTelegram())
                .like(StringUtils.hasText(query.getAddress()),  CbMember::getAddress,  query.getAddress())
                .eq(query.getStatus() != null, CbMember::getStatus, query.getStatus())
                .eq(query.getGender() != null, CbMember::getGender, query.getGender())
                .eq(query.getLevel()  != null, CbMember::getLevel,  query.getLevel())
                .eq(StringUtils.hasText(query.getLang()), CbMember::getLang, query.getLang())
                .ge(query.getStartDate() != null, CbMember::getRegisterTime, query.getStartDate())
                .le(query.getEndDate()   != null, CbMember::getRegisterTime, query.getEndDate())
                .eq(CbMember::getDeleted, 0)
                .orderByDesc(CbMember::getCreateTime)
                .page(new Page<>(query.getPage(), query.getSize()));
        List<MemberVO> vos = page.getRecords().stream().map(MemberVO::from).toList();
        return PageResult.of(page, vos);
    }

    @Override
    public MemberVO getDetail(Long id) {
        CbMember member = Optional.ofNullable(cbMemberService.getById(id)).orElseThrow(() -> new BusinessException(CbCodeEnum.MEMBER_NOT_FOUND));
        return MemberVO.from(member);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void update(MemberUpdateDTO dto) {
        Optional.ofNullable(cbMemberService.getById(dto.getId())).orElseThrow(() -> new BusinessException(CbCodeEnum.MEMBER_NOT_FOUND));
        cbMemberService.lambdaUpdate()
                .set(dto.getNickname() != null, CbMember::getNickname, dto.getNickname())
                .set(dto.getAvatar()   != null, CbMember::getAvatar,   dto.getAvatar())
                .set(dto.getGender()   != null, CbMember::getGender,   dto.getGender())
                .set(dto.getTelegram() != null, CbMember::getTelegram, dto.getTelegram())
                .set(dto.getAddress()  != null, CbMember::getAddress,  dto.getAddress())
                .eq(CbMember::getId, dto.getId())
                .update();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateStatus(Long id, MemberStatusDTO dto) {
        Optional.ofNullable(cbMemberService.getById(id)).orElseThrow(() -> new BusinessException(CbCodeEnum.MEMBER_NOT_FOUND));
        cbMemberService.lambdaUpdate().set(CbMember::getStatus, dto.getStatus()).eq(CbMember::getId, id).update();
    }
}
