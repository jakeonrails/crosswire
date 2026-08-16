import { defineConfig } from "vitest/config"

// Two-tier, per docs/DECISIONS.md R8.
//
// jsdom covers state, values and events — roughly two thirds of the suite.
// Anything touching focus, <dialog>, IntersectionObserver or positioning MUST run in a
// real browser: jsdom cannot test those honestly, and a library that only tests what
// jsdom supports ends up with stimulus-components' accessibility record (aria-expanded
// as its only ARIA attribute across 32 packages).
//
// This file is the DEFAULT config vitest auto-discovers, so plain `npx vitest run` /
// `npm test` stays jsdom-only — deliberately. The browser tier lives in
// vitest.browser.config.js as a fully separate config (not a `test.projects` entry in
// this file) because Vitest's project mechanism runs every declared project by default
// unless `--project <name>` is passed; putting both tiers in one projects array would
// make plain `vitest run` execute the browser tests too, which is exactly what must
// NOT happen here. Run the browser tier with `npm run test:browser` (or both with
// `npm run test:all`) after `npx playwright install chromium`.
export default defineConfig({
  test: {
    environment: "jsdom",
    include: ["test/js/**/*.test.js"],
    exclude: ["test/js/**/*.browser.test.js"],
    globals: true,
    setupFiles: ["test/js/setup.js"]
  }
})
