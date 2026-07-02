const root = document.documentElement;
const themeToggle = document.querySelector("#theme-toggle");
const clock = document.querySelector("#clock");
const coords = document.querySelector("#coords");
const scrollbar = document.querySelector(".scrollbar-ghost");

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

setTheme(initialTheme);
updateClock();
updateScroll();

themeToggle?.addEventListener("click", () => {
  setTheme(root.dataset.theme === "dark" ? "light" : "dark");
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
