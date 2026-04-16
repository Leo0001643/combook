package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbMerchantStaff;
import com.cambook.dao.mapper.CbMerchantStaffMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.apache.commons.lang3.StringUtils;
import org.springframework.util.DigestUtils;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 商户端 - 员工管理
 *
 * <p>所有操作严格验证数据归属，防止跨商户 IDOR 攻击。
 * {@code @RequireMerchant} 切面自动完成身份 + URI 双重安全校验。
 *
 * @author CamBook
 */
@RequireMerchant
@Tag(name = "商户端 - 员工管理")
@RestController
@RequestMapping("/merchant/staff")
public class MerchantStaffController {

    private final CbMerchantStaffMapper staffMapper;

    public MerchantStaffController(CbMerchantStaffMapper staffMapper) {
        this.staffMapper = staffMapper;
    }

    @Operation(summary = "员工列表")
    @GetMapping("/list")
    public Result<PageResult<CbMerchantStaff>> list(
            @Parameter(description = "页码")     @RequestParam(defaultValue = "1")  int page,
            @Parameter(description = "每页数量") @RequestParam(defaultValue = "10") int size,
            @Parameter(description = "关键词")   @RequestParam(required = false) String keyword,
            @Parameter(description = "状态")     @RequestParam(required = false) Integer status,
            @Parameter(description = "部门ID")   @RequestParam(required = false) Long deptId,
            @Parameter(description = "职位ID")   @RequestParam(required = false) Long positionId) {
        Long merchantId = requireMerchantId();

        LambdaQueryWrapper<CbMerchantStaff> wrapper = new LambdaQueryWrapper<CbMerchantStaff>()
                .eq(CbMerchantStaff::getMerchantId, merchantId)
                .eq(status     != null, CbMerchantStaff::getStatus,     status)
                .eq(deptId     != null, CbMerchantStaff::getDeptId,     deptId)
                .eq(positionId != null, CbMerchantStaff::getPositionId, positionId)
                .and(StringUtils.isNotBlank(keyword), q -> q
                        .like(CbMerchantStaff::getUsername,  keyword)
                        .or().like(CbMerchantStaff::getRealName, keyword)
                        .or().like(CbMerchantStaff::getMobile,   keyword)
                        .or().like(CbMerchantStaff::getTelegram, keyword))
                .orderByDesc(CbMerchantStaff::getCreateTime);

        Page<CbMerchantStaff> p = staffMapper.selectPage(new Page<>(page, size), wrapper);
        List<CbMerchantStaff> records = p.getRecords().stream().peek(s -> s.setPassword(null)).collect(Collectors.toList());

        return Result.success(PageResult.of(records, p.getTotal(), page, size));
    }

    @Operation(summary = "新增员工")
    @PostMapping("/add")
    public Result<Void> add(
            @RequestParam                  String username,
            @RequestParam                  String password,
            @RequestParam(required = false) String realName,
            @RequestParam(required = false) String mobile,
            @RequestParam(required = false) String telegram,
            @RequestParam(required = false) String email,
            @RequestParam(required = false) Long   deptId,
            @RequestParam(required = false) Long   positionId,
            @RequestParam(required = false) String remark) {
        Long merchantId = requireMerchantId();

        // 同一商户内用户名唯一
        Long usernameExists = staffMapper.selectCount(
                new LambdaQueryWrapper<CbMerchantStaff>()
                        .eq(CbMerchantStaff::getMerchantId, merchantId)
                        .eq(CbMerchantStaff::getUsername,   username));
        if (usernameExists > 0) throw new BusinessException("该用户名已存在，请换一个");

        // 手机号全局唯一（用于员工登录身份识别，避免跨商户冲突）
        if (mobile != null && !mobile.isBlank()) {
            Long mobileExists = staffMapper.selectCount(
                    new LambdaQueryWrapper<CbMerchantStaff>()
                            .eq(CbMerchantStaff::getMobile, mobile));
            if (mobileExists > 0) throw new BusinessException("该手机号已被其他员工账号使用，请换一个");
        }

        CbMerchantStaff staff = new CbMerchantStaff();
        staff.setMerchantId(merchantId);
        staff.setUsername(username);
        staff.setPassword(DigestUtils.md5DigestAsHex(password.getBytes(StandardCharsets.UTF_8)));
        staff.setRealName(realName);
        staff.setMobile(mobile);
        staff.setTelegram(telegram);
        staff.setEmail(email);
        staff.setDeptId(deptId);
        staff.setPositionId(positionId);
        staff.setRemark(remark);
        staff.setStatus(1);
        staffMapper.insert(staff);
        return Result.success();
    }

    @Operation(summary = "编辑员工")
    @PostMapping("/edit")
    public Result<Void> edit(
            @RequestParam                  Long   id,
            @RequestParam(required = false) String password,
            @RequestParam(required = false) String realName,
            @RequestParam(required = false) String mobile,
            @RequestParam(required = false) String telegram,
            @RequestParam(required = false) String email,
            @RequestParam(required = false) Long   deptId,
            @RequestParam(required = false) Long   positionId,
            @RequestParam(required = false) String remark) {
        Long merchantId = requireMerchantId();
        CbMerchantStaff staff = getAndVerify(id, merchantId);

        if (StringUtils.isNotBlank(password)) {
            staff.setPassword(DigestUtils.md5DigestAsHex(password.getBytes(StandardCharsets.UTF_8)));
        }
        if (realName != null) staff.setRealName(realName);
        if (mobile != null && !mobile.isBlank()) {
            // 手机号变更时检查全局唯一性（排除自身）
            Long mobileExists = staffMapper.selectCount(
                    new LambdaQueryWrapper<CbMerchantStaff>()
                            .eq(CbMerchantStaff::getMobile, mobile)
                            .ne(CbMerchantStaff::getId,     id));
            if (mobileExists > 0) throw new BusinessException("该手机号已被其他员工账号使用，请换一个");
            staff.setMobile(mobile);
        }
        if (telegram   != null) staff.setTelegram(telegram);
        if (email      != null) staff.setEmail(email);
        // deptId / positionId 用 0 表示"清空"，否则 null 不覆盖
        staff.setDeptId(deptId);
        staff.setPositionId(positionId);
        if (remark     != null) staff.setRemark(remark);
        staffMapper.updateById(staff);
        return Result.success();
    }

    @Operation(summary = "修改员工状态")
    @PostMapping("/status")
    public Result<Void> updateStatus(@RequestParam Long id, @RequestParam Integer status) {
        Long merchantId = requireMerchantId();
        CbMerchantStaff staff = getAndVerify(id, merchantId);
        staff.setStatus(status);
        staffMapper.updateById(staff);
        return Result.success();
    }

    @Operation(summary = "删除员工")
    @PostMapping("/delete")
    public Result<Void> delete(@RequestParam Long id) {
        Long merchantId = requireMerchantId();
        getAndVerify(id, merchantId);
        staffMapper.deleteById(id);
        return Result.success();
    }

    // ── private ──────────────────────────────────────────────────────────────

    private Long requireMerchantId() {
        return MerchantOwnershipGuard.requireMerchantId();
    }

    private CbMerchantStaff getAndVerify(Long id, Long merchantId) {
        CbMerchantStaff staff = staffMapper.selectById(id);
        // 行级安全：验证员工归属当前商户，防止 IDOR 攻击
        MerchantOwnershipGuard.assertOwnershipNonNull(staff, staff != null ? staff.getMerchantId() : null, "员工", id);
        return staff;
    }

}
