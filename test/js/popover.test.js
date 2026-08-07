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
