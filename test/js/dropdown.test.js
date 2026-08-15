// The vertical flip for the dropdown family (dropdown, user menu, language
// select, colour-scheme menu).
//
// Two layers are pinned here. `flipDecision` is the shared rule - a pure
// function the combobox uses too, so these cases are the contract both
// components stand on. `PetalDropdown` is the dropdown's use of it: the
// panel carries the hook, `JS.toggle`'s inline display is the open signal,
// and `data-flip` is the only thing written back.
//
// The markup mirrors what PetalComponents.Dropdown renders -
// test/petal/dropdown_test.exs pins that structure on the Elixir side;
// update both together if the anatomy changes.
import { afterEach, describe, expect, it } from "vitest";

import hooks, { flipDecision } from "../../assets/js/petal_components.js";

const mounted = [];

function mountDropdown({ id = "dropdown_1", placement = "left" } = {}) {
  const el = document.createElement("div");
  el.className = "pc-dropdown";
  el.innerHTML = `
    <div>
      <button type="button" aria-haspopup="true" data-pc-dropdown-trigger>
        <span class="sr-only">Open options</span>
      </button>
    </div>
    <div
      id="${id}"
      role="menu"
      style="display: none;"
      class="pc-dropdown__menu-items-wrapper-placement--${placement} pc-dropdown__menu-items-wrapper"
    >
      <div class="py-1" role="none">
        <a role="menuitem" href="/profile">Profile</a>
        <a role="menuitem" href="/settings">Settings</a>
      </div>
    </div>`;
  document.body.appendChild(el);

  const panel = el.querySelector(`#${id}`);
  const hook = Object.create(hooks.PetalDropdown);
  hook.el = panel;
  hook.mounted();

  const handle = {
    hook,
    root: el,
    panel,
    trigger: el.querySelector("[data-pc-dropdown-trigger]"),
    flipped: () => panel.hasAttribute("data-flip"),
  };
  mounted.push(handle);
  return handle;
}

// LiveView's JS.toggle writes `display` inline - that write, not a click, is
// what the hook watches, so the specs make the same write.
const show = (d) => {
  d.panel.style.display = "block";
};
const hide = (d) => {
  d.panel.style.display = "none";
};

// jsdom lays nothing out: the trigger's box and the panel's height are the
// two measurements the hook takes, so both get stood up by hand.
function withGeometry(
  d,
  { triggerTop, triggerBottom, panelHeight, viewport = 800 },
) {
  d.trigger.getBoundingClientRect = () => ({
    top: triggerTop,
    bottom: triggerBottom,
    left: 0,
    right: 40,
    width: 40,
    height: triggerBottom - triggerTop,
  });
  Object.defineProperty(d.panel, "offsetHeight", {
    configurable: true,
    value: panelHeight,
  });
  Object.defineProperty(window, "innerHeight", {
    configurable: true,
    writable: true,
    value: viewport,
  });
}

// MutationObserver records are delivered on a microtask; a macrotask turn is
// the cheapest way to be certain they have landed.
const settle = () => new Promise((r) => setTimeout(r, 0));

afterEach(() => {
  mounted.splice(0).forEach((d) => {
    d.hook.destroyed();
    d.root.remove();
  });
});

describe("flipDecision", () => {
  const base = { triggerTop: 100, triggerBottom: 140, viewportHeight: 800 };

  it("stays below when the panel fits below", () => {
    // 660px of room below, panel wants 200
    const { flip, room } = flipDecision({ ...base, panelHeight: 200 });
    expect(flip).toBe(false);
    expect(room).toBe(660);
  });

  it("flips when the panel does not fit below and above is roomier", () => {
    // trigger near the floor: 60 below, 700 above
    const { flip, room } = flipDecision({
      ...base,
      triggerTop: 700,
      triggerBottom: 740,
      panelHeight: 200,
    });
    expect(flip).toBe(true);
    expect(room).toBe(700);
  });

  it("stays below when neither side fits but below is the bigger side", () => {
    // 460 below, 300 above, panel wants 900 - neither fits, below is bigger
    const { flip, room } = flipDecision({
      triggerTop: 300,
      triggerBottom: 340,
      panelHeight: 900,
      viewportHeight: 800,
    });
    expect(flip).toBe(false);
    expect(room).toBe(460);
  });

  it("flips when neither side fits and above is the bigger side", () => {
    const { flip, room } = flipDecision({
      triggerTop: 500,
      triggerBottom: 540,
      panelHeight: 900,
      viewportHeight: 800,
    });
    expect(flip).toBe(true);
    expect(room).toBe(500);
  });

  it("stays below when both sides fit - a tie never moves the panel", () => {
    // dead centre: 380 either way, panel 100. Nothing to gain by flipping.
    const { flip } = flipDecision({
      triggerTop: 380,
      triggerBottom: 420,
      panelHeight: 100,
      viewportHeight: 800,
    });
    expect(flip).toBe(false);
  });

  it("takes the gap out of both sides", () => {
    const args = {
      triggerTop: 100,
      triggerBottom: 140,
      panelHeight: 200,
      viewportHeight: 800,
    };
    expect(flipDecision({ ...args, gap: 8 })).toMatchObject({
      above: 92,
      below: 652,
      room: 652,
    });
  });

  it("measures against the offset viewport it is handed", () => {
    // a visual viewport pushed down 100px (an on-screen keyboard, say):
    // room below shrinks by the offset, room above grows by it
    const shifted = flipDecision({
      triggerTop: 300,
      triggerBottom: 340,
      panelHeight: 200,
      viewportTop: 100,
      viewportHeight: 400,
    });
    expect(shifted).toMatchObject({ above: 200, below: 160, flip: true });
  });

  it("a panel exactly as tall as the room below stays below", () => {
    const { flip } = flipDecision({
      triggerTop: 100,
      triggerBottom: 140,
      panelHeight: 660,
      viewportHeight: 800,
    });
    expect(flip).toBe(false);
  });
});

describe("PetalDropdown", () => {
  it("opens downward when there is room below", async () => {
    const d = mountDropdown();
    withGeometry(d, { triggerTop: 100, triggerBottom: 140, panelHeight: 200 });
    show(d);
    await settle();
    expect(d.flipped()).toBe(false);
  });

  it("flips upward for a trigger at the bottom of the viewport", async () => {
    const d = mountDropdown();
    // the sidebar avatar: 60px of room below, panel wants 200
    withGeometry(d, { triggerTop: 700, triggerBottom: 740, panelHeight: 200 });
    show(d);
    await settle();
    expect(d.flipped()).toBe(true);
  });

  it("re-measures on scroll while open and clears the flip when room returns", async () => {
    const d = mountDropdown();
    withGeometry(d, { triggerTop: 700, triggerBottom: 740, panelHeight: 200 });
    show(d);
    await settle();
    expect(d.flipped()).toBe(true);

    withGeometry(d, { triggerTop: 100, triggerBottom: 140, panelHeight: 200 });
    window.dispatchEvent(new Event("scroll"));
    expect(d.flipped()).toBe(false);
  });

  it("re-measures on resize while open", async () => {
    const d = mountDropdown();
    withGeometry(d, { triggerTop: 400, triggerBottom: 440, panelHeight: 200 });
    show(d);
    await settle();
    expect(d.flipped()).toBe(false);

    // the window shrinks under an open menu
    withGeometry(d, {
      triggerTop: 400,
      triggerBottom: 440,
      panelHeight: 200,
      viewport: 500,
    });
    window.dispatchEvent(new Event("resize"));
    expect(d.flipped()).toBe(true);
  });

  it("keeps the flip through the close, then measures the next open fresh", async () => {
    const d = mountDropdown();
    withGeometry(d, { triggerTop: 700, triggerBottom: 740, panelHeight: 200 });
    show(d);
    await settle();
    expect(d.flipped()).toBe(true);

    // the out transition scales back into the trigger - dropping the panel
    // to the other side mid-fade is the jump the flip must not cause
    hide(d);
    await settle();
    expect(d.flipped()).toBe(true);

    withGeometry(d, { triggerTop: 100, triggerBottom: 140, panelHeight: 200 });
    show(d);
    await settle();
    expect(d.flipped()).toBe(false);
  });

  it("stops measuring once closed", async () => {
    const d = mountDropdown();
    withGeometry(d, { triggerTop: 100, triggerBottom: 140, panelHeight: 200 });
    show(d);
    await settle();
    hide(d);
    await settle();

    withGeometry(d, { triggerTop: 700, triggerBottom: 740, panelHeight: 200 });
    window.dispatchEvent(new Event("scroll"));
    expect(d.flipped()).toBe(false);
  });

  it("leaves the panel alone when nothing has been laid out", async () => {
    const d = mountDropdown();
    // jsdom's zeroes: no rect, no height. Guessing here would flip every
    // panel in a test suite that never lays anything out.
    show(d);
    await settle();
    expect(d.flipped()).toBe(false);
  });

  it("survives a trigger it cannot find", async () => {
    const d = mountDropdown();
    d.trigger.remove();
    show(d);
    await settle();
    expect(d.flipped()).toBe(false);
  });

  it("destroyed() drops its listeners", async () => {
    const d = mountDropdown();
    withGeometry(d, { triggerTop: 100, triggerBottom: 140, panelHeight: 200 });
    show(d);
    await settle();

    d.hook.destroyed();
    withGeometry(d, { triggerTop: 700, triggerBottom: 740, panelHeight: 200 });
    window.dispatchEvent(new Event("scroll"));
    expect(d.flipped()).toBe(false);
  });
});

// The mobile trap: the on-screen keyboard and pinch-zoom shrink and offset
// the VISUAL viewport without touching window.innerHeight or firing window
// events. The hook must measure the band the user can actually see, and
// re-ask when that band changes - the same contract the data table's
// positioner honours.
describe("PetalDropdown and the visual viewport", () => {
  function mockVisualViewport({ offsetTop = 0, height }) {
    const listeners = [];
    window.visualViewport = {
      offsetTop,
      height,
      addEventListener: (type, fn) => listeners.push([type, fn]),
      removeEventListener: (type, fn) => {
        const i = listeners.findIndex(([t, f]) => t === type && f === fn);
        if (i !== -1) listeners.splice(i, 1);
      },
      fire: (type) =>
        listeners.filter(([t]) => t === type).forEach(([, fn]) => fn()),
      listeners,
    };
    return window.visualViewport;
  }

  afterEach(() => {
    delete window.visualViewport;
  });

  it("measures the visible band, not the layout viewport", async () => {
    const d = mountDropdown();
    // Layout viewport says 252px of room below - plenty. The keyboard has
    // eaten the bottom half: the visible band ends at 300, so the panel
    // must flip up into the 492px above instead of opening behind the keys.
    withGeometry(d, {
      triggerTop: 500,
      triggerBottom: 540,
      panelHeight: 200,
      viewport: 800,
    });
    mockVisualViewport({ height: 300 });

    show(d);
    await settle();
    expect(d.flipped()).toBe(true);
  });

  it("honours the band's offset when the page is pinch-panned", async () => {
    const d = mountDropdown();
    // The visual viewport sits 400px down the layout viewport. The trigger
    // at 450 is near the band's TOP, so below (350) has the room and above
    // (42) does not - layout numbers alone would agree here, but offsetTop
    // is what keeps the maths honest either way.
    withGeometry(d, {
      triggerTop: 450,
      triggerBottom: 490,
      panelHeight: 200,
      viewport: 800,
    });
    mockVisualViewport({ offsetTop: 400, height: 400 });

    show(d);
    await settle();
    expect(d.flipped()).toBe(false);
  });

  it("re-asks when the visual viewport changes while open", async () => {
    const d = mountDropdown();
    withGeometry(d, {
      triggerTop: 500,
      triggerBottom: 540,
      panelHeight: 200,
      viewport: 800,
    });
    const vv = mockVisualViewport({ height: 800 });

    show(d);
    await settle();
    expect(d.flipped()).toBe(false);

    // The keyboard opens: no window event fires, only the vv's own resize.
    vv.height = 300;
    vv.fire("resize");
    expect(d.flipped()).toBe(true);
  });

  it("stops listening to the visual viewport on close and teardown", async () => {
    const d = mountDropdown();
    withGeometry(d, {
      triggerTop: 100,
      triggerBottom: 140,
      panelHeight: 200,
      viewport: 800,
    });
    const vv = mockVisualViewport({ height: 800 });

    show(d);
    await settle();
    expect(vv.listeners.length).toBe(2);

    hide(d);
    await settle();
    expect(vv.listeners.length).toBe(0);

    show(d);
    await settle();
    expect(vv.listeners.length).toBe(2);
    d.hook.destroyed();
    expect(vv.listeners.length).toBe(0);
  });
});
