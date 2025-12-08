如果你已经在 AWS 中误创建了两个 ALB（Application Load Balancer），而实际上它们的 listener rules 是相似的、可以被合并成一台 ALB，那么可以按照以下步骤进行「合并」操作，最终达到节省 IP 和运维成本的目的。

⚠️ 注意：ALB 本身无法被「直接合并」，但你可以通过以下流程手动迁移 Ingress 规则并删除多余的 ALB。

✅ 步骤概览：合并两台已存在的 ALB

🔹 步骤 1：分析现有两个 ALB 的配置

你需要确认这两个 ALB 分别绑定了哪些 Kubernetes Ingress 资源，以及它们的配置是否兼容合并。

查看命令（AWS CLI）：
aws elbv2 describe-load-balancers --names <alb-name-1> <alb-name-2>


查看 listener 和 rules：
aws elbv2 describe-listeners --load-balancer-arn <alb-arn>
aws elbv2 describe-rules --listener-arn <listener-arn>


同时，在 Kubernetes 中查看 Ingress 资源：
kubectl get ingress -A
kubectl describe ingress <ingress-name> -n <namespace>


重点检查：

• 两个 ALB 的 scheme（internet-facing / internal）

• 使用的 certificate（HTTPS）

• 端口（80, 443）

• 所属 IngressClass 或 group.name

• 安全组设置

• 注解是否一致

如果它们基本一致，就可以合并。

🔹 步骤 2：创建一个新的合并后的 Ingress 资源（或改造已有）

你可以选择：

• 编辑现有的其中一个 Ingress，加入另一个 ALB 中的路径规则；

• 或者创建一个新的 Ingress，包含两者的规则，并确保注解保持一致；

• 如果使用 IngressGroup，请添加 group.name 注解确保它们共用一个 ALB。

示例（Kubernetes Ingress YAML）：
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: merged-ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...
    alb.ingress.kubernetes.io/group.name: shared-alb-group   # 可选，用于强制合并
spec:
  rules:
  - http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: app1-svc
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: app2-svc
            port:
              number: 80


部署这个 Ingress 后，AWS Load Balancer Controller 会：

• 创建一个新的 ALB（如果没有 group.name）；

• 或向现有的 group.name 对应的 ALB 添加新的 Listener Rule（如果有 group.name 且匹配）；

🎯 目标：让所有规则都集中在一个 ALB 中。

🔹 步骤 3：验证新 ALB 正常工作

• 确认新的 ALB 已经成功创建，并且 listener rules 包含了原有两条 ALB 的所有路径。

• 访问测试各个路径（如 https://<alb-dns>/app1 和 /app2）确保服务可达。

• 查看 controller 日志确保没有报错：
kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller


🔹 步骤 4：清理旧的 ALB 和相关资源

一旦确认新的 Ingress 工作正常，不再依赖旧 ALB，可以安全删除旧的资源：

① 删除旧的 Ingress 资源（Kubernetes 中）

kubectl delete ingress <old-ingress-name> -n <namespace>


② 等待 AWS Load Balancer Controller 删除对应 ALB

默认情况下，删除 Ingress 后几分钟内 controller 会自动删除关联的 ALB（除非它被其他资源引用）。

你也可以手动删除（谨慎操作）：
aws elbv2 delete-load-balancer --load-balancer-arn <old-alb-arn>


⚠️ 注意：

• 删除 ALB 是不可逆操作；

• 如果有外部 DNS 或硬编码 IP 指向旧 ALB，需提前修改；

• 删除前请备份重要配置。

🔹 步骤 5：（可选）DNS 切换 & 通知团队

如果你曾将域名解析指向旧 ALB 的 DNS 名称，现在应：

• 更新 Route53 或其他 DNS 服务，将记录指向新的 ALB；

• 通知相关团队切换完成；

• 观察监控指标确保流量平滑迁移。

🧠 小贴士：防止未来误建多个 ALB

• 统一使用 IngressGroup（group.name）管理同类服务；

• 设置命名规范或 Terraform/Helm 模块限制重复创建；

• 定期审计 AWS 控制台或使用 Infrastructure as Code 工具管理资源。

✅ 总结

步骤 说明

① 分析 了解两个 ALB 的配置和对应 Ingress

② 合并 创建新的 Ingress 合并所有规则，可配合 group.name

③ 验证 测试新 ALB 是否工作正常

④ 清理 删除旧 Ingress 和 ALB

⑤ 切换 如有 DNS，需更新指向新 ALB

如果你提供两个 ALB 的相关配置，我还可以帮你写出具体的合并方案和 YAML 示例 👍

是否需要我进一步协助你分析现有 Ingress 和 ALB？
