#!/usr/bin/env bash
#===============================================================================
# OpenClaw Agent Bootstrap Kit — 主安装脚本
# 用法：
#   bash install.sh <agent_id> [--name <名字>] [--cron-base 0-3] [--slot 0-3] [--repair] [--verify]
# 示例：
#   bash install.sh mia --name Mia --cron-base 1 --slot 1
#===============================================================================

set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_ID="${1:-}"
ACTION="install"

#-------------------------------------------------------------------------------
# 颜色
#-------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_err()   { echo -e "${RED}[ERR]${NC}   $1"; }
log_step()  { echo -e "${BLUE}[STEP]${NC}  $1"; }

#-------------------------------------------------------------------------------
# 解析参数
#-------------------------------------------------------------------------------
NAME=""
CRON_BASE=""    # 0-3: daily distill slot
CRON_SLOT=""    # 0-3: weekly evolution slot
REPAIR=false
VERIFY=false

while [[ $# -gt 1 ]]; do
  case "$2" in
    --name)        NAME="$3";         shift 2 ;;
    --cron-base)   CRON_BASE="$3";   shift 2 ;;
    --slot)        CRON_SLOT="$3";    shift 2 ;;
    --repair)       REPAIR=true;      shift ;;
    --verify)       VERIFY=true;      shift ;;
    *)              log_err "未知参数: $2"; exit 1 ;;
  esac
done

if [[ "$ACTION" == "verify" ]] || [[ "$VERIFY" == "true" ]]; then
  VERIFY=true; ACTION="verify"
fi

if [[ -z "$AGENT_ID" ]]; then
  echo "用法: bash install.sh <agent_id> [--name <名字>] [--cron-base 0-3] [--slot 0-3] [--repair] [--verify]"
  echo ""
  echo "参数说明:"
  echo "  agent_id      智能体 ID（必填），如 mia / elena / coding"
  echo "  --name       智能体名字（默认等于 agent_id）"
  echo "  --cron-base  日蒸馏 cron 槽位 0-3（默认自动分配最小可用）"
  echo "  --slot       周提升 cron 槽位 0-3（默认自动分配最小可用）"
  echo "  --repair     修复模式：跳过已有文件，只补充缺失项"
  echo "  --verify     验证模式：检查安装状态，不做任何修改"
  exit 1
fi

# 默认名字
[[ -z "$NAME" ]] && NAME="$AGENT_ID"

#-------------------------------------------------------------------------------
# 读取 cron 分配配置
#-------------------------------------------------------------------------------
CRON_MAP="$KIT_DIR/config/agent-cron-map.json"

get_cron_slot() {
  local type="$1"      # "daily" or "weekly"
  local idx="$2"       # slot index 0-3
  python3 -c "
import json
with open('$CRON_MAP') as f:
    m = json.load(f)
print(m['$type'][str($idx)])
" 2>/dev/null || echo "10 0 * * *"
}

# 自动分配 cron slot（读取已占用，从最小可用分配）
allocate_slot() {
  local type="$1"
  local already_used=$(openclaw cron list 2>/dev/null | \
    awk '/memory-daily-distill|self-evolution/ {print $4}' | \
    grep -v '^$' | sort -u)

  for i in 0 1 2 3; do
    local candidate=$(get_cron_slot "$type" "$i" | awk '{print $1" "$2}')
    if ! echo "$already_used" | grep -qF "$candidate"; then
      echo "$i"
      return
    fi
  done
  echo "0"
}

# 自动分配
[[ -z "$CRON_BASE" ]] && CRON_BASE=$(allocate_slot "daily")
[[ -z "$CRON_SLOT" ]] && CRON_SLOT=$(allocate_slot "weekly")

CRON_DAILY=$(get_cron_slot "daily" "$CRON_BASE")
CRON_WEEKLY=$(get_cron_slot "weekly" "$CRON_SLOT")

# 解析 cron 表达式
read DAILY_MIN DAILY_HR _ <<< "$CRON_DAILY"
read WEEKLY_MIN WEEKLY_HR _ <<< "$CRON_WEEKLY"

INSTALL_DATE=$(date +%Y-%m-%d)

#-------------------------------------------------------------------------------
# 路径
#-------------------------------------------------------------------------------
WORKSPACE_DIR="$HOME/.openclaw/workspace-${AGENT_ID}"
AGENT_WORKSPACE_DIR="$HOME/.openclaw/workspace-${AGENT_ID}"

#-------------------------------------------------------------------------------
# 变量替换函数
#-------------------------------------------------------------------------------
substitute() {
  local src="$1"
  local dst="$2"
  sed -e "s/{{AGENT_ID}}/${AGENT_ID}/g" \
      -e "s/{{AGENT_NAME}}/${NAME}/g" \
      -e "s/{{CRON_BASE}}/${CRON_BASE}/g" \
      -e "s/{{CRON_SLOT}}/${CRON_SLOT}/g" \
      -e "s/{{INSTALL_DATE}}/${INSTALL_DATE}/g" \
      -e "s/{{CRON_DAILY}}/${CRON_DAILY}/g" \
      -e "s/{{CRON_WEEKLY}}/${CRON_WEEKLY}/g" \
      "$src" > "$dst"
}

#-------------------------------------------------------------------------------
# 验证模式
#-------------------------------------------------------------------------------
do_verify() {
  log_step "验证 $AGENT_ID 安装状态"
  local errors=0

  # 检查 workspace
  if [[ -d "$WORKSPACE_DIR" ]]; then
    log_ok "workspace 存在: $WORKSPACE_DIR"
  else
    log_err "workspace 不存在: $WORKSPACE_DIR"
    ((errors++))
  fi

  # 检查核心文件
  for f in SOUL.md AGENTS.md IDENTITY.md; do
    if [[ -f "$WORKSPACE_DIR/$f" ]]; then
      log_ok "$f 存在"
    else
      log_warn "$f 缺失"
    fi
  done

  # 检查 bootstrap.done
  if [[ -f "$WORKSPACE_DIR/bootstrap.done" ]]; then
    log_ok "bootstrap.done 存在"
  else
    log_warn "bootstrap.done 缺失（可能未完成初始化）"
  fi

  # 检查 skills
  local skill_count=$(ls "$WORKSPACE_DIR/skills/" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$skill_count" -gt 0 ]]; then
    log_ok "skills 目录: $skill_count 个 skill"
  else
    log_warn "skills 目录为空"
    ((errors++))
  fi

  # 检查 cron
  # 检查 cron（用 awk 替代 grep -P）
  local cron_count=$(openclaw cron list 2>/dev/null | \
    awk '/memory-daily-distill|self-evolution/ {c++} END {print c+0}')
  if [[ "$cron_count" -ge 1 ]]; then
    log_ok "cron 任务: $cron_count 个"
  else
    log_warn "cron 任务缺失（应该各有日蒸馏+周提升）"
  fi

  # 检查 memory 目录
  if [[ -d "$WORKSPACE_DIR/memory" ]]; then
    log_ok "memory 目录存在"
  else
    log_warn "memory 目录缺失"
  fi

  if [[ "$errors" -eq 0 ]]; then
    log_ok "验证通过，无严重错误"
  else
    log_err "发现 $errors 个问题，请运行 --repair 修复"
  fi
}

#-------------------------------------------------------------------------------
# 安装技能
#-------------------------------------------------------------------------------
install_skills() {
  log_step "安装技能"

  local dest="$WORKSPACE_DIR/skills"
  mkdir -p "$dest"

  # 技能安装映射：来源 → 目标名
  declare -A SKILL_MAP=(
    ["$HOME/.openclaw/workspace/skills/tuanziguardianclaw"]="tuanziguardianclaw"
    ["$HOME/.agents/skills/clawdefender-1"]="clawdefender"
    ["$HOME/.agents/skills/skill-vetter-1.0.0"]="skill-vetter"
    ["$HOME/.openclaw/workspace/skills/openclaw-memory-maintainer"]="openclaw-memory-maintainer"
    ["$HOME/.openclaw/workspace/skills/proactive-agent-lite"]="proactive-agent-lite"
    ["$HOME/.agents/skills/self-improving-1.1.3"]="self-improving"
    ["$HOME/.openclaw/workspace/skills/find-skills"]="find-skills"
    ["$HOME/.openclaw/workspace/skills/openclaw-minimax-router"]="openclaw-minimax-router"
    ["$HOME/.openclaw/workspace/skills/image-generation"]="image-generation"
    ["$HOME/.openclaw/workspace/skills/web-content-capture"]="web-content-capture"
    ["$HOME/.openclaw/workspace/skills/feishu-chat-history"]="feishu-chat-history"
    ["$HOME/.openclaw/workspace/skills/feishu-cron-reminder"]="feishu-cron-reminder"
    ["$HOME/.openclaw/workspace/skills/feishu-screenshot"]="feishu-screenshot"
    ["$HOME/.openclaw/workspace/skills/feishu-send-file"]="feishu-send-file"
    ["$HOME/.openclaw/workspace/skills/personhood-document-maintainer"]="personhood-document-maintainer"
    ["$HOME/.openclaw/workspace/skills/openclaw-cron-creator"]="openclaw-cron-creator"
    ["$HOME/.agents/skills/pinchtab-browser"]="pinchtab-browser"
    ["$HOME/.agents/skills/feishu-doc-1.2.7"]="feishu-doc"
    ["$HOME/.agents/skills/memory-1.0.2"]="memory"
    ["$HOME/.agents/skills/self-improving-1.1.3"]="self-improving"
    ["$HOME/.agents/skills/social-content-generator-0.1.0"]="social-content"
    ["$HOME/.agents/skills/brainstorming-0.1.0"]="brainstorming"
    ["$HOME/.agents/skills/writing-plans-0.1.0"]="writing-plans"
    ["$HOME/.agents/skills/automation-workflows-0.1.0"]="automation-workflows"
  )

  local installed=0
  local skipped=0
  local failed=0

  for src in "${!SKILL_MAP[@]}"; do
    local name="${SKILL_MAP[$src]}"
    local link="$dest/$name"

    if [[ ! -e "$src" ]]; then
      log_warn "来源不存在，跳过: $name ($src)"
      ((skipped++))
      continue
    fi

    if [[ -L "$link" ]]; then
      if [[ "$(readlink -f "$link")" == "$(readlink -f "$src")" ]]; then
        log_ok "已链接: $name"
        ((skipped++))
      else
        if [[ "$REPAIR" == "false" ]]; then
          log_warn "已有不同链接，覆盖: $name"
          rm "$link"
          ln -s "$(readlink -f "$src")" "$link"
          ((installed++))
        fi
      fi
    elif [[ -e "$link" ]]; then
      if [[ "$REPAIR" == "true" ]]; then
        log_ok "已存在，跳过: $name"
        ((skipped++))
      else
        log_warn "已存在文件（非链接），跳过: $name"
        ((skipped++))
      fi
    else
      mkdir -p "$(dirname "$link")"
      ln -s "$(readlink -f "$src")" "$link"
      log_ok "安装: $name"
      ((installed++))
    fi
  done

  echo "  安装 $installed / 跳过 $skipped / 失败 $failed"
}

#-------------------------------------------------------------------------------
# 安装 personality 模板
#-------------------------------------------------------------------------------
install_personality() {
  log_step "安装 personality 模板"

  local src="$KIT_DIR/templates/personality"
  local dst="$WORKSPACE_DIR"

  # 全局通用文件（直接复制，不替换）
  cp -n "$src/soul.md"           "$dst/SOUL.md"       2>/dev/null || log_ok "SOUL.md 已存在，跳过"
  cp -n "$src/agents.md"          "$dst/AGENTS.md"      2>/dev/null || log_ok "AGENTS.md 已存在，跳过"
  cp -n "$src/memory-layers.md"   "$dst/memory-layers.md" 2>/dev/null || true

  # 模板文件（变量替换）
  if [[ ! -f "$dst/IDENTITY.md" ]] || [[ "$REPAIR" == "true" ]]; then
    substitute "$src/identity.md.template" "$dst/IDENTITY.md"
    log_ok "生成 IDENTITY.md（$NAME）"
  else
    log_ok "IDENTITY.md 已存在，跳过"
  fi

  if [[ ! -f "$dst/HEARTBEAT.md" ]] || [[ "$REPAIR" == "true" ]]; then
    substitute "$src/heartbeat.md.template" "$dst/HEARTBEAT.md"
    log_ok "生成 HEARTBEAT.md"
  else
    log_ok "HEARTBEAT.md 已存在，跳过"
  fi
}

#-------------------------------------------------------------------------------
# 安装 memory 模板
#-------------------------------------------------------------------------------
install_memory() {
  log_step "安装 memory 模板"

  local mem_dir="$WORKSPACE_DIR/memory"
  mkdir -p "$mem_dir"
  mkdir -p "$mem_dir/projects"
  mkdir -p "$mem_dir/inbox"

  local today=$(date +%Y-%m-%d)
  local mem_file="$mem_dir/${today}.md"

  # 创建今日 memory 文件（已有则跳过）
  if [[ ! -f "$mem_file" ]]; then
    substitute "$KIT_DIR/templates/memory/memory-template.md" "$mem_file"
    log_ok "创建今日 memory: ${today}.md"
  else
    log_ok "今日 memory 已存在: ${today}.md"
  fi
}

#-------------------------------------------------------------------------------
# 安装安全体系说明
#-------------------------------------------------------------------------------
install_security() {
  log_step "安装安全体系"

  local dst="$WORKSPACE_DIR"
  cp -n "$KIT_DIR/templates/security/security-layers.md" "$dst/security-layers.md" 2>/dev/null || true
  log_ok "安全体系说明已安装"
}

#-------------------------------------------------------------------------------
# 创建 cron 任务
#-------------------------------------------------------------------------------
install_cron() {
  log_step "创建 cron 任务"

  local description="[${NAME}] 日级记忆蒸馏与整理"
  local message_memory='执行 personhood-document-maintainer skill，模式为 normal。对当日对话和任务结果做整理：1. 提炼当日关键决策；2. 检查是否有内容应升级到 MEMORY.md；3. 更新 memory/YYYY-MM-DD.md。完成后简报：本轮做了什么。'

  local description_ev="[${NAME}] 周級自进化深度维护"
  local message_ev='执行 personhood-document-maintainer skill，模式为 deep。对最近一周的对话和任务结果做深度结构整理：1. 做结构级清理与合并；2. 降级过时内容；3. 检查是否有内容应升级到对应人格文档；4. 校正文档边界漂移。完成后简报：本轮升了什么、没升什么、为什么。'

  # 日蒸馏 cron（检查是否已存在）
  local daily_exists=$(openclaw cron list 2>/dev/null | grep -c "${AGENT_ID}-memory-daily-distill" || echo "0")
  if [[ "$daily_exists" -eq 0 ]]; then
    openclaw cron add \
      --name "${AGENT_ID}-memory-daily-distill" \
      --description "$description" \
      --cron "${CRON_DAILY} * * *" \
      --tz Asia/Shanghai \
      --agent "$AGENT_ID" \
      --session isolated \
      --wake now \
      --message "$message_memory" \
      --timeout-seconds 120 \
      2>&1 | grep -v "^\[plugins\]" | grep -v "^$" || true
    log_ok "日蒸馏 cron 已创建: ${CRON_DAILY}"
  else
    log_ok "日蒸馏 cron 已存在，跳过"
  fi

  # 周提升 cron
  local weekly_exists=$(openclaw cron list 2>/dev/null | grep -c "${AGENT_ID}-self-evolution" || echo "0")
  if [[ "$weekly_exists" -eq 0 ]]; then
    openclaw cron add \
      --name "${AGENT_ID}-self-evolution" \
      --description "$description_ev" \
      --cron "${CRON_WEEKLY} * *" \
      --tz Asia/Shanghai \
      --agent "$AGENT_ID" \
      --session isolated \
      --wake now \
      --message "$message_ev" \
      --timeout-seconds 300 \
      2>&1 | grep -v "^\[plugins\]" | grep -v "^$" || true
    log_ok "周提升 cron 已创建: ${CRON_WEEKLY}"
  else
    log_ok "周提升 cron 已存在，跳过"
  fi
}

#-------------------------------------------------------------------------------
# 写入 bootstrap.done
#-------------------------------------------------------------------------------
mark_bootstrap() {
  log_step "写入 bootstrap 标记"
  cat > "$WORKSPACE_DIR/bootstrap.done" <<EOF
# Bootstrap 完成标记
# 由 agent-bootstrap-kit v1.0.0 生成
# 时间: $(date -u +%Y-%m-%dT%H:%M:%SZ)
# agent_id: $AGENT_ID
# agent_name: $NAME
# cron_base: $CRON_BASE (daily: $CRON_DAILY)
# cron_slot: $CRON_SLOT (weekly: $CRON_WEEKLY)
# install_date: $INSTALL_DATE
AGENT_ID=$AGENT_ID
AGENT_NAME=$NAME
CRON_BASE=$CRON_BASE
CRON_SLOT=$CRON_SLOT
INSTALL_DATE=$INSTALL_DATE
VERSION=1.0.0
EOF
  log_ok "bootstrap.done 已写入"
}

#-------------------------------------------------------------------------------
# 输出报告
#-------------------------------------------------------------------------------
report() {
  echo ""
  echo "============================================"
  echo -e "${GREEN}  Bootstrap 完成${NC}"
  echo "============================================"
  echo "  智能体:     $AGENT_ID ($NAME)"
  echo "  工作区:     $WORKSPACE_DIR"
  echo "  日蒸馏:     $CRON_DAILY"
  echo "  周提升:     $CRON_WEEKLY"
  echo "  安装日期:   $INSTALL_DATE"
  echo ""
  echo "  核心文件:"
  echo "    SOUL.md / AGENTS.md / IDENTITY.md"
  echo "    HEARTBEAT.md / MEMORY.md"
  echo "    bootstrap.done"
  echo ""
  echo "  技能清单 (~/.openclaw/workspace-${AGENT_ID}/skills/):"
  ls "$WORKSPACE_DIR/skills/" 2>/dev/null | sed 's/^/    /' || echo "    (空)"
  echo ""
  echo "  cron 任务:"
  openclaw cron list 2>/dev/null | \
    awk -v id="$AGENT_ID" '$1 ~ id && (/memory-daily-distill/ || /self-evolution/) {print "    " $1 "  " $2}' 2>/dev/null || echo "    (未找到)"
  echo "============================================"
}

#-------------------------------------------------------------------------------
# 主流程
#-------------------------------------------------------------------------------
main() {
  echo ""
  echo "============================================"
  echo "  OpenClaw Agent Bootstrap Kit v1.0.0"
  echo "  agent_id: $AGENT_ID  name: $NAME"
  echo "  daily cron: $CRON_DAILY"
  echo "  weekly cron: $CRON_WEEKLY"
  echo "  mode: $([[ "$REPAIR" == "true" ]] && echo "repair" || echo "install")"
  echo "============================================"

  # 验证 workspace 存在
  if [[ ! -d "$WORKSPACE_DIR" ]]; then
    log_err "workspace 不存在: $WORKSPACE_DIR"
    echo ""
    echo "请先用 agent-creator 创建智能体："
    echo "  openclaw agents add $AGENT_ID"
    exit 1
  fi

  if [[ "$VERIFY" == "true" ]]; then
    do_verify
    exit 0
  fi

  install_skills
  install_personality
  install_memory
  install_security
  install_cron
  mark_bootstrap
  report
}

main
