// PetalAlertDialog / PetalAlertDialogTrigger hooks.
//
// The component's whole point is friction: the dialog opens focused on the
// least destructive action, Escape runs the same cancel path as the Cancel
// button, and clicking the backdrop does nothing at all. Every spec here
// guards one of those.
import { afterEach, describe, expect, it } from "vitest";

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
        <div class="pc-alert-dialog__actions">
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

describe("PetalAlertDialog", () => {
  afterEach(() => {
    mounted.splice(0).forEach(({ hooks, wrap }) => {
      hooks.forEach((h) => h.destroyed());
      wrap.remove();
    });
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

    expect(el.closeCalls).toBe(1);
    expect(el.open).toBe(false);
  });

  it("closes when the confirm button is clicked", () => {
    const { el, confirm } = mount();

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    click(confirm);

    expect(el.closeCalls).toBe(1);
    expect(el.open).toBe(false);
  });

  it("closes when a click lands on a child of an action button", () => {
    const { el, confirm } = mount();
    const span = document.createElement("span");
    confirm.appendChild(span);

    el.dispatchEvent(new CustomEvent("pc:alert-dialog-open"));
    click(span);

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
    el.dispatchEvent(new Event("cancel", { cancelable: true }));

    expect(el.showModalCalls).toBe(0);
    expect(el.closeCalls).toBe(0);
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
