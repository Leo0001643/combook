package com.cambook.app.service.technician;

/**
 * 技师端订单操作服务接口
 *
 * <p>在线预约订单与门店散客订单的完整生命周期（接单/拒单/开始服务/完成服务）。
 *
 * @author CamBook
 */
public interface ITechOrderService {

    void acceptOnline(Long techId, Long orderId);

    void rejectOnline(Long techId, Long orderId);

    void startOnline(Long techId, Long orderId);

    void completeOnline(Long techId, Long orderId);

    void acceptWalkin(Long techId, Long sessionId);

    void rejectWalkin(Long techId, Long sessionId);

    void startWalkin(Long techId, Long sessionId);

    void completeWalkin(Long techId, Long sessionId);
}
