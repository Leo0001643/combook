package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.time.LocalDateTime;

/**
 * 评价实体
 */
@TableName("cb_review")
public class CbReview extends BaseEntity {

    private Long          orderId;
    private Long          memberId;
    private Long          technicianId;
    private Integer       overallScore;
    private Integer       techniqueScore;
    private Integer       attitudeScore;
    private Integer       punctualScore;
    private String        content;
    private String        tags;
    private Integer       isAnonymous;
    private String        reply;
    private LocalDateTime replyTime;
    private Integer       status;

    public Long          getOrderId()                      { return orderId; }
    public void          setOrderId(Long v)                 { this.orderId = v; }
    public Long          getMemberId()                     { return memberId; }
    public void          setMemberId(Long v)                { this.memberId = v; }
    public Long          getTechnicianId()                 { return technicianId; }
    public void          setTechnicianId(Long v)            { this.technicianId = v; }
    public Integer       getOverallScore()                 { return overallScore; }
    public void          setOverallScore(Integer v)         { this.overallScore = v; }
    public Integer       getTechniqueScore()               { return techniqueScore; }
    public void          setTechniqueScore(Integer v)       { this.techniqueScore = v; }
    public Integer       getAttitudeScore()                { return attitudeScore; }
    public void          setAttitudeScore(Integer v)        { this.attitudeScore = v; }
    public Integer       getPunctualScore()                { return punctualScore; }
    public void          setPunctualScore(Integer v)        { this.punctualScore = v; }
    public String        getContent()                      { return content; }
    public void          setContent(String v)               { this.content = v; }
    public String        getTags()                         { return tags; }
    public void          setTags(String v)                  { this.tags = v; }
    public Integer       getIsAnonymous()                  { return isAnonymous; }
    public void          setIsAnonymous(Integer v)          { this.isAnonymous = v; }
    public String        getReply()                        { return reply; }
    public void          setReply(String v)                 { this.reply = v; }
    public LocalDateTime getReplyTime()                    { return replyTime; }
    public void          setReplyTime(LocalDateTime v)      { this.replyTime = v; }
    public Integer       getStatus()                       { return status; }
    public void          setStatus(Integer v)               { this.status = v; }
}
