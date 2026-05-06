package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.domain.dto.SysConfigSaveDTO;
import com.cambook.app.service.admin.IAdminConfigService;
import com.cambook.common.enums.CbCodeEnum;
import java.util.Optional;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.SysConfig;
import com.cambook.db.service.ISysConfigService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * Admin 系统参数管理实现
 */
@Service
@RequiredArgsConstructor
public class AdminConfigService implements IAdminConfigService {

    private static final int IS_SYSTEM_FLAG = 1;

    private final ISysConfigService sysConfigService;

    @Override
    public PageResult<SysConfig> page(int current, int size, String configName, String configKey, String configGroup) {
        var page = sysConfigService.lambdaQuery()
                .like(configName != null && !configName.isBlank(), SysConfig::getConfigName, configName)
                .like(configKey != null && !configKey.isBlank(), SysConfig::getConfigKey, configKey)
                .eq(configGroup != null && !configGroup.isBlank(), SysConfig::getConfigGroup, configGroup)
                .orderByAsc(SysConfig::getId).page(new Page<>(current, size));
        return PageResult.of(page);
    }

    @Override
    public void add(SysConfigSaveDTO dto) {
        boolean exists = sysConfigService.lambdaQuery().eq(SysConfig::getConfigKey, dto.getConfigKey()).exists();
        if (exists) throw new BusinessException(CbCodeEnum.CONFIG_KEY_EXISTS);
        SysConfig config = new SysConfig();
        config.setConfigName(dto.getConfigName()); config.setConfigKey(dto.getConfigKey());
        config.setConfigValue(dto.getConfigValue()); config.setConfigGroup(dto.getConfigGroup());
        config.setRemark(dto.getRemark()); config.setIsSystem((byte) 0);
        sysConfigService.save(config);
    }

    @Override
    public void edit(SysConfigSaveDTO dto) {
        SysConfig config = Optional.ofNullable(sysConfigService.getById(dto.getId())).orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));
        config.setConfigName(dto.getConfigName()); config.setConfigValue(dto.getConfigValue());
        config.setRemark(dto.getRemark());
        sysConfigService.updateById(config);
    }

    @Override
    public void delete(Long id) {
        SysConfig config = Optional.ofNullable(sysConfigService.getById(id)).orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));
        if (config.getIsSystem() != null && config.getIsSystem() == IS_SYSTEM_FLAG) {
            throw new BusinessException(CbCodeEnum.CONFIG_BUILTIN);
        }
        sysConfigService.removeById(id);
    }
}
