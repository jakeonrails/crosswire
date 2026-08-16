import { defineConfig } from "vitest/config"
import { playwright } from "@vitest/browser-playwright"

// Browser tier (docs/COMPONENT_CONTRACT.md R8 / "Controller (Vitest)" test
// expectations). Runs only `*.browser.test.js` — the tests that need real focus, real
// <dialog> modality/inertness, and a real IntersectionObserver, none of which jsdom
// implements honestly (see the "Test-environment gotchas" table in
// docs/COMPONENT_CONTRACT.md).
//
// Deliberately a separate config file from vitest.config.js, not a `test.projects`
// entry inside it: Vitest runs every declared project by default unless `--project` is
// passed, so folding this into the same file would make plain `npx vitest run` also
// execute these — breaking the requirement that the default jsdom run stays at exactly
// its own test count. Invoke this file explicitly:
//
//   npx playwright install chromium   # once
//   npm run test:browser
export default defineConfig({
  test: {
    include: ["test/js/**/*.browser.test.js"],
    globals: true,
    setupFiles: ["test/js/setup.js"],
    browser: {
      enabled: true,
      headless: true,
      provider: playwright(),
      instances: [{ browser: "chromium" }]
    }
  }
})
