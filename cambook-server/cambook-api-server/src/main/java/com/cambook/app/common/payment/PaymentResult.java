package com.cambook.app.common.payment;

/**
 * 支付结果值对象
 *
 * @author CamBook
 */
public final class PaymentResult {

    private final boolean success;
    private final String  thirdPartyNo;
    private final String  rawResponse;
    private final String  failReason;

    private PaymentResult(boolean success, String thirdPartyNo,
                          String rawResponse, String failReason) {
        this.success      = success;
        this.thirdPartyNo = thirdPartyNo;
        this.rawResponse  = rawResponse;
        this.failReason   = failReason;
    }

    public static PaymentResult ok(String thirdPartyNo, String rawResponse) {
        return new PaymentResult(true, thirdPartyNo, rawResponse, null);
    }

    public static PaymentResult fail(String reason) {
        return new PaymentResult(false, null, null, reason);
    }

    public boolean isSuccess()      { return success; }
    public String getThirdPartyNo() { return thirdPartyNo; }
    public String getRawResponse()  { return rawResponse; }
    public String getFailReason()   { return failReason; }
}
