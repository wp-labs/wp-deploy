# station

该 Helm Chart 用于在 Kubernetes 中部署一套完整的 Warp Station 环境，内置以下组件：

- `warp-station`：主应用
- `postgres`：内部数据库
- `gitea`：内部 Git 服务
- `gitea-init`：通过 Helm hook 初始化 Gitea 管理员

## 目录结构

```text
k8s/station/
  station-config/config.toml
  default-configs/
  initdb/01-create-databases.sql
  templates/
  values.yaml
```

## 设计说明

### 1. warp-station 是主 Deployment

主服务镜像默认使用：

```text
ghcr.io/wp-labs/wp-station:v0.1.11-alpha
```

对外默认暴露：

```text
8081
```

### 2. postgres 和 gitea 为 chart 内置独立组件

它们不是 sidecar，而是独立 Deployment：

- `postgres` 使用 PVC 持久化数据
- `gitea` 使用 PVC 持久化 `/data`

### 3. gitea-init 使用 post-install/post-upgrade Hook Job

它不会作为 `gitea` 的 initContainer，因为它依赖 Gitea 完成首次启动并产出 `/data/gitea/conf/app.ini`。

当前实现为：

- `post-install`
- `post-upgrade`

Hook Job 会等待 Gitea HTTP 服务可访问后执行管理员创建，重复执行时使用 `|| true` 保持幂等。

### 4. warp-toolchain 使用 initContainer

`warp-station` 会通过 initContainer 从 `ghcr.io/wp-labs/warp-parse:0.23.8-alpha` 中复制：

- `wparse`
- `wpgen`
- `wproj`

复制目标目录：

```text
/app/toolchain
```

### 5. default_configs 使用 ConfigMap + .Files.Glob

`default-configs/**` 会整体打包进 ConfigMap，并在容器内恢复为原始目录结构，挂载到：

```text
/app/default_configs
```

## 安装

```bash
helm upgrade --install station ./k8s/station
```

查看渲染结果：

```bash
helm template station ./k8s/station
```

## 关键配置

### warp-station

```yaml
station:
  image:
    repository: ghcr.io/wp-labs/wp-station
    tag: v0.1.11-alpha
  web:
    host: 0.0.0.0
    port: 8081
  monitorUrl: http://wp-monitor:18080/wp-monitor
  assistBaseUrl: ""
  projectRoot: project_root
```

`station` 下还集中管理以下仅属于主 Pod 的配置：

- `toolchainImage`
- `initImage`
- `env` / `envFrom`
- `timezone`
- `podAnnotations` / `podLabels`
- `podSecurityContext` / `securityContext`
- `resources`
- `livenessProbe` / `readinessProbe`
- `autoscaling`
- `volumes` / `volumeMounts`
- `nodeSelector` / `tolerations` / `affinity`

### postgres

```yaml
postgres:
  user: postgres
  password: "123456"
  databases:
    default: postgres
    gitea: gitea
    station: wp-station
```

`postgres` 自身也支持单独配置：

- `podAnnotations` / `podLabels`
- `podSecurityContext` / `securityContext`
- `resources`
- `livenessProbe` / `readinessProbe`
- `volumes` / `volumeMounts`
- `nodeSelector` / `tolerations` / `affinity`

### gitea

```yaml
gitea:
  adminUsername: gitea
  adminPassword: "123456"
  rootUrl: http://localhost:3000
```

`gitea` 同样支持单独配置：

- `podAnnotations` / `podLabels`
- `podSecurityContext` / `securityContext`
- `resources`
- `livenessProbe` / `readinessProbe`
- `volumes` / `volumeMounts`
- `nodeSelector` / `tolerations` / `affinity`

## 配置文件来源

### `station-config/config.toml`

它会被挂载到：

```text
/app/config/config.toml
```

### `default-configs/**`

它们会被挂载到：

```text
/app/default_configs
```

## Secret

当前 Chart 会自动创建一个 Secret，包含：

- `postgres-password`
- `gitea-admin-password`

## 持久化

默认创建两个 PVC：

- `postgres` 数据卷
- `gitea` 数据卷

可通过以下字段修改：

```yaml
postgres.persistence.size
postgres.persistence.storageClassName
gitea.persistence.size
gitea.persistence.storageClassName
```

## 验证

```bash
helm lint ./k8s/station
helm template station ./k8s/station >/dev/null
```
