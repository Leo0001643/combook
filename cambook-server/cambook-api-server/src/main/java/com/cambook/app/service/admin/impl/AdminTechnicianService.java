package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.common.audit.AbstractAuditService;
import com.cambook.app.common.security.LoginSessionService;
import com.cambook.app.common.security.TokenKickService;
import com.cambook.app.domain.dto.TechnicianAuditDTO;
import com.cambook.app.domain.dto.TechnicianCreateDTO;
import com.cambook.app.domain.dto.TechnicianQueryDTO;
import com.cambook.app.domain.dto.TechnicianUpdateDTO;
import com.cambook.app.domain.vo.TechnicianVO;
import com.cambook.app.common.statemachine.TechnicianOnlineStatus;
import com.cambook.app.service.admin.IAdminTechnicianService;
import com.cambook.common.enums.AuditStatusEnum;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.enums.CommonStatus;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.CbMerchant;
import com.cambook.db.entity.CbTechnician;
import com.cambook.db.service.ICbMerchantService;
import com.cambook.db.service.ICbTechnicianService;
import lombok.RequiredArgsConstructor;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import com.cambook.common.utils.DateUtils;

/**
 * Admin 端技师管理服务实现
 *
 * <p>继承 {@link AbstractAuditService} 复用审核流程骨架（模板方法模式），
 * 只需实现技师特有的查询和更新逻辑。
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class AdminTechnicianService
        extends AbstractAuditService<CbTechnician>
        implements IAdminTechnicianService {

    private static final int AUDIT_PASS    = AuditStatusEnum.PASS.getCode();
    private static final int STATUS_NORMAL = CommonStatus.ENABLED.getCode();
    private static final int STATUS_ONLINE = TechnicianOnlineStatus.ONLINE.getCode();

    private final ICbTechnicianService cbTechnicianService;
    private final ICbMerchantService   cbMerchantService;
    private final TokenKickService     tokenKickService;
    private final LoginSessionService  loginSessionService;

    @Override
    public PageResult<TechnicianVO> pageList(TechnicianQueryDTO query) {
        var p = cbTechnicianService.lambdaQuery()
                .eq(query.getMerchantId() != null,                  CbTechnician::getMerchantId,   query.getMerchantId())
                .and(StringUtils.isNotBlank(query.getKeyword()), q -> q
                        .like(CbTechnician::getNickname,  query.getKeyword())
                        .or().like(CbTechnician::getRealName, query.getKeyword())
                        .or().like(CbTechnician::getMobile,   query.getKeyword()))
                .like(StringUtils.isNotBlank(query.getRealName()),  CbTechnician::getRealName,    query.getRealName())
                .like(StringUtils.isNotBlank(query.getMobile()),    CbTechnician::getMobile,      query.getMobile())
                .like(StringUtils.isNotBlank(query.getContactValue()), CbTechnician::getTelegram, query.getContactValue())
                .eq(query.getAuditStatus()  != null,                CbTechnician::getAuditStatus, query.getAuditStatus())
                .eq(query.getOnlineStatus() != null,                CbTechnician::getOnlineStatus,query.getOnlineStatus())
                .eq(StringUtils.isNotBlank(query.getServiceCity()), CbTechnician::getServiceCity, query.getServiceCity())
                .eq(query.getGender()       != null,                CbTechnician::getGender,      query.getGender())
                .eq(StringUtils.isNotBlank(query.getNationality()), CbTechnician::getNationality, query.getNationality())
                .orderByDesc(CbTechnician::getCreateTime)
                .page(new Page<>(query.getPage(), query.getSize()));

        List<TechnicianVO> records = p.getRecords().stream().map(TechnicianVO::from).collect(Collectors.toList());

        // 批量回填商户名称（一次查询，避免 N+1）
        Set<Long> merchantIds = records.stream()
                .map(TechnicianVO::getMerchantId)
                .filter(id -> id != null && id > 0)
                .collect(Collectors.toSet());
        if (!merchantIds.isEmpty()) {
            Map<Long, String> nameMap = cbMerchantService.listByIds(merchantIds).stream()
                    .collect(Collectors.toMap(CbMerchant::getId, CbMerchant::getMerchantNameZh));
            records.forEach(vo -> {
                if (vo.getMerchantId() != null) vo.setMerchantName(nameMap.getOrDefault(vo.getMerchantId(), null));
            });
        }

        // 批量查询登录会话（mGet，一次 Redis 往返），回填登录状态、设备、IP、时间
        List<Long> techIds = records.stream().map(TechnicianVO::getId).toList();
        Map<Long, LoginSessionService.SessionInfo> sessionMap = loginSessionService.batchGet("technician", techIds);
        records.forEach(vo -> {
            LoginSessionService.SessionInfo session = sessionMap.get(vo.getId());
            if (session != null) {
                vo.setLoginStatus(1);
                vo.setLastLoginTime(session.getLoginTime());
                vo.setLastLoginDevice(session.getDevice());
                vo.setLastLoginIp(session.getClientIp());
            } else {
                vo.setLoginStatus(0);
            }
        });
        // 按登录状态过滤（Redis 中的实时状态，DB 层无法过滤）
        if (query.getLoginStatus() != null) {
            records.removeIf(vo -> !query.getLoginStatus().equals(vo.getLoginStatus()));
        }

        return PageResult.of(records, p.getTotal(), query.getPage(), query.getSize());
    }

    @Override
    public TechnicianVO create(TechnicianCreateDTO dto) {
        long exists = cbTechnicianService.lambdaQuery().eq(CbTechnician::getMobile, dto.getMobile()).count();
        if (exists > 0) throw new BusinessException(CbCodeEnum.TECHNICIAN_MOBILE_EXISTS);

        CbTechnician t = new CbTechnician();
        String techNo = "T" + DateUtils.todayStr("yyyyMMdd")
                + String.format("%06d", (int)(Math.random() * 999999));
        t.setTechNo(techNo);
        t.setMobile(dto.getMobile());
        String raw = StringUtils.isNotBlank(dto.getPassword()) ? dto.getPassword() : "123456";
        t.setPassword(DigestUtils.md5DigestAsHex(raw.getBytes(StandardCharsets.UTF_8)));
        t.setRealName(dto.getRealName());
        t.setNickname(StringUtils.isNotBlank(dto.getNickname()) ? dto.getNickname() : dto.getRealName());
        t.setGender(dto.getGender() != null ? dto.getGender().byteValue() : (byte)1);
        t.setNationality(dto.getNationality());
        t.setServiceCity(dto.getServiceCity());
        t.setLang(StringUtils.isNotBlank(dto.getLang()) ? dto.getLang() : "zh");
        t.setIntroZh(dto.getIntroZh());
        t.setAvatar(dto.getAvatar());
        t.setPhotos(dto.getPhotos());
        t.setSkillTags(toJsonArray(dto.getSkillTags()));
        t.setServiceItemIds(toJsonLongArray(dto.getServiceItemIds()));
        t.setCommissionRate(dto.getCommissionRate());
        t.setMerchantId(dto.getMerchantId());
        t.setTelegram(dto.getTelegram());
        t.setHeight(dto.getHeight() == null ? null : dto.getHeight().shortValue());
        t.setWeight(dto.getWeight());
        t.setAge(dto.getAge() == null ? null : dto.getAge().byteValue());
        t.setBust(dto.getBust());
        t.setProvince(dto.getProvince());
        t.setVideoUrl(dto.getVideoUrl());
        t.setSettlementMode(dto.getSettlementMode() != null ? dto.getSettlementMode().byteValue() : (byte)3);
        t.setCommissionType(dto.getCommissionType() != null ? dto.getCommissionType().byteValue() : (byte)0);
        t.setCommissionRatePct(dto.getCommissionRatePct());
        t.setCommissionCurrency(dto.getCommissionCurrency());
        t.setAuditStatus(AuditStatusEnum.PASS.byteCode());
        t.setStatus(CommonStatus.ENABLED.byteCode());
        t.setOnlineStatus(TechnicianOnlineStatus.ONLINE.byteCode());
        t.setIsFeatured((byte) 0);
        cbTechnicianService.save(t);
        return TechnicianVO.from(t);
    }

    @Override
    public TechnicianVO getDetail(Long id) {
        CbTechnician t = Optional.ofNullable(cbTechnicianService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND));
        return TechnicianVO.from(t);
    }

    @Override
    public void update(TechnicianUpdateDTO dto) {
        Optional.ofNullable(cbTechnicianService.getById(dto.getId()))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND));

        var upd = cbTechnicianService.lambdaUpdate().eq(CbTechnician::getId, dto.getId());
        if (StringUtils.isNotBlank(dto.getRealName()))    upd.set(CbTechnician::getRealName,      dto.getRealName());
        if (StringUtils.isNotBlank(dto.getNickname()))    upd.set(CbTechnician::getNickname,      dto.getNickname());
        if (dto.getGender()        != null)               upd.set(CbTechnician::getGender,        dto.getGender());
        if (StringUtils.isNotBlank(dto.getNationality())) upd.set(CbTechnician::getNationality,   dto.getNationality());
        if (StringUtils.isNotBlank(dto.getServiceCity())) upd.set(CbTechnician::getServiceCity,   dto.getServiceCity());
        if (StringUtils.isNotBlank(dto.getLang()))        upd.set(CbTechnician::getLang,          dto.getLang());
        if (StringUtils.isNotBlank(dto.getIntroZh()))     upd.set(CbTechnician::getIntroZh,       dto.getIntroZh());
        if (dto.getAvatar()        != null)               upd.set(CbTechnician::getAvatar,        dto.getAvatar());
        if (dto.getPhotos()        != null)               upd.set(CbTechnician::getPhotos,        dto.getPhotos());
        if (StringUtils.isNotBlank(dto.getSkillTags()))   upd.set(CbTechnician::getSkillTags,     toJsonArray(dto.getSkillTags()));
        if (dto.getServiceItemIds() != null)              upd.set(CbTechnician::getServiceItemIds, toJsonLongArray(dto.getServiceItemIds()));
        if (dto.getCommissionRate() != null)              upd.set(CbTechnician::getCommissionRate,dto.getCommissionRate());
        if (dto.getHeight()        != null)               upd.set(CbTechnician::getHeight,        dto.getHeight());
        if (dto.getWeight()        != null)               upd.set(CbTechnician::getWeight,        dto.getWeight());
        if (dto.getAge()           != null)               upd.set(CbTechnician::getAge,           dto.getAge());
        if (dto.getBust()          != null)               upd.set(CbTechnician::getBust,          dto.getBust());
        if (dto.getTelegram()      != null)               upd.set(CbTechnician::getTelegram,      dto.getTelegram());
        if (StringUtils.isNotBlank(dto.getProvince()))    upd.set(CbTechnician::getProvince,      dto.getProvince());
        if (dto.getVideoUrl()      != null)               upd.set(CbTechnician::getVideoUrl,      dto.getVideoUrl());
        if (dto.getSettlementMode()    != null)           upd.set(CbTechnician::getSettlementMode, dto.getSettlementMode());
        if (dto.getCommissionType()    != null)           upd.set(CbTechnician::getCommissionType, dto.getCommissionType());
        if (dto.getCommissionRatePct() != null)           upd.set(CbTechnician::getCommissionRatePct, dto.getCommissionRatePct());
        if (dto.getCommissionCurrency() != null)          upd.set(CbTechnician::getCommissionCurrency, dto.getCommissionCurrency());
        upd.update();
    }

    @Override
    public void audit(TechnicianAuditDTO dto) {
        super.audit(dto.getId(), dto.getAuditStatus(), dto.getRejectReason());
    }

    // ── AbstractAuditService 实现 ────────────────────────────────────────────

    @Override
    protected CbTechnician findById(Long id) {
        return cbTechnicianService.getById(id);
    }

    @Override
    protected CbCodeEnum notFoundCode() {
        return CbCodeEnum.TECHNICIAN_NOT_FOUND;
    }

    @Override
    protected void doUpdateStatus(CbTechnician entity, int auditStatus, String rejectReason) {
        cbTechnicianService.lambdaUpdate()
                .set(CbTechnician::getAuditStatus, auditStatus)
                .set(auditStatus == AuditStatusEnum.REJECT.getCode(), CbTechnician::getRejectReason, rejectReason)
                .eq(CbTechnician::getId, entity.getId())
                .update();
    }

    @Override
    protected void beforeAudit(CbTechnician entity, int auditStatus, String rejectReason) {
        if (entity.getAuditStatus() != null && entity.getAuditStatus() != 0) {
            throw new BusinessException(CbCodeEnum.PARAM_ERROR);
        }
    }

    @Override
    protected void afterAudit(CbTechnician entity, int auditStatus) {
        if (auditStatus == AUDIT_PASS) {
            // TODO: 初始化钱包 + 推送审核通过通知
        }
    }

    @Override
    public void updateStatus(Long id, int status) {
        Optional.ofNullable(cbTechnicianService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND));
        cbTechnicianService.lambdaUpdate()
                .set(CbTechnician::getStatus, status)
                .eq(CbTechnician::getId, id)
                .update();
    }

    @Override
    public void updateOnlineStatus(Long id, int onlineStatus) {
        Optional.ofNullable(cbTechnicianService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND));
        cbTechnicianService.lambdaUpdate()
                .set(CbTechnician::getOnlineStatus, onlineStatus)
                .eq(CbTechnician::getId, id)
                .update();
    }

    @Override
    public void setFeatured(Long id, int featured) {
        Optional.ofNullable(cbTechnicianService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND));
        cbTechnicianService.lambdaUpdate()
                .set(CbTechnician::getIsFeatured, featured)
                .eq(CbTechnician::getId, id)
                .update();
    }

    @Override
    public void delete(Long id) {
        Optional.ofNullable(cbTechnicianService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND));
        cbTechnicianService.removeById(id);
    }

    // ── 工具方法 ─────────────────────────────────────────────────────────────

    private static String toJsonArray(String input) {
        if (input == null || input.isBlank()) return null;
        String trimmed = input.trim();
        if (trimmed.startsWith("[")) return trimmed;
        String[] parts = trimmed.split("[,，、\\s]+");
        StringBuilder sb = new StringBuilder("[");
        boolean first = true;
        for (String part : parts) {
            String tag = part.trim();
            if (tag.isEmpty()) continue;
            if (!first) sb.append(",");
            sb.append("\"").append(tag.replace("\\", "\\\\").replace("\"", "\\\"")).append("\"");
            first = false;
        }
        sb.append("]");
        return sb.toString();
    }

    @Override
    public void forceLogout(Long techId) {
        Optional.ofNullable(cbTechnicianService.getById(techId)).orElseThrow(() -> new BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND));
        tokenKickService.kick("technician", techId);
        loginSessionService.remove("technician", techId);
    }

    private static String toJsonLongArray(List<Long> ids) {
        if (ids == null || ids.isEmpty()) return "[]";
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < ids.size(); i++) {
            if (i > 0) sb.append(",");
            sb.append(ids.get(i));
        }
        sb.append("]");
        return sb.toString();
    }
}
