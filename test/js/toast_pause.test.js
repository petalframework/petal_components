// Pause/resume grammar across pointer types.
//
// The bug this pins (reported on playground.petal.build, mobile only):
// touch taps synthesize a compatibility mouseenter but never the matching
// mouseleave, so the stack latched into its hover-paused state the first
// time a finger tapped inside it - dismiss a toast via the X and every
// later toast mounted unarmed, progress frozen at 100%, never
// auto-dismissing until a page refresh. Hover-to-pause is mouse-only now
// (pointerenter carries pointerType); touch pauses via press-and-hold.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { mountGroup, pointerEvent, teardownGroups } from "./helpers.js";

const DURATION = 5000; // hook default
const REMOVE_FALLBACK = 400; // dismiss() safety timeout (no transitions in jsdom)

describe("PetalToast pause grammar", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    document.body.innerHTML = "";
  });

  afterEach(() => {
    teardownGroups();
    vi.useRealTimers();
  });

  it("does not latch the pause state when a tap dismisses via the X (the mobile bug)", () => {
    const g = mountGroup("app-toasts");
    g.handlers["petal:toast"]({ kind: "info", title: "First" });

    // What a mobile tap on the X synthesizes: compatibility mouseenter on
    // the stack (never followed by mouseleave), then the click.
    g.stackEl.dispatchEvent(new MouseEvent("mouseenter"));
    g.stackEl.querySelector("[data-toast-close]").click();
    vi.advanceTimersByTime(REMOVE_FALLBACK + 100);
    expect(g.toastEls()).toHaveLength(0);

    g.handlers["petal:toast"]({ kind: "success", title: "Second" });
    expect(g.stackEl.classList.contains("pc-toast-group__stack--paused")).toBe(false);

    vi.advanceTimersByTime(DURATION + REMOVE_FALLBACK + 100);
    expect(g.toastEls()).toHaveLength(0); // auto-dismissed - timer was armed
  });

  it("ignores pointerenter from touch", () => {
    const g = mountGroup("app-toasts");
    g.handlers["petal:toast"]({ kind: "info", title: "Tapped" });

    g.stackEl.dispatchEvent(pointerEvent("pointerenter", "touch"));

    expect(g.stackEl.classList.contains("pc-toast-group__stack--paused")).toBe(false);
    vi.advanceTimersByTime(DURATION + REMOVE_FALLBACK + 100);
    expect(g.toastEls()).toHaveLength(0);
  });

  it("pauses on mouse hover and resumes after leave", () => {
    const g = mountGroup("app-toasts");
    g.handlers["petal:toast"]({ kind: "info", title: "Reading" });

    g.stackEl.dispatchEvent(pointerEvent("pointerenter", "mouse"));
    expect(g.stackEl.classList.contains("pc-toast-group__stack--paused")).toBe(true);

    vi.advanceTimersByTime(DURATION * 4);
    expect(g.toastEls()).toHaveLength(1); // held open while hovered

    g.stackEl.dispatchEvent(pointerEvent("pointerleave", "mouse"));
    vi.advanceTimersByTime(150 + DURATION + REMOVE_FALLBACK + 100); // grace + remaining
    expect(g.toastEls()).toHaveLength(0);
  });

  it("press-and-hold pauses, release resumes", () => {
    const g = mountGroup("app-toasts");
    g.handlers["petal:toast"]({ kind: "info", title: "Held" });
    const toastEl = g.stackEl.querySelector(".pc-toast");

    toastEl.dispatchEvent(pointerEvent("pointerdown", "touch", { clientX: 10 }));
    expect(g.stackEl.classList.contains("pc-toast-group__stack--paused")).toBe(true);

    vi.advanceTimersByTime(DURATION * 4);
    expect(g.toastEls()).toHaveLength(1); // held under the finger

    // small dx: a hold, not a swipe-dismiss
    toastEl.dispatchEvent(pointerEvent("pointerup", "touch", { clientX: 12 }));
    expect(g.stackEl.classList.contains("pc-toast-group__stack--paused")).toBe(false);

    vi.advanceTimersByTime(DURATION + REMOVE_FALLBACK + 100);
    expect(g.toastEls()).toHaveLength(0);
  });
});
