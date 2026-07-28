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

  it("ignores a second pointer while a gesture is active", () => {
    const g = mountGroup("app-toasts");
    g.handlers["petal:toast"]({ id: "a", kind: "info", title: "First" });
    g.handlers["petal:toast"]({ id: "b", kind: "info", title: "Second" });
    const [toastB, toastA] = g.toastEls(); // newest first in the DOM query

    // finger A holds toast A at x=10
    toastA.dispatchEvent(pointerEvent("pointerdown", "touch", { clientX: 10, pointerId: 1 }));
    // finger B lands on toast B far away - must not steal the gesture
    toastB.dispatchEvent(pointerEvent("pointerdown", "touch", { clientX: 500, pointerId: 2 }));
    // finger B lifts: with shared state this computed dx against B's start
    // and could fake-swipe a toast; with identity it is a no-op
    toastB.dispatchEvent(pointerEvent("pointerup", "touch", { clientX: 500, pointerId: 2 }));

    expect(g.stackEl.classList.contains("pc-toast-group__stack--paused")).toBe(true); // A still holds
    expect(g.toastEls()).toHaveLength(2); // nothing fake-swiped

    // finger A releases: gesture ends, timers resume
    toastA.dispatchEvent(pointerEvent("pointerup", "touch", { clientX: 12, pointerId: 1 }));
    expect(g.stackEl.classList.contains("pc-toast-group__stack--paused")).toBe(false);
    vi.advanceTimersByTime(DURATION + REMOVE_FALLBACK + 100);
    expect(g.toastEls()).toHaveLength(0);
  });

  it("a leave-grace firing mid-drag does not resume timers under the pointer", () => {
    const g = mountGroup("app-toasts");
    g.handlers["petal:toast"]({ kind: "info", title: "Dragged" });
    const toastEl = g.stackEl.querySelector(".pc-toast");

    // mouse hovers in, starts a drag, then strays outside the stack
    g.stackEl.dispatchEvent(pointerEvent("pointerenter", "mouse"));
    toastEl.dispatchEvent(pointerEvent("pointerdown", "mouse", { clientX: 10, pointerId: 1 }));
    g.stackEl.dispatchEvent(pointerEvent("pointerleave", "mouse"));
    vi.advanceTimersByTime(DURATION * 4); // grace elapses mid-drag; timers must stay parked

    expect(g.stackEl.classList.contains("pc-toast-group__stack--paused")).toBe(true);
    expect(g.toastEls()).toHaveLength(1); // not expired under the pointer

    // release outside (small dx - not a dismiss), then the post-release leave
    toastEl.dispatchEvent(pointerEvent("pointerup", "mouse", { clientX: 20, pointerId: 1 }));
    g.stackEl.dispatchEvent(pointerEvent("pointerleave", "mouse"));
    vi.advanceTimersByTime(150 + DURATION + REMOVE_FALLBACK + 100);
    expect(g.toastEls()).toHaveLength(0); // resumed and expired normally
  });

  it("releasing a drag outside the stack resumes timers (no-capture fallback)", () => {
    const g = mountGroup("app-toasts");
    g.handlers["petal:toast"]({ kind: "info", title: "Dragged away" });
    const toastEl = g.stackEl.querySelector(".pc-toast");

    // hover in (mouse), start the drag, stray outside - leave grace fires
    // mid-drag and is correctly swallowed by the dragging guard
    g.stackEl.dispatchEvent(pointerEvent("pointerenter", "mouse"));
    toastEl.dispatchEvent(pointerEvent("pointerdown", "mouse", { clientX: 10, pointerId: 1 }));
    g.stackEl.dispatchEvent(pointerEvent("pointerleave", "mouse"));
    vi.advanceTimersByTime(300);

    // release OUTSIDE the stack: without capture no stack listener would
    // ever see this - it must reach the gesture via the window, and since
    // no further pointerleave is coming, it must collapse + resume itself
    window.dispatchEvent(pointerEvent("pointerup", "mouse", { clientX: 400, clientY: 900, pointerId: 1 }));

    expect(g.stackEl.classList.contains("pc-toast-group__stack--paused")).toBe(false);
    vi.advanceTimersByTime(DURATION + REMOVE_FALLBACK + 100);
    expect(g.toastEls()).toHaveLength(0); // expired normally - not parked forever
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
