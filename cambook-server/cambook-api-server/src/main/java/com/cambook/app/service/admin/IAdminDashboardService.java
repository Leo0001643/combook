package com.cambook.app.service.admin;

import java.util.Map;

/**
 * Admin 平台数据看板
 */
public interface IAdminDashboardService {

    Map<String, Object> stats(String period);
}
