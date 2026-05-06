package com.cambook.app.service.admin;

import com.cambook.app.domain.dto.DeptSaveDTO;
import com.cambook.db.entity.SysDept;

import java.util.List;

/**
 * Admin 部门管理
 */
public interface IAdminDeptService {

    List<SysDept> list(String name, Integer status);

    void add(DeptSaveDTO dto);

    void edit(DeptSaveDTO dto);

    void delete(Long id);

    void updateStatus(Long id, Integer status);
}
