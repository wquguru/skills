const root = document.documentElement;
const themeToggle = document.querySelector("#theme-toggle");
const langToggle = document.querySelector("#lang-toggle");
const clock = document.querySelector("#clock");
const coords = document.querySelector("#coords");
const scrollbar = document.querySelector(".scrollbar-ghost");
const copyButtons = document.querySelectorAll("[data-copy]");

const savedTheme = localStorage.getItem("skills-theme");
const prefersDark = matchMedia("(prefers-color-scheme: dark)").matches;
const initialTheme = savedTheme || (prefersDark ? "dark" : "light");

function setTheme(theme) {
  root.dataset.theme = theme;
  localStorage.setItem("skills-theme", theme);
  const isDark = theme === "dark";
  themeToggle?.setAttribute("aria-pressed", String(isDark));
  if (themeToggle) themeToggle.textContent = isDark ? "THEME[B]" : "THEME[A]";
}

function updateClock() {
  if (!clock) return;
  const now = new Date();
  const time = new Intl.DateTimeFormat("en-US", {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
    timeZoneName: "short",
  }).format(now);
  clock.textContent = time.replace(",", "");
}

function updateScroll() {
  const max = Math.max(1, document.documentElement.scrollHeight - window.innerHeight);
  const progress = Math.min(1, Math.max(0, window.scrollY / max));
  root.style.setProperty("--scroll-progress", progress.toFixed(4));

  if (scrollbar) {
    const track = scrollbar.getBoundingClientRect().height;
    const thumb = Math.max(0, track - 28);
    root.style.setProperty("--scroll-thumb", `${Math.round(progress * thumb)}px`);
  }
}

async function copyText(text) {
  if (navigator.clipboard?.writeText) {
    try {
      await navigator.clipboard.writeText(text);
      return;
    } catch {
      // Fall through to the textarea path for browsers that expose but block the Clipboard API.
    }
  }

  const input = document.createElement("textarea");
  input.value = text;
  input.setAttribute("readonly", "");
  input.style.position = "fixed";
  input.style.left = "-9999px";
  document.body.append(input);
  input.select();
  document.execCommand("copy");
  input.remove();
}

const I18N_ZH = {
  "nav.first": "自研技能",
  "nav.third": "第三方",
  "nav.install": "安装",
  "hero.care": "本地作业手册。<br />锁定的扩展。",
  "hero.intro":
    "一个面向实际 agent 工作的个人注册表：自研技能、经过审计的第三方模块，以及让两个 agent 目录保持同步的安装闭环。",
  "hero.t1": "Agent 技能",
  "hero.t2": "为真实工作",
  "hero.t3": "而生。",
  "hero.sync": "完整同步",
  "sec.eyebrow": "供应链闸门",
  "sec.meta": "每个变更的技能都会在 CI 中扫描并把关；每周一次全量复审整个注册表。",
  "stats.local": "本地可用技能",
  "stats.self": "skills/ 下的自研技能",
  "stats.vendored": "来自 external.yml 的内置技能",
  "stats.homes": "由 just add 链接的 agent 目录",
  "overview.eyebrow": "注册表结构",
  "overview.title": "一个目录，两个权威来源。",
  "src.first.kicker": "自研",
  "src.first.title": "在本仓库构建",
  "src.first.p":
    "<code>skills/</code> 下的技能在本仓库编写，直接从各自的 <code>SKILL.md</code>、脚本、参考资料和 agent 配置发布。",
  "src.third.kicker": "第三方",
  "src.third.title": "锁定并内置",
  "src.third.p":
    "在 <code>external.yml</code> 中声明的技能会被拉取到 <code>external/</code>，加上 <code>3rd-</code> 前缀重命名，并在 <code>external.lock</code> 中锁定上游 commit。",
  "fp.eyebrow": "本地操作偏好",
  "fp.title": "自研技能",
  "fp.p": "这些技能沉淀了个人工作流、来之不易的配置经验和自动化习惯，让 agent 可以稳定复现。",
  "skill.agent-compat-sync":
    "通过安全的符号链接保持 Claude 与 Codex 仓库指令兼容，覆盖 <code>CLAUDE.md</code>、<code>AGENTS.md</code> 与技能目录。",
  "skill.clean-my-loop":
    "审计循环运行的 agent 任务、过期记忆文件、臃肿 prompt 与指令漂移，让自主工作保持可靠。",
  "skill.english-swe-daily":
    "帮助软件工程师在站会、Slack、代码评审、会议和日常闲聊中说出更自然的英语。",
  "skill.fable-5-best-practice":
    "路由 Claude 模型分层与 effort 档位，先诊断再升级，并处理 refusal、fallback 与长时程 Fable 5 任务。",
  "skill.gpt-5-6-best-practice":
    "在 Sol、Terra、Luna 之间优化 GPT-5.6 Codex 的模型分层、reasoning-effort 与子代理选择，以被接受结果的总成本为目标。",
  "skill.grafana-best-practice":
    "评审并改进 Grafana 仪表盘、告警规则、Flux 查询、面板可读性、provisioning 与通知投递。",
  "skill.free-my-disk":
    "安全审计并回收 macOS / Linux 磁盘空间：缓存、Docker 存储、日志、SSH 服务器与定时磁盘巡检。",
  "skill.free-my-cpu":
    "审计 Linux 与 Docker 的 CPU 压力、负载、I/O 等待、热点容器和缓慢仪表盘，并给出安全的处置选项。",
  "skill.pi-setup":
    "为 Pi Agent 配置 DeepSeek、Ring、ZenMux、模型设置与精选扩展，并规避已知配置坑。",
  "skill.skills-finder":
    "搜索 skills.sh，并在采纳或安装任何第三方技能之前先通过安全审计把关。",
  "skill.youtube-toolkit":
    "使用 yt-dlp 下载 YouTube 视频，并用 ffmpeg 完成转码、音频提取、字幕烧录与水印。",
  "tp.eyebrow": "锁定的扩展",
  "tp.title": "第三方技能",
  "tp.p": "内置的第三方技能让外部专业能力触手可及，同时保持来源、命名与安装状态清晰可查。",
  "skill.3rd-agent-browser":
    "通过 agent-browser CLI 自动化浏览器导航、截图、抓取、表单操作、探索性 QA 与应用测试。",
  "skill.3rd-alerting-irm":
    "配置 Grafana Alerting、联系点、通知策略、静默、值班排班、IRM 流程与 SLO 消耗告警。",
  "skill.3rd-dashboarding":
    "创建和编辑 Grafana 仪表盘、变量、面板、阈值、转换、注释与可导出的仪表盘 JSON。",
  "skill.3rd-grafana-oss":
    "为 Grafana OSS 配置数据源、仪表盘、角色、服务账号、插件、注释与健康检查验证。",
  "skill.3rd-transitions-dev":
    "提供可移植的 CSS 过渡配方：模态框、下拉菜单、面板展开、文本切换、成功勾选与错误反馈。",
  "install.eyebrow": "安装与维护",
  "install.title": "本地链接一切，只把该发布的推到上游。",
  "install.single.h": "使用一个自研技能",
  "install.single.k": "单个安装",
  "install.sync.h": "完整本地同步",
  "install.sync.k": "拉取、链接、验证",
  "install.vendor.h": "刷新第三方技能",
  "install.vendor.k": "内置来源",
  "footer.src": "权威来源：",
  "modal.close": "关闭",
  "modal.install": "安装命令",
  "modal.source": "查看来源 →",
  "modal.share": "复制分享链接",
  "card.share": "分享",
};

const i18nNodes = document.querySelectorAll("[data-i18n]");
const i18nEnglish = new Map();
i18nNodes.forEach((node) => i18nEnglish.set(node, node.innerHTML));

const savedLang = localStorage.getItem("skills-lang");
const browserLang = (navigator.languages?.[0] || navigator.language || "").toLowerCase();
const initialLang = savedLang || (browserLang.startsWith("zh") ? "zh" : "en");

function setLang(lang) {
  root.lang = lang === "zh" ? "zh-CN" : "en";
  localStorage.setItem("skills-lang", lang);
  i18nNodes.forEach((node) => {
    const key = node.dataset.i18n;
    const zh = I18N_ZH[key];
    node.innerHTML = lang === "zh" && zh ? zh : i18nEnglish.get(node);
  });
  syncDynamicI18n(lang);
  document.title = lang === "zh" ? "Agent 技能注册表" : "Agent Skills Registry";
  langToggle?.setAttribute("aria-pressed", String(lang === "zh"));
  if (langToggle) langToggle.textContent = lang === "zh" ? "LANG[中]" : "LANG[EN]";
}

setTheme(initialTheme);
setLang(initialLang);
updateClock();
updateScroll();

themeToggle?.addEventListener("click", () => {
  setTheme(root.dataset.theme === "dark" ? "light" : "dark");
});

langToggle?.addEventListener("click", () => {
  setLang(root.lang.startsWith("zh") ? "en" : "zh");
});

const auditStatus = document.querySelector("#audit-status");

async function updateAuditStatus() {
  if (!auditStatus) return;
  try {
    const res = await fetch(
      "https://api.github.com/repos/wquguru/skills/actions/workflows/security-audit.yml/runs?branch=main&status=completed&per_page=1",
      { headers: { Accept: "application/vnd.github+json" } },
    );
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    const run = data.workflow_runs?.[0];
    if (!run?.conclusion) throw new Error("no completed run");
    const pass = run.conclusion === "success";
    auditStatus.dataset.state = pass ? "pass" : "fail";
    auditStatus.textContent = pass ? "AUDIT[PASS]" : "AUDIT[FAIL]";
    auditStatus.title = `Last run: ${run.conclusion} (${run.updated_at})`;
  } catch {
    // Rate-limited or offline: leave the neutral link to the Actions page.
    auditStatus.dataset.state = "unknown";
    auditStatus.textContent = "AUDIT[→]";
  }
}

updateAuditStatus();

copyButtons.forEach((button) => {
  const defaultLabel = button.textContent || "COPY";

  button.addEventListener("click", async () => {
    const command = button.getAttribute("data-copy");
    if (!command) return;

    try {
      await copyText(command);
      button.textContent = "COPIED";
      button.dataset.copyState = "copied";
      button.classList.add("is-copied");
      window.setTimeout(() => {
        button.textContent = defaultLabel;
        delete button.dataset.copyState;
        button.classList.remove("is-copied");
      }, 1400);
    } catch {
      button.textContent = "FAILED";
      button.dataset.copyState = "failed";
      window.setTimeout(() => {
        button.textContent = defaultLabel;
        delete button.dataset.copyState;
      }, 1400);
    }
  });
});

window.addEventListener(
  "pointermove",
  (event) => {
    root.style.setProperty("--cursor-x", `${event.clientX}px`);
    root.style.setProperty("--cursor-y", `${event.clientY}px`);
    if (coords) {
      coords.textContent = `${String(Math.round(event.clientX)).padStart(4, "0")} X ${String(
        Math.round(event.clientY),
      ).padStart(4, "0")} Y`;
    }
  },
  { passive: true },
);

window.addEventListener("scroll", updateScroll, { passive: true });
window.addEventListener("resize", updateScroll);
setInterval(updateClock, 30_000);

// ---- Skill detail modal (shareable via ?skill=<slug> or #skill=<slug>) ----

// Localizes dynamically created/updated nodes (card share buttons, modal
// description). These are not in `i18nNodes`, which is captured once at load,
// so they carry `data-i18n-dyn` (key) plus `data-en` (English innerHTML).
// Hoisted: setLang() calls this during initial load, before the modal wiring
// below runs.
function syncDynamicI18n(lang) {
  document.querySelectorAll("[data-i18n-dyn]").forEach((node) => {
    const zh = I18N_ZH[node.dataset.i18nDyn];
    node.innerHTML = lang === "zh" && zh ? zh : node.dataset.en || "";
  });
}

function currentLang() {
  return root.lang.startsWith("zh") ? "zh" : "en";
}

const skillModal = document.querySelector("#skill-modal");
const modalType = document.querySelector("#skill-modal-type");
const modalPath = document.querySelector("#skill-modal-path");
const modalTitle = document.querySelector("#skill-modal-title");
const modalDesc = document.querySelector("#skill-modal-desc");
const modalCmd = document.querySelector("#skill-modal-cmd");
const modalCopy = document.querySelector("#skill-modal-copy");
const modalSource = document.querySelector("#skill-modal-source");
const modalShare = document.querySelector("#skill-modal-share");
const modalCloseBtn = document.querySelector("#skill-modal-close");
const modalBackdrop = skillModal?.querySelector(".skill-modal-backdrop");

const skillCards = new Map();
document.querySelectorAll(".skill-card").forEach((card) => {
  const slug = card.querySelector(".skill-link")?.textContent.trim();
  if (slug) skillCards.set(slug, card);
});

let modalTrigger = null;
let modalHideTimer = 0;

function shareUrlFor(slug) {
  // Query params are lost when reopening a file:// URL, so use the hash form
  // there; on http(s) the canonical share link is ?skill=<slug>.
  if (location.protocol === "file:") {
    return `${location.href.split(/[?#]/)[0]}#skill=${encodeURIComponent(slug)}`;
  }
  return `${location.origin}${location.pathname}?skill=${encodeURIComponent(slug)}`;
}

function openSkillModal(slug, { trigger = null, updateUrl = false } = {}) {
  const card = skillCards.get(slug);
  if (!skillModal || !card) return;

  modalTrigger = trigger;
  modalType.textContent = card.querySelector(".skill-type")?.textContent || "";
  modalPath.textContent = card.querySelector(".skill-path")?.textContent || "";
  modalTitle.textContent = slug;
  skillModal.classList.toggle("third-party", card.classList.contains("third-party"));

  const cardDesc = card.querySelector("p[data-i18n]");
  modalDesc.dataset.i18nDyn = cardDesc?.dataset.i18n || "";
  modalDesc.dataset.en = (cardDesc && i18nEnglish.get(cardDesc)) || cardDesc?.innerHTML || "";
  syncDynamicI18n(currentLang());

  const command = card.querySelector(".copy-line code")?.textContent || "";
  modalCmd.textContent = command;
  modalCopy.setAttribute("data-copy", command);

  const sourceHref = card.querySelector(".skill-link")?.getAttribute("href") || "#";
  modalSource.setAttribute("href", sourceHref);

  window.clearTimeout(modalHideTimer);
  skillModal.hidden = false;
  void skillModal.offsetHeight; // reflow so the open transition plays
  skillModal.classList.add("is-open");
  document.body.style.overflow = "hidden";
  modalCloseBtn?.focus();

  if (updateUrl) {
    const target =
      location.protocol === "file:"
        ? `#skill=${encodeURIComponent(slug)}`
        : `${location.pathname}?skill=${encodeURIComponent(slug)}`;
    try {
      history.replaceState(null, "", target);
    } catch {
      // Some browsers block replaceState on file:// — the modal still works.
    }
  }
}

function closeSkillModal() {
  if (!skillModal || skillModal.hidden) return;
  skillModal.classList.remove("is-open");
  document.body.style.overflow = "";
  modalHideTimer = window.setTimeout(() => {
    skillModal.hidden = true;
  }, 200);
  try {
    history.replaceState(null, "", location.pathname);
  } catch {
    // Ignore: URL cleanup is best-effort on file://.
  }
  modalTrigger?.focus?.();
  modalTrigger = null;
}

modalCloseBtn?.addEventListener("click", closeSkillModal);
modalBackdrop?.addEventListener("click", closeSkillModal);
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && skillModal && !skillModal.hidden) closeSkillModal();
});

modalShare?.addEventListener("click", async () => {
  const slug = modalTitle?.textContent;
  if (!slug || !modalShare) return;
  try {
    await copyText(shareUrlFor(slug));
    modalShare.textContent = currentLang() === "zh" ? "已复制" : "COPIED";
  } catch {
    modalShare.textContent = "FAILED";
  }
  window.setTimeout(() => {
    const zh = I18N_ZH[modalShare.dataset.i18n];
    modalShare.innerHTML = currentLang() === "zh" && zh ? zh : i18nEnglish.get(modalShare);
  }, 1400);
});

// Per-card share affordance, injected so the 16 card blocks stay hand-editable.
skillCards.forEach((card, slug) => {
  const topline = card.querySelector(".skill-topline");
  if (!topline) return;
  const button = document.createElement("button");
  button.type = "button";
  button.className = "skill-share-button";
  button.dataset.i18nDyn = "card.share";
  button.dataset.en = "SHARE";
  button.setAttribute("aria-haspopup", "dialog");
  button.addEventListener("click", () => openSkillModal(slug, { trigger: button, updateUrl: true }));
  topline.append(button);
});
syncDynamicI18n(currentLang());

// Deep link: ?skill=<slug> wins, then #skill=<slug>. Unknown slugs are ignored.
const deepLinkSlug =
  new URLSearchParams(location.search).get("skill") ||
  (location.hash.startsWith("#skill=") ? decodeURIComponent(location.hash.slice("#skill=".length)) : "");
if (deepLinkSlug) openSkillModal(deepLinkSlug.trim());
