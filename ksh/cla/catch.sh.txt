#!/bin/ksh

# 方法1: 使用 awk 获取特定 Batch job id 的最新结果
get_latest_result_awk() {
    local job_id="$1"
    local log_file="$2"
    
    awk -v job_id="$job_id" '
    /Start Trigger Batch Job\.\.\./ { 
        in_job_block = 1 
        current_job = ""
        result = ""
    }
    /Batch job id:/ && in_job_block { 
        if ($0 ~ job_id) {
            current_job = job_id
        }
    }
    /Result:/ && in_job_block && current_job == job_id { 
        result = $2
    }
    /End Trigger Batch Job\.\.\./ && in_job_block {
        if (current_job == job_id && result != "") {
            latest_result = result
            latest_timestamp = timestamp
        }
        in_job_block = 0
    }
    /^\[.*\]/ { 
        match($0, /\[(.*)\]/, arr)
        if (arr[1]) timestamp = arr[1]
    }
    END { 
        if (latest_result != "") {
            print "Latest result for " job_id ": " latest_result
            print "Timestamp: " latest_timestamp
        } else {
            print "No result found for job id: " job_id
        }
    }' "$log_file"
}

# 方法2: 使用 grep 和 tail 的简单方法
get_latest_result_grep() {
    local job_id="$1"
    local log_file="$2"
    
    # 找到包含指定job id的所有块，然后获取最后一个结果
    grep -A 20 "Batch job id:$job_id" "$log_file" | \
    grep "Result:" | \
    tail -1 | \
    awk '{print "Latest result for '$job_id': " $2}'
}

# 方法3: 更精确的sed/awk组合方法
get_latest_result_precise() {
    local job_id="$1"
    local log_file="$2"
    
    # 提取所有相关的作业块，然后处理
    awk -v job_id="$job_id" '
    BEGIN { RS="\\*\\*\\*\\*\\*\\*"; job_found=0 }
    {
        if ($0 ~ "Batch job id:" job_id) {
            # 提取时间戳
            match($0, /\[([^\]]+)\]/, time_arr)
            timestamp = time_arr[1]
            
            # 提取结果
            match($0, /Result:([^\n\r]+)/, result_arr)
            if (result_arr[1]) {
                gsub(/^[ \t]+|[ \t]+$/, "", result_arr[1])  # 去除前后空格
                results[timestamp] = result_arr[1]
                job_found = 1
            }
        }
    }
    END {
        if (job_found) {
            # 找到最新的时间戳（假设时间戳是可排序的）
            latest_time = ""
            for (time in results) {
                if (latest_time == "" || time > latest_time) {
                    latest_time = time
                }
            }
            print "Latest result for " job_id ": " results[latest_time]
            print "Timestamp: " latest_time
        } else {
            print "No result found for job id: " job_id
        }
    }' "$log_file"
}

# 使用示例
LOG_FILE="your_log_file.log"  # 替换为你的日志文件路径
JOB_ID="RTPDS0231C"

echo "=== Method 1: Using AWK ==="
get_latest_result_awk "$JOB_ID" "$LOG_FILE"

echo -e "\n=== Method 2: Using GREP ==="
get_latest_result_grep "$JOB_ID" "$LOG_FILE"

echo -e "\n=== Method 3: Using Precise AWK ==="
get_latest_result_precise "$JOB_ID" "$LOG_FILE"

# 如果你只想要结果值，可以使用这个简化版本
get_result_only() {
    local job_id="$1"
    local log_file="$2"
    
    grep -A 20 "Batch job id:$job_id" "$log_file" | \
    grep "Result:" | \
    tail -1 | \
    awk '{print $2}'
}

echo -e "\n=== Result Only ==="
LATEST_RESULT=$(get_result_only "$JOB_ID" "$LOG_FILE")
echo "RTPDS0231C latest result: $LATEST_RESULT"
