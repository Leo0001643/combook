package com.cambook.app;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * CamBook 服务端启动类
 *
 * @author CamBook
 */
@EnableAsync
@EnableScheduling
@SpringBootApplication(scanBasePackages = {"com.cambook.app", "com.cambook.common", "com.cambook.db"})
@MapperScan("com.cambook.db.mapper")
public class CamBookApplication {

    public static void main(String[] args) {
        SpringApplication.run(CamBookApplication.class, args);
    }
}
