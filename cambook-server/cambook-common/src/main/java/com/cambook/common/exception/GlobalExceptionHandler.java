package com.cambook.common.exception;

import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.result.Result;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.stream.Collectors;

/**
 * 全局异常处理器
 *
 * @author CamBook
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /** 业务异常：返回对应枚举消息（多语言） */
    @ExceptionHandler(BusinessException.class)
    public Result<Void> handleBusiness(BusinessException ex) {
        log.warn("[Business] code={} message={}", ex.getCode(), ex.getMessage());
        return Result.fail(ex.getCode().httpStatus(), ex.getMessage());
    }

    /** @Valid 校验失败（RequestBody） */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<Void> handleValidation(MethodArgumentNotValidException ex) {
        String msg = ex.getBindingResult().getFieldErrors()
            .stream()
            .map(FieldError::getDefaultMessage)
            .collect(Collectors.joining("; "));
        log.warn("[ParamError] {}", msg);
        return Result.fail(CbCodeEnum.PARAM_ERROR.httpStatus(), msg);
    }

    /** @Valid 校验失败（PathVariable / RequestParam） */
    @ExceptionHandler(ConstraintViolationException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<Void> handleConstraint(ConstraintViolationException ex) {
        String msg = ex.getConstraintViolations()
            .stream()
            .map(ConstraintViolation::getMessage)
            .collect(Collectors.joining("; "));
        return Result.fail(CbCodeEnum.PARAM_ERROR.httpStatus(), msg);
    }

    /** 请求体无法解析（JSON 格式错误） */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<Void> handleNotReadable(HttpMessageNotReadableException ex) {
        log.warn("[BadRequest] {}", ex.getMessage());
        return Result.fail(CbCodeEnum.PARAM_ERROR);
    }

    /** 缺少必要请求参数 */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<Void> handleMissingParam(MissingServletRequestParameterException ex) {
        log.warn("[MissingParam] {}", ex.getParameterName());
        return Result.fail(CbCodeEnum.PARAM_ERROR.httpStatus(),
                "缺少参数: " + ex.getParameterName());
    }

    /** 参数类型不匹配 */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<Void> handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        log.warn("[TypeMismatch] param={}", ex.getName());
        return Result.fail(CbCodeEnum.PARAM_ERROR);
    }

    /** 数据库唯一键冲突 */
    @ExceptionHandler(DuplicateKeyException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    public Result<Void> handleDuplicateKey(DuplicateKeyException ex) {
        log.warn("[DuplicateKey] {}", ex.getMessage());
        return Result.fail(CbCodeEnum.PARAM_ERROR.httpStatus(), "数据已存在，请勿重复提交");
    }

    /** HTTP 方法不支持（如用 GET 请求 POST 接口） */
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    @ResponseStatus(HttpStatus.METHOD_NOT_ALLOWED)
    public Result<Void> handleMethodNotSupported(HttpRequestMethodNotSupportedException ex) {
        log.warn("[MethodNotAllowed] {}", ex.getMethod());
        return Result.fail(405, "请求方法不支持: " + ex.getMethod());
    }

    /** 静态资源不存在（如 favicon.ico），静默返回 404，不打印错误堆栈 */
    @ExceptionHandler(NoResourceFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public Result<Void> handleNoResource(NoResourceFoundException ex) {
        log.debug("[NotFound] {}", ex.getResourcePath());
        return Result.fail(404, "资源不存在: " + ex.getResourcePath());
    }

    /** 兜底：不向客户端暴露内部细节 */
    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public Result<Void> handleUnknown(Exception ex) {
        log.error("[UnknownError]", ex);
        return Result.fail(CbCodeEnum.SERVER_ERROR);
    }
}
