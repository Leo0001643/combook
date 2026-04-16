package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.domain.dto.PositionDTO;
import com.cambook.app.domain.vo.PositionVO;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.SysPosition;
import com.cambook.dao.mapper.SysPositionMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 商户端 - 职位管理（严格隔离，仅可操作本商户数据）
 */
@RequireMerchant
@Tag(name = "商户端 - 职位管理")
@RestController
@RequestMapping("/merchant/position")
public class MerchantPositionController {

    private final SysPositionMapper positionMapper;

    public MerchantPositionController(SysPositionMapper positionMapper) {
        this.positionMapper = positionMapper;
    }

    @Operation(summary = "职位列表")
    @GetMapping("/list")
    public Result<List<PositionVO>> list() {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        List<SysPosition> list = positionMapper.selectList(
                Wrappers.<SysPosition>lambdaQuery()
                        .eq(SysPosition::getMerchantId, merchantId)
                        .eq(SysPosition::getDeleted, 0)
                        .orderByAsc(SysPosition::getSort));
        return Result.success(list.stream().map(PositionVO::from).collect(Collectors.toList()));
    }

    @Operation(summary = "新增职位")
    @PostMapping
    public Result<Void> add(@Valid @ModelAttribute PositionDTO dto) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        // 同一商户内职位编码不重复
        long exists = positionMapper.selectCount(
                Wrappers.<SysPosition>lambdaQuery()
                        .eq(SysPosition::getMerchantId, merchantId)
                        .eq(SysPosition::getCode, dto.getCode()));
        if (exists > 0) throw new BusinessException("职位编码已存在");
        SysPosition p = new SysPosition();
        p.setMerchantId(merchantId);
        p.setDeptId(dto.getDeptId());
        p.setName(dto.getName());
        p.setCode(dto.getCode());
        p.setRemark(dto.getRemark());
        p.setSort(dto.getSort() != null ? dto.getSort() : 0);
        p.setStatus(dto.getStatus() != null ? dto.getStatus() : 1);
        p.setFullAccess(dto.getFullAccess() != null ? dto.getFullAccess() : 0);
        positionMapper.insert(p);
        return Result.success();
    }

    @Operation(summary = "修改职位")
    @PostMapping("/edit")
    public Result<Void> edit(@Valid @ModelAttribute PositionDTO dto) {
        SysPosition p = positionMapper.selectById(dto.getId());
        if (p == null) throw new BusinessException("职位不存在");
        MerchantOwnershipGuard.assertOwnership(p.getMerchantId(), "职位", dto.getId());
        if (dto.getDeptId() != null) p.setDeptId(dto.getDeptId());
        p.setName(dto.getName());
        p.setRemark(dto.getRemark());
        p.setSort(dto.getSort());
        if (dto.getStatus() != null) p.setStatus(dto.getStatus());
        if (dto.getFullAccess() != null) p.setFullAccess(dto.getFullAccess());
        positionMapper.updateById(p);
        return Result.success();
    }

    @Operation(summary = "删除职位")
    @PostMapping("/{id}/delete")
    public Result<Void> delete(@PathVariable Long id) {
        SysPosition p = positionMapper.selectById(id);
        if (p == null) throw new BusinessException("职位不存在");
        MerchantOwnershipGuard.assertOwnership(p.getMerchantId(), "职位", id);
        positionMapper.update(
                Wrappers.<SysPosition>lambdaUpdate()
                        .set(SysPosition::getDeleted, 1)
                        .eq(SysPosition::getId, id));
        return Result.success();
    }

    @Operation(summary = "修改职位状态")
    @PostMapping("/{id}/status")
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam Integer status) {
        SysPosition p = positionMapper.selectById(id);
        if (p == null) throw new BusinessException("职位不存在");
        MerchantOwnershipGuard.assertOwnership(p.getMerchantId(), "职位", id);
        positionMapper.update(
                Wrappers.<SysPosition>lambdaUpdate()
                        .set(SysPosition::getStatus, status)
                        .eq(SysPosition::getId, id));
        return Result.success();
    }
}
