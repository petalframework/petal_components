// Toast group ownership.
//
// Toast delivery is global: LiveView fans push_event out to every mounted
// hook and a window CustomEvent reaches all of them. A second group on the
// page therefore used to render an identical toast behind the first (a burst
// of 6 dismissing as 12). The hook elects one owner; these specs pin that
// down, because the failure mode is silent and mount order is NOT DOM order.
import { afterEach, beforeEach, describe, expect, it } from "vitest";

import { fanOutServerToast, mountGroup, teardownGroups } from "./helpers.js";

describe("PetalToast group ownership", () => {
  beforeEach(() => {
    document.body.innerHTML = "";
  });

  afterEach(() => {
    teardownGroups();
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
