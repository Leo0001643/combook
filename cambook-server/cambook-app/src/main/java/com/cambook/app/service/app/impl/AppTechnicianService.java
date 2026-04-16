package com.cambook.app.service.app.impl;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.context.MemberContext;
import com.cambook.app.domain.dto.TechnicianApplyDTO;
import com.cambook.app.domain.vo.TechnicianVO;
import com.cambook.app.service.app.IAppTechnicianService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.dao.entity.CbTechnician;
import com.cambook.dao.mapper.CbTechnicianMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * App 端技师服务实现
 *
 * @author CamBook
 */
@Service
public class AppTechnicianService implements IAppTechnicianService {

    private final CbTechnicianMapper technicianMapper;

    public AppTechnicianService(CbTechnicianMapper technicianMapper) {
        this.technicianMapper = technicianMapper;
    }

    @Override
    public PageResult<TechnicianVO> nearbyList(double lat, double lng, int page, int size) {
        IPage<CbTechnician> iPage = technicianMapper.selectPage(
                new Page<>(page, size),
                Wrappers.<CbTechnician>lambdaQuery()
                        .eq(CbTechnician::getAuditStatus, 1)
                        .eq(CbTechnician::getOnlineStatus, 1)
                        .eq(CbTechnician::getDeleted, 0));
        List<TechnicianVO> vos = iPage.getRecords().stream().map(TechnicianVO::from).toList();
        return PageResult.of(iPage, vos);
    }

    @Override
    public TechnicianVO getDetail(Long id) {
        CbTechnician t = technicianMapper.selectById(id);
        if (t == null) throw new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND);
        return TechnicianVO.from(t);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void apply(TechnicianApplyDTO dto) {
        Long memberId = MemberContext.currentId();
        long exists = technicianMapper.selectCount(
                Wrappers.<CbTechnician>lambdaQuery()
                        .eq(CbTechnician::getMemberId, memberId));
        if (exists > 0) throw new BusinessException(CbCodeEnum.TECHNICIAN_ALREADY_APPLIED);

        CbTechnician t = new CbTechnician();
        t.setMemberId(memberId);
        t.setRealName(dto.getRealName());
        t.setIdCard(dto.getIdCard());
        t.setIdCardFront(dto.getIdCardFront());
        t.setIdCardBack(dto.getIdCardBack());
        t.setSkillTags(dto.getSkillTags());
        t.setServiceCity(dto.getServiceCity());
        t.setAuditStatus(0);
        t.setOnlineStatus(0);
        technicianMapper.insert(t);
    }

    @Override
    public TechnicianVO getMyProfile() {
        Long memberId = MemberContext.currentId();
        CbTechnician t = technicianMapper.selectOne(
                Wrappers.<CbTechnician>lambdaQuery()
                        .eq(CbTechnician::getMemberId, memberId)
                        .last("LIMIT 1"));
        if (t == null) throw new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND);
        return TechnicianVO.from(t);
    }
}
