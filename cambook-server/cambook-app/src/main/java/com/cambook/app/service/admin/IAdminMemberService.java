package com.cambook.app.service.admin;

import com.cambook.app.domain.dto.MemberQueryDTO;
import com.cambook.app.domain.dto.MemberStatusDTO;
import com.cambook.app.domain.vo.MemberVO;
import com.cambook.common.result.PageResult;

/**
 * Admin 端会员管理服务
 *
 * @author CamBook
 */
public interface IAdminMemberService {

    PageResult<MemberVO> pageList(MemberQueryDTO query);

    MemberVO getDetail(Long id);

    void updateStatus(Long id, MemberStatusDTO dto);
}
