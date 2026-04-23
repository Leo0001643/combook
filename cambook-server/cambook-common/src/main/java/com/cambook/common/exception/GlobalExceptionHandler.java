package com.cambook.common.exception;

import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.result.Result;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 全局异常处理器
 *
 * <p>HTTP 状态码策略：
 * <ul>
 *   <li>业务码在标准 HTTP 范围（100-599）→ 直接作为 HTTP 状态返回（如 401/403）</li>
 *   <li>业务码为自定义扩展码（如 40001）→ HTTP 400，body 携带完整业务码</li>
 * </ul>
 *
 * <p>所有消息均通过 {@link CbCodeEnum#message()} 按请求语言动态返回，无硬编码文案。
 *
 * @author CamBook
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /**
     * 业务异常
     *
     * <p>使用 {@link ResponseEntity} 而非 {@code @ResponseStatus}，以便根据业务码动态确定
     * HTTP 状态：标准码（如 401/403）直接透传，扩展码（如 40001）统一映射到 HTTP 400。
     */
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<Result<Void>> handleBusiness(BusinessException ex) {
        int bizCode = ex.getCode().httpStatus();
        log.warn("[Business] code={} message={}", bizCode, ex.getMessage());
        // 标准 HTTP 状态码范围 100-599，业务扩展码（如 40001）回退到 400
        int httpStatus = (bizCode >= 100 && bizCode <= 599) ? bizCode : HttpStatus.BAD_REQUEST.value();
        return ResponseEntity.status(httpStatus)
                .body(Result.fail(bizCode, ex.getMessage()));
    }

    /**
     * @Valid 校验失败（RequestBody）
     *
     * <p>每个字段只保留第一条错误；主消息直接用于 Toast；data 携带完整字段→错误映射。
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<Map<String, String>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> violations = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors()
          .forEach(fe -> violations.putIfAbsent(fe.getField(), fe.getDefaultMessage()));

        String msg = violations.values().stream().findFirst()
                               .orElse(CbCodeEnum.PARAM_ERROR.message());
        log.warn("[ParamError] {}", violations);
        return Result.fail(CbCodeEnum.PARAM_ERROR.httpStatus(), msg, violations);
    }

    /** @Valid 校验失败（PathVariable / RequestParam） */
    @ExceptionHandler(ConstraintViolationException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<Void> handleConstraint(ConstraintViolationException ex) {
        String msg = ex.getConstraintViolations().stream()
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
        return Result.fail(CbCodeEnum.MISSING_PARAM);
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
        return Result.fail(CbCodeEnum.DATA_DUPLICATE);
    }

    /** HTTP 方法不支持 */
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    @ResponseStatus(HttpStatus.METHOD_NOT_ALLOWED)
    public Result<Void> handleMethodNotSupported(HttpRequestMethodNotSupportedException ex) {
        log.warn("[MethodNotAllowed] {}", ex.getMethod());
        return Result.fail(CbCodeEnum.METHOD_NOT_ALLOWED);
    }

    /** 静态资源不存在，静默返回 404 */
    @ExceptionHandler(NoResourceFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public Result<Void> handleNoResource(NoResourceFoundException ex) {
        log.debug("[NotFound] {}", ex.getResourcePath());
        return Result.fail(CbCodeEnum.DATA_NOT_FOUND);
    }

    /** 兜底：不向客户端暴露内部细节 */
    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public Result<Void> handleUnknown(Exception ex) {
        log.error("[UnknownError]", ex);
        return Result.fail(CbCodeEnum.SERVER_ERROR);
    }
}
