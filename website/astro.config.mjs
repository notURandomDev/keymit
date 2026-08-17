import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://noturandomdev.github.io',
  // GitHub Pages 部署说明：
  // - 部署到用户/组织根站点（noturandomdev.github.io 仓库）时，保持根路径即可，无需设置 base。
  // - 若改为部署到项目子路径（如 https://noturandomdev.github.io/keymit/），
  //   取消下一行注释，让 Astro 自动为所有内部链接加上前缀：
  // base: '/keymit',
  output: 'static',
});
