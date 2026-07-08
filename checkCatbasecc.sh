#!/bin/bash

# CatBase 批量测试脚本
# 用于测试 examples/ 文件夹中的所有 .cat 程序

# 注意：不要使用 set -e，让脚本继续运行所有测试
# set -e  # 已禁用，允许脚本继续运行即使遇到错误

CATBASE_CC="./bin/catbasecc"
EXAMPLES_DIR="./examples"
RESULTS_FILE="test_results.txt"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 统计变量
total=0
passed=0
failed=0
skipped=0

# 记录成功和失败的测试
declare -a PASSED_TESTS=()
declare -a FAILED_TESTS=()
declare -a SKIPPED_TESTS=()

# 清空结果文件
> "$RESULTS_FILE"

echo "========================================" | tee -a "$RESULTS_FILE"
echo "CatBase 批量测试开始" | tee -a "$RESULTS_FILE"
echo "时间: $(date)" | tee -a "$RESULTS_FILE"
echo "========================================" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

# 获取所有 .cat 文件（排除 test_all.sh 自身）
cat_files=()
for f in "$EXAMPLES_DIR"/*.cat; do
    basename_file="$(basename "$f")"
    # 跳过 test_all.sh 和 import_* 文件（这些是被其他程序引用的模块，不是独立程序）
    if [[ "$basename_file" != "test_all.sh" ]] && [[ ! "$basename_file" =~ ^import_ ]]; then
        cat_files+=("$f")
    fi
done

total=${#cat_files[@]}

echo "找到 $total 个测试文件" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

# 按文件名排序
IFS=$'\n' sorted=($(sort <<<"${cat_files[*]}"))
unset IFS

# 编译并运行每个文件
for cat_file in "${sorted[@]}"; do
    filename=$(basename "$cat_file")
    base_name="${filename%.cat}"
    executable="./$base_name"
    
    echo "----------------------------------------" | tee -a "$RESULTS_FILE"
    echo "测试: $filename" | tee -a "$RESULTS_FILE"
    echo "----------------------------------------" | tee -a "$RESULTS_FILE"
    
    # 编译
    echo "编译中..." | tee -a "$RESULTS_FILE"
    if $CATBASE_CC "$cat_file" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 编译成功${NC}" | tee -a "$RESULTS_FILE"
        
        # test_norun_* 文件只编译不运行
        if [[ "$base_name" == test_norun_* ]]; then
            echo -e "${YELLOW}⚠ test_norun_* 文件，只编译不运行${NC}" | tee -a "$RESULTS_FILE"
            ((passed++))
            PASSED_TESTS+=("$filename (编译通过)")
        # 检查可执行文件是否存在
        elif [[ -f "$executable" ]]; then
            # 运行
            echo "运行中..." | tee -a "$RESULTS_FILE"
            if timeout 30 "$executable" > /dev/null 2>&1; then
                echo -e "${GREEN}✓ 运行成功${NC}" | tee -a "$RESULTS_FILE"
                ((passed++))
                PASSED_TESTS+=("$filename")
            else
                exit_code=$?
                if [[ $exit_code -eq 139 ]] || [[ $exit_code -eq 134 ]]; then
                    # 139 = SIGSEGV, 134 = SIGABRT (段错误/断言失败)
                    echo -e "${RED}✗ 运行失败 (段错误/崩溃)${NC}" | tee -a "$RESULTS_FILE"
                else
                    echo -e "${RED}✗ 运行失败 (退出码: $exit_code)${NC}" | tee -a "$RESULTS_FILE"
                fi
                ((failed++))
                FAILED_TESTS+=("$filename")
            fi
        else
            echo -e "${YELLOW}⚠ 可执行文件不存在，跳过运行${NC}" | tee -a "$RESULTS_FILE"
            ((skipped++))
            SKIPPED_TESTS+=("$filename")
        fi
    else
        echo -e "${RED}✗ 编译失败${NC}" | tee -a "$RESULTS_FILE"
        # 重新运行编译命令以显示错误
        $CATBASE_CC "$cat_file" 2>&1 | head -5 | tee -a "$RESULTS_FILE"
        # test_error_* 文件预期编译失败，这是正确的行为
        if [[ "$base_name" == test_error_* ]]; then
            echo -e "${GREEN}✓ (预期错误，测试正确)${NC}" | tee -a "$RESULTS_FILE"
            ((passed++))
            PASSED_TESTS+=("$filename (预期编译错误)")
        else
            ((failed++))
            FAILED_TESTS+=("$filename")
        fi
    fi
    
    echo "" | tee -a "$RESULTS_FILE"
done

# 输出总结
# 输出成功列表
if [[ ${#PASSED_TESTS[@]} -gt 0 ]]; then
    echo -e "${GREEN}========================================${NC}" | tee -a "$RESULTS_FILE"
    echo -e "${GREEN}✓ 成功的测试 (${#PASSED_TESTS[@]}个)${NC}" | tee -a "$RESULTS_FILE"
    echo -e "${GREEN}========================================${NC}" | tee -a "$RESULTS_FILE"
    for test in "${PASSED_TESTS[@]}"; do
        echo -e "  ${GREEN}✓${NC} $test" | tee -a "$RESULTS_FILE"
    done
    echo "" | tee -a "$RESULTS_FILE"
fi

# 输出失败列表
if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
    echo -e "${RED}========================================${NC}" | tee -a "$RESULTS_FILE"
    echo -e "${RED}✗ 失败的测试 (${#FAILED_TESTS[@]}个)${NC}" | tee -a "$RESULTS_FILE"
    echo -e "${RED}========================================${NC}" | tee -a "$RESULTS_FILE"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}✗${NC} $test" | tee -a "$RESULTS_FILE"
    done
    echo "" | tee -a "$RESULTS_FILE"
fi

# 输出跳过列表
if [[ ${#SKIPPED_TESTS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}========================================${NC}" | tee -a "$RESULTS_FILE"
    echo -e "${YELLOW}⚠ 跳过的测试 (${#SKIPPED_TESTS[@]}个)${NC}" | tee -a "$RESULTS_FILE"
    echo -e "${YELLOW}========================================${NC}" | tee -a "$RESULTS_FILE"
    for test in "${SKIPPED_TESTS[@]}"; do
        echo -e "  ${YELLOW}⚠${NC} $test" | tee -a "$RESULTS_FILE"
    done
    echo "" | tee -a "$RESULTS_FILE"
fi

echo "========================================" | tee -a "$RESULTS_FILE"
echo "测试总结" | tee -a "$RESULTS_FILE"
echo "========================================" | tee -a "$RESULTS_FILE"
echo "总数:   $total" | tee -a "$RESULTS_FILE"
echo -e "通过:   ${GREEN}$passed${NC}" | tee -a "$RESULTS_FILE"
echo -e "失败:   ${RED}$failed${NC}" | tee -a "$RESULTS_FILE"
echo -e "跳过:   ${YELLOW}$skipped${NC}" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}所有测试通过！${NC}" | tee -a "$RESULTS_FILE"
    exit 0
else
    echo -e "${RED}有 $failed 个测试失败！${NC}" | tee -a "$RESULTS_FILE"
    echo "详细信息请查看: $RESULTS_FILE"
    exit 1
fi
