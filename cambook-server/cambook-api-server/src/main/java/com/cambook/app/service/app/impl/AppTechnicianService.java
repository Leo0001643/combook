package com.cambook.app.service.app.impl;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.context.MemberContext;
import com.cambook.app.domain.dto.TechnicianApplyDTO;
import com.cambook.app.domain.vo.TechnicianVO;
import com.cambook.app.service.app.IAppTechnicianService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.CbTechnician;
import com.cambook.db.service.ICbTechnicianService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * App 端技师服务实现
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class AppTechnicianService implements IAppTechnicianService {

    private static final Byte AUDIT_PASS   = 1;
    private static final Byte ONLINE_IDLE  = 1;
    private static final Byte AUDIT_PENDING = 0;
    private static final Byte OFFLINE       = 0;

    private final ICbTechnicianService cbTechnicianService;

    @Override
    public PageResult<TechnicianVO> nearbyList(double lat, double lng, int page, int size) {
        var iPage = cbTechnicianService.lambdaQuery()
                .eq(CbTechnician::getAuditStatus, AUDIT_PASS)
                .eq(CbTechnician::getOnlineStatus, ONLINE_IDLE)
                .eq(CbTechnician::getDeleted, 0)
                .page(new Page<>(page, size));
        List<TechnicianVO> vos = iPage.getRecords().stream().map(TechnicianVO::from).toList();
        return PageResult.of(iPage, vos);
    }

    @Override
    public TechnicianVO getDetail(Long id) {
        CbTechnician t = Optional.ofNullable(cbTechnicianService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND));
        return TechnicianVO.from(t);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void apply(TechnicianApplyDTO dto) {
        Long memberId = MemberContext.currentId();
        long exists = cbTechnicianService.lambdaQuery().eq(CbTechnician::getMemberId, memberId).count();
        if (exists > 0) throw new BusinessException(CbCodeEnum.TECHNICIAN_ALREADY_APPLIED);

        CbTechnician t = new CbTechnician();
        t.setMemberId(memberId);
        t.setRealName(dto.getRealName());
        t.setIdCard(dto.getIdCard());
        t.setIdCardFront(dto.getIdCardFront());
        t.setIdCardBack(dto.getIdCardBack());
        t.setSkillTags(dto.getSkillTags());
        t.setServiceCity(dto.getServiceCity());
        t.setAuditStatus(AUDIT_PENDING);
        t.setOnlineStatus(OFFLINE);
        cbTechnicianService.save(t);
    }

    @Override
    public TechnicianVO getMyProfile() {
        Long memberId = MemberContext.currentId();
        CbTechnician t = Optional.ofNullable(
                cbTechnicianService.lambdaQuery()
                        .eq(CbTechnician::getMemberId, memberId)
                        .last("LIMIT 1")
                        .one())
                .orElseThrow(() -> new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND));
        return TechnicianVO.from(t);
    }
}
