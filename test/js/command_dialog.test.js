// PetalCommandDialog hook: the background scroll lock.
//
// A native modal <dialog> gives the palette its top layer, focus trap and
// Escape for free, but it does NOT stop the page behind it scrolling. The
// hook adds the same `overflow-hidden` body class the modal and slide_over
// use, and every spec here guards one of the paths that has to release it.
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
    // real dialogs fire the close event; the hook's unlock path drains it
    el.dispatchEvent(new Event("close"));
  };
  el.open = false;
  el.showModalCalls = 0;
  el.closeCalls = 0;
  return el;
}

function mount({ shortcut = "k" } = {}) {
  const wrap = document.createElement("div");
  wrap.innerHTML = `
    <dialog id="cmdk" class="pc-command-dialog"
            data-shortcut="${shortcut}" data-reset-on-close="true">
      <div id="cmdk-palette" class="pc-command">
        <input class="pc-command__input" />
        <div role="listbox">
          <div data-pc-command-item data-value="settings">Settings</div>
        </div>
      </div>
    </dialog>
  `;
  document.body.appendChild(wrap);

  const el = stubDialog(wrap.querySelector("#cmdk"));
  const hook = Object.create(hooks.PetalCommandDialog);
  hook.el = el;
  hook.mounted();
  mounted.push({ hook, wrap });

  return {
    hook,
    el,
    wrap,
    item: wrap.querySelector("[data-pc-command-item]"),
  };
}

function click(el) {
  el.dispatchEvent(new MouseEvent("click", { bubbles: true }));
}

const locked = () => document.body.classList.contains("overflow-hidden");

describe("PetalCommandDialog scroll lock", () => {
  afterEach(() => {
    mounted.splice(0).forEach(({ hook, wrap }) => {
      hook.destroyed();
      wrap.remove();
    });
    document.body.classList.remove("overflow-hidden");
  });

  it("locks the background on open and releases it on close", () => {
    const { el } = mount();

    el.dispatchEvent(new CustomEvent("pc:command-open"));
    expect(locked()).toBe(true);

    el.dispatchEvent(new CustomEvent("pc:command-close"));
    expect(locked()).toBe(false);
  });

  it("releases the lock when an item runs and closes the palette", () => {
    const { el, item } = mount();

    el.dispatchEvent(new CustomEvent("pc:command-open"));
    click(item);

    expect(el.open).toBe(false);
    expect(locked()).toBe(false);
  });

  it("releases the lock on a backdrop click", () => {
    const { el } = mount();

    el.dispatchEvent(new CustomEvent("pc:command-open"));
    // a backdrop click is a click whose target is the dialog element itself
    click(el);

    expect(el.open).toBe(false);
    expect(locked()).toBe(false);
  });

  it("releases the lock on a close the hook did not initiate", () => {
    // Escape closes a native dialog on its own, and Chrome's close watcher
    // can fire `close` without any cancel we could intercept. The close event
    // is the funnel both drain through, so the unlock still runs.
    const { el } = mount();

    el.dispatchEvent(new CustomEvent("pc:command-open"));
    expect(locked()).toBe(true);

    el.open = false;
    el.dispatchEvent(new Event("close"));

    expect(locked()).toBe(false);
  });

  it("does not stack a lock a single close cannot release", () => {
    const { el } = mount();

    el.dispatchEvent(new CustomEvent("pc:command-open"));
    el.dispatchEvent(new CustomEvent("pc:command-open"));
    expect(el.showModalCalls).toBe(1);

    el.dispatchEvent(new CustomEvent("pc:command-close"));
    expect(locked()).toBe(false);
  });

  it("locks and unlocks across the ⌘K toggle", () => {
    const { el } = mount();
    const cmdK = () =>
      document.dispatchEvent(
        new KeyboardEvent("keydown", { key: "k", metaKey: true }),
      );

    cmdK();
    expect(el.open).toBe(true);
    expect(locked()).toBe(true);

    cmdK();
    expect(el.open).toBe(false);
    expect(locked()).toBe(false);
  });

  it("a patch removing an OPEN palette never leaves the page locked", () => {
    const { el, hook } = mount();

    el.dispatchEvent(new CustomEvent("pc:command-open"));
    expect(locked()).toBe(true);

    hook.destroyed();
    expect(locked()).toBe(false);
    // afterEach will call destroyed() again; it is idempotent
  });

  it("tearing down a CLOSED palette leaves another overlay's lock alone", () => {
    const { hook } = mount();
    // something else on the page owns the lock
    document.body.classList.add("overflow-hidden");

    hook.destroyed();

    expect(locked()).toBe(true);
  });

  it("stops locking once destroyed", () => {
    const { el, hook } = mount();

    hook.destroyed();
    el.dispatchEvent(new CustomEvent("pc:command-open"));

    expect(el.showModalCalls).toBe(0);
    expect(locked()).toBe(false);
  });
});

// LiveView merges the dialog's attributes against the SERVER's render, which
// never carries `open` - showModal() sets it client-side. Left alone, any
// patch that re-renders the palette's subtree (a reconnect's join morph,
// live assigns feeding the items) yanks an open palette shut with no `close`
// event: the scroll lock never releases, and the page behind stays frozen
// with nothing on screen to explain why.
describe("PetalCommandDialog - surviving a LiveView patch", () => {
  afterEach(() => {
    mounted.splice(0).forEach(({ hook, wrap }) => {
      hook.destroyed();
      wrap.remove();
    });
    document.body.classList.remove("overflow-hidden");
  });

  // What morphdom does to this element: everything the server did not
  // render comes off.
  function patch(hook, el) {
    hook.beforeUpdate();
    el.open = false;
    hook.updated();
  }

  it("an open palette is still open after a patch, scroll lock intact", () => {
    const { el, hook } = mount();
    el.dispatchEvent(new CustomEvent("pc:command-open"));

    patch(hook, el);

    expect(el.open).toBe(true);
    expect(el.showModalCalls).toBe(2);
    expect(locked()).toBe(true);
  });

  it("focus returns to the search input after a patch", () => {
    const { el, hook } = mount();
    el.dispatchEvent(new CustomEvent("pc:command-open"));
    const input = el.querySelector(".pc-command__input");
    expect(document.activeElement).toBe(input);

    patch(hook, el);

    expect(document.activeElement).toBe(input);
  });

  it("focus elsewhere inside the palette is put back where the user left it", () => {
    const { el, hook } = mount();
    el.dispatchEvent(new CustomEvent("pc:command-open"));
    const button = document.createElement("button");
    el.querySelector(".pc-command").appendChild(button);
    button.focus();

    patch(hook, el);

    expect(document.activeElement).toBe(button);
  });

  it("a focus target the patch removed falls back to the search input", () => {
    const { el, hook } = mount();
    el.dispatchEvent(new CustomEvent("pc:command-open"));
    const button = document.createElement("button");
    el.querySelector(".pc-command").appendChild(button);
    button.focus();

    hook.beforeUpdate();
    button.remove();
    el.open = false;
    hook.updated();

    expect(el.open).toBe(true);
    expect(document.activeElement).toBe(el.querySelector(".pc-command__input"));
  });

  it("the typed query survives the patch - reset waits for a real close", () => {
    const { el, hook } = mount();
    el.dispatchEvent(new CustomEvent("pc:command-open"));
    const input = el.querySelector(".pc-command__input");
    input.value = "set";

    patch(hook, el);
    expect(input.value).toBe("set");

    // a REAL close still resets - the patch path did not eat the behaviour
    el.dispatchEvent(new CustomEvent("pc:command-close"));
    expect(input.value).toBe("");
  });

  it("a patch never opens a palette that was closed", () => {
    const { el, hook } = mount();

    patch(hook, el);

    expect(el.open).toBe(false);
    expect(el.showModalCalls).toBe(0);
    expect(locked()).toBe(false);
  });

  it("a patch that leaves the palette open on its own re-does nothing", () => {
    const { el, hook } = mount();
    el.dispatchEvent(new CustomEvent("pc:command-open"));

    hook.beforeUpdate();
    hook.updated();

    expect(el.showModalCalls).toBe(1);
  });
});
