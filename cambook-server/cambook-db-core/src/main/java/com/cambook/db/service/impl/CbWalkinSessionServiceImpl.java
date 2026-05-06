package com.cambook.db.service.impl;

import com.cambook.db.entity.CbWalkinSession;
import com.cambook.db.mapper.CbWalkinSessionMapper;
import com.cambook.db.service.ICbWalkinSessionService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 散客接待 Session：一次到店对应一个 session，手环是识别载体 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbWalkinSessionServiceImpl extends ServiceImpl<CbWalkinSessionMapper, CbWalkinSession> implements ICbWalkinSessionService {

}
