const { defineConfig } = require('vite');
const path = require('path');
const vue = require('@vitejs/plugin-vue');

const projectRoot = path.resolve(__dirname);
// https://vitejs.dev/config/
module.exports = defineConfig({
  root: projectRoot,
  plugins: [vue()],
  server: {
    port: 3002,
  },
  build: {
    chunkSizeWarningLimit: 600, // 设置警告阈值为600KiB
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes('node_modules')) {
            return id
              .toString()
              .split('node_modules/')[1]
              .split('/')[0]
              .toString();
          }
        },
      },
    },
  },
  resolve: {
    alias: {
      '@': path.join(projectRoot, 'src'),
    },
  },
});
