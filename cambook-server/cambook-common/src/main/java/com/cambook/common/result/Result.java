package com.cambook.common.result;

import com.cambook.common.enums.CbCodeEnum;
import com.fasterxml.jackson.annotation.JsonInclude;
import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 统一 API 响应包装
 *
 * <p>响应结构：{@code {code, message, data}}
 * <p>{@code message} 自动按 {@link com.cambook.common.i18n.I18nContext} 当前语言输出
 *
 * @param <T> 响应数据类型
 * @author CamBook
 */
@Schema(description = "统一响应对象")
@JsonInclude(JsonInclude.Include.NON_NULL)
public final class Result<T> {

    @Schema(description = "业务状态码")
    private final int code;

    @Schema(description = "响应消息（多语言）")
    private final String message;

    @Schema(description = "响应数据")
    private final T data;

    private Result(int code, String message, T data) {
        this.code    = code;
        this.message = message;
        this.data    = data;
    }

    // ── 成功 ──────────────────────────────────────────────────────────────────

    public static <T> Result<T> success() {
        return new Result<>(CbCodeEnum.SUCCESS.httpStatus(), CbCodeEnum.SUCCESS.message(), null);
    }

    public static <T> Result<T> success(T data) {
        return new Result<>(CbCodeEnum.SUCCESS.httpStatus(), CbCodeEnum.SUCCESS.message(), data);
    }

    public static <T> Result<T> success(CbCodeEnum code, T data) {
        return new Result<>(code.httpStatus(), code.message(), data);
    }

    // ── 失败 ──────────────────────────────────────────────────────────────────

    public static <T> Result<T> fail(CbCodeEnum code) {
        return new Result<>(code.httpStatus(), code.message(), null);
    }

    public static <T> Result<T> fail(int code, String message) {
        return new Result<>(code, message, null);
    }

    public static <T> Result<T> fail(int code, String message, T data) {
        return new Result<>(code, message, data);
    }

    // ── getter ────────────────────────────────────────────────────────────────

    public int getCode()       { return code; }
    public String getMessage() { return message; }
    public T getData()         { return data; }

    public boolean isSuccess() { return code >= 200 && code < 300; }
}
