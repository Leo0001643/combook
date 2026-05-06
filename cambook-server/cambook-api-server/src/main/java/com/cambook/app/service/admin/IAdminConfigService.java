package com.cambook.app.service.admin;

import com.cambook.app.domain.dto.SysConfigSaveDTO;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.SysConfig;

/**
 * Admin 系统参数管理
 */
public interface IAdminConfigService {

    PageResult<SysConfig> page(int current, int size, String configName, String configKey, String configGroup);

    void add(SysConfigSaveDTO dto);

    void edit(SysConfigSaveDTO dto);

    void delete(Long id);
}
