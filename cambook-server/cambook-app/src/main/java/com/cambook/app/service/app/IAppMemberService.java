package com.cambook.app.service.app;

import com.cambook.app.domain.dto.MemberProfileDTO;
import com.cambook.app.domain.vo.MemberVO;
import com.cambook.app.domain.vo.WalletVO;

/**
 * App 端会员服务
 *
 * @author CamBook
 */
public interface IAppMemberService {

    MemberVO getMyProfile();

    void updateProfile(MemberProfileDTO dto);

    WalletVO getWallet();
}
