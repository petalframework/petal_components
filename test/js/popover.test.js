// PetalPopover hook: top-layer panel positioning.
//
// The panel's CSS zeroes the margin that would otherwise centre a
// popover, so an unpositioned panel sits at 0,0 - every spec here is
// ultimately about never letting a frame paint from that corner.
import { afterEach, beforeEach, describe, expect, it } from "vitest";

import hooks from "../../assets/js/petal_components.js";

const mounted = [];

// jsdom has no CSS.escape; the hook uses it to find the trigger
beforeEach(() => {
  if (typeof globalThis.CSS === "undefined") globalThis.CSS = {};
  if (!globalThis.CSS.escape) globalThis.CSS.escape = (s) => s;
});

function mount({ placement = "bottom-start" } = {}) {
  const wrap = document.createElement("div");
  wrap.innerHTML = `
    <button type="button" popovertarget="pop">Filter</button>
    <div id="pop" class="pc-popover__panel pc-popover__panel--top-layer" data-placement="${placement}"></div>
  `;
  document.body.appendChild(wrap);

  const el = wrap.querySelector("#pop");
  const hook = Object.create(hooks.PetalPopover);
  hook.el = el;
  hook.mounted();
  mounted.push({ hook, wrap });

  return { hook, el, wrap };
}

function fire(el, type, newState) {
  const e = new Event(type);
  e.newState = newState;
  el.dispatchEvent(e);
}

describe("PetalPopover", () => {
  afterEach(() => {
    mounted.splice(0).forEach(({ hook, wrap }) => {
      hook.destroyed();
      wrap.remove();
    });
  });

  it("hides the panel before it is shown, then reveals it positioned", () => {
    const { el } = mount();

    // beforetoggle runs before the browser paints the open panel
    fire(el, "beforetoggle", "open");
    expect(el.style.opacity).toBe("0");
    expect(el.style.top).toBe("");

    // toggle positions it, then hands opacity back to the CSS fade
    fire(el, "toggle", "open");
    expect(el.style.opacity).toBe("");
    expect(el.style.top).not.toBe("");
    expect(el.style.left).not.toBe("");
  });

  it("re-asserts position after a patch strips the inline styles", () => {
    const { hook, el } = mount();
    fire(el, "beforetoggle", "open");
    fire(el, "toggle", "open");

    const positioned = { top: el.style.top, left: el.style.left };

    // what LiveView's attribute merge does to styles the server never rendered
    el.removeAttribute("style");
    expect(el.style.top).toBe("");

    hook.updated();
    expect(el.style.top).toBe(positioned.top);
    expect(el.style.left).toBe(positioned.left);
  });

  // Geometry helpers: the specs below drive real numbers through the
  // hook the way a phone would - a shrunken visual viewport for the
  // keyboard, a moved trigger for scrolling.
  function stubViewport({
    offsetTop = 0,
    offsetLeft = 0,
    width = 375,
    height = 812,
  } = {}) {
    const calls = [];
    Object.defineProperty(window, "visualViewport", {
      value: {
        offsetTop,
        offsetLeft,
        width,
        height,
        addEventListener: (type) => calls.push(`add:${type}`),
        removeEventListener: (type) => calls.push(`remove:${type}`),
      },
      configurable: true,
    });
    return calls;
  }

  function stubRects(wrap, el, { trigger, panel }) {
    wrap.querySelector("button").getBoundingClientRect = () => ({
      top: trigger.top,
      bottom: trigger.top + trigger.height,
      left: trigger.left,
      right: trigger.left + trigger.width,
      width: trigger.width,
      height: trigger.height,
    });
    el.getBoundingClientRect = () => ({
      top: 0,
      bottom: panel.height,
      left: 0,
      right: panel.width,
      width: panel.width,
      height: panel.height,
    });
  }

  function open(el) {
    fire(el, "beforetoggle", "open");
    fire(el, "toggle", "open");
  }

  it("anchors a panel that was opened before the hook mounted", () => {
    stubViewport();

    // build the panel WITHOUT mounting the hook, and open it - the
    // native popovertarget works from first paint
    const wrap = document.createElement("div");
    wrap.innerHTML = `
      <button type="button" popovertarget="pop">Filter</button>
      <div id="pop" class="pc-popover__panel pc-popover__panel--top-layer" data-placement="bottom-start"></div>
    `;
    document.body.appendChild(wrap);
    const el = wrap.querySelector("#pop");
    el.matches = (sel) => sel === ":popover-open";
    wrap.querySelector("button").getBoundingClientRect = () => ({
      top: 200,
      bottom: 230,
      left: 40,
      right: 140,
      width: 100,
      height: 30,
    });
    el.getBoundingClientRect = () => ({
      top: 0,
      bottom: 150,
      left: 0,
      right: 220,
      width: 220,
      height: 150,
    });

    expect(el.style.top).toBe("");

    const hook = Object.create(hooks.PetalPopover);
    hook.el = el;
    hook.mounted();
    mounted.push({ hook, wrap });

    // mounting anchors the already-open panel instead of leaving it centred
    expect(parseFloat(el.style.top)).toBe(230 + 8);
    expect(parseFloat(el.style.left)).toBe(40);
  });

  it("stays glued under its trigger - never pinned to the viewport edge", () => {
    stubViewport();
    const { el, wrap } = mount();
    // trigger low on a tall page, panel taller than the room beneath it
    stubRects(wrap, el, {
      trigger: { top: 700, left: 20, width: 100, height: 30 },
      panel: { width: 220, height: 200 },
    });

    open(el);

    // it flips above rather than shunting up to the top of the screen
    const top = parseFloat(el.style.top);
    expect(top).toBe(700 - 200 - 8);
    expect(top).not.toBe(8);
  });

  it("flips above the trigger when a keyboard eats the space below, without covering it", () => {
    stubViewport({ offsetTop: 0, height: 380 }); // keyboard up
    const { el, wrap } = mount();
    stubRects(wrap, el, {
      trigger: { top: 300, left: 20, width: 100, height: 30 },
      panel: { width: 220, height: 200 },
    });

    open(el);

    const top = parseFloat(el.style.top);
    const height = parseFloat(el.style.maxHeight);
    // sits fully above the trigger: bottom edge clears trigger.top
    expect(top + Math.min(200, height)).toBeLessThanOrEqual(300 - 8);
    // and never overlaps the control that opened it
    expect(top).toBeLessThan(300);
  });

  it("caps its height to the room available instead of overflowing", () => {
    stubViewport({ offsetTop: 0, height: 400 });
    const { el, wrap } = mount();
    // trigger high, panel far taller than the 400px visible strip
    stubRects(wrap, el, {
      trigger: { top: 100, left: 20, width: 100, height: 30 },
      panel: { width: 220, height: 900 },
    });

    open(el);

    const maxHeight = parseFloat(el.style.maxHeight);
    // room below the trigger inside the visible box, less gap and pad
    expect(maxHeight).toBe(400 - 130 - 8 - 8);
    expect(el.style.overflowY).toBe("auto");
  });

  it("never caps taller than the room it has, even in a sliver of viewport", () => {
    // a viewport strip barely taller than the trigger: neither side has
    // room for a comfortable panel, and the cap must still contain it
    stubViewport({ offsetTop: 0, height: 140 });
    const { el, wrap } = mount();
    stubRects(wrap, el, {
      trigger: { top: 60, left: 20, width: 100, height: 30 },
      panel: { width: 220, height: 400 },
    });

    open(el);

    const top = parseFloat(el.style.top);
    const maxHeight = parseFloat(el.style.maxHeight);
    // it takes the roomier side - 60px above the trigger beats 50 below -
    // and caps to exactly that room, less gap and pad
    expect(maxHeight).toBe(44);
    // the whole box stays inside the 140px strip, above the trigger
    expect(top).toBeGreaterThanOrEqual(0);
    expect(top + maxHeight).toBeLessThanOrEqual(60);
  });

  it("hides when its trigger leaves sideways, not just vertically", () => {
    stubViewport({ offsetLeft: 0, width: 375 });
    const { hook, el, wrap } = mount();
    stubRects(wrap, el, {
      trigger: { top: 100, left: 40, width: 100, height: 30 },
      panel: { width: 220, height: 150 },
    });

    open(el);
    expect(el.style.visibility).toBe("");

    // a horizontally scrolling container carries the trigger off-screen
    // while it stays vertically in view
    stubRects(wrap, el, {
      trigger: { top: 100, left: -300, width: 100, height: 30 },
      panel: { width: 220, height: 150 },
    });
    hook.position();
    expect(el.style.visibility).toBe("hidden");
  });

  it("hides itself when its trigger scrolls out of the visible region", () => {
    stubViewport({ offsetTop: 0, height: 400 });
    const { hook, el, wrap } = mount();
    stubRects(wrap, el, {
      trigger: { top: 100, left: 20, width: 100, height: 30 },
      panel: { width: 220, height: 150 },
    });

    open(el);
    expect(el.style.visibility).toBe("");

    // the page scrolls; the trigger leaves the top of the visible box
    stubRects(wrap, el, {
      trigger: { top: -200, left: 20, width: 100, height: 30 },
      panel: { width: 220, height: 150 },
    });
    hook.position();
    expect(el.style.visibility).toBe("hidden");

    // and comes back when it returns
    stubRects(wrap, el, {
      trigger: { top: 150, left: 20, width: 100, height: 30 },
      panel: { width: 220, height: 150 },
    });
    hook.position();
    expect(el.style.visibility).toBe("");
  });

  it("tracks the trigger through a scroll, one layout pass per frame", async () => {
    stubViewport();
    const { hook, el, wrap } = mount();
    let scrollY = 0;
    const triggerAt = () => ({
      trigger: { top: 400 - scrollY, left: 20, width: 100, height: 30 },
      panel: { width: 220, height: 150 },
    });
    stubRects(wrap, el, triggerAt());
    open(el);

    let passes = 0;
    const real = hook.position.bind(hook);
    hook.position = () => {
      passes += 1;
      real();
    };

    // a burst of scroll events inside one frame
    for (let i = 1; i <= 10; i += 1) {
      scrollY = i * 10;
      stubRects(wrap, el, triggerAt());
      hook.reposition();
    }
    expect(passes).toBe(0); // nothing runs synchronously

    await new Promise((resolve) => requestAnimationFrame(resolve));
    await new Promise((resolve) => requestAnimationFrame(resolve));

    expect(passes).toBe(1); // coalesced into a single pass
    // and it landed glued to where the trigger ended up
    expect(parseFloat(el.style.top)).toBe(400 - 100 + 30 + 8);
  });

  it("unsubscribes from the visual viewport on close and on destroy", () => {
    const calls = [];
    const vv = {
      offsetTop: 0,
      offsetLeft: 0,
      width: 375,
      height: 812,
      addEventListener: (type) => calls.push(`add:${type}`),
      removeEventListener: (type) => calls.push(`remove:${type}`),
    };
    Object.defineProperty(window, "visualViewport", {
      value: vv,
      configurable: true,
    });

    const { hook, el, wrap } = mount();

    fire(el, "beforetoggle", "open");
    fire(el, "toggle", "open");
    expect(calls).toEqual(["add:resize", "add:scroll"]);

    // closing detaches them - a hook that mounts per filter popover
    // must not accumulate viewport listeners
    fire(el, "toggle", "closed");
    expect(calls).toContain("remove:resize");
    expect(calls).toContain("remove:scroll");

    calls.length = 0;
    hook.destroyed();
    expect(calls).toEqual(["remove:resize", "remove:scroll"]);

    mounted.splice(
      mounted.findIndex((m) => m.hook === hook),
      1,
    );
    wrap.remove();
    delete window.visualViewport;
  });

  it("does not reposition a closed panel", () => {
    const { hook, el } = mount();
    fire(el, "beforetoggle", "open");
    fire(el, "toggle", "open");
    fire(el, "toggle", "closed");

    el.removeAttribute("style");
    hook.updated();
    expect(el.style.top).toBe("");
  });

  it("clears the opacity gate when a panel closes without opening cleanly", () => {
    const { el } = mount();
    fire(el, "beforetoggle", "open");
    expect(el.style.opacity).toBe("0");

    fire(el, "toggle", "closed");
    expect(el.style.opacity).toBe("");
  });
});
