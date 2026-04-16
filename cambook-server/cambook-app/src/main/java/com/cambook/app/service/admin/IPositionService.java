package com.cambook.app.service.admin;

import com.cambook.app.domain.dto.PositionDTO;
import com.cambook.app.domain.vo.PositionVO;

import java.util.List;

/**
 * 职位管理服务
 *
 * @author CamBook
 */
public interface IPositionService {

    List<PositionVO> list();

    void add(PositionDTO dto);

    void edit(PositionDTO dto);

    void delete(Long id);

    void updateStatus(Long id, Integer status);
}
