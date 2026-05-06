package com.cambook.db;

import com.baomidou.mybatisplus.generator.FastAutoGenerator;
import com.baomidou.mybatisplus.generator.config.TemplateType;
import com.baomidou.mybatisplus.generator.engine.FreemarkerTemplateEngine;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.List;
import java.util.Properties;

public class InitDB {

    public static void main(String[] args) {
        DbConfig db = DbConfig.load();
        String moduleDir = resolveModuleDir();
        List<String> tables = db.tables();

        System.out.printf("[Generator] outputDir : %s/src/main/java%n", moduleDir);
        System.out.printf("[Generator] db.url    : %s%n", db.url());
        System.out.printf("[Generator] tables    : %s%n", tables.isEmpty() ? "ALL" : tables);

        FastAutoGenerator.create(db.url(), db.username(), db.password())
                .globalConfig(builder -> builder
                        .author("Baomidou")
                        .outputDir(moduleDir + "/src/main/java")
                        .commentDate("yyyy-MM-dd")
                )
                .packageConfig(builder -> builder
                        .parent("com.cambook.db")
                        .entity("entity")
                        .mapper("mapper")
                        .service("service")
                        .serviceImpl("service.impl")
                        .xml("mapper.xml")
                )
                .strategyConfig(builder -> {
                    // 指定表：有则按表生成，无则生成整库
                    if (!tables.isEmpty()) {
                        builder.addInclude(tables);
                    }

                    // Entity：始终覆盖 —— 纯数据结构，无业务逻辑，新字段必须同步
                    builder.entityBuilder()
                            .enableLombok()
                            .enableFileOverride();

                    // Mapper 接口：始终覆盖 —— 仅继承 BaseMapper，无自定义逻辑
                    builder.mapperBuilder()
                            .enableFileOverride();

                    // Service / ServiceImpl：不覆盖 —— 含业务逻辑，首次生成后手动维护
                    builder.serviceBuilder();

                    builder.controllerBuilder().disable();
                })
                // XML 完全不生成：MP 基础 CRUD 无需 XML；复杂 SQL 手写在 resources/mapper 下，永不被覆盖
                .templateConfig(builder -> builder.disable(TemplateType.XML))
                .templateEngine(new FreemarkerTemplateEngine())
                .execute();
    }

    // -------------------------------------------------------------------------
    // 配置加载：优先级 环境变量 > generator.properties > 内置默认值
    // -------------------------------------------------------------------------
    private record DbConfig(String url, String username, String password, String rawTables) {

        private static final String DEFAULT_URL =
                "jdbc:mysql://127.0.0.1:3306/cambook?useUnicode=true" +
                "&characterEncoding=utf8&serverTimezone=Asia/Shanghai" +
                "&allowMultiQueries=true&remarks=true&useInformationSchema=true";

        static DbConfig load() {
            Properties props = loadPropertiesFile();
            return new DbConfig(
                    resolve("DB_URL",        "db.url",          DEFAULT_URL, props),
                    resolve("DB_USERNAME",   "db.username",     "root",      props),
                    resolve("DB_PASSWORD",   "db.password",     "Root123456",props),
                    resolve("GENERATOR_TABLES","generator.tables", "",       props)
            );
        }

        /** 解析表名列表：空字符串返回空集合（代表全库） */
        List<String> tables() {
            if (rawTables == null || rawTables.isBlank()) return List.of();
            return Arrays.stream(rawTables.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .toList();
        }

        /** 环境变量 → properties 文件 → 默认值 */
        private static String resolve(String envKey, String propKey,String defaultVal, Properties props) {
            String env = System.getenv(envKey);
            if (env != null && !env.isBlank()) return env;
            return props.getProperty(propKey, defaultVal);
        }

        private static Properties loadPropertiesFile() {
            Properties props = new Properties();
            try (InputStream is = InitDB.class.getClassLoader()
                    .getResourceAsStream("generator.properties")) {
                if (is != null) {
                    props.load(is);
                } else {
                    System.out.println("[Generator] generator.properties not found, using defaults. " +
                            "Copy generator.properties.example to generator.properties to customize.");
                }
            } catch (IOException e) {
                System.err.println("[Generator] Failed to load generator.properties: " + e.getMessage());
            }
            return props;
        }
    }

    // -------------------------------------------------------------------------
    // 通过类文件位置精准定位当前模块根目录，不受 IntelliJ 工作目录影响
    // -------------------------------------------------------------------------
    private static String resolveModuleDir() {
        return new File(InitDB.class.getProtectionDomain()
                .getCodeSource().getLocation().getPath())
                .getParentFile()   // target/classes -> target
                .getParentFile()   // target          -> module root
                .getAbsolutePath();
    }
}
