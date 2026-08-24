// Behavioural smoke test for site/index.html.
//
// The build script guards the bytes; this guards the behaviour. Both exist because of
// one bug: Ruby's String#sub silently ate a `\+` from Stimulus's action-descriptor
// regex, every `click->` was parsed as `lick`, and the entire page was inert — with a
// correct DOM, connected controllers, resolved targets, and no error anywhere.
//
// A byte guard alone would not have caught a mangled controller. An interaction test
// would. Run both.
//
//   node bin/smoke_site.mjs      (or `rake site`)

import { chromium } from "playwright"
import { fileURLToPath } from "node:url"
import path from "node:path"
import fs from "node:fs"

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..")
const browser = await chromium.launch()
const page = await browser.newPage()
const errors = []
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
page.on("console", (m) => { if (m.type() === "error") errors.push("console: " + m.text()) })

await page.goto("file://" + path.join(root, "site/index.html"))
await page.waitForTimeout(500)

const checks = []
const check = (name, ok, detail = "") => checks.push({ name, ok, detail })

const trigger = "[data-cw--disclosure-target='trigger']"
const before = await page.getAttribute(trigger, "aria-expanded")
await page.click(trigger)
await page.waitForTimeout(200)
check("cw--disclosure toggles", await page.getAttribute(trigger, "aria-expanded") !== before)

const n0 = await page.locator("#toast-stack .toast").count()
await page.locator("#toast-stack .toast").first().locator("button").click()
await page.waitForTimeout(200)
check("cw--dismiss removes", await page.locator("#toast-stack .toast").count() < n0)

await page.click("[data-action='click->cw--dialog#open']")
await page.waitForTimeout(200)
const dlg = page.locator("dialog").first()
check("cw--dialog opens", await dlg.evaluate((d) => d.open))
await page.keyboard.press("Escape")

const box = page.locator("[data-controller='cw--persist']")
await box.check()
await page.waitForTimeout(200)
await page.reload()
await page.waitForTimeout(400)
check("cw--persist survives reload", await box.isChecked())

check("site/index.html: no console or page errors", errors.length === 0, errors.join(" | "))

// ---- component gallery pages (ui-tier-spec.md §9) -----------------------------
// Walks every site/components/<name>/index.html bin/build_gallery.rb wrote, failing
// on a console/page error OR a zero-height root — the two failure modes a byte-guard
// alone cannot catch (site/template.html's own header tells that exact story: a
// mangled regex left a correct-looking DOM with nothing connected. A zero-height
// root is that same class of bug for a component page specifically: markup that
// rendered, script that didn't throw, and a component that is nonetheless invisible.
const componentsDir = path.join(root, "site/components")
const componentNames = fs.existsSync(componentsDir)
  ? fs.readdirSync(componentsDir).filter((name) => fs.existsSync(path.join(componentsDir, name, "index.html"))).sort()
  : []

for (const name of componentNames) {
  const pageErrors = []
  const onPageError = (e) => pageErrors.push("pageerror: " + e.message)
  const onConsole = (m) => { if (m.type() === "error") pageErrors.push("console: " + m.text()) }
  page.on("pageerror", onPageError)
  page.on("console", onConsole)

  await page.goto("file://" + path.join(componentsDir, name, "index.html"))
  await page.waitForTimeout(200)

  const rootHeights = await page.locator(".example .stage").evaluateAll((els) => els.map((el) => el.offsetHeight))
  check(`site/components/${name}: at least one rendered example`, rootHeights.length > 0)
  check(`site/components/${name}: no zero-height example root`, rootHeights.every((h) => h > 0),
        rootHeights.map((h, i) => `#${i}=${h}px`).join(" "))

  page.off("pageerror", onPageError)
  page.off("console", onConsole)
  check(`site/components/${name}: no console or page errors`, pageErrors.length === 0, pageErrors.join(" | "))
}

await browser.close()

for (const c of checks) console.log(`${c.ok ? "  ok  " : "  FAIL"}  ${c.name}${c.detail ? "  — " + c.detail : ""}`)
const failed = checks.filter((c) => !c.ok)
if (failed.length) {
  console.error(`\n${failed.length} of ${checks.length} smoke checks failed`)
  process.exit(1)
}
console.log(`\nall ${checks.length} smoke checks passed`)
