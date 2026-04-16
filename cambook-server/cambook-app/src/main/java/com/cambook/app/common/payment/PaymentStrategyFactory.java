package com.cambook.app.common.payment;

import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 支付策略工厂（工厂模式 + 策略模式联合使用）
 *
 * <p>Spring 启动时自动收集所有 {@link IPaymentStrategy} 实现并以 payType 为 key 建立索引。
 * 新增支付渠道只需新增 {@link IPaymentStrategy} 实现类，工厂无需改动（开闭原则）。
 *
 * @author CamBook
 */
@Component
public class PaymentStrategyFactory {

    private final Map<Integer, IPaymentStrategy> strategyMap;

    public PaymentStrategyFactory(List<IPaymentStrategy> strategies) {
        this.strategyMap = strategies.stream()
                .collect(Collectors.toMap(IPaymentStrategy::payType, Function.identity()));
    }

    /**
     * 根据支付方式获取对应策略
     *
     * @param payType 支付方式（1-ABA 2-USDT 3-余额 4-现金）
     */
    public IPaymentStrategy getStrategy(int payType) {
        IPaymentStrategy strategy = strategyMap.get(payType);
        if (strategy == null) {
            throw new BusinessException(CbCodeEnum.PARAM_ERROR);
        }
        return strategy;
    }
}
