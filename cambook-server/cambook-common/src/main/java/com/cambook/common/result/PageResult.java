package com.cambook.common.result;

import com.baomidou.mybatisplus.core.metadata.IPage;
import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;

/**
 * 分页响应包装
 *
 * @param <T> 列表元素类型
 * @author CamBook
 */
@Schema(description = "分页响应对象")
public final class PageResult<T> {

    @Schema(description = "数据列表")
    private final List<T> list;

    @Schema(description = "总记录数")
    private final long total;

    @Schema(description = "当前页码")
    private final long page;

    @Schema(description = "每页大小")
    private final long size;

    @Schema(description = "总页数")
    private final long pages;

    private PageResult(List<T> list, long total, long page, long size) {
        this.list  = list;
        this.total = total;
        this.page  = page;
        this.size  = size;
        this.pages = size > 0 ? (total + size - 1) / size : 0;
    }

    /**
     * 从 MyBatis-Plus IPage 构建（记录类型与 VO 相同时使用）
     */
    public static <T> PageResult<T> of(IPage<T> page) {
        return new PageResult<>(page.getRecords(), page.getTotal(),
            page.getCurrent(), page.getSize());
    }

    /**
     * 从 IPage 元数据 + 已转换的 VO 列表构建（Entity → VO 转换场景）
     */
    public static <R> PageResult<R> of(IPage<?> meta, List<R> records) {
        return new PageResult<>(records, meta.getTotal(), meta.getCurrent(), meta.getSize());
    }

    /**
     * 直接从记录列表 + 分页参数构建（手动查询场景）
     */
    public static <R> PageResult<R> of(List<R> records, long total, int page, int size) {
        return new PageResult<>(records, total, page, size);
    }

    // ── getter ────────────────────────────────────────────────────────────────

    public List<T> getList()  { return list; }
    public long getTotal()    { return total; }
    public long getPage()     { return page; }
    public long getSize()     { return size; }
    public long getPages()    { return pages; }
}
