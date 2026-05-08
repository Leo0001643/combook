package com.cambook.app.domain.vo.chat;

import com.cambook.db.entity.ImChatRule;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

/**
 * IM 权限矩阵视图（供前端管理页面渲染九宫格）
 *
 * <pre>
 * {
 *   "matrix": {
 *     "OWNER": { "MANAGER": true, "STAFF": true, ... },
 *     "MANAGER": { "OWNER": true, "STAFF": true, ... },
 *     ...
 *   },
 *   "customs": [ { id, senderRole, receiverRole, allowed } ]
 * }
 * </pre>
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "IM 角色权限矩阵视图")
public class ImPermMatrixVO {

    @Schema(description = "最终生效矩阵：senderRole → receiverRole → allowed")
    private Map<String, Map<String, Boolean>> matrix;

    @Schema(description = "当前商户的自定义规则列表（用于高亮覆盖项）")
    private List<ImChatRule> customs;
}
