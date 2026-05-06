package com.cambook.app.service.admin;

import com.cambook.common.result.PageResult;
import com.cambook.db.entity.SysOperLog;

/**
 * 操作日志服务
 */
public interface IAdminOperLogService {

    PageResult<SysOperLog> page(int current, int size, String title, String operName, String requestMethod, Integer status);

    void delete(Long id);

    void clean();
}
