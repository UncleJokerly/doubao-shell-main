// 仅在浏览器里跑 `npm run dev` 时用到。
// 正式桌面壳的 frontendDist 是 https://www.doubao.com/，本目录不会被打进安装程序。
const DOUBAO_URL = "https://www.doubao.com/";

const hint = document.querySelector<HTMLElement>("#shortcut-hint");
if (hint) {
  hint.textContent = "桌面壳直接加载 " + DOUBAO_URL + "，安装后按 Alt+D 唤出或收起小窗。";
}

const openButton = document.querySelector<HTMLButtonElement>("#open-doubao");
openButton?.addEventListener("click", () => {
  window.location.href = DOUBAO_URL;
});
