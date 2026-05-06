package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.service.admin.IAdminOperLogService;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.SysOperLog;
import com.cambook.db.service.ISysOperLogService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * 操作日志服务实现
 */
@Service
@RequiredArgsConstructor
public class AdminOperLogService implements IAdminOperLogService {

    private final ISysOperLogService sysOperLogService;

    @Override
    public PageResult<SysOperLog> page(int current, int size, String title, String operName, String requestMethod, Integer status) {
        var page = sysOperLogService.lambdaQuery()
                .like(title != null && !title.isBlank(), SysOperLog::getTitle, title)
                .like(operName != null && !operName.isBlank(), SysOperLog::getOperName, operName)
                .eq(requestMethod != null && !requestMethod.isBlank(), SysOperLog::getRequestMethod, requestMethod)
                .eq(status != null, SysOperLog::getStatus, status)
                .orderByDesc(SysOperLog::getOperTime).page(new Page<>(current, size));
        return PageResult.of(page);
    }

    @Override
    public void delete(Long id) {
        sysOperLogService.removeById(id);
    }

    @Override
    public void clean() {
        sysOperLogService.remove(null);
    }
}
