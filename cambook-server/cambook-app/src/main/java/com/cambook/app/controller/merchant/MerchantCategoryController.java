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

import java.util.List;

/**
 * 商户端 - 服务类目管理（薄包装层）
 *
 * <p>服务类目支持两个范围：
 * <ul>
 *   <li>merchant_id = null → 平台公共类目（所有商户可见）</li>
 *   <li>merchant_id = {id} → 该商户私有类目（仅该商户可见/编辑）</li>
 * </ul>
 * 商户查询时返回 平台公共 ∪ 自己私有 两部分，写操作仅允许操作自己私有类目。
 *
 * @author CamBook
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

    @Operation(summary = "服务类目列表（平台公共 + 本商户私有）")
    @GetMapping("/list")
    public Result<List<CbServiceCategory>> list(
            @RequestParam(required = false) String  keyword,
            @RequestParam(required = false) Integer status) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        List<CbServiceCategory> list = categoryMapper.selectList(
                new LambdaQueryWrapper<CbServiceCategory>()
                        // 平台公共类目 OR 本商户私有类目
                        .and(w -> w.isNull(CbServiceCategory::getMerchantId)
                                   .or().eq(CbServiceCategory::getMerchantId, merchantId))
                        .like(keyword != null && !keyword.isBlank(), CbServiceCategory::getNameZh, keyword)
                        .eq(status != null, CbServiceCategory::getStatus, status)
                        .orderByAsc(CbServiceCategory::getSort));
        return Result.success(list);
    }

    @Operation(summary = "新增私有服务类目")
    @PostMapping("/add")
    public Result<Void> add(
            @RequestParam           String  nameZh,
            @RequestParam(required = false) String  nameEn,
            @RequestParam(required = false) String  icon,
            @RequestParam(required = false) Long    parentId,
            @RequestParam(defaultValue = "0") Integer sort,
            @RequestParam(defaultValue = "1") Integer status) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        CbServiceCategory cat = new CbServiceCategory();
        cat.setMerchantId(merchantId);   // 强制归属当前商户
        cat.setParentId(parentId != null ? parentId : 0L);
        cat.setNameZh(nameZh);
        cat.setNameEn(nameEn);
        cat.setIcon(icon);
        cat.setSort(sort);
        cat.setStatus(status);
        categoryMapper.insert(cat);
        return Result.success();
    }

    @Operation(summary = "编辑私有服务类目")
    @PostMapping("/edit")
    public Result<Void> edit(
            @RequestParam           Long    id,
            @RequestParam(required = false) String  nameZh,
            @RequestParam(required = false) String  nameEn,
            @RequestParam(required = false) String  icon,
            @RequestParam(required = false) Integer sort,
            @RequestParam(required = false) Integer status) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        CbServiceCategory cat = categoryMapper.selectById(id);
        if (cat == null) throw new BusinessException("类目不存在");
        // 仅允许编辑本商户私有类目，不允许修改平台公共类目
        if (cat.getMerchantId() == null || !merchantId.equals(cat.getMerchantId())) {
            throw new BusinessException("平台类目不可编辑，请添加商户私有类目");
        }
        if (nameZh  != null) cat.setNameZh(nameZh);
        if (nameEn  != null) cat.setNameEn(nameEn);
        if (icon    != null) cat.setIcon(icon);
        if (sort    != null) cat.setSort(sort);
        if (status  != null) cat.setStatus(status);
        categoryMapper.updateById(cat);
        return Result.success();
    }

    @Operation(summary = "删除私有服务类目")
    @PostMapping("/{id}/delete")
    public Result<Void> delete(@PathVariable Long id) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        CbServiceCategory cat = categoryMapper.selectById(id);
        if (cat == null) throw new BusinessException("类目不存在");
        if (cat.getMerchantId() == null || !merchantId.equals(cat.getMerchantId())) {
            throw new BusinessException("平台类目不可删除");
        }
        categoryMapper.deleteById(id);
        return Result.success();
    }
}
