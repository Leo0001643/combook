package com.cambook.app.common.config;

import com.baomidou.mybatisplus.core.handlers.MetaObjectHandler;
import org.apache.ibatis.reflection.MetaObject;
import org.springframework.stereotype.Component;
import com.cambook.common.utils.DateUtils;

/**
 * MyBatis-Plus 自动填充处理器
 *
 * <p>配合 {@code @TableField(fill = FieldFill.INSERT / INSERT_UPDATE)} 使用，
 * 自动为 createTime / updateTime 字段填入当前时间，无需手动赋值。
 *
 * @author CamBook
 */
@Component
public class MybatisMetaObjectHandler implements MetaObjectHandler {

    @Override
    public void insertFill(MetaObject metaObject) {
        long nowSec = DateUtils.nowSeconds();
        this.strictInsertFill(metaObject, "createTime", Long.class, nowSec);
        this.strictInsertFill(metaObject, "updateTime", Long.class, nowSec);
    }

    @Override
    public void updateFill(MetaObject metaObject) {
        this.strictUpdateFill(metaObject, "updateTime", Long.class, DateUtils.nowSeconds());
    }
}
