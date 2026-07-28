// Toast group ownership.
//
// Toast delivery is global: LiveView fans push_event out to every mounted
// hook and a window CustomEvent reaches all of them. A second group on the
// page therefore used to render an identical toast behind the first (a burst
// of 6 dismissing as 12). The hook elects one owner; these specs pin that
// down, because the failure mode is silent and mount order is NOT DOM order.
import { afterEach, beforeEach, describe, expect, it } from "vitest";

import { PetalToast } from "../../assets/js/petal_components.js";

// Ownership is module-level state, so a spec that leaves a group mounted
// would own the page for every spec after it. Tear them down the way
// LiveView does.
const mounted = [];

// Minimal stand-in for the LiveView hook lifecycle: enough of `this` for
// mounted()/destroyed() to run, capturing the handleEvent callbacks so a
// spec can fan an event out to every group the way LiveView does.
function mountGroup(id) {
  const el = document.createElement("div");
  el.id = id;
  el.className = "pc-toast-group";
  const stack = document.createElement("div");
  stack.id = `${id}-stack`;
  stack.className = "pc-toast-group__stack";
  el.appendChild(stack);
  document.body.appendChild(el);

  const hook = Object.create(PetalToast);
  hook.el = el;
  hook.handlers = {};
  hook.pushed = [];
  hook.handleEvent = (name, cb) => {
    hook.handlers[name] = cb;
  };
  hook.pushEvent = (name, payload) => hook.pushed.push([name, payload]);
  hook.mounted();

  hook.toastEls = () => stack.querySelectorAll(".pc-toast");
  mounted.push(hook);
  return hook;
}

// LiveView delivers a push_event to every mounted hook, not just one.
const fanOutServerToast = (groups, payload) =>
  groups.forEach((g) => g.handlers["petal:toast"](payload));

describe("PetalToast group ownership", () => {
  beforeEach(() => {
    document.body.innerHTML = "";
  });

  afterEach(() => {
    mounted.splice(0).forEach((hook) => hook.destroyed());
  });

  it("renders one toast per event when a single group is mounted", () => {
    const only = mountGroup("app-toasts");

    fanOutServerToast([only], { kind: "info", title: "Heads up" });

    expect(only.toastEls()).toHaveLength(1);
  });

  it("renders the toast once when a second group is on the page", () => {
    const first = mountGroup("app-toasts");
    const second = mountGroup("demo-toasts");

    fanOutServerToast([first, second], { kind: "info", title: "Heads up" });

    expect(first.toastEls()).toHaveLength(1);
    expect(second.toastEls()).toHaveLength(0);
  });

  it("ignores window CustomEvents in the non-owning group", () => {
    const first = mountGroup("app-toasts");
    const second = mountGroup("demo-toasts");

    window.dispatchEvent(
      new window.CustomEvent("petal:toast", { detail: { kind: "success", title: "Saved" } })
    );

    expect(first.toastEls()).toHaveLength(1);
    expect(second.toastEls()).toHaveLength(0);
  });

  it("promotes the next group when the owner is destroyed", () => {
    const first = mountGroup("app-toasts");
    const second = mountGroup("demo-toasts");

    first.destroyed();
    fanOutServerToast([second], { kind: "info", title: "After teardown" });

    expect(second.toastEls()).toHaveLength(1);
  });

  it("keeps dismissal scoped to the owning group", () => {
    const first = mountGroup("app-toasts");
    const second = mountGroup("demo-toasts");
    fanOutServerToast([first, second], { id: "export", kind: "loading", title: "Exporting" });

    [first, second].forEach((g) => g.handlers["petal:toast-dismiss"]({ id: "export" }));

    expect(first.toasts[0].closing).toBe(true);
    expect(second.toasts).toHaveLength(0);
  });
});
