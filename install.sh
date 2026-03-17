#!/bin/bash

set -e

# OpenClaw 人格化成长系统 - 一键安装脚本

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST="$SCRIPT_DIR/manifest.json"
CONFIG_DIR="$SCRIPT_DIR/config"

# 默认值
AGENT=""
WORKSPACE=""
DRY_RUN=false
FORCE=false
SKIP_CRON=false
VERBOSE=false
UNINSTALL=false

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    cat <<EOF
用法: $0 --agent <name> [options]

选项:
  --agent <name>      目标 agent (必选: mia/main/eric/elena/自定义)
  --workspace <path> 目标 workspace 路径 (可选，默认从 openclaw.json 推断)
  --dry-run           只模拟安装，不实际写入
  --force             强制覆盖已存在的文件
  --skip-cron         不自动创建 cron 任务
  --verbose           显示详细安装过程
  --uninstall         卸载已安装的人格化系统
  -h, --help         显示帮助信息

示例:
  $0 --agent mia
  $0 --agent main --verbose
  $0 --agent eric --dry-run
  $0 --agent mia --uninstall
EOF
    exit 1
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --agent)
            AGENT="$2"
            shift 2
            ;;
        --workspace)
            WORKSPACE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --skip-cron)
            SKIP_CRON=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "未知参数: $1"
            usage
            ;;
    esac
done

# 必选参数检查
if [[ -z "$AGENT" ]]; then
    log_error "必须指定 --agent 参数"
    usage
fi

# =============================================
# 环境检查函数
# =============================================

check_openclaw_version() {
    log_info "检查 OpenClaw 版本..."
    
    if command -v openclaw &> /dev/null; then
        local version=$(openclaw --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [[ -n "$version" ]]; then
            # 简单版本比较 (需要 0.9.0+)
            local major=$(echo "$version" | cut -d. -f1)
            local minor=$(echo "$version" | cut -d. -f2)
            if [[ "$major" -lt 1 && "$minor" -lt 9 ]]; then
                log_warn "OpenClaw 版本 $version < 0.9.0，部分功能可能不可用"
            else
                log_success "OpenClaw 版本: $version"
            fi
        fi
    else
        log_warn "openclaw 命令未找到，跳过版本检查"
    fi
}

check_heartbeat() {
    log_info "检查 heartbeat 配置..."
    
    local openclaw_json="$HOME/.openclaw/openclaw.json"
    if [[ ! -f "$openclaw_json" ]]; then
        log_warn "openclaw.json 不存在，跳过 heartbeat 检查"
        return 0
    fi
    
    # 检查默认 heartbeat 配置
    if grep -q '"heartbeat"' "$openclaw_json"; then
        local hb_enabled=$(grep -A2 '"heartbeat"' "$openclaw_json" | grep -o '"enabled"[[:space:]]*:[[:space:]]*[^,]*' | grep -o 'true\|false')
        if [[ "$hb_enabled" == "true" ]]; then
            log_success "heartbeat 已启用"
        else
            log_warn "heartbeat 未启用，light 模式可能无法工作"
        fi
    else
        log_warn "未找到 heartbeat 配置"
    fi
}

check_memory_search() {
    log_info "检查 memorySearch 配置..."
    
    local openclaw_json="$HOME/.openclaw/openclaw.json"
    if [[ ! -f "$openclaw_json" ]]; then
        log_warn "openclaw.json 不存在，跳过 memorySearch 检查"
        return 0
    fi
    
    # 检查默认 memorySearch 配置
    if grep -q '"memorySearch"' "$openclaw_json"; then
        local ms_enabled=$(grep -A2 '"memorySearch"' "$openclaw_json" | grep -o '"enabled"[[:space:]]*:[[:space:]]*[^,]*' | grep -o 'true\|false')
        if [[ "$ms_enabled" == "true" ]]; then
            log_success "memorySearch 已启用"
        else
            log_warn "memorySearch 未启用，长期文档语义检索可能不可用"
        fi
    else
        log_warn "未找到 memorySearch 配置，建议启用以获得更好的文档检索"
    fi
}

check_agent_exists() {
    log_info "检查 agent '$AGENT' 是否存在..."
    
    local openclaw_json="$HOME/.openclaw/openclaw.json"
    if [[ ! -f "$openclaw_json" ]]; then
        log_error "openclaw.json 不存在，无法验证 agent"
        exit 1
    fi
    
    if grep -q "\"$AGENT\"" "$openclaw_json"; then
        log_success "agent '$AGENT' 已存在"
    else
        log_error "agent '$AGENT' 不存在，请先创建: openclaw agent create $AGENT"
        exit 1
    fi
}

check_cron_support() {
    log_info "检查 cron 支持..."
    
    # 检查 cron 目录是否存在
    if [[ -d "$HOME/.openclaw/cron" ]]; then
        log_success "cron 目录存在"
    else
        log_warn "cron 目录不存在，尝试创建..."
        mkdir -p "$HOME/.openclaw/cron"
    fi
    
    # 检查 cron jobs.json 是否可写
    local cron_file="$HOME/.openclaw/cron/jobs.json"
    if [[ -f "$cron_file" ]]; then
        if [[ -w "$cron_file" ]]; then
            log_success "cron jobs.json 可写"
        else
            log_warn "cron jobs.json 不可写，可能需要手动添加任务"
        fi
    else
        log_info "cron jobs.json 不存在，安装后可以创建"
    fi
}

run_environment_check() {
    echo ""
    echo "============================================"
    echo "  环境检查"
    echo "============================================"
    echo ""
    
    check_openclaw_version
    check_heartbeat
    check_memory_search
    check_agent_exists
    check_cron_support
    
    echo ""
    log_success "环境检查完成"
    echo ""
}

# 推断 workspace 路径
infer_workspace() {
    if [[ -n "$WORKSPACE" ]]; then
        return 0
    fi
    
    local openclaw_json="$HOME/.openclaw/openclaw.json"
    if [[ -f "$openclaw_json" ]]; then
        local ws_path=$(grep -A5 "\"$AGENT\"" "$openclaw_json" | grep -o '"workspace"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)"/\1/')
        if [[ -n "$ws_path" ]]; then
            WORKSPACE="$ws_path"
            return 0
        fi
    fi
    
    # 默认路径
    WORKSPACE="$HOME/.openclaw/workspace-$AGENT"
    return 0
}

# 检查 workspace 是否存在
check_workspace() {
    if [[ ! -d "$WORKSPACE" ]]; then
        log_error "Workspace 不存在: $WORKSPACE"
        log_info "请先创建 agent 或指定正确的 --workspace 路径"
        exit 1
    fi
    log_success "目标 workspace: $WORKSPACE"
}

# 读取 manifest
load_manifest() {
    if [[ ! -f "$MANIFEST" ]]; then
        log_error "manifest.json 不存在"
        exit 1
    fi
    log_success "加载 manifest.json 成功"
}

# 创建目录结构
create_directories() {
    log_info "创建目录结构..."
    
    local dirs=(
        "$WORKSPACE/memory"
        "$WORKSPACE/memory/inbox"
        "$WORKSPACE/skills/personhood-document-maintainer"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY-RUN] 创建目录: $dir"
            else
                mkdir -p "$dir"
                log_success "创建目录: $dir"
            fi
        else
            log_warn "目录已存在: $dir"
        fi
    done
}

# 安装模板文件
install_templates() {
    log_info "安装模板文件..."
    
    local templates=(
        "templates/world.md"
        "templates/self.md"
        "templates/expression.md"
        "templates/inbox-README.md"
    )
    
    for tmpl in "${templates[@]}"; do
        local src="$SCRIPT_DIR/$tmpl"
        local dst="$WORKSPACE/memory/$(basename "$tmpl")"
        
        if [[ -f "$src" ]]; then
            if [[ -f "$dst" && "$FORCE" != "true" ]]; then
                log_warn "跳过已存在文件: $dst (使用 --force 强制覆盖)"
            else
                if [[ "$DRY_RUN" == "true" ]]; then
                    log_info "[DRY-RUN] 复制: $src -> $dst"
                else
                    cp "$src" "$dst"
                    log_success "安装模板: $(basename "$tmpl")"
                fi
            fi
        else
            log_warn "模板源文件不存在: $src"
        fi
    done
}

# 安装 skill
install_skill() {
    log_info "安装 personhood-document-maintainer skill..."
    
    local src="$SCRIPT_DIR/skills/personhood-document-maintainer/SKILL.md"
    local dst="$WORKSPACE/skills/personhood-document-maintainer/SKILL.md"
    
    if [[ -f "$src" ]]; then
        if [[ -f "$dst" && "$FORCE" != "true" ]]; then
            log_warn "跳过已存在 skill: $dst (使用 --force 强制覆盖)"
        else
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY-RUN] 复制: $src -> $dst"
            else
                mkdir -p "$(dirname "$dst")"
                cp "$src" "$dst"
                log_success "安装 skill: personhood-document-maintainer"
            fi
        fi
    else
        log_error "skill 源文件不存在: $src"
    fi
}

# 安装文档
install_docs() {
    log_info "安装方案文档..."
    
    local doc_files=(
        "docs/overview.md"
        "docs/pre-hook-methodology.md"
        "docs/post-hook-methodology.md"
        "docs/capture-hook-selection-rules.md"
        "docs/cron-hooking-plan.md"
        "docs/weekly-evolution-and-skill-improvement.md"
    )
    
    for doc in "${doc_files[@]}"; do
        local src="$SCRIPT_DIR/$doc"
        local dst="$WORKSPACE/docs/personhood/$(basename "$doc")"
        
        if [[ -f "$src" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY-RUN] 复制: $src -> $dst"
            else
                mkdir -p "$(dirname "$dst")"
                cp "$src" "$dst"
                log_success "安装文档: $(basename "$doc")"
            fi
        fi
    done
}

# 生成 cron 任务配置
generate_cron_config() {
    log_info "生成 cron 任务配置..."
    
    local cron_file="$WORKSPACE/.personhood-cron.json"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] 生成 cron 配置: $cron_file"
        return 0
    fi
    
    cat > "$cron_file" <<'CRONEOF'
{
  "personhoodSystem": {
    "installed": true,
    "version": "1.0.0",
    "installedAt": "2026-03-17",
    "agent": "AGENT_PLACEHOLDER"
  },
  "cronJobs": [
    {
      "name": "AGENT_PLACEHOLDER-memory-daily-distill",
      "schedule": "30 23 * * *",
      "mode": "normal",
      "enabled": true
    },
    {
      "name": "AGENT_PLACEHOLDER-agent-self-evolution",
      "schedule": "0 2 * * 0",
      "mode": "deep",
      "enabled": true
    },
    {
      "name": "AGENT_PLACEHOLDER-capability-evolver",
      "schedule": "20 2 * * 0",
      "mode": "weekly-skill-evolution",
      "enabled": true
    }
  ]
}
CRONEOF
    
    # 替换 agent 占位符
    sed -i '' "s/AGENT_PLACEHOLDER/$AGENT/g" "$cron_file"
    
    log_success "生成 cron 配置: $cron_file"
    log_info "请手动将以下 cron 任务添加到 openclaw cron:"
    log_info "  - ${AGENT}-memory-daily-distill (每日 23:30)"
    log_info "  - ${AGENT}-agent-self-evolution (每周日 02:00)"
    log_info "  - ${AGENT}-capability-evolver (每周日 02:20)"
}

# 验证安装
validate_install() {
    log_info "验证安装..."
    
    local required_files=(
        "$WORKSPACE/memory/world.md"
        "$WORKSPACE/memory/self.md"
        "$WORKSPACE/memory/expression.md"
        "$WORKSPACE/memory/inbox/README.md"
        "$WORKSPACE/skills/personhood-document-maintainer/SKILL.md"
    )
    
    local missing=0
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            [[ "$VERBOSE" == "true" ]] && log_success "验证通过: $(basename "$file")"
        else
            log_error "验证失败: $file"
            ((missing++))
        fi
    done
    
    if [[ $missing -eq 0 ]]; then
        log_success "安装验证通过"
        return 0
    else
        log_error "安装验证失败: $missing 个文件缺失"
        return 1
    fi
}

# 卸载
uninstall() {
    log_info "卸载人格化系统..."
    
    local files=(
        "$WORKSPACE/memory/world.md"
        "$WORKSPACE/memory/self.md"
        "$WORKSPACE/memory/expression.md"
        "$WORKSPACE/memory/inbox/README.md"
        "$WORKSPACE/skills/personhood-document-maintainer/SKILL.md"
        "$WORKSPACE/.personhood-cron.json"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY-RUN] 删除: $file"
            else
                rm -f "$file"
                log_success "删除: $file"
            fi
        fi
    done
    
    log_success "卸载完成"
}

# 主流程
main() {
    echo "============================================"
    echo "  OpenClaw 人格化成长系统 - 安装向导"
    echo "============================================"
    echo ""
    
    if [[ "$UNINSTALL" == "true" ]]; then
        infer_workspace
        check_workspace
        uninstall
        exit 0
    fi
    
    # 先做环境检查
    run_environment_check
    
    infer_workspace
    check_workspace
    load_manifest
    
    echo ""
    echo "安装配置:"
    echo "  Agent: $AGENT"
    echo "  Workspace: $WORKSPACE"
    echo "  Dry-Run: $DRY_RUN"
    echo "  Force: $FORCE"
    echo "  Skip-Cron: $SKIP_CRON"
    echo ""
    
    create_directories
    install_templates
    install_skill
    install_docs
    
    if [[ "$SKIP_CRON" != "true" ]]; then
        generate_cron_config
    fi
    
    if [[ "$DRY_RUN" != "true" ]]; then
        validate_install
    fi
    
    echo ""
    log_success "安装完成!"
    echo ""
    echo "下一步:"
    echo "  1. 查看文档: $WORKSPACE/docs/personhood/"
    echo "  2. 整理现有 AGENTS.md / USER.md / MEMORY.md 内容到新分层"
    echo "  3. 添加 cron 任务（如果未自动创建）"
    echo "  4. 运行一次 normal 模式维护初始化内容"
    echo ""
}

main
