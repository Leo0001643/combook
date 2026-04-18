package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbServiceCategory;
import com.cambook.dao.mapper.CbServiceCategoryMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 商户端 - 服务类目管理（写时复制模式）
 *
 * <p>类目范围：
 * <ul>
 *   <li>merchant_id = null → 平台公共类目（所有商户可见）</li>
 *   <li>merchant_id = {id} → 该商户私有类目（source_category_id=null 表示原创，非 null 表示从平台克隆）</li>
 * </ul>
 *
 * <p>写时复制（Copy-on-Write）：
 * 商户编辑平台类目时，系统自动克隆一份私有副本并应用修改，对商户完全透明。
 * 列表查询时，已有私有副本的平台类目自动被隐藏，避免重复显示。
 */
@RequireMerchant
@Tag(name = "商户端 - 服务类目")
@RestController
@RequestMapping("/merchant/category")
public class MerchantCategoryController {

    private final CbServiceCategoryMapper categoryMapper;

    public MerchantCategoryController(CbServiceCategoryMapper categoryMapper) {
        this.categoryMapper = categoryMapper;
    }

    @Operation(summary = "服务类目列表（平台公共 + 本商户私有，已克隆的平台类目自动去重）")
    @GetMapping("/list")
    public Result<List<CbServiceCategory>> list(
            @RequestParam(required = false) String  keyword,
            @RequestParam(required = false) Integer status) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();

        // 查询商户所有私有类目（含 status=0 的隐藏副本，用于收集被屏蔽的平台类目 ID）
        List<CbServiceCategory> allPrivate = categoryMapper.selectList(
                new LambdaQueryWrapper<CbServiceCategory>()
                        .eq(CbServiceCategory::getMerchantId, merchantId)
                        .orderByAsc(CbServiceCategory::getSort));

        // 被克隆/隐藏覆盖的平台类目 ID（不管副本 status，只要有副本就屏蔽平台版本）
        Set<Long> overriddenPlatformIds = allPrivate.stream()
                .filter(c -> c.getSourceCategoryId() != null)
                .map(CbServiceCategory::getSourceCategoryId)
                .collect(Collectors.toSet());

        // 用于显示的私有类目：按 status 过滤（status=0 的纯隐藏副本不展示）
        int displayStatus = (status != null) ? status : 1; // 默认只展示启用的
        List<CbServiceCategory> privateList = allPrivate.stream()
                .filter(c -> c.getStatus() != null && c.getStatus() == displayStatus)
                .filter(c -> keyword == null || keyword.isBlank()
                        || (c.getNameZh() != null && c.getNameZh().contains(keyword)))
                .collect(Collectors.toList());

        // 查询平台类目，排除已有商户私有副本（无论副本 status）
        List<CbServiceCategory> platformList = categoryMapper.selectList(
                new LambdaQueryWrapper<CbServiceCategory>()
                        .isNull(CbServiceCategory::getMerchantId)
                        .eq(CbServiceCategory::getStatus, displayStatus)
                        .like(keyword != null && !keyword.isBlank(), CbServiceCategory::getNameZh, keyword)
                        .orderByAsc(CbServiceCategory::getSort));

        platformList.removeIf(c -> overriddenPlatformIds.contains(c.getId()));

        // 合并：私有类目优先，平台类目补充
        platformList.addAll(privateList);
        platformList.sort((a, b) -> {
            int s = Integer.compare(a.getSort() != null ? a.getSort() : 0,
                                    b.getSort() != null ? b.getSort() : 0);
            return s != 0 ? s : Long.compare(a.getId(), b.getId());
        });
        return Result.success(platformList);
    }

    @Operation(summary = "新增私有服务类目")
    @PostMapping("/add")
    public Result<Void> add(
            @RequestParam           String  nameZh,
            @RequestParam(required = false) String  nameEn,
            @RequestParam(required = false) String  icon,
            @RequestParam(required = false) Long    parentId,
            @RequestParam(required = false) BigDecimal price,
            @RequestParam(required = false) Integer duration,
            @RequestParam(defaultValue = "0") Integer isSpecial,
            @RequestParam(defaultValue = "0") Integer sort,
            @RequestParam(defaultValue = "1") Integer status) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        CbServiceCategory cat = new CbServiceCategory();
        cat.setMerchantId(merchantId);
        cat.setParentId(parentId != null ? parentId : 0L);
        cat.setNameZh(nameZh);
        cat.setNameEn(nameEn);
        cat.setIcon(icon);
        cat.setPrice(price);
        cat.setDuration(duration);
        cat.setIsSpecial(isSpecial);
        cat.setSort(sort);
        cat.setStatus(status);
        categoryMapper.insert(cat);
        return Result.success();
    }

    @Operation(summary = "编辑服务类目（平台类目自动写时复制为商户私有副本）")
    @PostMapping("/edit")
    public Result<Void> edit(
            @RequestParam           Long    id,
            @RequestParam(required = false) String  nameZh,
            @RequestParam(required = false) String  nameEn,
            @RequestParam(required = false) String  nameVi,
            @RequestParam(required = false) String  nameKm,
            @RequestParam(required = false) String  icon,
            @RequestParam(required = false) BigDecimal price,
            @RequestParam(required = false) Integer duration,
            @RequestParam(required = false) Integer isSpecial,
            @RequestParam(required = false) Integer sort,
            @RequestParam(required = false) Integer status) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        CbServiceCategory cat = categoryMapper.selectById(id);
        if (cat == null) throw new BusinessException("类目不存在");

        // ── 写时复制：平台类目自动克隆为商户私有副本 ──────────────────────────────
        if (cat.getMerchantId() == null) {
            // 检查是否已存在该平台类目的私有副本（防止重复克隆）
            CbServiceCategory existing = categoryMapper.selectOne(
                    new LambdaQueryWrapper<CbServiceCategory>()
                            .eq(CbServiceCategory::getMerchantId, merchantId)
                            .eq(CbServiceCategory::getSourceCategoryId, id));
            if (existing != null) {
                // 副本已存在，直接在副本上编辑
                cat = existing;
            } else {
                // 克隆平台类目为商户私有副本
                CbServiceCategory copy = new CbServiceCategory();
                copy.setMerchantId(merchantId);
                copy.setSourceCategoryId(id);        // 记录来源
                copy.setParentId(cat.getParentId());
                copy.setNameZh(cat.getNameZh());
                copy.setNameEn(cat.getNameEn());
                copy.setNameVi(cat.getNameVi());
                copy.setNameKm(cat.getNameKm());
                copy.setIcon(cat.getIcon());
                copy.setPrice(cat.getPrice());
                copy.setDuration(cat.getDuration());
                copy.setIsSpecial(cat.getIsSpecial());
                copy.setSort(cat.getSort());
                copy.setStatus(cat.getStatus());
                // 应用本次修改
                if (nameZh    != null) copy.setNameZh(nameZh);
                if (nameEn    != null) copy.setNameEn(nameEn);
                if (nameVi    != null) copy.setNameVi(nameVi);
                if (nameKm    != null) copy.setNameKm(nameKm);
                if (icon      != null) copy.setIcon(icon);
                if (price     != null) copy.setPrice(price);
                if (duration  != null) copy.setDuration(duration);
                if (isSpecial != null) copy.setIsSpecial(isSpecial);
                if (sort      != null) copy.setSort(sort);
                if (status    != null) copy.setStatus(status);
                categoryMapper.insert(copy);
                return Result.success();
            }
        } else if (!merchantId.equals(cat.getMerchantId())) {
            throw new BusinessException("无权编辑其他商户的类目");
        }

        // ── 编辑商户自有类目 ───────────────────────────────────────────────────────
        if (nameZh    != null) cat.setNameZh(nameZh);
        if (nameEn    != null) cat.setNameEn(nameEn);
        if (nameVi    != null) cat.setNameVi(nameVi);
        if (nameKm    != null) cat.setNameKm(nameKm);
        if (icon      != null) cat.setIcon(icon);
        if (price     != null) cat.setPrice(price);
        if (duration  != null) cat.setDuration(duration);
        if (isSpecial != null) cat.setIsSpecial(isSpecial);
        if (sort      != null) cat.setSort(sort);
        if (status    != null) cat.setStatus(status);
        categoryMapper.updateById(cat);
        return Result.success();
    }

    @Operation(summary = "删除服务类目（私有类目直接删除；平台类目自动创建隐藏副本以从列表移除）")
    @PostMapping("/{id}/delete")
    public Result<Void> delete(@PathVariable Long id) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        CbServiceCategory cat = categoryMapper.selectById(id);
        if (cat == null) throw new BusinessException("类目不存在");

        if (cat.getMerchantId() == null) {
            // 平台类目：检查是否已有私有副本
            CbServiceCategory existing = categoryMapper.selectOne(
                    new LambdaQueryWrapper<CbServiceCategory>()
                            .eq(CbServiceCategory::getMerchantId, merchantId)
                            .eq(CbServiceCategory::getSourceCategoryId, id));
            if (existing != null) {
                // 已有副本，直接删除副本即可（平台版本将重新出现在列表，如不想显示则保留副本但禁用）
                categoryMapper.deleteById(existing.getId());
            } else {
                // 创建隐藏副本（status=0）使平台类目从该商户的列表中消失
                CbServiceCategory tombstone = new CbServiceCategory();
                tombstone.setMerchantId(merchantId);
                tombstone.setSourceCategoryId(id);
                tombstone.setParentId(cat.getParentId());
                tombstone.setNameZh(cat.getNameZh());
                tombstone.setNameEn(cat.getNameEn());
                tombstone.setNameVi(cat.getNameVi());
                tombstone.setNameKm(cat.getNameKm());
                tombstone.setIcon(cat.getIcon());
                tombstone.setPrice(cat.getPrice());
                tombstone.setDuration(cat.getDuration());
                tombstone.setIsSpecial(cat.getIsSpecial());
                tombstone.setSort(cat.getSort());
                tombstone.setStatus(0); // 禁用，列表查询 status=1 时自动过滤
                categoryMapper.insert(tombstone);
            }
            return Result.success();
        }

        if (!merchantId.equals(cat.getMerchantId())) {
            throw new BusinessException("无权删除其他商户的类目");
        }
        categoryMapper.deleteById(id);
        return Result.success();
    }
}
