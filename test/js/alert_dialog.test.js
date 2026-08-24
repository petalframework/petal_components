// PetalAlertDialog / PetalAlertDialogTrigger hooks.
//
// The component's whole point is friction: the dialog opens focused on the
// least destructive action, Escape runs the same cancel path as the Cancel
// button, and clicking the backdrop does nothing at all. Every spec here
// guards one of those - plus the exit funnel, which is the reason a click on
// Cancel no longer closes the dialog in the same tick.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import hooks from "../../assets/js/petal_components.js";

const mounted = [];

// jsdom has no <dialog> behaviour: showModal()/close() are not implemented,
// and the `open` property is not wired to them. Stub the parts the hook
// touches so the specs test the hook's decisions, not jsdom's gaps.
function stubDialog(el) {
  el.showModal = () => {
    el.open = true;
    el.showModalCalls = (el.showModalCalls || 0) + 1;
  };
  el.close = () => {
    el.open = false;
    el.closeCalls = (el.closeCalls || 0) + 1;
    // real dialogs fire the close event; the hook's unlock path drains it
    el.dispatchEvent(new Event("close"));
  };
  el.open = false;
  el.showModalCalls = 0;
  el.closeCalls = 0;
  return el;
}

function mount({ withTrigger = false } = {}) {
  const wrap = document.createElement("div");
  wrap.innerHTML = `
    ${
      withTrigger
        ? `<div id="d-trigger" data-dialog="d"><button type="button" id="opener">Delete</button></div>`
        : ""
    }
    <dialog id="d" class="pc-alert-dialog" role="alertdialog">
      <div class="pc-alert-dialog__panel">
        <div class="pc-alert-dialog__footer">
          <button type="button" class="pc-alert-dialog__cancel"
                  data-pc-alert-dialog-cancel data-pc-alert-dialog-close>Cancel</button>
          <button type="button" class="pc-alert-dialog__confirm"
                  data-pc-alert-dialog-confirm data-pc-alert-dialog-close>Continue</button>
        </div>
      </div>
    </dialog>
  `;
  document.body.appendChild(wrap);

  const el = stubDialog(wrap.querySelector("#d"));
  const hook = Object.create(hooks.PetalAlertDialog);
  hook.el = el;
  hook.mounted();

  const entry = { hooks: [hook], wrap };

  let trigger = null;
  if (withTrigger) {
    trigger = wrap.querySelector("#d-trigger");
    const triggerHook = Object.create(hooks.PetalAlertDialogTrigger);
    triggerHook.el = trigger;
    triggerHook.mounted();
    entry.hooks.push(triggerHook);
  }

  mounted.push(entry);

  return {
    hook,
    el,
    wrap,
    trigger,
    cancel: wrap.querySelector(".pc-alert-dialog__cancel"),
    confirm: wrap.querySelector(".pc-alert-dialog__confirm"),
  };
}

function click(el) {
  el.dispatchEvent(new MouseEvent("click", { bubbles: true }));
}

// The exit animation finishing. Real browsers fire this off the CSS
// keyframes; here the spec decides when the 150ms is up.
function endExit(el) {
  el.dispatchEvent(new Event("animationend"));
}

// The ::backdrop's animation reports on the SAME element, distinguished only
// by pseudoElement. jsdom has no AnimationEvent, so stamp the field on.
function endBackdropExit(el) {
  const e = new Event("animationend");
  Object.defineProperty(e, "pseudoElement", { value: "::backdrop" });
  el.dispatchEvent(e);
}

function closing(el) {
  return el.classList.contains("pc-alert-dialog--closing");
}

function locked() {
  return document.body.classList.contains("overflow-hidden");
}

// jsdom's matchMedia always answers false, which is the motion-allowed
// default every spec but the reduced-motion ones want.
function withReducedMotion(fn) {
  const real = window.matchMedia;
  window.matchMedia = (q) => ({ matches: q.includes("reduce"), media: q });
  try {
    fn();
  } finally {
    window.matchMedia = real;
  }
}

describe("PetalAlertDialog", () => {
  afterEach(() => {
    mounted.splice(0).forEach(({ hooks, wrap }) => {
      hooks.forEach((h) => h.destroyed());
      wrap.remove();
    });
  });

  it("locks background scroll on open and unlocks on every close path", () => {
    const { el, cancel } = mount();

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    expect(locked()).toBe(true);

    // close INTENT is not the close: the page stays locked while the dialog
    // is still on screen playing its exit
    click(cancel);
    expect(locked()).toBe(true);

    endExit(el);
    expect(locked()).toBe(false);
  });

  it("a close that bypassed the hook still runs the cancel path", () => {
    // Chrome's close watcher lets a second rapid Escape skip the cancelable
    // `cancel` event entirely - the dialog closes natively without our code
    const { el, cancel } = mount();
    let cancelClicks = 0;
    cancel.addEventListener("click", () => cancelClicks++);

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    // native bypass: the browser closed it, not us
    el.open = false;
    el.dispatchEvent(new Event("close"));

    expect(cancelClicks).toBe(1);
    expect(locked()).toBe(false);
  });

  it("a patch removing an OPEN dialog never leaves the page locked", () => {
    const { el, hook } = mount();
    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    expect(locked()).toBe(true);

    hook.destroyed();
    expect(locked()).toBe(false);
    // afterEach will call destroyed() again; it is idempotent
  });

  it("opens as a modal on the open event", () => {
    const { el } = mount();

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));

    expect(el.showModalCalls).toBe(1);
    expect(el.open).toBe(true);
  });

  it("focuses the cancel button on open, never confirm", () => {
    const { el, cancel } = mount();

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));

    expect(document.activeElement).toBe(cancel);
  });

  it("tells the engine the modality: tap-open asks for focusVisible false, keyboard true", () => {
    // WebKit marks any focus inside a freshly shown modal keyboard-visible -
    // even script focus after a tap, even deferred (measured in real WebKit;
    // this is why the blur-refocus alone satisfied Chromium and still ringed
    // on the maintainer's iPhone). FocusOptions.focusVisible is the shared
    // escape hatch, driven by tracked input modality.
    const { hook, el, cancel } = mount();
    const focusCalls = [];
    cancel.focus = (opts) => focusCalls.push(opts);

    document.dispatchEvent(new Event("pointerdown", { bubbles: true }));
    hook.focusCancel();
    expect(focusCalls).toEqual([{ focusVisible: false }]);

    document.dispatchEvent(
      new KeyboardEvent("keydown", { key: "Tab", bubbles: true }),
    );
    hook.focusCancel();
    expect(focusCalls).toEqual([
      { focusVisible: false },
      { focusVisible: true },
    ]);

    // a modifier chord is a shortcut, not keyboard navigation
    document.dispatchEvent(new Event("pointerdown", { bubbles: true }));
    document.dispatchEvent(
      new KeyboardEvent("keydown", { key: "k", metaKey: true, bubbles: true }),
    );
    hook.focusCancel();
    expect(focusCalls[2]).toEqual({ focusVisible: false });
  });

  it("re-issues a FRESH focus even when the native pass already sits on cancel", () => {
    // showModal()'s own focusing pass marks whatever it lands on as
    // keyboard-visible unconditionally - a permanent ring on every
    // tap-open. A focus() no-op on the already-focused button would keep
    // that state, so focusCancel must blur and refocus: the fresh script
    // focus follows the user's input modality instead (the Radix behavior
    // the maintainer compared against on an iPhone).
    const { hook, cancel } = mount();
    let focusEvents = 0;
    cancel.addEventListener("focus", () => focusEvents++);

    cancel.focus(); // stand in for the native focusing pass
    expect(focusEvents).toBe(1);

    hook.focusCancel();
    expect(focusEvents).toBe(2);
    expect(document.activeElement).toBe(cancel);
  });

  it("ignores a second open while already open", () => {
    const { el } = mount();

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));

    expect(el.showModalCalls).toBe(1);
  });

  it("closes when the cancel button is clicked", () => {
    const { el, cancel } = mount();

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    click(cancel);
    endExit(el);

    expect(el.closeCalls).toBe(1);
    expect(el.open).toBe(false);
  });

  it("closes when the confirm button is clicked", () => {
    const { el, confirm } = mount();

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    click(confirm);
    endExit(el);

    expect(el.closeCalls).toBe(1);
    expect(el.open).toBe(false);
  });

  it("closes when a click lands on a child of an action button", () => {
    const { el, confirm } = mount();
    const span = document.createElement("span");
    confirm.appendChild(span);

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    click(span);
    endExit(el);

    expect(el.closeCalls).toBe(1);
  });

  it("does NOT close on a backdrop click - the friction is the point", () => {
    const { el } = mount();

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    // a backdrop click is a click whose target is the dialog element itself
    click(el);

    expect(el.closeCalls).toBe(0);
    expect(el.open).toBe(true);
  });

  it("does NOT close on a click inside the panel but outside the actions", () => {
    const { el, wrap } = mount();

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    click(wrap.querySelector(".pc-alert-dialog__panel"));

    expect(el.closeCalls).toBe(0);
    expect(el.open).toBe(true);
  });

  it("routes Escape through the cancel button so it runs the same cancel path", () => {
    const { el, cancel } = mount();
    const clicked = [];
    cancel.addEventListener("click", () => clicked.push("cancel"));

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    const cancelEvent = new Event("cancel", { cancelable: true });
    el.dispatchEvent(cancelEvent);
    endExit(el);

    // native close is swallowed; the cancel button drives the close instead
    expect(cancelEvent.defaultPrevented).toBe(true);
    expect(clicked).toEqual(["cancel"]);
    expect(el.open).toBe(false);
    expect(el.closeCalls).toBe(1);
  });

  it("still closes on Escape when there is no cancel button to route through", () => {
    const { el, cancel } = mount();
    cancel.remove();

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    el.dispatchEvent(new Event("cancel", { cancelable: true }));
    endExit(el);

    expect(el.open).toBe(false);
    expect(el.closeCalls).toBe(1);
  });

  it("close is a no-op when the dialog is already closed", () => {
    const { el, confirm } = mount();

    click(confirm);

    expect(el.closeCalls).toBe(0);
  });

  it("removes every listener on destroy so a reused node cannot close a torn-down dialog", () => {
    const { hook, el, confirm } = mount();

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    hook.destroyed();

    el.showModalCalls = 0;
    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    click(confirm);
    endExit(el);
    el.dispatchEvent(new Event("cancel", { cancelable: true }));

    expect(el.showModalCalls).toBe(0);
    expect(el.closeCalls).toBe(0);
  });
});

// The exit funnel. dialog.close() is instant - the element leaves the top
// layer in the same frame - so an out animation only exists if the hook holds
// the close back. These specs pin that hold: one door in (requestClose), one
// door out (finishClose), and nothing that can leave a dialog stuck half-way.
describe("PetalAlertDialog - the exit funnel", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
    mounted.splice(0).forEach(({ hooks, wrap }) => {
      hooks.forEach((h) => h.destroyed());
      wrap.remove();
    });
  });

  function open() {
    const ctx = mount();
    ctx.el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    return ctx;
  }

  it("a close intent marks the dialog closing and holds the real close back", () => {
    const { el, cancel } = open();

    click(cancel);

    expect(closing(el)).toBe(true);
    expect(el.open).toBe(true);
    expect(el.closeCalls).toBe(0);
  });

  it("the animation ending is what closes the dialog, and it clears the class", () => {
    const { el, cancel } = open();

    click(cancel);
    endExit(el);

    expect(el.closeCalls).toBe(1);
    expect(el.open).toBe(false);
    expect(closing(el)).toBe(false);
  });

  it("the watchdog closes the dialog when animationend never arrives", () => {
    // a background tab, a consumer who overrode the keyframes away, a frame
    // dropped at the boundary - the dialog must not stay stuck open
    const { el, cancel } = open();

    click(cancel);
    expect(el.closeCalls).toBe(0);

    vi.advanceTimersByTime(500);

    expect(el.closeCalls).toBe(1);
    expect(closing(el)).toBe(false);
  });

  it("closes exactly once when the animation and the watchdog both land", () => {
    const { el, cancel } = open();

    click(cancel);
    endExit(el);
    vi.advanceTimersByTime(500);

    expect(el.closeCalls).toBe(1);
  });

  it("the ::backdrop finishing first does not cut the box's exit short", () => {
    // the backdrop animates separately and reports on the SAME element; only
    // the box's own animationend may end the exit
    const { el, cancel } = open();

    click(cancel);
    endBackdropExit(el);

    expect(el.closeCalls).toBe(0);
    expect(el.open).toBe(true);

    endExit(el);
    expect(el.closeCalls).toBe(1);
  });

  it("the ENTRANCE animation ending never closes the dialog", () => {
    // same element, same event name - only the closing flag tells them apart
    const { el } = open();

    endExit(el);

    expect(el.closeCalls).toBe(0);
    expect(el.open).toBe(true);
  });

  it("a second close intent during the exit is ignored", () => {
    const { el, cancel, confirm } = open();

    click(cancel);
    click(confirm);
    endExit(el);

    expect(el.closeCalls).toBe(1);
  });

  it("Escape funnels through the same exit as the buttons", () => {
    const { el } = open();

    el.dispatchEvent(new Event("cancel", { cancelable: true }));

    expect(closing(el)).toBe(true);
    expect(el.open).toBe(true);

    endExit(el);
    expect(el.closeCalls).toBe(1);
  });

  it("a programmatic pc:alert-dialog-close funnels through the exit too", () => {
    const { el } = open();

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-close"));

    expect(closing(el)).toBe(true);
    expect(el.open).toBe(true);

    endExit(el);
    expect(el.closeCalls).toBe(1);
  });

  it("pc:alert-dialog-close on a closed dialog is a no-op", () => {
    const { el } = mount();

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-close"));

    expect(closing(el)).toBe(false);
    expect(el.closeCalls).toBe(0);
  });

  it("reopening mid-exit recovers: the exit is abandoned, the dialog stays", () => {
    const { el, cancel } = open();

    click(cancel);
    expect(closing(el)).toBe(true);

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));

    expect(closing(el)).toBe(false);
    expect(el.open).toBe(true);
    expect(el.closeCalls).toBe(0);
    // it kept the dialog it already had rather than closing and reopening
    expect(el.showModalCalls).toBe(1);
    expect(document.activeElement).toBe(cancel);

    // and the abandoned exit's watchdog cannot close it later
    vi.advanceTimersByTime(500);
    expect(el.closeCalls).toBe(0);
    expect(el.open).toBe(true);
  });

  it("the scroll lock releases exactly once, at the real close", () => {
    const { el, cancel } = open();
    expect(locked()).toBe(true);

    click(cancel);
    expect(locked()).toBe(true);

    endExit(el);
    expect(locked()).toBe(false);

    // a late watchdog must not re-run the unlock against a page that has
    // since opened something else
    document.body.classList.add("overflow-hidden");
    vi.advanceTimersByTime(500);
    expect(locked()).toBe(true);
    document.body.classList.remove("overflow-hidden");
  });

  it("destroy during an exit clears the watchdog and the closing class", () => {
    const { el, hook, cancel } = open();

    click(cancel);
    hook.destroyed();

    expect(closing(el)).toBe(false);
    expect(locked()).toBe(false);

    vi.advanceTimersByTime(500);
    expect(el.closeCalls).toBe(0);
  });

  it("reduced motion skips the animation and closes in the same tick", () => {
    withReducedMotion(() => {
      const { el, cancel } = open();

      click(cancel);

      // nothing to wait on: no animation would ever fire animationend
      expect(closing(el)).toBe(false);
      expect(el.closeCalls).toBe(1);
      expect(el.open).toBe(false);
      expect(locked()).toBe(false);
    });
  });

  it("reduced motion still routes Escape through the cancel path", () => {
    withReducedMotion(() => {
      const { el, cancel } = open();
      const clicked = [];
      cancel.addEventListener("click", () => clicked.push("cancel"));

      el.dispatchEvent(new Event("cancel", { cancelable: true }));

      expect(clicked).toEqual(["cancel"]);
      expect(el.closeCalls).toBe(1);
    });
  });
});

// LiveView merges the dialog's attributes against the SERVER's render, which
// carries neither `open` nor the closing class. Left alone, that means any
// patch - and the action buttons push, so the patch is the common case -
// yanks an open dialog shut with no `close` event: no exit, and a page left
// scroll-locked forever.
describe("PetalAlertDialog - surviving a LiveView patch", () => {
  afterEach(() => {
    mounted.splice(0).forEach(({ hooks, wrap }) => {
      hooks.forEach((h) => h.destroyed());
      wrap.remove();
    });
  });

  // What morphdom does to this element: everything the server did not render
  // comes off.
  function patch(hook, el) {
    hook.beforeUpdate();
    el.open = false;
    el.classList.remove("pc-alert-dialog--closing");
    hook.updated();
  }

  it("an open dialog is still open after a patch", () => {
    const { el, hook, cancel } = mount();
    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));

    patch(hook, el);

    expect(el.open).toBe(true);
    expect(el.showModalCalls).toBe(2);
    expect(document.activeElement).toBe(cancel);
  });

  it("a patch mid-exit keeps the closing class so the exit still finishes", () => {
    const { el, hook, cancel } = mount();
    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    click(cancel);

    patch(hook, el);

    expect(closing(el)).toBe(true);
    expect(el.open).toBe(true);
    expect(el.closeCalls).toBe(0);

    endExit(el);
    expect(el.closeCalls).toBe(1);
    expect(locked()).toBe(false);
  });

  it("a patch never opens a dialog that was closed", () => {
    const { el, hook } = mount();

    patch(hook, el);

    expect(el.open).toBe(false);
    expect(el.showModalCalls).toBe(0);
  });

  it("focus inside the dialog is restored to where the user left it", () => {
    const { el, hook, confirm } = mount();
    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    confirm.focus();

    patch(hook, el);

    expect(document.activeElement).toBe(confirm);
  });

  it("a patch that leaves the dialog open on its own re-does nothing", () => {
    const { el, hook } = mount();
    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));

    hook.beforeUpdate();
    hook.updated();

    expect(el.showModalCalls).toBe(1);
  });
});

describe("PetalAlertDialogTrigger", () => {
  afterEach(() => {
    mounted.splice(0).forEach(({ hooks, wrap }) => {
      hooks.forEach((h) => h.destroyed());
      wrap.remove();
    });
  });

  it("opens the dialog named in data-dialog", () => {
    const { el, wrap } = mount({ withTrigger: true });

    click(wrap.querySelector("#opener"));

    expect(el.showModalCalls).toBe(1);
    expect(el.open).toBe(true);
  });

  it("does nothing when data-dialog points at no element", () => {
    const { el, trigger, wrap } = mount({ withTrigger: true });
    trigger.dataset.dialog = "not-here";

    expect(() => click(wrap.querySelector("#opener"))).not.toThrow();
    expect(el.showModalCalls).toBe(0);
  });

  it("stops opening the dialog once destroyed", () => {
    const { el, wrap, hooks: _ } = mount({ withTrigger: true });
    mounted[mounted.length - 1].hooks[1].destroyed();

    click(wrap.querySelector("#opener"));

    expect(el.showModalCalls).toBe(0);
  });
});
