// PetalDrawer hook: the bottom-sheet drag layer.
//
// The physics is pure - offsets are pixels DOWN from the drawer's tallest
// resting position, so 0 is fully open and larger is further off-screen. The
// specs below pin the two decisions that matter on release: did this drag go
// far enough, or fast enough, to mean "close".
import { afterEach, describe, expect, it, vi } from "vitest";

import hooks, {
  drawerResistance,
  drawerSettle,
  drawerVelocity,
  PetalDrawer,
} from "../../assets/js/petal_components.js";

// a viewport-sized sheet: 800px tall drawer in an 800px viewport
const HEIGHT = 800;

describe("drawerResistance", () => {
  it("passes ordinary downward drag through untouched", () => {
    expect(drawerResistance(120, 0)).toBe(120);
    expect(drawerResistance(0, 0)).toBe(0);
  });

  it("rubber-bands above the top snap so the sheet feels anchored", () => {
    // 100px of pull above the top only buys 15px of travel
    expect(drawerResistance(-100, 0)).toBeCloseTo(-15);
    expect(drawerResistance(-100, 0, 0.5)).toBeCloseTo(-50);
  });

  it("measures resistance from the top snap, not from zero", () => {
    // top snap is 200px down; pulling to 100 is 100px of overshoot
    expect(drawerResistance(100, 200)).toBeCloseTo(185);
    expect(drawerResistance(250, 200)).toBe(250);
  });
});

describe("drawerVelocity", () => {
  it("is zero without at least two samples", () => {
    expect(drawerVelocity([])).toBe(0);
    expect(drawerVelocity([{ y: 10, time: 1 }])).toBe(0);
    expect(drawerVelocity(undefined)).toBe(0);
  });

  it("reports px/ms, signed downward-positive", () => {
    expect(
      drawerVelocity([
        { y: 0, time: 0 },
        { y: 100, time: 100 },
      ]),
    ).toBeCloseTo(1);

    expect(
      drawerVelocity([
        { y: 100, time: 0 },
        { y: 0, time: 50 },
      ]),
    ).toBeCloseTo(-2);
  });

  it("averages over a window, so one fast frame cannot fake a flick", () => {
    const slowDragEndingFast = [
      { y: 0, time: 0 },
      { y: 10, time: 100 },
      { y: 20, time: 200 },
      { y: 30, time: 300 },
      { y: 60, time: 320 },
    ];
    // the last pair alone reads 1.5px/ms; across the window it is ~0.19
    expect(drawerVelocity(slowDragEndingFast)).toBeCloseTo(0.1875);
  });

  it("cannot divide by a zero time delta", () => {
    expect(
      drawerVelocity([
        { y: 0, time: 5 },
        { y: 90, time: 5 },
      ]),
    ).toBe(0);
  });
});

describe("drawerSettle without snap points", () => {
  const release = (offset, velocity = 0, extra = {}) =>
    drawerSettle({ offset, velocity, height: HEIGHT, ...extra });

  it("springs back from a short, slow drag", () => {
    // 25% of 800 is 200px; 120px with no flick is not a dismiss
    expect(release(120)).toEqual({ type: "settle", offset: 0 });
  });

  it("dismisses once the drag passes the distance threshold", () => {
    expect(release(220)).toEqual({ type: "dismiss" });
  });

  it("dismisses a short flick that clears the velocity threshold", () => {
    // 60px is well under the 200px threshold, but 0.9px/ms is a flick
    expect(release(60, 0.9)).toEqual({ type: "dismiss" });
  });

  it("keeps a short, gentle drag even when it ends moving", () => {
    expect(release(60, 0.2)).toEqual({ type: "settle", offset: 0 });
  });

  it("never dismisses on an upward flick", () => {
    expect(release(150, -2)).toEqual({ type: "settle", offset: 0 });
  });

  it("never dismisses from rest, however hard the flick", () => {
    expect(release(0, 5)).toEqual({ type: "settle", offset: 0 });
  });

  it("springs back instead of closing when dismissal is off", () => {
    expect(release(500, 3, { dismissible: false })).toEqual({
      type: "settle",
      offset: 0,
    });
  });
});

describe("drawerSettle with snap points", () => {
  // snaps [0.4, 0.9] in an 800px viewport: the sheet is 720px tall, so 0.9
  // rests at offset 0 and 0.4 rests 400px down
  const snapOffsets = [0, 400];
  const height = 720;
  const release = (offset, velocity = 0, extra = {}) =>
    drawerSettle({ offset, velocity, height, snapOffsets, ...extra });

  it("settles on the nearest point when released slowly", () => {
    expect(release(120)).toEqual({ type: "settle", offset: 0 });
    expect(release(300)).toEqual({ type: "settle", offset: 400 });
  });

  it("lets a downward flick skip to the next point down", () => {
    // nearest is 0, but the flick direction wins
    expect(release(100, 1.2)).toEqual({ type: "settle", offset: 400 });
  });

  it("lets an upward flick skip to the next point up", () => {
    expect(release(340, -1.2)).toEqual({ type: "settle", offset: 0 });
  });

  it("falls back to nearest when a flick has nowhere left to go", () => {
    // already at the top point and still flicking up
    expect(release(0, -1.5)).toEqual({ type: "settle", offset: 0 });
  });

  it("holds a drag between points that has not passed the lowest one", () => {
    // 180px below the lowest snap is under the 25% (180px) threshold
    expect(release(560)).toEqual({ type: "settle", offset: 400 });
  });

  it("dismisses only below the lowest snap, past the threshold", () => {
    expect(release(600)).toEqual({ type: "dismiss" });
  });

  it("dismisses on a flick below the lowest snap", () => {
    expect(release(430, 1.2)).toEqual({ type: "dismiss" });
  });

  it("does not dismiss on a flick that is still above the lowest snap", () => {
    expect(release(200, 1.2)).toEqual({ type: "settle", offset: 400 });
  });

  it("accepts snap offsets in any order", () => {
    expect(
      drawerSettle({ offset: 300, height, snapOffsets: [400, 0] }),
    ).toEqual({ type: "settle", offset: 400 });
  });
});

// A thin harness over the hook lifecycle - enough of `this` for mounted() to
// run, and a liveSocket that records the JS command a dismiss fires.
const mounted = [];

function mount({
  snapPoints = "",
  initialSnap = "",
  dragDismiss = "true",
  scaleBackground = "",
  scrollTop = 0,
} = {}) {
  const wrap = document.createElement("div");
  wrap.innerHTML = `
    <div data-pc-drawer-wrapper></div>
    <div id="sheet-content" class="pc-slideover__box pc-slideover__box--drawer"
         data-drag-dismiss="${dragDismiss}"
         data-snap-points="${snapPoints}"
         data-initial-snap="${initialSnap}"
         data-scale-background="${scaleBackground}"
         data-pc-drawer-hide='[["push",{"event":"close_slide_over"}]]'>
      <div class="pc-slideover__handle" data-pc-drawer-handle></div>
      <div class="pc-slideover__content"></div>
    </div>
  `;
  document.body.appendChild(wrap);

  const el = wrap.querySelector("#sheet-content");
  Object.defineProperty(el.querySelector(".pc-slideover__content"), "scrollTop", {
    value: scrollTop,
    writable: true,
  });

  const executed = [];
  const hook = Object.create(PetalDrawer);
  hook.el = el;
  hook.liveSocket = { execJS: (_el, cmd) => executed.push(cmd) };
  hook.mounted();

  mounted.push({ hook, wrap });
  return { hook, el, wrap, executed };
}

// the hook binds pointer handlers to the window, so drive them directly -
// jsdom has no PointerEvent and the maths is what these specs are about
const down = (hook, target, y) =>
  hook.onPointerDown({
    isPrimary: true,
    button: 0,
    pointerId: 1,
    clientY: y,
    timeStamp: 0,
    target,
  });

const move = (hook, y, time) =>
  hook.onPointerMove({ pointerId: 1, clientY: y, timeStamp: time });

const up = (hook) => hook.onPointerUp({ pointerId: 1 });

describe("PetalDrawer", () => {
  afterEach(() => {
    mounted.splice(0).forEach(({ hook, wrap }) => {
      hook.destroyed();
      wrap.remove();
    });
    vi.restoreAllMocks();
  });

  it("is exported on the hooks object under the name the component asks for", () => {
    expect(hooks.PetalDrawer).toBe(PetalDrawer);
  });

  it("opens a snapped drawer at its initial snap", () => {
    const { hook, el } = mount({ snapPoints: "0.4,0.9", initialSnap: "0.4" });
    // (0.9 - 0.4) of the viewport down from the top of a 0.9-tall sheet
    expect(hook.offset).toBeCloseTo(0.5 * window.innerHeight);
    expect(el.style.transform).toContain("translate3d");
  });

  it("leaves an unsnapped drawer at rest with no transform", () => {
    const { hook, el } = mount();
    expect(hook.offset).toBe(0);
    expect(el.style.transform).toBe("");
  });

  it("follows the finger downward and springs back from a short drag", () => {
    const { hook, el } = mount();
    const handle = el.querySelector("[data-pc-drawer-handle]");

    down(hook, handle, 500);
    // slowly - 40px over 300ms is a nudge, not a flick
    move(hook, 540, 300);
    expect(hook.offset).toBeCloseTo(40);
    expect(el.classList.contains("pc-slideover__box--dragging")).toBe(true);

    up(hook);
    expect(hook.offset).toBe(0);
    expect(el.classList.contains("pc-slideover__box--dragging")).toBe(false);
  });

  it("routes a dismissing drag through the shared hide command", () => {
    const { hook, el, executed } = mount();
    const handle = el.querySelector("[data-pc-drawer-handle]");

    down(hook, handle, 100);
    // a decisive flick down
    move(hook, 200, 20);
    move(hook, 400, 60);
    up(hook);

    expect(executed).toHaveLength(1);
    expect(executed[0]).toContain("close_slide_over");
  });

  it("does not dismiss when drag_to_dismiss is off", () => {
    const { hook, el, executed } = mount({ dragDismiss: "false" });
    const handle = el.querySelector("[data-pc-drawer-handle]");

    down(hook, handle, 100);
    move(hook, 400, 60);
    up(hook);

    expect(executed).toHaveLength(0);
    expect(hook.offset).toBe(0);
  });

  it("ignores a pointer landing on a control inside the sheet", () => {
    const { hook, el } = mount();
    const button = document.createElement("button");
    el.querySelector(".pc-slideover__content").appendChild(button);

    down(hook, button, 500);
    expect(hook.dragging).toBe(false);
  });

  it("leaves the drag to the body while its content is scrolled", () => {
    const { hook, el } = mount({ scrollTop: 120 });

    down(hook, el.querySelector(".pc-slideover__content"), 500);
    expect(hook.dragging).toBe(false);
  });

  it("still drags from the handle when the body is scrolled", () => {
    const { hook, el } = mount({ scrollTop: 120 });

    down(hook, el.querySelector("[data-pc-drawer-handle]"), 500);
    expect(hook.dragging).toBe(true);
  });

  it("scales the page wrapper only while the drawer is open", () => {
    const { hook, el, wrap } = mount({ scaleBackground: "true" });
    const page = wrap.querySelector("[data-pc-drawer-wrapper]");

    expect(page.classList.contains("pc-drawer-scaled")).toBe(false);

    el.style.display = "flex";
    hook.syncBackground();
    expect(page.classList.contains("pc-drawer-scaled")).toBe(true);

    el.style.display = "none";
    hook.syncBackground();
    expect(page.classList.contains("pc-drawer-scaled")).toBe(false);
  });

  it("settles instantly under prefers-reduced-motion", () => {
    vi.spyOn(window, "matchMedia").mockImplementation(() => ({
      matches: true,
      addEventListener() {},
      removeEventListener() {},
    }));

    const { hook, el } = mount();
    const handle = el.querySelector("[data-pc-drawer-handle]");

    down(hook, handle, 500);
    move(hook, 540, 300);
    up(hook);

    expect(el.style.transition).toBe("");
  });
});
