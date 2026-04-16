package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.app.domain.dto.PositionDTO;
import com.cambook.app.domain.vo.PositionVO;
import com.cambook.app.service.admin.IPositionService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.dao.entity.SysPosition;
import com.cambook.dao.mapper.SysPositionMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 职位管理服务实现
 *
 * @author CamBook
 */
@Service
public class PositionService implements IPositionService {

    private final SysPositionMapper positionMapper;

    public PositionService(SysPositionMapper positionMapper) {
        this.positionMapper = positionMapper;
    }

    @Override
    public List<PositionVO> list() {
        return positionMapper.selectList(
                        Wrappers.<SysPosition>lambdaQuery()
                                .eq(SysPosition::getDeleted, 0)
                                .orderByAsc(SysPosition::getSort))
                .stream().map(PositionVO::from).collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void add(PositionDTO dto) {
        long exists = positionMapper.selectCount(
                Wrappers.<SysPosition>lambdaQuery().eq(SysPosition::getCode, dto.getCode()));
        if (exists > 0) throw new BusinessException(CbCodeEnum.PARAM_ERROR);

        SysPosition p = new SysPosition();
        p.setName(dto.getName());
        p.setCode(dto.getCode());
        p.setRemark(dto.getRemark());
        p.setSort(dto.getSort() != null ? dto.getSort() : 0);
        p.setStatus(dto.getStatus() != null ? dto.getStatus() : 1);
        positionMapper.insert(p);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void edit(PositionDTO dto) {
        SysPosition p = positionMapper.selectById(dto.getId());
        if (p == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);
        positionMapper.update(
                Wrappers.<SysPosition>lambdaUpdate()
                        .set(SysPosition::getName,   dto.getName())
                        .set(SysPosition::getRemark, dto.getRemark())
                        .set(SysPosition::getSort,   dto.getSort())
                        .eq(SysPosition::getId, dto.getId()));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        positionMapper.update(
                Wrappers.<SysPosition>lambdaUpdate()
                        .set(SysPosition::getDeleted, 1)
                        .eq(SysPosition::getId, id));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateStatus(Long id, Integer status) {
        positionMapper.update(
                Wrappers.<SysPosition>lambdaUpdate()
                        .set(SysPosition::getStatus, status)
                        .eq(SysPosition::getId, id));
    }
}
