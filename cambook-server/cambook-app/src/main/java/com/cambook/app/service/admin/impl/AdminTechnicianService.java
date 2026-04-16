package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.common.audit.AbstractAuditService;
import com.cambook.app.domain.dto.TechnicianAuditDTO;
import com.cambook.app.domain.dto.TechnicianCreateDTO;
import com.cambook.app.domain.dto.TechnicianQueryDTO;
import com.cambook.app.domain.vo.TechnicianVO;
import com.cambook.app.service.admin.IAdminTechnicianService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.result.PageResult;
import com.cambook.dao.entity.CbMerchant;
import com.cambook.dao.entity.CbTechnician;
import com.cambook.dao.mapper.CbMerchantMapper;
import com.cambook.dao.mapper.CbTechnicianMapper;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Admin 端技师管理服务实现
 *
 * <p>继承 {@link AbstractAuditService} 复用审核流程骨架（模板方法模式），
 * 只需实现技师特有的查询和更新逻辑。
 *
 * @author CamBook
 */
@Service
public class AdminTechnicianService
        extends AbstractAuditService<CbTechnician>
        implements IAdminTechnicianService {

    private final CbTechnicianMapper technicianMapper;
    private final CbMerchantMapper   merchantMapper;

    public AdminTechnicianService(CbTechnicianMapper technicianMapper,
                                  CbMerchantMapper   merchantMapper) {
        this.technicianMapper = technicianMapper;
        this.merchantMapper   = merchantMapper;
    }

    @Override
    public PageResult<TechnicianVO> pageList(TechnicianQueryDTO query) {
        LambdaQueryWrapper<CbTechnician> wrapper = new LambdaQueryWrapper<CbTechnician>()
                // 商户范围隔离
                .eq(query.getMerchantId() != null,                  CbTechnician::getMerchantId,   query.getMerchantId())
                .and(StringUtils.isNotBlank(query.getKeyword()), q -> q
                        .like(CbTechnician::getNickname,  query.getKeyword())
                        .or().like(CbTechnician::getRealName, query.getKeyword())
                        .or().like(CbTechnician::getMobile,   query.getKeyword()))
                .like(StringUtils.isNotBlank(query.getRealName()),  CbTechnician::getRealName,    query.getRealName())
                .like(StringUtils.isNotBlank(query.getMobile()),    CbTechnician::getMobile,      query.getMobile())
                // 联系方式模糊查：有 contactType 则精确字段，否则 OR 匹配全部三个字段
                .and(StringUtils.isNotBlank(query.getContactValue()), w -> {
                    String v    = query.getContactValue();
                    String type = query.getContactType();
                    if ("wechat".equals(type)) {
                        w.like(CbTechnician::getWechat, v);
                    } else if ("facebook".equals(type)) {
                        w.like(CbTechnician::getFacebook, v);
                    } else if ("telegram".equals(type)) {
                        w.like(CbTechnician::getTelegram, v);
                    } else {
                        w.like(CbTechnician::getTelegram, v)
                         .or().like(CbTechnician::getWechat, v)
                         .or().like(CbTechnician::getFacebook, v);
                    }
                })
                .eq(query.getAuditStatus() != null,                 CbTechnician::getAuditStatus, query.getAuditStatus())
                .eq(query.getOnlineStatus() != null,                CbTechnician::getOnlineStatus,query.getOnlineStatus())
                .eq(StringUtils.isNotBlank(query.getServiceCity()), CbTechnician::getServiceCity, query.getServiceCity())
                .eq(query.getGender() != null,                          CbTechnician::getGender,       query.getGender())
                .eq(StringUtils.isNotBlank(query.getNationality()),     CbTechnician::getNationality,  query.getNationality())
                .orderByDesc(CbTechnician::getCreateTime);

        Page<CbTechnician> p = technicianMapper.selectPage(new Page<>(query.getPage(), query.getSize()), wrapper);
        List<TechnicianVO> records = p.getRecords().stream().map(TechnicianVO::from).collect(Collectors.toList());

        // 批量回填商户名称（一次查询，避免 N+1）
        Set<Long> merchantIds = records.stream()
                .map(TechnicianVO::getMerchantId)
                .filter(id -> id != null && id > 0)
                .collect(Collectors.toSet());
        if (!merchantIds.isEmpty()) {
            Map<Long, String> nameMap = merchantMapper.selectBatchIds(merchantIds).stream()
                    .collect(Collectors.toMap(CbMerchant::getId, CbMerchant::getMerchantNameZh));
            records.forEach(vo -> {
                if (vo.getMerchantId() != null) {
                    vo.setMerchantName(nameMap.getOrDefault(vo.getMerchantId(), null));
                }
            });
        }

        return PageResult.of(records, p.getTotal(), query.getPage(), query.getSize());
    }

    @Override
    public TechnicianVO create(TechnicianCreateDTO dto) {
        // 手机号唯一性校验
        Long exists = technicianMapper.selectCount(
                new LambdaQueryWrapper<CbTechnician>().eq(CbTechnician::getMobile, dto.getMobile()));
        if (exists > 0) {
            throw new com.cambook.common.exception.BusinessException("该手机号已注册");
        }

        CbTechnician t = new CbTechnician();
        // 生成技师编号：T + yyyyMMdd + 6位随机
        String techNo = "T" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"))
                + String.format("%06d", (int)(Math.random() * 999999));
        t.setTechNo(techNo);
        t.setMobile(dto.getMobile());
        // 密码 MD5 加密（与登录认证保持一致）
        String raw = StringUtils.isNotBlank(dto.getPassword()) ? dto.getPassword() : "123456";
        t.setPassword(DigestUtils.md5DigestAsHex(raw.getBytes(StandardCharsets.UTF_8)));
        t.setRealName(dto.getRealName());
        t.setNickname(StringUtils.isNotBlank(dto.getNickname()) ? dto.getNickname() : dto.getRealName());
        t.setGender(dto.getGender() != null ? dto.getGender() : 1);
        t.setNationality(dto.getNationality());
        t.setServiceCity(dto.getServiceCity());
        t.setLang(StringUtils.isNotBlank(dto.getLang()) ? dto.getLang() : "zh");
        t.setIntroZh(dto.getIntroZh());
        t.setAvatar(dto.getAvatar());
        t.setPhotos(dto.getPhotos());
        t.setSkillTags(toJsonArray(dto.getSkillTags()));
        t.setCommissionRate(dto.getCommissionRate());
        // 归属商户（商户端新增时由控制器注入，admin端无merchantId则为平台技师）
        t.setMerchantId(dto.getMerchantId());
        t.setHeight(dto.getHeight());
        t.setWeight(dto.getWeight());
        t.setAge(dto.getAge());
        t.setBust(dto.getBust());
        t.setProvince(dto.getProvince());
        // 后台新增默认已通过审核，状态正常
        t.setAuditStatus(1);
        t.setStatus(1);
        t.setOnlineStatus(1); // 后台新增默认在线
        t.setIsFeatured(0);
        technicianMapper.insert(t);
        return TechnicianVO.from(t);
    }

    @Override
    public TechnicianVO getDetail(Long id) {
        CbTechnician t = technicianMapper.selectById(id);
        if (t == null) throw new com.cambook.common.exception.BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND);
        return TechnicianVO.from(t);
    }

    @Override
    public void audit(TechnicianAuditDTO dto) {
        // 委托模板方法统一执行：查询 → 前置校验 → 更新 → 后置钩子
        super.audit(dto.getId(), dto.getAuditStatus(), dto.getRejectReason());
    }

    // ── AbstractAuditService 实现 ────────────────────────────────────────────

    @Override
    protected CbTechnician findById(Long id) {
        return technicianMapper.selectById(id);
    }

    @Override
    protected CbCodeEnum notFoundCode() {
        return CbCodeEnum.TECHNICIAN_NOT_FOUND;
    }

    @Override
    protected void doUpdateStatus(CbTechnician entity, int auditStatus, String rejectReason) {
        technicianMapper.update(null,
                new LambdaUpdateWrapper<CbTechnician>()
                        .set(CbTechnician::getAuditStatus, auditStatus)
                        .set(auditStatus == 2, CbTechnician::getRejectReason, rejectReason)
                        .eq(CbTechnician::getId, entity.getId())
        );
    }

    @Override
    protected void beforeAudit(CbTechnician entity, int auditStatus, String rejectReason) {
        // 已有最终审核结果的不允许重复审核
        if (entity.getAuditStatus() != null && entity.getAuditStatus() != 0) {
            throw new com.cambook.common.exception.BusinessException(CbCodeEnum.PARAM_ERROR);
        }
    }

    @Override
    protected void afterAudit(CbTechnician entity, int auditStatus) {
        // 审核通过后可在此初始化技师钱包、发送通知等
        if (auditStatus == 1) {
            // TODO: 初始化钱包 + 推送审核通过通知
        }
    }

    @Override
    public void updateStatus(Long id, int status) {
        CbTechnician t = technicianMapper.selectById(id);
        if (t == null) throw new com.cambook.common.exception.BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND);
        technicianMapper.update(null,
                new LambdaUpdateWrapper<CbTechnician>()
                        .set(CbTechnician::getStatus, status)
                        .eq(CbTechnician::getId, id));
    }

    @Override
    public void updateOnlineStatus(Long id, int onlineStatus) {
        CbTechnician t = technicianMapper.selectById(id);
        if (t == null) throw new com.cambook.common.exception.BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND);
        technicianMapper.update(null,
                new LambdaUpdateWrapper<CbTechnician>()
                        .set(CbTechnician::getOnlineStatus, onlineStatus)
                        .eq(CbTechnician::getId, id));
    }

    @Override
    public void setFeatured(Long id, int featured) {
        CbTechnician t = technicianMapper.selectById(id);
        if (t == null) throw new com.cambook.common.exception.BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND);
        technicianMapper.update(null,
                new LambdaUpdateWrapper<CbTechnician>()
                        .set(CbTechnician::getIsFeatured, featured)
                        .eq(CbTechnician::getId, id));
    }

    @Override
    public void delete(Long id) {
        CbTechnician t = technicianMapper.selectById(id);
        if (t == null) throw new com.cambook.common.exception.BusinessException(CbCodeEnum.TECHNICIAN_NOT_FOUND);
        technicianMapper.deleteById(id);
    }

    // ── 工具方法 ─────────────────────────────────────────────────────────────

    /**
     * 将逗号分隔的技能标签字符串转换为合法 JSON 数组。
     * <ul>
     *   <li>空值 → null（不写入数据库）</li>
     *   <li>已是 JSON 数组（以 [ 开头）→ 直接返回</li>
     *   <li>普通字符串（如 "按摩,正骨,足疗"）→ 拆分后转 ["按摩","正骨","足疗"]</li>
     * </ul>
     */
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
}
