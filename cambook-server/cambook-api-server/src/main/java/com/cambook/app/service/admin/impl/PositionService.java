package com.cambook.app.service.admin.impl;

import com.cambook.app.domain.dto.PositionDTO;
import com.cambook.app.domain.vo.PositionVO;
import com.cambook.app.service.admin.IPositionService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.SysPosition;
import com.cambook.db.service.ISysPositionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import com.cambook.common.enums.CommonStatus;

/**
 * 职位管理服务实现
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class PositionService implements IPositionService {

    private final ISysPositionService sysPositionService;

    @Override
    public List<PositionVO> list() {
        return sysPositionService.lambdaQuery()
                .eq(SysPosition::getDeleted, 0)
                .orderByAsc(SysPosition::getSort)
                .list()
                .stream().map(PositionVO::from).collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void add(PositionDTO dto) {
        long exists = sysPositionService.lambdaQuery().eq(SysPosition::getCode, dto.getCode()).count();
        if (exists > 0) throw new BusinessException(CbCodeEnum.PARAM_ERROR);

        SysPosition p = new SysPosition();
        p.setName(dto.getName());
        p.setCode(dto.getCode());
        p.setRemark(dto.getRemark());
        p.setSort(dto.getSort() != null ? dto.getSort() : 0);
        p.setStatus(dto.getStatus() != null ? dto.getStatus().byteValue() : CommonStatus.ENABLED.byteCode());
        sysPositionService.save(p);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void edit(PositionDTO dto) {
        Optional.ofNullable(sysPositionService.getById(dto.getId())).orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));
        sysPositionService.lambdaUpdate().set(SysPosition::getName,   dto.getName()).set(SysPosition::getRemark, dto.getRemark())
        .set(SysPosition::getSort,   dto.getSort()).eq(SysPosition::getId, dto.getId()).update();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        sysPositionService.lambdaUpdate().set(SysPosition::getDeleted, 1).eq(SysPosition::getId, id).update();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateStatus(Long id, Integer status) {
        sysPositionService.lambdaUpdate().set(SysPosition::getStatus, status).eq(SysPosition::getId, id).update();
    }
}
