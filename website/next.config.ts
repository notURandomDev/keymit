import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // 静态导出，部署到 GitHub Pages。
  output: 'export',
  // 生成 /en/index.html 这类目录式 URL，GitHub Pages 友好。
  trailingSlash: true,
  // 若改为部署到项目子路径（如 https://noturandomdev.github.io/keymit/），
  // 取消下一行注释，让 Next 自动为所有内部链接与资源加上前缀：
  // basePath: '/keymit',
};

export default nextConfig;
