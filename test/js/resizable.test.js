// PetalResizable: the sizing maths, and the hook wiring on top of it.
//
// Everything is a percentage of the group. Two invariants carry the whole
// component and every spec here is ultimately about one of them:
//   1. the sizes array always sums to 100
//   2. an operation on one separator only ever moves its two panels
// The Elixir side pins the markup this reads (test/petal/resizable_test.exs);
// update both together if the anatomy changes.
import { afterEach, describe, expect, it } from "vitest";

import hooks, {
  distributeSizes,
  keyboardDelta,
  resizableConstraint,
  resolveDrag,
  resolveEdge,
  resolveReset,
  resolveToggle,
} from "../../assets/js/petal_components.js";

import { pointerEvent } from "./helpers.js";

const c = (over = {}) => ({
  min: 10,
  max: 100,
  default: null,
  collapsible: false,
  collapsedSize: 0,
  ...over,
});

const sum = (sizes) => sizes.reduce((a, b) => a + b, 0);

describe("distributeSizes", () => {
  it("splits an all-unsized group equally", () => {
    expect(distributeSizes([c(), c(), c()])).toEqual([
      100 / 3,
      100 / 3,
      100 / 3,
    ].map((n) => Math.round(n * 1e6) / 1e6));
  });

  it("honours every default_size when they already add up", () => {
    expect(distributeSizes([c({ default: 25 }), c({ default: 75 })])).toEqual([
      25, 75,
    ]);
  });

  it("gives unsized panels the remainder, split between them", () => {
    const sizes = distributeSizes([c({ default: 50 }), c(), c()]);
    expect(sizes).toEqual([50, 25, 25]);
  });

  it("normalises defaults that do not add up to 100", () => {
    const sizes = distributeSizes([c({ default: 30 }), c({ default: 30 })]);
    expect(sizes).toEqual([50, 50]);
    expect(sum(sizes)).toBeCloseTo(100, 6);
  });

  it("clamps a default below min up to the floor before normalising", () => {
    // default_size < min_size must not paint below the floor on first render
    const sizes = distributeSizes([
      { min: 30, max: 100, default: 10 },
      { min: 10, max: 100 },
    ]);
    // 10 clamps up to 30 against the unsized panel's 90, then normalises
    expect(sizes[0]).toBeCloseTo(25, 1);
    expect(sizes[1]).toBeCloseTo(75, 1);
  });

  it("lets a collapsible panel start below min - its floor is the collapsed size", () => {
    const sizes = distributeSizes([
      { min: 20, max: 100, default: 5, collapsible: true, collapsedSize: 0 },
      { min: 10, max: 100 },
    ]);
    expect(sizes[0]).toBeCloseTo(5, 1);
  });

  it("returns nothing for an empty group", () => {
    expect(distributeSizes([])).toEqual([]);
  });
});

describe("resizableConstraint", () => {
  it("reads the data-* contract the Elixir panel renders", () => {
    const el = document.createElement("div");
    el.dataset.min = "15";
    el.dataset.max = "60";
    el.dataset.default = "25";
    el.dataset.collapsible = "true";
    el.dataset.collapsedSize = "4";

    expect(resizableConstraint(el)).toEqual({
      min: 15,
      max: 60,
      default: 25,
      collapsible: true,
      collapsedSize: 4,
    });
  });

  it("falls back to the component defaults when attributes are absent", () => {
    const el = document.createElement("div");
    expect(resizableConstraint(el)).toEqual({
      min: 10,
      max: 100,
      default: null,
      collapsible: false,
      collapsedSize: 0,
    });
  });
});

describe("resolveDrag", () => {
  const pair = [c({ min: 20, max: 80 }), c({ min: 20, max: 80 })];

  it("moves both adjacent panels and conserves the total", () => {
    const { sizes } = resolveDrag([50, 50], 0, 10, pair);
    expect(sizes).toEqual([60, 40]);
    expect(sum(sizes)).toBeCloseTo(100, 6);
  });

  it("clamps at the primary panel's max", () => {
    const { sizes } = resolveDrag([50, 50], 0, 40, pair);
    expect(sizes).toEqual([80, 20]);
  });

  it("clamps at the primary panel's min", () => {
    const { sizes } = resolveDrag([50, 50], 0, -40, pair);
    expect(sizes).toEqual([20, 80]);
  });

  it("respects the FOLLOWING panel's min, not just the primary's", () => {
    // panel a could legally reach 90, but b refuses to go under 35
    const constraints = [c({ min: 10, max: 90 }), c({ min: 35, max: 90 })];
    const { sizes } = resolveDrag([50, 50], 0, 100, constraints);
    expect(sizes).toEqual([65, 35]);
    expect(sum(sizes)).toBeCloseTo(100, 6);
  });

  it("respects the following panel's max", () => {
    const constraints = [c({ min: 5, max: 90 }), c({ min: 5, max: 60 })];
    const { sizes } = resolveDrag([50, 50], 0, -100, constraints);
    expect(sizes).toEqual([40, 60]);
  });

  it("leaves panels either side of the pair untouched", () => {
    const three = [c(), c(), c()];
    const { sizes } = resolveDrag([30, 40, 30], 1, 10, three);
    expect(sizes).toEqual([30, 50, 20]);
    expect(sum(sizes)).toBeCloseTo(100, 6);
  });

  it("is a no-op on an out-of-range separator", () => {
    const { sizes, collapse } = resolveDrag([50, 50], 1, 10, pair);
    expect(sizes).toEqual([50, 50]);
    expect(collapse).toBeNull();
  });

  describe("collapse", () => {
    const collapsible = [
      c({ min: 20, max: 80, collapsible: true, default: 25 }),
      c({ min: 10, max: 100 }),
    ];

    it("snaps shut below half the min and reports the collapse", () => {
      const { sizes, collapse } = resolveDrag([25, 75], 0, -20, collapsible);
      expect(sizes).toEqual([0, 100]);
      expect(collapse).toEqual({ index: 0, collapsed: true });
    });

    it("does not snap while still above the threshold, it just clamps", () => {
      const { sizes, collapse } = resolveDrag([25, 75], 0, -3, collapsible);
      expect(sizes).toEqual([22, 78]);
      expect(collapse).toBeNull();
    });

    it("stays collapsed on a small nudge, without re-firing", () => {
      const { sizes, collapse } = resolveDrag([0, 100], 0, 3, collapsible);
      expect(sizes).toEqual([0, 100]);
      expect(collapse).toBeNull();
    });

    it("expands back to min_size once dragged past the threshold", () => {
      const { sizes, collapse } = resolveDrag([0, 100], 0, 15, collapsible);
      expect(sizes).toEqual([20, 80]);
      expect(collapse).toEqual({ index: 0, collapsed: false });
    });

    it("collapses the FOLLOWING panel when the drag pushes it shut", () => {
      const constraints = [
        c({ min: 10, max: 100 }),
        c({ min: 20, max: 80, collapsible: true }),
      ];
      const { sizes, collapse } = resolveDrag([75, 25], 0, 20, constraints);
      expect(sizes).toEqual([100, 0]);
      expect(collapse).toEqual({ index: 1, collapsed: true });
    });

    it("honours a non-zero collapsed_size", () => {
      const constraints = [
        c({ min: 20, max: 80, collapsible: true, collapsedSize: 5 }),
        c(),
      ];
      const { sizes, collapse } = resolveDrag([25, 75], 0, -25, constraints);
      expect(sizes).toEqual([5, 95]);
      expect(collapse).toEqual({ index: 0, collapsed: true });
    });
  });
});

describe("resolveEdge", () => {
  it("Home shrinks a plain panel to its min", () => {
    const { sizes } = resolveEdge([50, 50], 0, "min", [
      c({ min: 20 }),
      c({ min: 10 }),
    ]);
    expect(sizes).toEqual([20, 80]);
  });

  it("Home collapses a collapsible panel instead of stopping at min", () => {
    const { sizes, collapse } = resolveEdge([50, 50], 0, "min", [
      c({ min: 20, collapsible: true }),
      c({ min: 0 }),
    ]);
    expect(sizes).toEqual([0, 100]);
    expect(collapse).toEqual({ index: 0, collapsed: true });
  });

  it("End grows the panel to its max, bounded by its neighbour's min", () => {
    const { sizes } = resolveEdge([50, 50], 0, "max", [
      c({ max: 90 }),
      c({ min: 25 }),
    ]);
    expect(sizes).toEqual([75, 25]);
    expect(sum(sizes)).toBeCloseTo(100, 6);
  });
});

describe("resolveToggle", () => {
  const constraints = [
    c({ min: 20, max: 80, default: 25, collapsible: true }),
    c({ min: 10 }),
  ];

  it("collapses an open panel", () => {
    const { sizes, collapse } = resolveToggle([25, 75], 0, constraints);
    expect(sizes).toEqual([0, 100]);
    expect(collapse).toEqual({ index: 0, collapsed: true });
  });

  it("restores a collapsed panel to its default", () => {
    const { sizes, collapse } = resolveToggle([0, 100], 0, constraints);
    expect(sizes).toEqual([25, 75]);
    expect(collapse).toEqual({ index: 0, collapsed: false });
  });

  it("is a no-op on a panel that cannot collapse", () => {
    const { sizes, collapse } = resolveToggle([50, 50], 0, [c(), c()]);
    expect(sizes).toEqual([50, 50]);
    expect(collapse).toBeNull();
  });
});

describe("resolveReset", () => {
  it("puts the two adjacent panels back on their default ratio", () => {
    const constraints = [c({ default: 25 }), c({ default: 75 })];
    const { sizes } = resolveReset([70, 30], 0, constraints);
    expect(sizes).toEqual([25, 75]);
  });

  it("spends only the space the pair already holds", () => {
    const constraints = [c({ default: 25 }), c({ default: 75 }), c()];
    const { sizes } = resolveReset([50, 20, 30], 0, constraints);
    expect(sizes).toEqual([17.5, 52.5, 30]);
    expect(sum(sizes)).toBeCloseTo(100, 6);
  });

  it("splits the pair evenly when neither panel declared a default", () => {
    const { sizes } = resolveReset([70, 30], 0, [c(), c()]);
    expect(sizes).toEqual([50, 50]);
  });

  it("reports the expand when it reopens a collapsed panel", () => {
    const constraints = [
      c({ default: 25, min: 20, collapsible: true }),
      c({ default: 75 }),
    ];
    const { sizes, collapse } = resolveReset([0, 100], 0, constraints);
    expect(sizes).toEqual([25, 75]);
    expect(collapse).toEqual({ index: 0, collapsed: false });
  });
});

describe("keyboardDelta", () => {
  it("steps a vertical separator with Left and Right", () => {
    expect(keyboardDelta("ArrowLeft", false, "horizontal")).toBe(-2);
    expect(keyboardDelta("ArrowRight", false, "horizontal")).toBe(2);
  });

  it("steps a horizontal separator with Up and Down", () => {
    expect(keyboardDelta("ArrowUp", false, "vertical")).toBe(-2);
    expect(keyboardDelta("ArrowDown", false, "vertical")).toBe(2);
  });

  it("takes a bigger bite with Shift", () => {
    expect(keyboardDelta("ArrowRight", true, "horizontal")).toBe(10);
    expect(keyboardDelta("ArrowUp", true, "vertical")).toBe(-10);
  });

  it("is a no-op for arrows perpendicular to the separator", () => {
    expect(keyboardDelta("ArrowUp", false, "horizontal")).toBeNull();
    expect(keyboardDelta("ArrowDown", false, "horizontal")).toBeNull();
    expect(keyboardDelta("ArrowLeft", false, "vertical")).toBeNull();
    expect(keyboardDelta("ArrowRight", false, "vertical")).toBeNull();
  });

  it("ignores keys that are not arrows", () => {
    expect(keyboardDelta("a", false, "horizontal")).toBeNull();
    expect(keyboardDelta("Tab", false, "vertical")).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// The hook on top of the maths: ARIA stamping, the events, and the guard that
// keeps a nested group's separators away from the outer hook.
// ---------------------------------------------------------------------------

const mounted = [];

function panelHtml(id, { size, min = 10, max = 100, collapsible, collapsedSize = 0 } = {}) {
  return `<div id="${id}" class="pc-resizable__panel" data-pc-resizable-panel
    data-min="${min}" data-max="${max}"
    ${size === undefined ? "" : `data-default="${size}"`}
    ${collapsible ? 'data-collapsible="true"' : ""}
    data-collapsed-size="${collapsedSize}"></div>`;
}

const handleHtml = `<div class="pc-resizable__handle" data-pc-resizable-handle role="separator"
  tabindex="0" aria-orientation="vertical" aria-valuenow="50" aria-valuemin="0"
  aria-valuemax="100"></div>`;

function mount({ orientation = "horizontal", onResize = null, panels } = {}) {
  const el = document.createElement("div");
  el.id = "grp";
  el.className = "pc-resizable";
  el.dataset.orientation = orientation;
  if (onResize) el.dataset.onResize = onResize;

  const cells =
    panels ||
    [panelHtml("p0", { size: 25, min: 20, collapsible: true }), panelHtml("p1", { size: 75 })];
  el.innerHTML = cells.join(handleHtml);
  document.body.appendChild(el);

  // jsdom lays nothing out, so the group has no size of its own. Pointer maths
  // divides by this, so give it the 1000px a real group would report.
  el.getBoundingClientRect = () => ({ width: 1000, height: 1000, top: 0, left: 0 });

  const hook = Object.create(hooks.PetalResizable);
  hook.el = el;
  hook.pushed = [];
  hook.pushEvent = (name, payload) => hook.pushed.push([name, payload]);

  const resizes = [];
  const collapses = [];
  el.addEventListener("petal:resizable-resize", (e) => resizes.push(e.detail));
  el.addEventListener("petal:resizable-collapse", (e) => collapses.push(e.detail));

  hook.mounted();
  mounted.push({ hook, el });

  return { hook, el, resizes, collapses };
}

const handles = (el) => Array.from(el.querySelectorAll("[data-pc-resizable-handle]"));
const flexOf = (el, id) => el.querySelector(`#${id}`).style.flex;

function key(target, k, props = {}) {
  target.dispatchEvent(new KeyboardEvent("keydown", { bubbles: true, key: k, ...props }));
}

describe("PetalResizable hook", () => {
  afterEach(() => {
    mounted.splice(0).forEach(({ hook, el }) => {
      hook.destroyed();
      el.remove();
    });
  });

  it("applies the distributed sizes as flex-grow on mount", () => {
    const { el } = mount();
    expect(flexOf(el, "p0")).toBe("25 1 0px");
    expect(flexOf(el, "p1")).toBe("75 1 0px");
  });

  it("stamps the live ARIA contract onto every separator", () => {
    const { el } = mount();
    const [h] = handles(el);

    expect(h.getAttribute("aria-valuenow")).toBe("25");
    // the panel is collapsible, so its floor is the collapsed size
    expect(h.getAttribute("aria-valuemin")).toBe("0");
    expect(h.getAttribute("aria-valuemax")).toBe("100");
    expect(h.getAttribute("aria-orientation")).toBe("vertical");
    expect(h.getAttribute("aria-controls")).toBe("p0");
  });

  it("inverts aria-orientation for a vertical group", () => {
    const { el } = mount({ orientation: "vertical" });
    expect(handles(el)[0].getAttribute("aria-orientation")).toBe("horizontal");
  });

  it("Enter on a non-collapsible separator is a TRUE no-op", () => {
    // no resize event, no on_resize push, and the key is left to the page -
    // firing petal:resizable-resize with unchanged sizes was noise
    const { el, resizes, hook } = mount({
      onResize: "save",
      panels: [panelHtml("p0", { size: 25, min: 20 }), panelHtml("p1", { size: 75 })],
    });
    const [h] = handles(el);

    const ev = new KeyboardEvent("keydown", { bubbles: true, cancelable: true, key: "Enter" });
    h.dispatchEvent(ev);

    expect(resizes).toEqual([]);
    expect(hook.pushed).toEqual([]);
    expect(ev.defaultPrevented).toBe(false);
  });

  it("updated() re-stamps flex and ARIA a patch wiped", () => {
    const { el, hook } = mount();
    const [h] = handles(el);

    el.querySelector("#p0").style.flex = "";
    h.removeAttribute("aria-valuenow");

    hook.updated();
    expect(flexOf(el, "p0")).toBe("25 1 0px");
    expect(h.getAttribute("aria-valuenow")).toBe("25");
  });

  it("updated() re-derives sizes when the panel count changes", () => {
    const { el, hook } = mount();

    el.insertAdjacentHTML("beforeend", handleHtml + panelHtml("p2", { size: 50 }));
    hook.updated();

    expect(flexOf(el, "p2")).toMatch(/ 1 0px$/);
    expect(flexOf(el, "p0")).not.toBe("25 1 0px");
  });

  it("grabbing a separator with the pointer hands it keyboard focus", () => {
    // preventDefault on pointerdown suppresses native focus - without the
    // explicit hand-over, click-then-arrow-keys did nothing
    const { el } = mount();
    const [h] = handles(el);

    h.dispatchEvent(new MouseEvent("pointerdown", { bubbles: true, button: 0 }));
    expect(document.activeElement).toBe(h);
  });

  it("resizes on an arrow key and keeps aria-valuenow current", () => {
    const { el } = mount();
    const [h] = handles(el);

    key(h, "ArrowRight");

    expect(flexOf(el, "p0")).toBe("27 1 0px");
    expect(flexOf(el, "p1")).toBe("73 1 0px");
    expect(h.getAttribute("aria-valuenow")).toBe("27");
  });

  it("takes a 10-point step with Shift", () => {
    const { el } = mount();
    key(handles(el)[0], "ArrowRight", { shiftKey: true });
    expect(flexOf(el, "p0")).toBe("35 1 0px");
  });

  it("ignores arrows perpendicular to the separator", () => {
    const { el } = mount();
    key(handles(el)[0], "ArrowUp");
    expect(flexOf(el, "p0")).toBe("25 1 0px");
  });

  it("Home collapses the collapsible primary panel, End grows it to max", () => {
    const { el, collapses } = mount();
    const [h] = handles(el);

    key(h, "Home");
    expect(flexOf(el, "p0")).toBe("0 1 0px");
    expect(collapses).toEqual([{ panel_id: "p0", collapsed: true }]);

    key(h, "End");
    expect(flexOf(el, "p0")).toBe("90 1 0px");
  });

  it("Enter toggles collapse and restore", () => {
    const { el, collapses } = mount();
    const [h] = handles(el);

    key(h, "Enter");
    expect(flexOf(el, "p0")).toBe("0 1 0px");

    key(h, "Enter");
    expect(flexOf(el, "p0")).toBe("25 1 0px");
    expect(collapses).toEqual([
      { panel_id: "p0", collapsed: true },
      { panel_id: "p0", collapsed: false },
    ]);
  });

  it("commits the sizes on every keyboard resize", () => {
    const { el, resizes } = mount({ onResize: "split" });
    const hook = mounted[mounted.length - 1].hook;

    key(handles(el)[0], "ArrowRight");

    expect(resizes).toEqual([{ sizes: [27, 73] }]);
    expect(hook.pushed).toEqual([["split", { sizes: [27, 73] }]]);
  });

  it("does not push when no on_resize event is configured", () => {
    const { el, resizes } = mount();
    const hook = mounted[mounted.length - 1].hook;

    key(handles(el)[0], "ArrowRight");

    expect(resizes).toHaveLength(1);
    expect(hook.pushed).toEqual([]);
  });

  it("drags through pointer events and commits once on release", () => {
    const { el, resizes } = mount();
    const [h] = handles(el);
    h.setPointerCapture = () => {};
    h.releasePointerCapture = () => {};

    h.dispatchEvent(pointerEvent("pointerdown", "mouse", { clientX: 250, button: 0 }));
    el.dispatchEvent(pointerEvent("pointermove", "mouse", { clientX: 400 }));

    // 150px of a 1000px group is 15 points
    expect(flexOf(el, "p0")).toBe("40 1 0px");
    expect(resizes).toHaveLength(0);
    expect(document.body.style.userSelect).toBe("none");

    h.dispatchEvent(pointerEvent("pointerup", "mouse", { clientX: 400 }));

    expect(resizes).toEqual([{ sizes: [40, 60] }]);
    expect(document.body.style.userSelect).toBe("");
  });

  it("double-click resets the pair to their defaults", () => {
    const { el, resizes } = mount();
    const [h] = handles(el);

    key(h, "ArrowRight", { shiftKey: true });
    expect(flexOf(el, "p0")).toBe("35 1 0px");

    h.dispatchEvent(new MouseEvent("dblclick", { bubbles: true }));

    expect(flexOf(el, "p0")).toBe("25 1 0px");
    expect(resizes[resizes.length - 1]).toEqual({ sizes: [25, 75] });
  });

  it("ignores separators belonging to a nested group", () => {
    const { el } = mount({
      panels: [
        `<div id="p0" class="pc-resizable__panel" data-pc-resizable-panel data-min="10" data-max="100" data-default="50" data-collapsed-size="0">
           <div id="inner" class="pc-resizable" data-orientation="horizontal">
             ${panelHtml("i0", { size: 40 })}
             ${handleHtml.replace("data-pc-resizable-handle", 'data-pc-resizable-handle id="inner-h"')}
             ${panelHtml("i1", { size: 60 })}
           </div>
         </div>`,
        panelHtml("p1", { size: 50 }),
      ],
    });

    const outer = mounted[mounted.length - 1].hook;
    expect(outer.panels.map((p) => p.id)).toEqual(["p0", "p1"]);
    expect(outer.handles).toHaveLength(1);

    // an inner separator's keydown bubbles up to the outer group; it must not
    // move the outer panels
    key(el.querySelector("#inner-h"), "ArrowRight");
    expect(flexOf(el, "p0")).toBe("50 1 0px");
  });

  it("restores the body cursor when torn down mid-drag", () => {
    const { el } = mount();
    const [h] = handles(el);
    h.setPointerCapture = () => {};

    h.dispatchEvent(pointerEvent("pointerdown", "mouse", { clientX: 250, button: 0 }));
    expect(document.body.style.cursor).toBe("col-resize");

    mounted.splice(0).forEach(({ hook, el: node }) => {
      hook.destroyed();
      node.remove();
    });

    expect(document.body.style.cursor).toBe("");
  });
});
