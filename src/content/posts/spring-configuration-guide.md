---
title: "Spring @Configuration 配置类完全指南"
description: "从零到一掌握 Spring 配置类的写法、原理和最佳实践"
pubDate: 2026-07-14
tags: ["Spring", "Java", "Backend"]
author: "Sirmem"
---

## 前言

Spring 中配置类（`@Configuration`）是替代传统 `applicationContext.xml` 的现代方案，从 Spring 3.0 开始引入。今天我们来系统地梳理它的写法。

## 1. 核心注解

### @Configuration

标记一个类为 Spring IoC 容器的配置类：

```java
@Configuration
public class AppConfig {
    
    @Bean
    public DataSource dataSource() {
        return new HikariDataSource();
    }
}
```

### @Bean

告诉 Spring：方法的返回值需要注册为容器中的一个 Bean。

- **方法名** → Bean 名称（默认）
- **返回值类型** → Bean 类型
- **方法体** → Bean 的创建逻辑

## 2. 三种 Bean 注册方式对比

| 方式 | 注解 | 适用场景 |
|------|------|----------|
| **配置类 + @Bean** | `@Configuration` + `@Bean` | 第三方类库（无法修改源码） |
| **组件扫描** | `@ComponentScan` + `@Service`/`@Repository` | 自己项目内的类 |
| **@Import** | `@Import(OtherConfig.class)` | 拆分/组合多个配置类 |

### 示例：第三方类（@Bean 方式）

```java
@Configuration
public class RedisConfig {
    
    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory factory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(factory);
        return template;
    }
}
```

## 3. 配置类常用组合

### 3.1 读取配置文件

```java
@Configuration
@PropertySource("classpath:application.yml")
public class AppConfig {
    
    @Value("${database.url}")
    private String dbUrl;
    
    @Value("${database.username}")
    private String dbUser;
}
```

### 3.2 开启特定功能

```java
@Configuration
@EnableTransactionManagement    // 开启声明式事务
@EnableAspectJAutoProxy        // 开启 AOP
@EnableScheduling              // 开启定时任务
public class RootConfig {
}
```

### 3.3 条件化配置

```java
@Configuration
@ConditionalOnProperty(name = "cache.enabled", havingValue = "true")
public class CacheConfig {
    
    @Bean
    public CacheManager cacheManager() {
        return new ConcurrentMapCacheManager();
    }
}
```

## 4. 多层架构下的配置拆分

实际项目中推荐按功能拆分配置类：

```
com/example/
├── config/
│   ├── DatabaseConfig.java     // 数据源、JPA/MyBatis
│   ├── SecurityConfig.java     // Spring Security
│   ├── WebMvcConfig.java       // 拦截器、CORS
│   └── AppConfig.java          // 通用 Bean
├── service/
├── repository/
└── controller/
```

### 组合方式：@Import

```java
@Configuration
@Import({DatabaseConfig.class, SecurityConfig.class, WebMvcConfig.class})
public class AppConfig {
}
```

或者使用 `@ComponentScan` 自动扫描 `config` 包。

## 5. 注入依赖的几种姿势

### 5.1 构造器注入（推荐）

```java
@Configuration
public class AppConfig {
    
    private final DataSource dataSource;
    
    public AppConfig(DataSource dataSource) {
        this.dataSource = dataSource;
    }
    
    @Bean
    public JdbcTemplate jdbcTemplate() {
        return new JdbcTemplate(dataSource);
    }
}
```

### 5.2 方法参数注入

```java
@Configuration
public class AppConfig {
    
    @Bean
    public JdbcTemplate jdbcTemplate(DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }
}
```

### 5.3 字段注入（不推荐）

```java
@Configuration
public class AppConfig {
    @Autowired
    private DataSource dataSource;  // ❌ 配置类中尽量避免
}
```

## 6. @Configuration 与 @Component 的区别

很多新手会混淆这两者：

| 特性 | @Configuration | @Component |
|------|---------------|------------|
| 代理 | CGLIB 代理（单例保证） | 无代理 |
| @Bean 调用 | 返回同一个实例（单例） | 返回新实例 |
| 用途 | 定义配置/Bean | 普通组件 |
| 内部方法调用 | `@Bean` 方法互相调用走代理 | 不走代理 |

举个栗子 🌰：

```java
@Configuration
public class AppConfig {
    
    @Bean
    public A a() {
        return new A(b());  // 调用 b() 走代理，返回单例
    }
    
    @Bean
    public B b() {
        return new B();
    }
}
```

## 7. 实战：一个完整的配置类

```java
@Configuration
@EnableTransactionManagement
@PropertySource("classpath:application.yml")
@ComponentScan(basePackages = "com.example")
public class AppConfig {
    
    @Value("${db.url}")
    private String dbUrl;
    
    @Value("${db.username}")
    private String dbUser;
    
    @Value("${db.password}")
    private String dbPassword;
    
    @Bean
    public DataSource dataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(dbUrl);
        config.setUsername(dbUser);
        config.setPassword(dbPassword);
        return new HikariDataSource(config);
    }
    
    @Bean
    public PlatformTransactionManager transactionManager(DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }
}
```

## 8. 常见坑点

### ❌ 配置类加上 final
`@Configuration` 依赖 CGLIB 代理，`final` 类无法被代理。

### ❌ 内部 private @Bean 方法
`@Bean` 方法不能是 `private` 的。

### ✅ 推荐的做法
- 用 `@Configuration` + `@Bean` 管理第三方依赖
- 自己写的业务类用 `@ComponentScan` + 注解
- 按功能模块拆分配置类，再通过 `@Import` 组合
- 多加 `@ConditionalOnXxx` 实现环境差异化

## 总结

Spring 配置类（`@Configuration`）是 Spring 框架的基石之一。掌握它的写法不仅能让你告别 XML，还能更深入地理解 IoC 容器的工作原理。从单类配置到多模块拆分，再到条件化装配，这些都是在实际项目中每天都会用到的技能。
