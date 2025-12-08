
在 AWS 控制台里只能创建、删除或修改单个 ALB 的监听器、规则、目标组等配置，但没有“把两个已有 ALB 合并成一个”的按钮或向导。
一旦 ALB 被创建出来，它就拥有自己独立的 ARN、DNS 名、监听器和目标组，控制台无法将其“融合”到一起。
想实现“多组规则共用同一个 ALB”只能走 Kubernetes 侧的方案：

    给所有 Ingress 加上同样的
    alb.ingress.kubernetes.io/group.name: <同一名称>
    注解，AWS Load Balancer Controller 会自动把规则写到同一台 ALB上

    。
    若已经误建了两台 ALB，只能：
        在控制台手动删除其中一台（先导出它的规则），
        然后把规则通过 kubectl 补到剩下的 Ingress 里，
        让 Controller 把缺失的规则重新写进剩下的那台 ALB。

总结：合并动作必须在 Kubernetes Ingress 层面完成，控制台本身不提供 ALB 合并功能。
*****************************************************
在控制台手动删除其中一台（先导出它的规则

AWS 控制台 **没有“一键导出”** 按钮能把 ALB 的所有 listener rule 一次性抓下来，  
但可以用 **AWS CLI 一条循环命令** 把规则完整地“导出”成文本，步骤如下（全过程 1-2 分钟）：

1. 安装/配置 CLI（已配置可跳过）  
   ```bash
   aws configure   # 选区、Key 配好
   ```

2. 找到要退役的那台 ALB 的 ARN  
   控制台 **Load Balancers → 选中实例 → 右上角 Copy ARN**  
   或 CLI  
   ```bash
   aws elbv2 describe-load-balancers \
     --query 'LoadBalancers[?LoadBalancerName==`my-alb-name`].LoadBalancerArn' \
     --output text
   ```

3. 列出该 ALB 的所有 listener ARN  
   ```bash
   aws elbv2 describe-listeners \
     --load-balancer-arn <ALB_ARN> \
     --query 'Listeners[].ListenerArn' \
     --output table
   ```

4. 对每个 listener 导出 rules（核心）  
   ```bash
   for ln in $(aws elbv2 describe-listeners \
                 --load-balancer-arn <ALB_ARN> \
                 --query 'Listeners[].ListenerArn' --output text); do
     echo "===== Listener $ln ====="
     aws elbv2 describe-rules --listener-arn $ln \
       --query 'Rules[*].{Priority:Priority,Conditions:Conditions,Actions:Actions,RuleArn:RuleArn}' \
       --output json
   done > alb-rules-backup.json
   ```
   得到的 `alb-rules-backup.json` 就是**完整规则副本**，包括优先级、路径/主机条件、目标组、固定响应、重定向等所有字段。

5. （可选）把目标组信息也备份一下，方便稍后核对  
   ```bash
   aws elbv2 describe-target-groups \
     --query 'TargetGroups[*].{TGArn:TargetGroupArn,Protocol:Protocol,Port:Port,VPC:VpcId}' \
     --output table
   ```

6. 确认备份无误后，即可  
   - 在控制台 **Listeners 页签** 逐条**手动删除**非默认规则（默认规则无法删，只能随监听一起删）；  
   - 或继续用 CLI 批量删：  
     ```bash
     aws elbv2 delete-rule --rule-arn <RULE_ARN>
     ```

7. 规则已全部移除、流量归零后，**删除 ALB 本身**即完成“合并”前的清理工作。

这样就把“导出规则 → 留档 → 清规则 → 删 ALB”整条链路跑通了，之后把对应域名/路径补到剩下的 Ingress 里，AWS Load Balancer Controller 会自动把规则写回**仅存的那台 ALB** 上，实现真正的“合并”并节省一个 IP。

*****

