import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // Hooks are DOM-driven; jsdom gives them a document without a browser.
    environment: "jsdom",
    // JS specs live in test/js so they stay out of the Hex package, whose
    // files list ships `assets` but not `test`.
    include: ["test/js/**/*.test.js"],
  },
});
