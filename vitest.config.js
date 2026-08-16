import { defineConfig } from "vitest/config"

// Two-tier, per docs/DECISIONS.md R8.
//
// jsdom covers state, values and events — roughly two thirds of the suite.
// Anything touching focus, <dialog>, IntersectionObserver or positioning MUST run in a
// real browser: jsdom cannot test those honestly, and a library that only tests what
// jsdom supports ends up with stimulus-components' accessibility record (aria-expanded
// as its only ARIA attribute across 32 packages).
//
// Browser-tier files are named *.browser.test.js. Run with `npm run test:browser`
// after `npx playwright install chromium`.
export default defineConfig({
  test: {
    environment: "jsdom",
    include: ["test/js/**/*.test.js"],
    exclude: ["test/js/**/*.browser.test.js"],
    globals: true,
    setupFiles: ["test/js/setup.js"]
  }
})
