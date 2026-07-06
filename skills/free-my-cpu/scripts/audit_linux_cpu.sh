#!/usr/bin/env bash
set -u

section() {
  printf '\n== %s ==\n' "$1"
}

run() {
  "$@" 2>/dev/null || true
}

SAMPLES="${SAMPLES:-3}"
INTERVAL="${INTERVAL:-10}"
LOG_SCAN="${LOG_SCAN:-0}"
LOG_SINCE="${LOG_SINCE:-30m}"
LOG_TAIL="${LOG_TAIL:-200}"

section "System identity"
hostname 2>/dev/null || true
date -Is 2>/dev/null || date
uname -a
if [ -r /etc/os-release ]; then
  sed -n '1,8p' /etc/os-release
fi

section "Capacity and load"
uptime
printf 'CPU count: '
nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || true
free -h 2>/dev/null || true

section "Pressure stall information"
if [ -r /proc/pressure/cpu ]; then
  printf 'cpu: '
  cat /proc/pressure/cpu
else
  echo "CPU PSI unavailable."
fi
if [ -r /proc/pressure/io ]; then
  printf 'io: '
  cat /proc/pressure/io
else
  echo "I/O PSI unavailable."
fi
if [ -r /proc/pressure/memory ]; then
  printf 'memory: '
  cat /proc/pressure/memory
fi

section "Top processes by CPU"
ps -eo pid,ppid,user,stat,wchan:24,pcpu,pmem,etime,comm,args --sort=-pcpu | head -30

section "Blocked or D-state processes"
ps -eo pid,ppid,user,stat,wchan:24,pcpu,pmem,etime,comm,args | sed -n '1p; / D/p' | head -80

section "I/O sample"
if command -v iostat >/dev/null 2>&1; then
  iostat -xz 1 2
else
  echo "iostat unavailable."
fi

if command -v docker >/dev/null 2>&1; then
  section "Docker stats samples"
  i=1
  while [ "$i" -le "$SAMPLES" ]; do
    printf '\n-- sample %s at %s --\n' "$i" "$(date -Is 2>/dev/null || date)"
    docker stats --no-stream --format '{{.Name}} {{.CPUPerc}} {{.MemUsage}} {{.MemPerc}} {{.NetIO}} {{.BlockIO}} {{.PIDs}}' 2>/dev/null \
      | sed 's/%//' \
      | sort -k2 -nr \
      | head -25 || true
    if [ "$i" -lt "$SAMPLES" ]; then
      sleep "$INTERVAL"
    fi
    i=$((i + 1))
  done

  section "Docker hot container metadata"
  hot_containers="$(
    docker stats --no-stream --format '{{.Name}} {{.CPUPerc}}' 2>/dev/null \
      | sed 's/%//' \
      | sort -k2 -nr \
      | head -10 \
      | awk '{print $1}'
  )"
  for c in $hot_containers; do
    printf '\n-- %s --\n' "$c"
    docker inspect "$c" --format 'pid={{.State.Pid}} restart={{.RestartCount}} status={{.State.Status}} started={{.State.StartedAt}} image={{.Config.Image}} project={{index .Config.Labels "com.docker.compose.project"}} service={{index .Config.Labels "com.docker.compose.service"}}' 2>/dev/null || true
    docker inspect "$c" --format 'NanoCpus={{.HostConfig.NanoCpus}} CpuQuota={{.HostConfig.CpuQuota}} CpuPeriod={{.HostConfig.CpuPeriod}} CpusetCpus={{.HostConfig.CpusetCpus}} Memory={{.HostConfig.Memory}}' 2>/dev/null || true
  done

  section "Docker restarts"
  docker ps -q 2>/dev/null \
    | xargs -r docker inspect --format '{{.Name}} restart={{.RestartCount}} status={{.State.Status}} started={{.State.StartedAt}} image={{.Config.Image}}' 2>/dev/null \
    | sed 's#^/##' \
    | sort \
    | head -120 || true

  if [ "$LOG_SCAN" = "1" ]; then
    section "Recent hot container log clues"
    for c in $hot_containers; do
      printf '\n-- %s logs since %s --\n' "$c" "$LOG_SINCE"
      docker logs --since "$LOG_SINCE" --tail "$LOG_TAIL" "$c" 2>&1 \
        | grep -Ei 'timeout|deadline|error|warn|retry|oom|slow|duration| 500|status.?500|panic|killed' \
        | tail -80 || true
    done
  else
    section "Skipped log scan"
    echo "Set LOG_SCAN=1 to scan recent hot-container logs for timeouts, retries, slow requests, OOM, and errors."
  fi
else
  section "Docker"
  echo "Docker is unavailable or not in PATH."
fi

section "Kernel OOM and throttling clues"
run dmesg -T | grep -Ei 'out of memory|oom-killer|killed process|cpu stall|soft lockup|blocked for more than' | tail -80
