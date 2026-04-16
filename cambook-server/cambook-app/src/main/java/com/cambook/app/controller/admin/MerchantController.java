package com.cambook.app.controller.admin;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.domain.dto.MerchantCreateDTO;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbMerchant;
import com.cambook.dao.mapper.CbMerchantMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.util.DigestUtils;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

/**
 * Admin 端 - 商户管理
 */
@Tag(name = "Admin - 商户管理")
@RestController
@RequestMapping("/admin/merchant")
public class MerchantController {

    private final CbMerchantMapper merchantMapper;

    public MerchantController(CbMerchantMapper merchantMapper) {
        this.merchantMapper = merchantMapper;
    }

    @RequirePermission("merchant:edit")
    @Operation(summary = "后台新增商户")
    @PostMapping("/create")
    public Result<CbMerchant> create(@Valid @ModelAttribute MerchantCreateDTO dto) {
        // 手机号唯一性校验
        Long exists = merchantMapper.selectCount(
                new LambdaQueryWrapper<CbMerchant>().eq(CbMerchant::getMobile, dto.getMobile()));
        if (exists > 0) return Result.fail(400, "该手机号已注册");

        CbMerchant m = new CbMerchant();
        String merchantNo = "M" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"))
                + String.format("%06d", (int)(Math.random() * 999999));
        m.setMerchantNo(merchantNo);
        m.setMobile(dto.getMobile());
        m.setUsername(dto.getUsername());
        m.setPassword(DigestUtils.md5DigestAsHex(
                (dto.getPassword() != null ? dto.getPassword() : "123456")
                        .getBytes(StandardCharsets.UTF_8)));
        m.setMerchantNameZh(dto.getMerchantNameZh());
        m.setMerchantNameEn(dto.getMerchantNameEn());
        m.setContactPerson(dto.getContactPerson());
        m.setContactMobile(dto.getContactMobile());
        m.setCity(dto.getCity());
        m.setAddressZh(dto.getAddressZh());
        m.setBusinessScope(dto.getBusinessScope());
        m.setBusinessArea(dto.getBusinessArea());
        m.setBusinessLicenseNo(dto.getBusinessLicenseNo());
        m.setBusinessLicensePic(dto.getBusinessLicensePic());
        m.setLogo(dto.getLogo());
        m.setPhotos(dto.getPhotos());
        m.setBusinessType(dto.getBusinessType() != null ? dto.getBusinessType() : 1);
        m.setCommissionRate(dto.getCommissionRate());
        m.setAuditStatus(1);   // 后台直接通过
        m.setStatus(1);
        merchantMapper.insert(m);
        return Result.success(m);
    }

    @RequirePermission("merchant:list")
    @Operation(summary = "商户分页列表")
    @GetMapping("/list")
    public Result<PageResult<CbMerchant>> list(
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) Integer auditStatus) {
        IPage<CbMerchant> page = merchantMapper.selectPage(new Page<>(current, size),
                new LambdaQueryWrapper<CbMerchant>()
                        .and(keyword != null && !keyword.isBlank(), q -> q
                                .like(CbMerchant::getMerchantNameZh, keyword)
                                .or().like(CbMerchant::getMobile, keyword)
                                .or().like(CbMerchant::getContactPerson, keyword))
                        .eq(city != null && !city.isBlank(), CbMerchant::getCity, city)
                        .eq(status != null, CbMerchant::getStatus, status)
                        .eq(auditStatus != null, CbMerchant::getAuditStatus, auditStatus)
                        .orderByDesc(CbMerchant::getCreateTime));
        return Result.success(PageResult.of(page));
    }

    @RequirePermission("merchant:list")
    @Operation(summary = "商户详情")
    @GetMapping("/{id}")
    public Result<CbMerchant> detail(@PathVariable Long id) {
        CbMerchant m = merchantMapper.selectById(id);
        if (m == null) return Result.fail(400, "商户不存在");
        return Result.success(m);
    }

    @RequirePermission("merchant:edit")
    @Operation(summary = "修改商户状态")
    @PatchMapping("/{id}/status")
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam Integer status) {
        CbMerchant m = merchantMapper.selectById(id);
        if (m == null) return Result.fail(400, "商户不存在");
        m.setStatus(status);
        merchantMapper.updateById(m);
        return Result.success();
    }

    @RequirePermission("merchant:edit")
    @Operation(summary = "审核商户")
    @PatchMapping("/{id}/audit")
    public Result<Void> audit(@PathVariable Long id,
                               @RequestParam Integer auditStatus,
                               @RequestParam(required = false) String rejectReason) {
        CbMerchant m = merchantMapper.selectById(id);
        if (m == null) return Result.fail(400, "商户不存在");
        m.setAuditStatus(auditStatus);
        if (rejectReason != null) m.setRejectReason(rejectReason);
        merchantMapper.updateById(m);
        return Result.success();
    }

    @RequirePermission("merchant:edit")
    @Operation(summary = "修改佣金比例")
    @PatchMapping("/{id}/commission")
    public Result<Void> updateCommission(@PathVariable Long id,
                                          @RequestParam java.math.BigDecimal commissionRate) {
        CbMerchant m = merchantMapper.selectById(id);
        if (m == null) return Result.fail(400, "商户不存在");
        m.setCommissionRate(commissionRate);
        merchantMapper.updateById(m);
        return Result.success();
    }

    @RequirePermission("merchant:delete")
    @Operation(summary = "删除商户")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        merchantMapper.deleteById(id);
        return Result.success();
    }
}
