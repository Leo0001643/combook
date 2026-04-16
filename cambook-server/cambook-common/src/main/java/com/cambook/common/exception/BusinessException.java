package com.cambook.common.exception;

import com.cambook.common.enums.CbCodeEnum;

/**
 * 业务异常
 *
 * <p>服务层主动抛出，由全局异常处理器捕获并转为标准响应。
 * 消息自动按 {@link com.cambook.common.i18n.I18nContext} 当前语言输出。
 *
 * <p>使用示例：
 * <pre>
 *   throw new BusinessException(CbCodeEnum.ORDER_NOT_FOUND);
 *   throw new BusinessException(CbCodeEnum.PARAM_ERROR, "手机号格式错误");
 * </pre>
 *
 * @author CamBook
 */
public class BusinessException extends RuntimeException {

    private final CbCodeEnum code;

    public BusinessException(CbCodeEnum code) {
        super(code.message());
        this.code = code;
    }

    public BusinessException(String message) {
        super(message);
        this.code = CbCodeEnum.PARAM_ERROR;
    }

    public BusinessException(CbCodeEnum code, String message) {
        super(message);
        this.code = code;
    }

    public CbCodeEnum getCode() { return code; }
}
