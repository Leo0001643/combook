package com.cambook.app.common.audit;

import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import org.springframework.transaction.annotation.Transactional;

/**
 * 审核流程模板方法（Template Method Pattern）
 *
 * <p>将"查询 → 校验 → 更新 → 后置钩子"定义为不变骨架，
 * 子类只需实现各个步骤的具体细节（技师审核、商户审核、提现审核等）。
 * 新增审核场景只需继承本类，无需修改骨架逻辑（开闭原则）。
 *
 * @param <T> 被审核实体类型
 * @author CamBook
 */
public abstract class AbstractAuditService<T> {

    /**
     * 审核流程骨架方法（final 防止子类破坏流程）
     *
     * @param id           被审核记录 ID
     * @param auditStatus  审核结果：1-通过  2-拒绝
     * @param rejectReason 拒绝原因（auditStatus=2 时必填）
     */
    @Transactional(rollbackFor = Exception.class)
    public void audit(Long id, int auditStatus, String rejectReason) {
        if (auditStatus == 2 && (rejectReason == null || rejectReason.isBlank())) {
            throw new BusinessException(CbCodeEnum.PARAM_ERROR);
        }

        T entity = findById(id);
        if (entity == null) {
            throw new BusinessException(notFoundCode());
        }

        beforeAudit(entity, auditStatus, rejectReason);
        doUpdateStatus(entity, auditStatus, rejectReason);
        afterAudit(entity, auditStatus);
    }

    // ── 子类必须实现 ─────────────────────────────────────────────────────────

    /** 根据 ID 加载实体 */
    protected abstract T findById(Long id);

    /** 实体不存在时使用的错误码 */
    protected abstract CbCodeEnum notFoundCode();

    /** 实际执行状态更新（INSERT/UPDATE） */
    protected abstract void doUpdateStatus(T entity, int auditStatus, String rejectReason);

    // ── 子类可选覆盖（钩子方法） ──────────────────────────────────────────────

    /** 审核前校验钩子（如检查是否重复审核） */
    protected void beforeAudit(T entity, int auditStatus, String rejectReason) {}

    /** 审核后回调钩子（如通过后创建钱包、发送通知） */
    protected void afterAudit(T entity, int auditStatus) {}
}
