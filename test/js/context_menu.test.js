// PetalContextMenu hook: right-click / long-press / Shift+F10 opening,
// pointer-position anchoring, and the WAI-ARIA menu keyboard model.
//
// jsdom implements no popover API, so the hook's showPopover/hidePopover
// calls fall through to their catch. That is deliberate and load-bearing:
// `data-pc-open` is the hook's own record of state and works either way,
// which is what these specs assert against.
import { afterEach, describe, expect, it } from "vitest";

import hooks from "../../assets/js/petal_components.js";
import { pointerEvent } from "./helpers.js";

const mounted = [];

function mount() {
  const wrap = document.createElement("div");
  wrap.innerHTML = `
    <div id="cm" data-pc-context-menu-panel="cm-menu">
      <div id="cm-trigger" class="pc-context-menu__trigger" tabindex="0" aria-expanded="false">
        <span id="cm-inner">Q3-forecast.xlsx</span>
      </div>
      <div id="cm-menu" popover="manual" role="menu" tabindex="-1" class="pc-context-menu__panel">
        <button id="i-open" data-pc-context-menu-item role="menuitem" tabindex="-1">Open</button>
        <button id="i-move" data-pc-context-menu-item role="menuitem" tabindex="-1" disabled aria-disabled="true">Move</button>
        <button id="i-del" data-pc-context-menu-item role="menuitem" tabindex="-1">Delete</button>
      </div>
    </div>
    <button id="elsewhere">Somewhere else</button>
  `;
  document.body.appendChild(wrap);

  const el = wrap.querySelector("#cm");
  const hook = Object.create(hooks.PetalContextMenu);
  hook.el = el;
  hook.mounted();
  mounted.push({ hook, wrap });

  return {
    hook,
    el,
    wrap,
    trigger: wrap.querySelector("#cm-trigger"),
    inner: wrap.querySelector("#cm-inner"),
    panel: wrap.querySelector("#cm-menu"),
    items: {
      open: wrap.querySelector("#i-open"),
      move: wrap.querySelector("#i-move"),
      del: wrap.querySelector("#i-del"),
    },
    outside: wrap.querySelector("#elsewhere"),
  };
}

function rightClick(target, x = 100, y = 100) {
  const ev = new MouseEvent("contextmenu", {
    bubbles: true,
    cancelable: true,
    clientX: x,
    clientY: y,
  });
  target.dispatchEvent(ev);
  return ev;
}

function key(target, k, props = {}) {
  const ev = new KeyboardEvent("keydown", {
    key: k,
    bubbles: true,
    cancelable: true,
    ...props,
  });
  target.dispatchEvent(ev);
  return ev;
}

// The panel has no layout in jsdom; every geometry spec drives its own
// numbers through the hook.
function stubPanel(panel, { width = 200, height = 150 } = {}) {
  panel.getBoundingClientRect = () => ({
    top: 0,
    bottom: height,
    left: 0,
    right: width,
    width,
    height,
  });
}

const px = (v) => parseInt(v, 10);

describe("PetalContextMenu", () => {
  afterEach(() => {
    mounted.splice(0).forEach(({ hook, wrap }) => {
      hook.destroyed();
      wrap.remove();
    });
  });

  describe("opening", () => {
    it("opens at the pointer on right-click and suppresses the native menu", () => {
      const { hook, panel, inner } = mount();
      stubPanel(panel);

      const ev = rightClick(inner, 120, 80);

      expect(ev.defaultPrevented).toBe(true);
      expect(hook.open).toBe(true);
      expect(panel.hasAttribute("data-pc-open")).toBe(true);
      expect(px(panel.style.left)).toBe(120);
      expect(px(panel.style.top)).toBe(80);
    });

    it("marks the trigger expanded while the menu is open", () => {
      const { hook, panel, trigger, inner } = mount();
      stubPanel(panel);

      rightClick(inner);
      expect(trigger.getAttribute("aria-expanded")).toBe("true");

      hook.close();
      expect(trigger.getAttribute("aria-expanded")).toBe("false");
    });

    it("focuses the panel, not an item, when a pointer opened it", () => {
      const { panel, inner, items } = mount();
      stubPanel(panel);

      rightClick(inner);

      expect(document.activeElement).toBe(panel);
      expect(document.activeElement).not.toBe(items.open);
    });

    it("repositions rather than reopening on a second right-click", () => {
      const { hook, panel, inner } = mount();
      stubPanel(panel);

      rightClick(inner, 100, 100);
      rightClick(inner, 300, 220);

      expect(hook.open).toBe(true);
      expect(px(panel.style.left)).toBe(300);
      expect(px(panel.style.top)).toBe(220);
    });

    it("swallows a right-click on its own panel without reopening", () => {
      const { hook, panel } = mount();
      stubPanel(panel);

      const ev = rightClick(panel, 50, 50);

      expect(ev.defaultPrevented).toBe(true);
      expect(hook.open).toBe(false);
    });

    it("leaves the native menu alone outside the trigger region", () => {
      const { hook, outside } = mount();

      const ev = rightClick(outside);

      expect(ev.defaultPrevented).toBe(false);
      expect(hook.open).toBe(false);
    });
  });

  describe("viewport collision", () => {
    it("flips to the left of the cursor near the right edge", () => {
      const { panel, inner } = mount();
      stubPanel(panel, { width: 200, height: 150 });

      // window.innerWidth is 1024 in jsdom
      rightClick(inner, 1000, 100);

      expect(px(panel.style.left)).toBe(800);
    });

    it("flips above the cursor near the bottom edge", () => {
      const { panel, inner } = mount();
      stubPanel(panel, { width: 200, height: 150 });

      // window.innerHeight is 768 in jsdom
      rightClick(inner, 100, 750);

      expect(px(panel.style.top)).toBe(600);
    });

    it("clamps to the padded viewport rather than starting off-screen", () => {
      const { panel, inner } = mount();
      // taller than the whole viewport: the flip would put it at a negative top
      stubPanel(panel, { width: 200, height: 2000 });

      rightClick(inner, 100, 700);

      expect(px(panel.style.top)).toBe(8);
      // capped and scrollable instead of running off the bottom
      expect(px(panel.style.maxHeight)).toBe(768 - 16);
      expect(panel.style.overflowY).toBe("auto");
    });

    it("re-anchors on resize while open, and stays put once closed", () => {
      const { hook, panel, inner } = mount();
      stubPanel(panel, { width: 200, height: 150 });

      rightClick(inner, 100, 100);
      stubPanel(panel, { width: 400, height: 150 });
      window.dispatchEvent(new Event("resize"));
      expect(px(panel.style.left)).toBe(100);

      hook.close();
      panel.style.left = "";
      window.dispatchEvent(new Event("resize"));
      expect(panel.style.left).toBe("");
    });

    it("re-asserts position after a patch strips the inline coordinates", () => {
      const { hook, panel, inner } = mount();
      stubPanel(panel);

      rightClick(inner, 140, 90);
      panel.removeAttribute("style");
      expect(panel.style.left).toBe("");

      hook.updated();
      expect(px(panel.style.left)).toBe(140);
      expect(px(panel.style.top)).toBe(90);
    });
  });

  describe("keyboard", () => {
    it("opens on Shift+F10 with the first enabled item focused", () => {
      const { hook, panel, trigger, items } = mount();
      stubPanel(panel);
      trigger.getBoundingClientRect = () => ({
        top: 40,
        bottom: 80,
        left: 20,
        right: 220,
        width: 200,
        height: 40,
      });

      const ev = key(trigger, "F10", { shiftKey: true });

      expect(ev.defaultPrevented).toBe(true);
      expect(hook.open).toBe(true);
      expect(document.activeElement).toBe(items.open);
    });

    it("opens on the ContextMenu key", () => {
      const { hook, panel, trigger, items } = mount();
      stubPanel(panel);
      trigger.getBoundingClientRect = () => ({
        top: 0,
        bottom: 40,
        left: 0,
        right: 200,
        width: 200,
        height: 40,
      });

      key(trigger, "ContextMenu");

      expect(hook.open).toBe(true);
      expect(document.activeElement).toBe(items.open);
    });

    it("ignores a bare F10", () => {
      const { hook, trigger } = mount();

      key(trigger, "F10");

      expect(hook.open).toBe(false);
    });

    it("arrows move through items, skipping disabled ones and wrapping", () => {
      const { panel, inner, items } = mount();
      stubPanel(panel);
      rightClick(inner);

      key(panel, "ArrowDown");
      expect(document.activeElement).toBe(items.open);

      // the disabled middle item is not a stop
      key(items.open, "ArrowDown");
      expect(document.activeElement).toBe(items.del);

      // wraps at the end
      key(items.del, "ArrowDown");
      expect(document.activeElement).toBe(items.open);

      // and at the start, going the other way
      key(items.open, "ArrowUp");
      expect(document.activeElement).toBe(items.del);
    });

    it("ArrowUp from the panel enters at the last item", () => {
      const { panel, inner, items } = mount();
      stubPanel(panel);
      rightClick(inner);

      key(panel, "ArrowUp");

      expect(document.activeElement).toBe(items.del);
    });

    it("Home and End jump to the ends", () => {
      const { panel, inner, items } = mount();
      stubPanel(panel);
      rightClick(inner);

      key(panel, "End");
      expect(document.activeElement).toBe(items.del);

      key(items.del, "Home");
      expect(document.activeElement).toBe(items.open);
    });

    it("Space activates the focused item, because links ignore it natively", () => {
      const { hook, panel, inner, items } = mount();
      stubPanel(panel);
      rightClick(inner);

      let clicked = 0;
      items.del.addEventListener("click", () => clicked++);

      key(panel, "End");
      const ev = key(items.del, " ");

      expect(ev.defaultPrevented).toBe(true);
      expect(clicked).toBe(1);
      // activation closes
      expect(hook.open).toBe(false);
    });

    it("Escape closes and hands focus back to the trigger region", () => {
      const { hook, panel, trigger, inner } = mount();
      stubPanel(panel);
      rightClick(inner);

      const ev = key(panel, "Escape");

      expect(ev.defaultPrevented).toBe(true);
      expect(hook.open).toBe(false);
      expect(panel.hasAttribute("data-pc-open")).toBe(false);
      expect(document.activeElement).toBe(trigger);
    });

    it("Tab closes the menu and lets focus leave the widget", () => {
      const { hook, panel, trigger, inner } = mount();
      stubPanel(panel);
      rightClick(inner);

      const ev = key(panel, "Tab");

      expect(hook.open).toBe(false);
      // not swallowed: the browser's own Tab carries on from the trigger
      expect(ev.defaultPrevented).toBe(false);
      expect(document.activeElement).toBe(trigger);
    });
  });

  describe("dismiss", () => {
    it("closes on a tap outside the panel", () => {
      const { hook, panel, inner, outside } = mount();
      stubPanel(panel);
      rightClick(inner);

      outside.dispatchEvent(
        pointerEvent("pointerdown", "mouse", { clientX: 500, clientY: 500 }),
      );
      outside.dispatchEvent(
        pointerEvent("pointerup", "mouse", { clientX: 500, clientY: 500 }),
      );

      expect(hook.open).toBe(false);
    });

    it("survives a drag that starts outside - that is a scroll, not a tap", () => {
      const { hook, panel, inner, outside } = mount();
      stubPanel(panel);
      rightClick(inner);

      outside.dispatchEvent(
        pointerEvent("pointerdown", "touch", { clientX: 500, clientY: 500 }),
      );
      outside.dispatchEvent(
        pointerEvent("pointerup", "touch", { clientX: 500, clientY: 420 }),
      );

      expect(hook.open).toBe(true);
    });

    it("ignores a multi-touch gesture", () => {
      const { hook, panel, inner, outside } = mount();
      stubPanel(panel);
      rightClick(inner);

      const at = (type, id, x) =>
        outside.dispatchEvent(
          pointerEvent(type, "touch", { pointerId: id, clientX: x, clientY: 500 }),
        );

      at("pointerdown", 1, 400);
      at("pointerdown", 2, 600);
      at("pointerup", 1, 400);
      at("pointerup", 2, 600);

      expect(hook.open).toBe(true);
    });

    it("does not close on a tap inside the panel", () => {
      const { hook, panel, inner, items } = mount();
      stubPanel(panel);
      rightClick(inner);

      items.open.dispatchEvent(
        pointerEvent("pointerdown", "mouse", { clientX: 10, clientY: 10 }),
      );
      items.open.dispatchEvent(
        pointerEvent("pointerup", "mouse", { clientX: 10, clientY: 10 }),
      );

      expect(hook.open).toBe(true);
    });

    it("closes when an item is clicked", () => {
      const { hook, panel, inner, items } = mount();
      stubPanel(panel);
      rightClick(inner);

      items.open.click();

      expect(hook.open).toBe(false);
    });

    it("closes when the page scrolls out from under it", () => {
      const { hook, panel, inner } = mount();
      stubPanel(panel);
      rightClick(inner);

      document.body.dispatchEvent(new Event("scroll", { bubbles: false }));

      expect(hook.open).toBe(false);
    });

    it("stays open when the panel itself scrolls", () => {
      const { hook, panel, inner } = mount();
      stubPanel(panel);
      rightClick(inner);

      panel.dispatchEvent(new Event("scroll"));

      expect(hook.open).toBe(true);
    });
  });

  describe("long press", () => {
    it("opens at the finger after a held touch", async () => {
      const { hook, panel, inner } = mount();
      stubPanel(panel);

      inner.dispatchEvent(
        pointerEvent("pointerdown", "touch", { clientX: 210, clientY: 160 }),
      );
      expect(hook.open).toBe(false);

      await new Promise((r) => setTimeout(r, 520));

      expect(hook.open).toBe(true);
      expect(px(panel.style.left)).toBe(210);
      expect(px(panel.style.top)).toBe(160);
    });

    it("a finger that moves is a scroll, not a press", async () => {
      const { hook, inner, panel } = mount();
      stubPanel(panel);

      inner.dispatchEvent(
        pointerEvent("pointerdown", "touch", { clientX: 210, clientY: 160 }),
      );
      inner.dispatchEvent(
        pointerEvent("pointermove", "touch", { clientX: 210, clientY: 100 }),
      );

      await new Promise((r) => setTimeout(r, 520));

      expect(hook.open).toBe(false);
    });

    it("a finger lifted early is a tap, not a press", async () => {
      const { hook, inner, panel } = mount();
      stubPanel(panel);

      inner.dispatchEvent(
        pointerEvent("pointerdown", "touch", { clientX: 210, clientY: 160 }),
      );
      inner.dispatchEvent(
        pointerEvent("pointerup", "touch", { clientX: 210, clientY: 160 }),
      );

      await new Promise((r) => setTimeout(r, 520));

      expect(hook.open).toBe(false);
    });

    it("a mouse press never arms the timer - that is what contextmenu is for", async () => {
      const { hook, inner, panel } = mount();
      stubPanel(panel);

      inner.dispatchEvent(
        pointerEvent("pointerdown", "mouse", { clientX: 210, clientY: 160 }),
      );

      await new Promise((r) => setTimeout(r, 520));

      expect(hook.open).toBe(false);
    });
  });

  describe("teardown", () => {
    it("stops listening on the document once destroyed", () => {
      const { hook, panel, inner, outside, wrap } = mount();
      stubPanel(panel);
      rightClick(inner);

      mounted.splice(0);
      hook.destroyed();

      // a tap that would have closed it does nothing now
      outside.dispatchEvent(
        pointerEvent("pointerdown", "mouse", { clientX: 500, clientY: 500 }),
      );
      outside.dispatchEvent(
        pointerEvent("pointerup", "mouse", { clientX: 500, clientY: 500 }),
      );
      expect(hook.open).toBe(true);

      wrap.remove();
    });
  });
});
