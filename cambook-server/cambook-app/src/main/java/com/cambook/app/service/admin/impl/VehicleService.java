package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.domain.dto.VehicleDTO;
import com.cambook.app.domain.vo.VehicleVO;
import com.cambook.app.service.admin.IVehicleService;
import com.cambook.common.exception.BusinessException;
import com.cambook.dao.entity.CbVehicle;
import com.cambook.dao.mapper.CbVehicleMapper;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

/**
 * 车辆管理 Service 实现
 *
 * @author CamBook
 */
@Service
public class VehicleService implements IVehicleService {

    private final CbVehicleMapper vehicleMapper;

    public VehicleService(CbVehicleMapper vehicleMapper) {
        this.vehicleMapper = vehicleMapper;
    }

    @Override
    public IPage<VehicleVO> page(int current, int size, String keyword, Integer status, Long merchantId) {
        LambdaQueryWrapper<CbVehicle> qw = new LambdaQueryWrapper<CbVehicle>()
                // 商户范围隔离：null=admin查全量，非null=仅该商户
                .eq(merchantId != null, CbVehicle::getMerchantId, merchantId)
                // 关键词搜索：所有 OR 必须包在 and() 嵌套内，否则会绕过 merchantId 过滤
                .and(StringUtils.hasText(keyword), w -> w
                        .like(CbVehicle::getPlateNumber, keyword)
                        .or().like(CbVehicle::getBrand, keyword)
                        .or().like(CbVehicle::getModel, keyword))
                .eq(status != null, CbVehicle::getStatus, status)
                .orderByDesc(CbVehicle::getCreateTime);

        IPage<CbVehicle> raw = vehicleMapper.selectPage(new Page<>(current, size), qw);
        return raw.convert(e -> {
            VehicleVO vo = new VehicleVO();
            BeanUtils.copyProperties(e, vo);
            return vo;
        });
    }

    @Override
    public void add(VehicleDTO dto) {
        Long count = vehicleMapper.selectCount(
                new LambdaQueryWrapper<CbVehicle>().eq(CbVehicle::getPlateNumber, dto.getPlateNumber()));
        if (count > 0) {
            throw new BusinessException("车牌号已存在");
        }
        CbVehicle entity = new CbVehicle();
        BeanUtils.copyProperties(dto, entity);
        // merchantId 由商户控制器注入（admin端为null，商户端强制赋值）
        entity.setMerchantId(dto.getMerchantId());
        vehicleMapper.insert(entity);
    }

    @Override
    public void edit(VehicleDTO dto) {
        if (dto.getId() == null) throw new BusinessException("ID 不能为空");
        CbVehicle entity = vehicleMapper.selectById(dto.getId());
        if (entity == null) throw new BusinessException("车辆不存在");
        BeanUtils.copyProperties(dto, entity, "id", "merchantId"); // 不覆盖归属商户
        vehicleMapper.updateById(entity);
    }

    @Override
    public void delete(Long id) {
        CbVehicle entity = vehicleMapper.selectById(id);
        if (entity == null) throw new BusinessException("车辆不存在");
        vehicleMapper.deleteById(id);
    }

    @Override
    public void updateStatus(Long id, Integer status) {
        CbVehicle entity = vehicleMapper.selectById(id);
        if (entity == null) throw new BusinessException("车辆不存在");
        entity.setStatus(status);
        vehicleMapper.updateById(entity);
    }

    /** 查询单辆车并返回实体（供商户控制器做归属校验） */
    @Override
    public CbVehicle getById(Long id) {
        CbVehicle entity = vehicleMapper.selectById(id);
        if (entity == null) throw new BusinessException("车辆不存在");
        return entity;
    }
}
