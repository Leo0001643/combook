package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.domain.dto.DictDataSaveDTO;
import com.cambook.app.domain.dto.DictTypeSaveDTO;
import com.cambook.app.service.admin.IAdminDictService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.SysDict;
import com.cambook.db.entity.SysDictType;
import com.cambook.db.service.ISysDictService;
import com.cambook.db.service.ISysDictTypeService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import com.cambook.common.enums.CommonStatus;

/**
 * Admin 字典管理实现
 */
@Service
@RequiredArgsConstructor
public class AdminDictService implements IAdminDictService {

    private final ISysDictTypeService sysDictTypeService;
    private final ISysDictService     sysDictService;

    @Override
    public PageResult<SysDictType> typeList(int current, int size, String dictName, String dictType, Integer status) {
        var page = sysDictTypeService.lambdaQuery()
                .like(dictName != null && !dictName.isBlank(), SysDictType::getDictName, dictName)
                .like(dictType != null && !dictType.isBlank(), SysDictType::getDictType, dictType)
                .eq(status != null, SysDictType::getStatus, status)
                .orderByAsc(SysDictType::getId).page(new Page<>(current, size));
        return PageResult.of(page);
    }

    @Override
    public void addType(DictTypeSaveDTO dto) {
        boolean exists = sysDictTypeService.lambdaQuery().eq(SysDictType::getDictType, dto.getDictType()).exists();
        if (exists) throw new BusinessException(CbCodeEnum.DATA_DUPLICATE);
        SysDictType t = new SysDictType();
        t.setDictName(dto.getDictName()); t.setDictType(dto.getDictType());
        t.setRemark(dto.getRemark()); t.setStatus(CommonStatus.ENABLED.byteCode());
        sysDictTypeService.save(t);
    }

    @Override
    public void editType(DictTypeSaveDTO dto) {
        SysDictType t = Optional.ofNullable(sysDictTypeService.getById(dto.getId())).orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));
        t.setDictName(dto.getDictName()); t.setRemark(dto.getRemark());
        if (dto.getStatus() != null) t.setStatus(dto.getStatus().byteValue());
        sysDictTypeService.updateById(t);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteType(Long id) {
        SysDictType t = Optional.ofNullable(sysDictTypeService.getById(id)).orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));
        sysDictService.lambdaUpdate().eq(SysDict::getDictType, t.getDictType()).remove();
        sysDictTypeService.removeById(id);
    }

    @Override
    public List<SysDict> dataList(String dictType, Integer status) {
        return sysDictService.lambdaQuery()
                .eq(SysDict::getDictType, dictType)
                .eq(status != null, SysDict::getStatus, status)
                .orderByAsc(SysDict::getSort).list();
    }

    @Override
    public void addData(DictDataSaveDTO dto) {
        SysDict d = new SysDict();
        d.setDictType(dto.getDictType()); d.setLabelZh(dto.getLabelZh());
        d.setDictValue(dto.getDictValue()); d.setLabelEn(dto.getLabelEn());
        d.setLabelVi(dto.getLabelVi()); d.setLabelKm(dto.getLabelKm());
        d.setSort(dto.getSort()); d.setRemark(dto.getRemark()); d.setStatus(CommonStatus.ENABLED.byteCode());
        sysDictService.save(d);
    }

    @Override
    public void editData(DictDataSaveDTO dto) {
        SysDict d = Optional.ofNullable(sysDictService.getById(dto.getId())).orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));
        d.setLabelZh(dto.getLabelZh()); d.setDictValue(dto.getDictValue());
        d.setLabelEn(dto.getLabelEn()); d.setLabelVi(dto.getLabelVi());
        d.setLabelKm(dto.getLabelKm()); d.setSort(dto.getSort()); d.setRemark(dto.getRemark());
        if (dto.getStatus() != null) d.setStatus(dto.getStatus().byteValue());
        sysDictService.updateById(d);
    }

    @Override
    public void deleteData(Long id) {
        sysDictService.removeById(id);
    }
}
