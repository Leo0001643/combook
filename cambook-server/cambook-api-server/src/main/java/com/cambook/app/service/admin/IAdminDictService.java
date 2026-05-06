package com.cambook.app.service.admin;

import com.cambook.app.domain.dto.DictDataSaveDTO;
import com.cambook.app.domain.dto.DictTypeSaveDTO;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.SysDict;
import com.cambook.db.entity.SysDictType;

import java.util.List;

/**
 * Admin 字典管理
 */
public interface IAdminDictService {

    PageResult<SysDictType> typeList(int current, int size, String dictName, String dictType, Integer status);

    void addType(DictTypeSaveDTO dto);

    void editType(DictTypeSaveDTO dto);

    void deleteType(Long id);

    List<SysDict> dataList(String dictType, Integer status);

    void addData(DictDataSaveDTO dto);

    void editData(DictDataSaveDTO dto);

    void deleteData(Long id);
}
