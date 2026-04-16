package com.cambook.app;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * CamBook 服务端启动类
 *
 * <p>包扫描说明：
 * <ul>
 *   <li>@SpringBootApplication 默认扫描 com.cambook.app 及子包</li>
 *   <li>common / dao 模块的 Bean 通过 @ComponentScan 隐式扫描（Spring Boot auto-config）</li>
 *   <li>mapper 扫描需要显式指定 cambook-dao 模块的包路径</li>
 * </ul>
 *
 * @author CamBook
 */
@EnableAsync
@SpringBootApplication(scanBasePackages = {"com.cambook.app", "com.cambook.common"})
@MapperScan("com.cambook.dao.mapper")
public class CamBookApplication {

    public static void main(String[] args) {
        SpringApplication.run(CamBookApplication.class, args);
    }
}
