package com.cambook.app.service.app.impl;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.common.context.MemberContext;
import com.cambook.app.domain.dto.MemberProfileDTO;
import com.cambook.app.domain.vo.MemberVO;
import com.cambook.app.domain.vo.WalletVO;
import com.cambook.app.service.app.IAppMemberService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.dao.entity.CbMember;
import com.cambook.dao.mapper.CbMemberMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

/**
 * App 端会员服务实现
 *
 * @author CamBook
 */
@Service
public class AppMemberService implements IAppMemberService {

    private final CbMemberMapper memberMapper;

    public AppMemberService(CbMemberMapper memberMapper) {
        this.memberMapper = memberMapper;
    }

    @Override
    public MemberVO getMyProfile() {
        CbMember member = requireCurrentMember();
        return MemberVO.from(member);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateProfile(MemberProfileDTO dto) {
        Long memberId = MemberContext.currentId();
        memberMapper.update(
                Wrappers.<CbMember>lambdaUpdate()
                        .set(dto.getNickname() != null, CbMember::getNickname, dto.getNickname())
                        .set(dto.getAvatar()   != null, CbMember::getAvatar,   dto.getAvatar())
                        .set(dto.getGender()   != null, CbMember::getGender,   dto.getGender())
                        .set(dto.getBirthday() != null, CbMember::getBirthday, dto.getBirthday())
                        .eq(CbMember::getId, memberId));
    }

    @Override
    public WalletVO getWallet() {
        CbMember member = requireCurrentMember();
        WalletVO vo = new WalletVO();
        vo.setBalance(member.getBalance() != null ? member.getBalance() : BigDecimal.ZERO);
        return vo;
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    private CbMember requireCurrentMember() {
        Long memberId = MemberContext.currentId();
        CbMember member = memberMapper.selectById(memberId);
        if (member == null) throw new BusinessException(CbCodeEnum.MEMBER_NOT_FOUND);
        return member;
    }
}
