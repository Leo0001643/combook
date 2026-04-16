package com.cambook.app.controller.app;

import com.cambook.app.domain.dto.TechnicianApplyDTO;
import com.cambook.app.domain.vo.TechnicianVO;
import com.cambook.app.service.app.IAppTechnicianService;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * App 端 - 技师
 *
 * @author CamBook
 */
@Tag(name = "App - 技师")
@RestController("appTechnicianController")
@RequestMapping("/app/technician")
public class TechnicianController {

    private final IAppTechnicianService technicianService;

    public TechnicianController(IAppTechnicianService technicianService) {
        this.technicianService = technicianService;
    }

    @Operation(summary = "附近技师列表（首页）")
    @GetMapping("/nearby")
    public Result<PageResult<TechnicianVO>> nearby(
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(defaultValue = "1")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(technicianService.nearbyList(lat, lng, page, size));
    }

    @Operation(summary = "技师详情")
    @GetMapping("/{id}")
    public Result<TechnicianVO> detail(@PathVariable Long id) {
        return Result.success(technicianService.getDetail(id));
    }

    @Operation(summary = "申请成为技师")
    @PostMapping("/apply")
    public Result<Void> apply(@Valid @ModelAttribute TechnicianApplyDTO dto) {
        technicianService.apply(dto);
        return Result.success();
    }

    @Operation(summary = "获取我的技师资料（已成为技师）")
    @GetMapping("/mine")
    public Result<TechnicianVO> mine() {
        return Result.success(technicianService.getMyProfile());
    }
}
