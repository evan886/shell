#!/bin/ksh
#
###############################################################################
# Enhanced batch script with retry mechanism
# Usage: batch.sh SYSTEM_NAME JOB_BATCH_NUM NEED_RESPONSE COUNTRY_CODE GROUP_MEMBER [COUNTRY_EXCHANGE_CODE] [EXTRA_PARMS_LIST] [MAX_RETRIES] [RETRY_INTERVAL]
#
# Examples:
# batch.sh RBP RTBPC022A Y HK HASE BROKER_ID=CUTAS,ASSET_CLASS=CTY
# batch.sh RBP RTBPC022A Y HK HASE "" BROKER_ID=CUTAS,ASSET_CLASS=CTY 3 30
# batch.sh RBP RTBPC022A Y HK HASE CUTAS BROKER_ID=CUTAS,ASSET_CLASS=CTY 5 60
###############################################################################

# 原有参数
SYSTEM_NAME=$1
JOB_BATCH_NUM=$2
NEED_RESPONSE=$3
COUNTRY_CODE=$4
GROUP_MEMBER=$5
COUNTRY_EXCHANGE_CODE=$6
EXTRA_PARMS_LIST=$7

# 新增重试参数
MAX_RETRIES=${8:-3}          # 最大重试次数，默认3次
RETRY_INTERVAL=${9:-30}      # 重试间隔秒数，默认30秒

# 参数验证
if [[ -z "$SYSTEM_NAME" || -z "$JOB_BATCH_NUM" || -z "$NEED_RESPONSE" || -z "$COUNTRY_CODE" || -z "$GROUP_MEMBER" ]]; then
    echo "错误: 缺少必需参数"
    echo "用法: $0 SYSTEM_NAME JOB_BATCH_NUM NEED_RESPONSE COUNTRY_CODE GROUP_MEMBER [COUNTRY_EXCHANGE_CODE] [EXTRA_PARMS_LIST] [MAX_RETRIES] [RETRY_INTERVAL]"
    exit 1
fi

# 处理可能为空的第6个参数
if [[ -z "$COUNTRY_EXCHANGE_CODE" ]]; then
    COUNTRY_EXCHANGE_CODE=""
fi

# 处理可能为空的第7个参数
if [[ -z "$EXTRA_PARMS_LIST" ]]; then
    EXTRA_PARMS_LIST=""
fi

CONFIG_FILE_NAME=`echo "batch.${COUNTRY_CODE}${GROUP_MEMBER}.config" | awk '{print tolower($0)}'`

#Init the SUBJECT DIR
ROOT_DIR=`dirname $0`
if [[ $ROOT_DIR == "." ]] ; then
   ROOT_DIR=`pwd`
fi

# 日志函数
log_message() {
    local level=$1
    local message=$2
    local timestamp=`date '+%Y-%m-%d %H:%M:%S'`
    echo "[$timestamp] [$level] $message"
}

# 数据库状态检查函数
check_db_status() {
    local job_id=$1
    local status=""
    
    # 这里需要根据你的实际数据库连接方式修改
    # 示例使用sqlplus (Oracle) 或者 mysql 命令
    
    # Oracle示例：
    # status=$(sqlplus -s username/password@database <<EOF
    # SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
    # SELECT status FROM job_status_table WHERE job_id='$job_id';
    # EXIT;
    # EOF
    # )
    
    # MySQL示例：
    # status=$(mysql -u username -ppassword -D database_name -sN -e "SELECT status FROM job_status_table WHERE job_id='$job_id'")
    
    # PostgreSQL示例：
    # status=$(psql -U username -d database_name -t -c "SELECT status FROM job_status_table WHERE job_id='$job_id'")
    
    # 临时示例 - 请替换为实际的数据库查询
    log_message "INFO" "检查作业状态: $job_id"
    
    # 模拟数据库查询（请替换为实际查询）
    # 这里需要你提供实际的数据库连接和查询逻辑
    status="UNKNOWN"  # 默认状态
    
    # 实际实现示例（需要根据你的环境调整）:
    if command -v sqlplus >/dev/null 2>&1; then
        # Oracle数据库示例
        status=$(sqlplus -s $DB_USER/$DB_PASS@$DB_SID <<EOF 2>/dev/null | tail -1
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT NVL(status, 'NOT_FOUND') FROM job_status_table WHERE job_id='$job_id';
EXIT;
EOF
        )
    elif command -v mysql >/dev/null 2>&1; then
        # MySQL数据库示例
        status=$(mysql -u$DB_USER -p$DB_PASS -D$DB_NAME -sN -e "SELECT IFNULL(status, 'NOT_FOUND') FROM job_status_table WHERE job_id='$job_id'" 2>/dev/null)
    fi
    
    # 清理状态字符串
    status=$(echo "$status" | tr -d ' \n\r')
    
    log_message "INFO" "作业 $job_id 当前状态: $status"
    echo "$status"
}

# 判断状态是否正常
is_status_normal() {
    local status=$1
    case "$status" in
        "SUCCESS"|"COMPLETED"|"FINISHED"|"OK")
            return 0  # 正常状态
            ;;
        "FAILED"|"ERROR"|"TIMEOUT"|"CANCELLED"|"UNKNOWN"|"NOT_FOUND")
            return 1  # 异常状态，需要重试
            ;;
        "RUNNING"|"PROCESSING"|"IN_PROGRESS")
            return 2  # 运行中状态，需要等待
            ;;
        *)
            return 1  # 未知状态，当作异常处理
            ;;
    esac
}

# 执行主要业务逻辑的函数
execute_main_logic() {
    log_message "INFO" "开始执行批处理作业"
    log_message "INFO" "参数: SYSTEM_NAME=$SYSTEM_NAME, JOB_BATCH_NUM=$JOB_BATCH_NUM"
    log_message "INFO" "参数: NEED_RESPONSE=$NEED_RESPONSE, COUNTRY_CODE=$COUNTRY_CODE"
    log_message "INFO" "参数: GROUP_MEMBER=$GROUP_MEMBER, COUNTRY_EXCHANGE_CODE=$COUNTRY_EXCHANGE_CODE"
    log_message "INFO" "参数: EXTRA_PARMS_LIST=$EXTRA_PARMS_LIST"
    log_message "INFO" "配置文件: $CONFIG_FILE_NAME"
    
    # 这里放置你的原始业务逻辑
    # 例如：
    # - 读取配置文件
    # - 执行数据处理
    # - 调用其他程序
    # - 等等...
    
    # 示例业务逻辑（请替换为实际逻辑）
    if [[ -f "$ROOT_DIR/$CONFIG_FILE_NAME" ]]; then
        log_message "INFO" "使用配置文件: $ROOT_DIR/$CONFIG_FILE_NAME"
        # source "$ROOT_DIR/$CONFIG_FILE_NAME"
    else
        log_message "WARN" "配置文件不存在: $ROOT_DIR/$CONFIG_FILE_NAME"
    fi
    
    # 模拟执行一些处理
    sleep 2
    
    # 返回执行结果
    # 0: 成功, 1: 失败
    return 0
}

# 主重试逻辑
main_with_retry() {
    local attempt=1
    local max_attempts=$((MAX_RETRIES + 1))
    
    while [[ $attempt -le $max_attempts ]]; do
        log_message "INFO" "第 $attempt 次尝试执行 (最多 $max_attempts 次)"
        
        # 执行主要业务逻辑
        if execute_main_logic; then
            log_message "INFO" "业务逻辑执行成功"
            
            # 检查数据库状态
            if [[ -n "$JOB_BATCH_NUM" ]]; then
                log_message "INFO" "等待3秒后检查数据库状态..."
                sleep 3
                
                # 首先尝试详细查询
                local db_status=$(check_job_details "$JOB_BATCH_NUM")
                
                # 如果详细查询失败，尝试简单查询
                if [[ "$db_status" == "DB_ERROR" || "$db_status" == "NOT_FOUND" ]]; then
                    log_message "INFO" "尝试简单状态查询..."
                    db_status=$(check_db_status "$JOB_BATCH_NUM")
                fi
                
                is_status_normal "$db_status"
                local status_result=$?
                
                case $status_result in
                    0)  # 正常状态
                        log_message "INFO" "数据库状态正常，执行完成"
                        return 0
                        ;;
                    2)  # 运行中状态
                        log_message "INFO" "作业仍在运行中，等待 $RETRY_INTERVAL 秒后重新检查"
                        sleep $RETRY_INTERVAL
                        
                        # 重新检查状态
                        db_status=$(check_db_status "$JOB_BATCH_NUM")
                        is_status_normal "$db_status"
                        status_result=$?
                        
                        if [[ $status_result -eq 0 ]]; then
                            log_message "INFO" "作业完成，状态正常"
                            return 0
                        else
                            log_message "WARN" "作业状态仍然异常: $db_status"
                        fi
                        ;;
                    1)  # 异常状态
                        log_message "WARN" "数据库状态异常: $db_status"
                        ;;
                esac
            else
                log_message "INFO" "未提供JOB_BATCH_NUM，跳过状态检查"
                return 0
            fi
        else
            log_message "ERROR" "业务逻辑执行失败"
        fi
        
        # 检查是否还有重试机会
        if [[ $attempt -lt $max_attempts ]]; then
            log_message "WARN" "第 $attempt 次尝试失败，将在 $RETRY_INTERVAL 秒后重试"
            sleep $RETRY_INTERVAL
        else
            log_message "ERROR" "已达到最大重试次数 $MAX_RETRIES，执行失败"
            return 1
        fi
        
        attempt=$((attempt + 1))
    done
    
    return 1
}

# 脚本开始执行
log_message "INFO" "脚本开始执行"
log_message "INFO" "最大重试次数: $MAX_RETRIES, 重试间隔: $RETRY_INTERVAL 秒"

# 执行主逻辑（带重试）
if main_with_retry; then
    log_message "INFO" "脚本执行成功"
    exit 0
else
    log_message "ERROR" "脚本执行失败"
    exit 1
fi