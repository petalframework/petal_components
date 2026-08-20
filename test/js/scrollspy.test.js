// PetalScrollspy hook: which nav entry is highlighted while you read.
//
// jsdom has no IntersectionObserver and no layout, so the specs stub the
// observer and feed rects by hand. That is not a workaround for the test
// environment - the hook decides from rects rather than from observer entries
// precisely so the decision is a pure function anyone can reason about.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import hooks, { scrollspyActive } from "../../assets/js/petal_components.js";

const mounted = [];

// A stub with the same shape LiveView's DOM would give us: it records what
// was observed and hands back a way to fire the callback.
function stubIntersectionObserver() {
  const instances = [];

  class FakeIntersectionObserver {
    constructor(callback, options) {
      this.callback = callback;
      this.options = options;
      this.observed = [];
      this.disconnected = false;
      instances.push(this);
    }
    observe(el) {
      this.observed.push(el);
    }
    disconnect() {
      this.disconnected = true;
    }
  }

  globalThis.IntersectionObserver = FakeIntersectionObserver;
  return instances;
}

beforeEach(() => {
  window.location.hash = "";
  // Nothing in these specs cares about frame timing; run the work now so the
  // assertions read straight through.
  vi.stubGlobal("requestAnimationFrame", (cb) => {
    cb();
    return 1;
  });
  vi.stubGlobal("cancelAnimationFrame", () => {});
  vi.stubGlobal(
    "matchMedia",
    vi.fn(() => ({ matches: false, addEventListener() {}, removeEventListener() {} })),
  );
});

afterEach(() => {
  mounted.splice(0).forEach(({ hook, wrap }) => {
    try {
      hook.destroyed();
    } finally {
      wrap.remove();
    }
  });
  vi.unstubAllGlobals();
});

// A rail plus its sections. `tops` sets each section's rect top in viewport
// coordinates; page-scrolled rails read exactly that, pane-scrolled rails
// subtract the pane's own top (see the pane spec).
function mount({ ids = ["a", "b", "c"], tops = {}, offset = "6rem" } = {}) {
  const observers = stubIntersectionObserver();

  const wrap = document.createElement("div");
  wrap.innerHTML = `
    <nav id="toc" class="pc-scrollspy" data-offset="${offset}" aria-label="On this page">
      <div class="pc-scrollspy__indicator" aria-hidden="true"></div>
      <ul>
        ${ids
          .map(
            (id) =>
              `<li><a href="#${id}" class="pc-scrollspy-link" data-scrollspy-target="${id}">${id}</a></li>`,
          )
          .join("")}
      </ul>
    </nav>
    <div class="sections">
      ${ids.map((id) => `<section id="${id}"></section>`).join("")}
    </div>
  `;
  document.body.appendChild(wrap);

  ids.forEach((id, i) => {
    const section = wrap.querySelector(`#${id}`);
    const top = tops[id] ?? i * 1000;
    section.getBoundingClientRect = () => ({ top, height: 1000, bottom: top + 1000 });
  });

  const el = wrap.querySelector("#toc");
  const hook = Object.create(hooks.PetalScrollspy);
  hook.el = el;
  hook.mounted();
  mounted.push({ hook, wrap });

  return { hook, el, wrap, observers, link: (id) => wrap.querySelector(`[href="#${id}"]`) };
}

// jsdom lays nothing out, so a scroll container has to be described rather
// than built. Listener stubs keep destroyed() happy.
const fakeScroller = (metrics) => ({
  addEventListener() {},
  removeEventListener() {},
  style: {},
  // a pane at the top of the viewport unless the spec says otherwise
  getBoundingClientRect: () => ({ top: 0 }),
  ...metrics,
});

const activeIds = (wrap) =>
  Array.from(wrap.querySelectorAll(".pc-scrollspy-link--active")).map(
    (el) => el.dataset.scrollspyTarget,
  );

const currentIds = (wrap) =>
  Array.from(wrap.querySelectorAll('[aria-current="location"]')).map(
    (el) => el.dataset.scrollspyTarget,
  );

describe("scrollspyActive", () => {
  it("picks the section that owns the activation line", () => {
    const sections = [
      { id: "a", top: -400 },
      { id: "b", top: 120 },
      { id: "c", top: 900 },
    ];

    expect(scrollspyActive(sections, { line: 200 })).toBe("b");
  });

  it("topmost wins: the newest section to reach the line takes over", () => {
    // Three short sections all crowded above the line at once.
    const sections = [
      { id: "a", top: -50 },
      { id: "b", top: 30 },
      { id: "c", top: 120 },
    ];

    expect(scrollspyActive(sections, { line: 200 })).toBe("c");
    // Back the line off above `c` and the previous section owns it again.
    expect(scrollspyActive(sections, { line: 100 })).toBe("b");
  });

  it("holds the first section while the page is still above the line", () => {
    const sections = [
      { id: "a", top: 600 },
      { id: "b", top: 1600 },
    ];

    expect(scrollspyActive(sections, { line: 200 })).toBe("a");
  });

  it("snaps to the last section at the bottom of the scroll", () => {
    // `c` is short and never reaches the line - without the snap it could
    // never be highlighted at all.
    const sections = [
      { id: "a", top: -1200 },
      { id: "b", top: -200 },
      { id: "c", top: 700 },
    ];

    expect(scrollspyActive(sections, { line: 200 })).toBe("b");
    expect(scrollspyActive(sections, { line: 200, atBottom: true })).toBe("c");
  });

  it("returns null with nothing to spy on", () => {
    expect(scrollspyActive([], { line: 200 })).toBe(null);
  });
});

describe("PetalScrollspy", () => {
  it("observes every section a link points at", () => {
    const { observers, wrap } = mount();

    expect(observers).toHaveLength(1);
    expect(observers[0].observed).toEqual([
      wrap.querySelector("#a"),
      wrap.querySelector("#b"),
      wrap.querySelector("#c"),
    ]);
    expect(observers[0].options.rootMargin).toBe("-25% 0px -70% 0px");
  });

  it("honours a data-threshold rootMargin override", () => {
    const wrapper = document.createElement("div");
    wrapper.innerHTML = `<nav id="t2" data-threshold="-10% 0px -80% 0px"></nav>`;
    document.body.appendChild(wrapper);

    const observers = stubIntersectionObserver();
    const hook = Object.create(hooks.PetalScrollspy);
    hook.el = wrapper.querySelector("#t2");
    hook.mounted();
    mounted.push({ hook, wrap: wrapper });

    expect(observers[0].options.rootMargin).toBe("-10% 0px -80% 0px");
  });

  it("ignores links whose target is not on the page", () => {
    const { observers, wrap } = mount({ ids: ["a", "b"] });
    wrap.querySelector("#b").remove();

    mounted[mounted.length - 1].hook.updated();
    const latest = observers[observers.length - 1];

    expect(latest.observed.map((el) => el.id)).toEqual(["a"]);
  });

  it("applies data-offset as scroll-margin-top on the targets", () => {
    const { wrap } = mount({ offset: "8rem" });

    expect(wrap.querySelector("#a").style.scrollMarginTop).toBe("8rem");
    expect(wrap.querySelector("#c").style.scrollMarginTop).toBe("8rem");
  });

  it("marks exactly one link active, with aria-current", () => {
    // Only `b` has reached the line (window.innerHeight is 768 in jsdom, so
    // the default -25% line sits at 192).
    const { hook, wrap } = mount({ tops: { a: -500, b: 100, c: 900 } });
    hook.sync();

    expect(activeIds(wrap)).toEqual(["b"]);
    expect(currentIds(wrap)).toEqual(["b"]);
  });

  it("moves the active state, leaving nothing stale behind", () => {
    const { hook, wrap } = mount({ tops: { a: -500, b: 100, c: 900 } });
    hook.sync();
    expect(activeIds(wrap)).toEqual(["b"]);

    wrap.querySelector("#c").getBoundingClientRect = () => ({ top: 20, height: 1000, bottom: 1020 });
    hook.sync();

    expect(activeIds(wrap)).toEqual(["c"]);
    expect(currentIds(wrap)).toEqual(["c"]);
  });

  it("measures against the pane when the sections scroll inside one", () => {
    // The pane sits 500px down the page and is 400px tall. Section b is
    // 100px into the pane (viewport top 600). Measured against the viewport,
    // the -25% line (192 of jsdom's 768) would still call `a` active - the
    // bug this pins: the highlight depended on where the pane sat on the
    // page. Against the pane's own box the line is 100, and b has reached it.
    const { hook, wrap } = mount({ tops: { a: -400, b: 600, c: 1400 } });
    hook.scrollRoot = fakeScroller({
      clientHeight: 400,
      scrollTop: 500,
      scrollHeight: 3000,
      getBoundingClientRect: () => ({ top: 500 }),
    });
    hook.sync();

    expect(activeIds(wrap)).toEqual(["b"]);
  });

  it("re-syncs when the observer fires", () => {
    const { observers, wrap } = mount({ tops: { a: -500, b: 100, c: 900 } });

    observers[0].callback([]);

    expect(activeIds(wrap)).toEqual(["b"]);
  });

  it("snaps to the last entry at the bottom of a real scroll", () => {
    const { hook, wrap } = mount({ tops: { a: -1200, b: -200, c: 700 } });
    hook.scrollRoot = fakeScroller({ scrollTop: 900, clientHeight: 700, scrollHeight: 1600 });

    hook.sync();

    expect(activeIds(wrap)).toEqual(["c"]);
  });

  it("does not snap when there is nothing to scroll", () => {
    // A short page that fits entirely on screen is not at any bottom worth
    // reacting to - the first section stays active.
    const { hook, wrap } = mount({ tops: { a: 0, b: 1000, c: 2000 } });
    hook.scrollRoot = fakeScroller({ scrollTop: 0, clientHeight: 700, scrollHeight: 700 });

    hook.sync();

    expect(activeIds(wrap)).toEqual(["a"]);
  });

  it("activates a matching hash on mount without waiting for the observer", () => {
    window.location.hash = "#c";
    const { wrap } = mount({ tops: { a: 0, b: 1000, c: 2000 } });

    // Geometry alone would say `a`; the explicit deep link wins.
    expect(activeIds(wrap)).toEqual(["c"]);
    expect(currentIds(wrap)).toEqual(["c"]);
  });

  it("follows hashchange", () => {
    const { wrap } = mount({ tops: { a: 0, b: 1000, c: 2000 } });
    expect(activeIds(wrap)).toEqual(["a"]);

    window.location.hash = "#b";
    window.dispatchEvent(new Event("hashchange"));

    expect(activeIds(wrap)).toEqual(["b"]);
  });

  it("ignores a hash that is not one of the targets", () => {
    window.location.hash = "#somewhere-else";
    const { wrap } = mount({ tops: { a: -500, b: 100, c: 900 } });

    expect(activeIds(wrap)).toEqual(["b"]);
  });

  it("never moves focus", () => {
    const { hook, wrap } = mount({ tops: { a: -500, b: 100, c: 900 } });
    const outside = document.createElement("input");
    document.body.appendChild(outside);
    outside.focus();

    hook.sync();

    expect(document.activeElement).toBe(outside);
    expect(activeIds(wrap)).toEqual(["b"]);
    outside.remove();
  });

  it("turns smooth scrolling on, and off again on destroy", () => {
    const { hook } = mount();
    expect(document.documentElement.style.scrollBehavior).toBe("smooth");

    hook.destroyed();
    expect(document.documentElement.style.scrollBehavior).toBe("");
    mounted.pop();
  });

  it("leaves scrolling instant under prefers-reduced-motion", () => {
    vi.stubGlobal(
      "matchMedia",
      vi.fn(() => ({ matches: true, addEventListener() {}, removeEventListener() {} })),
    );

    mount();
    expect(document.documentElement.style.scrollBehavior).toBe("");
  });

  it("two rails on one scroller hand smooth back only when the LAST one leaves", () => {
    // instance-local snapshots restored in mount order used to leave
    // smooth applied forever: A saved "", B saved "smooth"; A restored "",
    // B re-restored "smooth"
    const a = mount({ ids: ["a", "b"] });
    const b = mount({ ids: ["a", "b"] });
    expect(document.documentElement.style.scrollBehavior).toBe("smooth");

    a.hook.destroyed();
    expect(document.documentElement.style.scrollBehavior).toBe("smooth");

    b.hook.destroyed();
    expect(document.documentElement.style.scrollBehavior).toBe("");
    expect(document.documentElement.dataset.pcSmoothCount).toBeUndefined();
    mounted.pop();
    mounted.pop();
  });

  it("updated() applies the offset to targets added by a patch", () => {
    const { hook, wrap } = mount({ ids: ["a", "b"] });

    // unique id: earlier mounts leave a/b/c sections in the document, and
    // getElementById would resolve a stale twin instead of this one
    const section = document.createElement("section");
    section.id = "zz-patched-in";
    wrap.querySelector(".sections").appendChild(section);
    wrap.querySelector("nav ul").insertAdjacentHTML(
      "beforeend",
      `<li><a href="#zz-patched-in" class="pc-scrollspy-link" data-scrollspy-target="zz-patched-in">new</a></li>`,
    );

    hook.updated();
    expect(section.style.scrollMarginTop).toBe("6rem");
  });

  it("cleans up the observer, the listeners and the borrowed styles", () => {
    const { hook, wrap, observers } = mount();
    const removed = [];
    const realRemove = window.removeEventListener.bind(window);
    window.removeEventListener = (type, ...rest) => {
      removed.push(type);
      realRemove(type, ...rest);
    };

    hook.destroyed();
    window.removeEventListener = realRemove;
    mounted.pop();

    expect(observers[0].disconnected).toBe(true);
    expect(removed).toContain("hashchange");
    expect(removed).toContain("resize");
    expect(wrap.querySelector("#a").style.scrollMarginTop).toBe("");
    expect(document.documentElement.style.scrollBehavior).toBe("");

    // A stale hook must not keep driving a page it no longer owns.
    expect(activeIds(wrap)).toEqual(["a"]);
    window.location.hash = "#c";
    window.dispatchEvent(new Event("hashchange"));
    expect(activeIds(wrap)).toEqual(["a"]);
    wrap.remove();
  });

  it("re-scans after a LiveView patch replaces the rail", () => {
    const { hook, wrap, observers } = mount({ ids: ["a", "b"] });

    wrap.querySelector("nav ul").innerHTML = `
      <li><a href="#b" class="pc-scrollspy-link" data-scrollspy-target="b">b</a></li>
    `;
    hook.updated();

    expect(observers).toHaveLength(2);
    expect(observers[0].disconnected).toBe(true);
    expect(observers[1].observed.map((el) => el.id)).toEqual(["b"]);
  });
});
