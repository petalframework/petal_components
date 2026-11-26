// Where focus goes when an alert dialog closes and the element that opened
// it is gone: the Delete button of a table row that the confirm deleted
// (a LiveView stream delete removes the whole <tr>). The native close only
// restores focus to an opener that is still in the page, so without help
// focus falls to <body> and a keyboard user loses their place.
//
// The hook acts for the keyboard only, so most specs start with a keydown
// on document, which is what its modality tracker listens for. Half of
// them guard the other direction: a mouse user gets exactly what they got
// before, focus the user or the browser put somewhere is never taken, a
// live navigation's teardown moves nothing, and nothing climbs out of the
// list that lost a row.
import { afterEach, describe, expect, it, vi } from "vitest";

import hooks from "../../assets/js/petal_components.js";

const live = [];

// jsdom has no <dialog> behaviour. This stub models the one native step
// these specs are about: close() tries to focus whatever had focus before
// showModal(), and does nothing if that element has left the page (Chrome
// leaves activeElement on the hidden button inside the dialog until its next
// rendering step, then moves it to <body>; measured over CDP).
function stubDialog(el) {
  let previous = null;
  el.open = false;
  el.showModal = () => {
    previous = document.activeElement;
    el.open = true;
  };
  el.close = () => {
    el.open = false;
    if (previous?.isConnected) previous.focus();
    previous = null;
    el.dispatchEvent(new Event("close"));
  };
  return el;
}

const dialogHtml = (id) => `
  <dialog id="${id}" class="pc-alert-dialog" role="alertdialog">
    <div class="pc-alert-dialog__footer">
      <button type="button" class="pc-alert-dialog__cancel"
              data-pc-alert-dialog-cancel data-pc-alert-dialog-close>Cancel</button>
      <button type="button" class="pc-alert-dialog__confirm"
              data-pc-alert-dialog-confirm data-pc-alert-dialog-close>Delete</button>
    </div>
  </dialog>`;

function mountHook(name, el) {
  const hook = Object.create(hooks[name]);
  hook.el = el;
  hook.mounted();
  live.push(hook);
  return hook;
}

function render(html) {
  const wrap = document.createElement("div");
  wrap.id = "page";
  wrap.innerHTML = html;
  document.body.appendChild(wrap);
  return wrap;
}

const rowsHtml = (n) =>
  Array.from(
    { length: n },
    (_, i) =>
      `<tr id="row-${i + 1}"><td><button type="button" id="delete-${i + 1}">Delete</button></td></tr>`,
  ).join("");

// Dialog OUTSIDE the table, opened by row buttons with open_alert_dialog/2.
function tableWithOutsideDialog(rows = 2) {
  render(`
    <button type="button" id="add">New invoice</button>
    <table><tbody id="rows">${rowsHtml(rows)}</tbody></table>
    ${dialogHtml("d")}`);
  const el = stubDialog($("#d"));
  const hook = mountHook("PetalAlertDialog", el);
  return { el, hook };
}

// The Petal Pro and petal.gen.live shape: trigger AND dialog in the row.
function rowWithDialog(n) {
  return `
    <tr id="row-${n}"><td>
      <a href="/invoices/${n}" id="show-${n}">Show</a>
      <div id="d${n}-trigger" class="pc-alert-dialog__trigger" data-dialog="d${n}">
        <button type="button" id="delete-${n}">Delete</button>
      </div>
      ${dialogHtml(`d${n}`)}
    </td></tr>`;
}

function mountRowHooks(n) {
  const el = stubDialog($(`#d${n}`));
  const hook = mountHook("PetalAlertDialog", el);
  const trigger = mountHook("PetalAlertDialogTrigger", $(`#d${n}-trigger`));
  return { el, hook, trigger };
}

function tableWithDialogInRows(rows = 2) {
  render(`
    <button type="button" id="elsewhere">Filters</button>
    <table><tbody id="rows">
      ${Array.from({ length: rows }, (_, i) => rowWithDialog(i + 1)).join("")}
    </tbody></table>`);
  return Array.from({ length: rows }, (_, i) => mountRowHooks(i + 1));
}

const $ = (sel) => document.querySelector(sel);
const click = (el) =>
  el.dispatchEvent(new MouseEvent("click", { bubbles: true }));
const endExit = (el) => el.dispatchEvent(new Event("animationend"));
const confirm = (el) => click(el.querySelector(".pc-alert-dialog__confirm"));
const cancel = (el) => click(el.querySelector(".pc-alert-dialog__cancel"));
const escape = (el) => {
  keyDown("Escape");
  el.dispatchEvent(new Event("cancel", { cancelable: true }));
};
const openWith = (el, detail) =>
  el.dispatchEvent(new CustomEvent("pc:alert-dialog-open", { detail }));
const pointerDown = (el) =>
  el.dispatchEvent(new Event("pointerdown", { bubbles: true }));
const keyDown = (key) =>
  document.dispatchEvent(new KeyboardEvent("keydown", { key, bubbles: true }));
// The user reached the opener with Tab: the input the hook calls keyboard.
const keyboard = () => keyDown("Tab");
const toBody = () => document.activeElement?.blur();

// What LiveView does when a stream delete lands: the row leaves the DOM,
// then every hook inside it gets destroyed().
function removeRow(id, hooksInRow = []) {
  $(`#${id}`).remove();
  destroy(hooksInRow);
}

function destroy(hooksToGo) {
  hooksToGo.forEach((h) => {
    h.destroyed();
    live.splice(live.indexOf(h), 1);
  });
}

// jsdom lets any element take focus. A browser refuses one that is not
// rendered; these stubs say which.
function refuseFocus(refuse) {
  const realFocus = HTMLElement.prototype.focus;
  return vi
    .spyOn(HTMLElement.prototype, "focus")
    .mockImplementation(function (opts) {
      if (refuse(this)) return;
      realFocus.call(this, opts);
    });
}

const inDisplayNone = (n) => {
  for (let e = n; e; e = e.parentElement)
    if (e.style?.display === "none") return true;
  return false;
};

// Records every focus() options object, by element id.
function recordFocus() {
  const seen = [];
  const realFocus = HTMLElement.prototype.focus;
  vi.spyOn(HTMLElement.prototype, "focus").mockImplementation(function (opts) {
    seen.push([this.id, opts]);
    realFocus.call(this, opts);
  });
  return seen;
}

// Counts the document-level focusin and pointerdown listeners added since
// the call, net of removals. Arming adds one of each. A dialog hook's mount
// also adds a pointerdown for its modality tracker, so a spec that mounts
// after the call compares with a count taken after the mount.
function trackArming() {
  const count = { focusin: 0, pointerdown: 0 };
  const add = document.addEventListener.bind(document);
  const remove = document.removeEventListener.bind(document);
  vi.spyOn(document, "addEventListener").mockImplementation((t, f, o) => {
    if (t in count) count[t]++;
    add(t, f, o);
  });
  vi.spyOn(document, "removeEventListener").mockImplementation((t, f, o) => {
    if (t in count) count[t]--;
    remove(t, f, o);
  });
  return () => ({ ...count });
}

// A Chrome-like checkVisibility(): false for an element with no box, which
// is one with display:contents or inside display:none (CSSOM View). From
// the spec, not measured; the real check is the lead's browser pass.
const chromeLikeCheckVisibility = () => {
  Element.prototype.checkVisibility = function () {
    if (getComputedStyle(this).display === "contents") return false;
    for (let e = this; e; e = e.parentElement)
      if (getComputedStyle(e).display === "none") return false;
    return true;
  };
};

// The component's own stylesheet rule for the trigger wrapper.
const triggerCss = `<style>.pc-alert-dialog__trigger { display: contents; }</style>`;

describe("PetalAlertDialog focus return when the opener is removed", () => {
  afterEach(() => {
    vi.restoreAllMocks();
    live.splice(0).forEach((h) => h.destroyed());
    document.body.innerHTML = "";
    delete Element.prototype.checkVisibility;
    delete Element.prototype.scrollIntoView;
    delete window.matchMedia;
  });

  describe("the keyboard gate (R1)", () => {
    it("mouse open, mouse confirm, row removed mid-exit: nothing moves and no arming listener is left", () => {
      const arming = trackArming();
      const { el, hook } = tableWithOutsideDialog(3);
      const mounted = arming();
      pointerDown($("#delete-2"));
      $("#delete-2").focus();
      openWith(el, { dispatcher: $("#delete-2") });

      pointerDown(el.querySelector(".pc-alert-dialog__confirm"));
      confirm(el);
      removeRow("row-2");
      endExit(el);

      expect(document.activeElement).not.toBe($("#delete-3"));
      const active = document.activeElement;
      expect(active === document.body || el.contains(active)).toBe(true);
      expect(hook.focusArmed).toBe(false);
      expect(arming()).toEqual(mounted);
    });

    it("mouse open, mouse confirm, then the row with the dialog goes: focus falls to body, as on main", () => {
      const arming = trackArming();
      const [, row2] = tableWithDialogInRows(3);
      const mounted = arming();
      pointerDown($("#delete-2"));
      $("#delete-2").focus();
      click($("#delete-2"));

      pointerDown(row2.el.querySelector(".pc-alert-dialog__confirm"));
      confirm(row2.el);
      endExit(row2.el);
      expect(arming()).toEqual(mounted);
      removeRow("row-2", [row2.hook, row2.trigger]);

      expect(document.activeElement).toBe(document.body);
    });

    it("mouse open, keyboard confirm: focus moves, and asks for the ring", () => {
      const seen = recordFocus();
      const { el } = tableWithOutsideDialog(3);
      pointerDown($("#delete-1"));
      $("#delete-1").focus();
      openWith(el, { dispatcher: $("#delete-1") });

      keyboard();
      keyDown("Enter");
      confirm(el);
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).toBe($("#delete-2"));
      expect(seen.filter(([id]) => id === "delete-2")).toEqual([
        ["delete-2", { preventScroll: true, focusVisible: true }],
      ]);
    });

    it("keyboard open, mouse confirm: focus moves, and asks for the ring", () => {
      const seen = recordFocus();
      const { el } = tableWithOutsideDialog(3);
      $("#delete-1").focus();
      keyDown("Enter");
      openWith(el);

      pointerDown(el.querySelector(".pc-alert-dialog__confirm"));
      confirm(el);
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).toBe($("#delete-2"));
      expect(seen.filter(([id]) => id === "delete-2")).toEqual([
        ["delete-2", { preventScroll: true, focusVisible: true }],
      ]);
    });

    it("a close the guard drops still records its keyboard (Chrome's second Escape skips the cancel event)", () => {
      const { el } = tableWithOutsideDialog(3);
      pointerDown($("#delete-2"));
      $("#delete-2").focus();
      openWith(el);
      removeRow("row-2");

      // the native close lands first; the hook's own cancel path then runs
      // requestClose() on a dialog that is already closed
      keyDown("Escape");
      el.close();

      expect(document.activeElement).toBe($("#delete-3"));
    });

    it("an earlier keyboard close does not count for the next, mouse, open", () => {
      const [, row2] = tableWithDialogInRows(3);
      $("#delete-2").focus();
      keyboard();
      click($("#delete-2"));
      escape(row2.el);
      endExit(row2.el);

      // reopened with the mouse, then the row is deleted elsewhere while
      // the dialog is still open: no close intent at all
      pointerDown($("#delete-2"));
      click($("#delete-2"));
      removeRow("row-2", [row2.hook, row2.trigger]);

      expect(document.activeElement).toBe(document.body);
    });
  });

  describe("who the opener is (R2)", () => {
    it("the trigger names the control even when nothing has focus", () => {
      const [row1] = tableWithDialogInRows();
      keyboard();
      toBody();
      click($("#delete-1"));
      expect(row1.el.open).toBe(true);

      cancel(row1.el);
      endExit(row1.el);

      expect(document.activeElement).toBe($("#delete-1"));
    });

    it("the trigger uses the dialog's control list (a <summary> is one)", () => {
      render(`
        <div id="d-trigger" data-dialog="d">
          <details><summary id="sum">Delete</summary></details>
        </div>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      mountHook("PetalAlertDialogTrigger", $("#d-trigger"));
      keyboard();
      toBody();
      click($("#sum"));

      cancel(el);
      endExit(el);

      expect(document.activeElement).toBe($("#sum"));
    });

    it("the trigger names only a control inside itself, never a focusable row around it", () => {
      render(`
        <table><tbody>
          <tr id="row-1" tabindex="0"><td>
            <div id="d-trigger" data-dialog="d"><span id="label">Delete</span></div>
          </td></tr>
        </tbody></table>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      mountHook("PetalAlertDialogTrigger", $("#d-trigger"));
      const named = [];
      el.addEventListener("pc:alert-dialog-open", (e) =>
        named.push(e.detail.opener),
      );

      click($("#label"));

      expect(named).toEqual([null]);
    });

    it("a dispatcher that is a control wins over what has focus", () => {
      const { el, hook } = tableWithOutsideDialog(4);
      $("#add").focus();
      keyboard();
      openWith(el, { dispatcher: $("#delete-3") });

      expect(hook.opener).toBe($("#delete-3"));
    });

    // <div phx-click={open_alert_dialog("dN")}><button>Delete</button></div>:
    // LiveView names the div (live_socket.ts click binding, js.js:78).
    it("the wrapper shape: a div dispatcher around the focused button, row removed after the close: next row", () => {
      render(`
        <table><tbody id="rows">
          ${[1, 2, 3]
            .map(
              (n) => `<tr id="row-${n}"><td>
                <div id="wrap-${n}"><button type="button" id="delete-${n}">Delete</button></div>
                ${dialogHtml(`d${n}`)}
              </td></tr>`,
            )
            .join("")}
        </tbody></table>`);
      const el = stubDialog($("#d1"));
      const hook = mountHook("PetalAlertDialog", el);
      $("#delete-1").focus();
      keyDown("Enter");
      openWith(el, { dispatcher: $("#wrap-1") });

      confirm(el);
      endExit(el);
      // the native close refocused the button: that must not disarm
      expect(document.activeElement).toBe($("#delete-1"));
      expect(hook.focusArmed).toBe(true);
      removeRow("row-1", [hook]);

      expect(document.activeElement).toBe($("#delete-2"));
    });

    // <div phx-window-keydown={open_alert_dialog("d")} phx-key="Delete">:
    // the dispatcher is that div, wherever focus was.
    it("the window-binding shape: the focused control is the opener, not the element with the binding", () => {
      render(`
        <div id="shortcuts">
          <table><tbody id="rows">
            ${[1, 2, 3]
              .map(
                (n) =>
                  `<tr id="row-${n}"><td><input type="checkbox" id="cb-${n}" /></td></tr>`,
              )
              .join("")}
          </tbody></table>
        </div>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#cb-2").focus();
      keyDown("Delete");
      openWith(el, { dispatcher: $("#shortcuts") });

      confirm(el);
      removeRow("row-2");
      endExit(el);

      expect(document.activeElement).toBe($("#cb-3"));
    });

    it("an open with neither opener nor dispatcher uses activeElement, and never an earlier opener", () => {
      const { el } = tableWithOutsideDialog(3);
      keyboard();
      $("#delete-1").focus();
      openWith(el, {});
      cancel(el);
      endExit(el);

      $("#delete-2").focus();
      openWith(el, {});
      confirm(el);
      removeRow("row-2");
      endExit(el);

      expect(document.activeElement).toBe($("#delete-3"));
    });

    it("an open with no opener at all forgets the earlier one: nothing moves", () => {
      const { el, hook } = tableWithOutsideDialog(3);
      keyboard();
      $("#delete-1").focus();
      openWith(el, {});
      // a confirm whose reply kept row 1: still armed on its Delete
      confirm(el);
      endExit(el);
      expect(hook.opener).toBe($("#delete-1"));

      toBody();
      openWith(el, {});
      expect(hook.focusArmed).toBe(false);
      expect(hook.opener).toBe(null);
      confirm(el);
      removeRow("row-1");
      endExit(el);

      // Left where the native close leaves it (<body> in a browser, a hidden
      // button in this stub), not sent to row 1's neighbour.
      expect(document.activeElement).not.toBe($("#delete-2"));
      const active = document.activeElement;
      expect(active === document.body || el.contains(active)).toBe(true);
    });

    it("a shared dialog opened from row 3 after an earlier open from row 1 goes to row 4", () => {
      const { el } = tableWithOutsideDialog(4);
      keyboard();
      toBody();
      // open_alert_dialog/2 through JS.dispatch: LiveView sets detail.dispatcher
      openWith(el, { dispatcher: $("#delete-1") });
      cancel(el);
      endExit(el);

      toBody();
      openWith(el, { dispatcher: $("#delete-3") });
      confirm(el);
      removeRow("row-3");
      endExit(el);

      expect(document.activeElement).toBe($("#delete-4"));
    });
  });

  describe("a clicked row that is no control (R2.4, R7.b)", () => {
    // <tr phx-click={JS.push("pick") |> open_alert_dialog("confirm")}>
    // LiveView names the <tr> as the dispatcher, and nothing has focus.
    const clickableRows = (n) =>
      Array.from(
        { length: n },
        (_, i) =>
          `<tr id="row-${i + 1}"><td>Invoice ${i + 1}</td><td><a href="/invoices/${i + 1}" id="view-${i + 1}">View</a></td></tr>`,
      ).join("");

    function clickableTable(rows = 3) {
      render(`
        <table><tbody id="rows">${clickableRows(rows)}</tbody></table>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      const hook = mountHook("PetalAlertDialog", el);
      return { el, hook };
    }

    // The browser's next rendering step, which jsdom never takes: a focused
    // button inside a closed dialog is no longer rendered, so focus falls to
    // <body> (see stubDialog).
    const nextFrame = (el) => {
      if (!el.open && el.contains(document.activeElement)) toBody();
    };

    // A mouse click on the row's text, then the dialog answered from the
    // keyboard: the only way a no-control opener reaches the restore.
    const clickRow = (el, row) => {
      pointerDown(row.querySelector("td"));
      toBody();
      openWith(el, { dispatcher: row });
    };

    it("Escape: focus stays where the browser left it, never the next row", () => {
      const { el, hook } = clickableTable();
      clickRow(el, $("#row-2"));

      escape(el);
      endExit(el);
      nextFrame(el);

      expect(document.activeElement).toBe(document.body);
      expect(document.querySelector("[tabindex]")).toBe(null);
      expect(hook.focusArmed).toBe(false);
    });

    it("keyboard Cancel: the same", () => {
      const { el, hook } = clickableTable();
      clickRow(el, $("#row-2"));

      keyboard();
      cancel(el);
      endExit(el);
      nextFrame(el);

      expect(document.activeElement).toBe(document.body);
      expect(hook.focusArmed).toBe(false);
    });

    it("keyboard confirm removes the row while the exit plays: focus goes to the next row", () => {
      const { el } = clickableTable();
      clickRow(el, $("#row-2"));

      keyDown("Enter");
      confirm(el);
      removeRow("row-2");
      endExit(el);

      expect(document.activeElement).toBe($("#view-3"));
    });

    it("a confirm that kept the row: nothing moves at the close, and the row going later still sends focus on", () => {
      render(`
        <table><tbody id="rows">
          <tr id="row-1"><td>Invoice 1 ${dialogHtml("d1")}</td></tr>
          <tr id="row-2"><td><a href="/invoices/2" id="view-2">View</a></td></tr>
        </tbody></table>`);
      const el = stubDialog($("#d1"));
      const hook = mountHook("PetalAlertDialog", el);
      clickRow(el, $("#row-1"));

      keyDown("Enter");
      confirm(el);
      endExit(el);
      nextFrame(el);
      expect(document.activeElement).toBe(document.body);

      removeRow("row-1", [hook]);

      expect(document.activeElement).toBe($("#view-2"));
    });

    it("cancelled, then removed later for another reason: nothing moves", () => {
      render(`
        <table><tbody id="rows">
          <tr id="row-1"><td>Invoice 1 ${dialogHtml("d1")}</td></tr>
          <tr id="row-2"><td><a href="/invoices/2" id="view-2">View</a></td></tr>
        </tbody></table>`);
      const el = stubDialog($("#d1"));
      const hook = mountHook("PetalAlertDialog", el);
      clickRow(el, $("#row-1"));

      escape(el);
      endExit(el);
      nextFrame(el);
      removeRow("row-1", [hook]);

      expect(document.activeElement).toBe(document.body);
    });

    it("Enter on a link inside the clicked row: the link is the opener", () => {
      const { el } = clickableTable();
      $("#view-2").focus();
      keyDown("Enter");
      openWith(el, { dispatcher: $("#row-2") });

      confirm(el);
      removeRow("row-2");
      endExit(el);

      expect(document.activeElement).toBe($("#view-3"));
    });
  });

  describe("when to try, and staying armed (R4, R5, R6)", () => {
    it("the Pro shape: close finishes, THEN the row (with the dialog in it) is removed", () => {
      const [row1] = tableWithDialogInRows();
      $("#delete-1").focus();
      keyDown("Enter");
      click($("#delete-1"));

      confirm(row1.el);
      endExit(row1.el);
      // the native close put focus back on the opener
      expect(document.activeElement).toBe($("#delete-1"));

      removeRow("row-1", [row1.hook, row1.trigger]);

      expect(document.activeElement).toBe($("#delete-2"));
    });

    it("the Pro shape: the row is removed while the dialog is still open", () => {
      const [row1] = tableWithDialogInRows();
      $("#delete-1").focus();
      keyDown("Enter");
      click($("#delete-1"));
      confirm(row1.el);

      removeRow("row-1", [row1.hook, row1.trigger]);

      expect(document.activeElement).toBe($("#delete-2"));
    });

    it("an index-keyed list (a :for with no :key): the opener node is moved, not removed, and still takes focus", () => {
      // petal.gen.live.data_table and Pro's passkeys render rows with no id,
      // so LiveView keys them by index. Deleting item 2 of 3, morphdom keeps
      // the second <tr>, moves item 3's trigger and dialog (keyed by id) into
      // it, and moves item 2's Delete button (keyed by its index) into item 3's
      // trigger. The button never leaves the page, but the move blurs it.
      const row = (n) => `
        <tr><td>
          <div id="d${n}-trigger" class="pc-alert-dialog__trigger" data-dialog="d${n}">
            <button type="button" data-label="delete-${n}">Delete</button>
          </div>
          ${dialogHtml(`d${n}`)}
        </td></tr>`;
      render(
        `<table><tbody id="rows">${[1, 2, 3].map(row).join("")}</tbody></table>`,
      );
      const rows = [1, 2, 3].map(mountRowHooks);
      const opener = $('[data-label="delete-2"]');
      opener.focus();
      keyDown("Enter");
      click(opener);
      confirm(rows[1].el);
      endExit(rows[1].el);
      expect(document.activeElement).toBe(opener);

      // what morphdom does with LiveView's node keys (id, else data-phx-id)
      const [, tr2, tr3] = $("#rows").children;
      $("#d3-trigger").querySelector("button").replaceWith(opener);
      opener.dataset.label = "delete-3";
      tr2.querySelector("td").replaceChildren($("#d3-trigger"), $("#d3"));
      tr3.remove();
      destroy([rows[1].hook, rows[1].trigger]);

      expect(opener.isConnected).toBe(true);
      expect(document.activeElement).toBe(opener);
    });

    it("an opener still in the page keeps its focus: nothing else is touched", () => {
      const { el } = tableWithOutsideDialog();
      $("#delete-1").focus();
      keyboard();
      openWith(el);

      cancel(el);
      endExit(el);

      expect(document.activeElement).toBe($("#delete-1"));
      expect(document.querySelector("[tabindex]")).toBe(null);
    });

    it("focus the user has moved on with is left alone when the row goes later", () => {
      const [row1] = tableWithDialogInRows();
      $("#delete-1").focus();
      keyboard();
      click($("#delete-1"));
      confirm(row1.el);
      endExit(row1.el);

      $("#elsewhere").focus();
      removeRow("row-1", [row1.hook, row1.trigger]);

      expect(document.activeElement).toBe($("#elsewhere"));
    });

    it("a focus elsewhere disarms it, even if that element later goes too", () => {
      const [row1] = tableWithDialogInRows();
      $("#delete-1").focus();
      keyboard();
      click($("#delete-1"));
      confirm(row1.el);
      endExit(row1.el);

      // Tab on to another control, which a later patch removes
      $("#elsewhere").focus();
      $("#elsewhere").remove();
      removeRow("row-1", [row1.hook, row1.trigger]);

      expect(document.activeElement).toBe(document.body);
    });

    it("a live navigation's teardown (the page still connected) moves nothing and leaves no arming listener", () => {
      const arming = trackArming();
      const [row1, row2] = tableWithDialogInRows();
      const mounted = arming();
      $("#delete-1").focus();
      keyboard();
      click($("#delete-1"));
      confirm(row1.el);
      endExit(row1.el);
      expect(arming()).toEqual({
        focusin: mounted.focusin + 1,
        pointerdown: mounted.pointerdown + 1,
      });
      // the click that starts the navigation blurs to <body>
      toBody();

      // LiveView destroys every hook while the old page is still in the DOM
      destroy([row1.hook, row1.trigger, row2.hook, row2.trigger]);

      expect(document.activeElement).toBe(document.body);
      // every listener the hooks added is gone, the modality ones included
      expect(arming()).toEqual({ focusin: 0, pointerdown: 0 });
    });

    it("focus inside the dialog while it is still open is not lost: a teardown then moves nothing", () => {
      const { el, hook } = tableWithOutsideDialog(3);
      $("#delete-2").focus();
      keyboard();
      openWith(el);
      const cancelButton = el.querySelector(".pc-alert-dialog__cancel");
      expect(document.activeElement).toBe(cancelButton);

      // another user deletes the row, then a navigation tears the page down
      removeRow("row-2");
      destroy([hook]);

      expect(document.activeElement).toBe(cancelButton);
    });

    it("a pointerdown elsewhere that focuses nothing disarms it: a later removal moves nothing", () => {
      const [row1, row2] = tableWithDialogInRows();
      $("#delete-1").focus();
      keyboard();
      click($("#delete-1"));
      confirm(row1.el);
      endExit(row1.el);

      // a mouse click on a plain table cell
      pointerDown($("#row-2 td"));
      toBody();
      removeRow("row-1", [row1.hook, row1.trigger]);

      expect(document.activeElement).toBe(document.body);
      expect(row2.el.open).toBe(false);
    });

    it("a Cancel that ends on the living opener disarms it, and lets go of the opener, its path and its region", () => {
      render(`
        <div role="dialog" id="panel">
          <table><tbody id="rows">${rowWithDialog(1)}${rowWithDialog(2)}</tbody></table>
        </div>`);
      const [row1] = [1, 2].map(mountRowHooks);
      $("#delete-1").focus();
      keyboard();
      click($("#delete-1"));
      expect(row1.hook.region).toBe($("#panel"));
      cancel(row1.el);
      endExit(row1.el);
      expect(document.activeElement).toBe($("#delete-1"));
      expect(row1.hook.opener).toBe(null);
      expect(row1.hook.openerPath).toEqual([]);
      expect(row1.hook.region).toBe(null);

      // the row goes later for an unrelated reason (a filter, another user)
      removeRow("row-1", [row1.hook, row1.trigger]);

      expect(document.activeElement).toBe(document.body);
    });

    it("Escape closes through the same cancel path and disarms the same way", () => {
      const [row1] = tableWithDialogInRows();
      $("#delete-1").focus();
      keyboard();
      click($("#delete-1"));
      escape(row1.el);
      endExit(row1.el);
      expect(document.activeElement).toBe($("#delete-1"));

      removeRow("row-1", [row1.hook, row1.trigger]);

      expect(document.activeElement).toBe(document.body);
    });

    it("an idle dialog holds no arming listener; an open adds focusin and pointerdown, and the close-out removes both", () => {
      const arming = trackArming();
      const { el } = tableWithOutsideDialog();
      const mounted = arming();
      expect(mounted.focusin).toBe(0);

      $("#delete-1").focus();
      keyboard();
      openWith(el);
      expect(arming()).toEqual({
        focusin: 1,
        pointerdown: mounted.pointerdown + 1,
      });

      cancel(el);
      endExit(el);
      expect(arming()).toEqual(mounted);
    });

    it("a reopen mid-exit forgets the Escape it abandoned: a later close on the living opener stays armed for the removal", () => {
      const [, row2] = tableWithDialogInRows(3);
      $("#delete-2").focus();
      keyboard();
      click($("#delete-2"));
      escape(row2.el);

      // reopened from the same button while the exit plays, then closed by
      // close_alert_dialog/2, which is neither Cancel nor confirm
      click($("#delete-2"));
      row2.el.dispatchEvent(new CustomEvent("pc:alert-dialog-close"));
      endExit(row2.el);
      expect(document.activeElement).toBe($("#delete-2"));
      removeRow("row-2", [row2.hook, row2.trigger]);

      expect(document.activeElement).toBe($("#delete-3"));
    });

    // Safari does not focus a clicked button, so the native close has
    // nothing to give back and the hook puts focus on the opener itself.
    it("a restore to the opener stays armed: the slow reply's row removal still sends focus on", () => {
      const [, row2] = tableWithDialogInRows(3);
      pointerDown($("#delete-2"));
      toBody();
      click($("#delete-2"));
      keyDown("Enter");
      confirm(row2.el);
      endExit(row2.el);
      expect(document.activeElement).toBe($("#delete-2"));
      expect(row2.hook.focusArmed).toBe(true);

      removeRow("row-2", [row2.hook, row2.trigger]);

      expect(document.activeElement).toBe($("#delete-3"));
    });

    it("a reopen mid-exit with no detail keeps the opener: the confirm that follows still sends focus to the next row", () => {
      const { el } = tableWithOutsideDialog(3);
      $("#delete-2").focus();
      keyboard();
      openWith(el);
      cancel(el);

      // activeElement is the Cancel button inside the dialog by now
      openWith(el);
      expect(el.open).toBe(true);
      confirm(el);
      removeRow("row-2");
      endExit(el);

      expect(document.activeElement).toBe($("#delete-3"));
    });

    it("reopening from the same button after a row was inserted uses the rows as they are now", () => {
      const { el } = tableWithOutsideDialog(3);
      $("#delete-2").focus();
      keyboard();
      openWith(el);
      cancel(el);
      endExit(el);

      $("#row-2").insertAdjacentHTML(
        "afterend",
        `<tr id="row-new"><td><button type="button" id="delete-new">Delete</button></td></tr>`,
      );
      $("#delete-2").focus();
      openWith(el);
      confirm(el);
      removeRow("row-2");
      endExit(el);

      expect(document.activeElement).toBe($("#delete-new"));
    });

    it("under reduced motion, a dialog outside the row: the row goes after the close, so focus falls to body (the documented limit)", () => {
      window.matchMedia = (q) => ({ matches: q.includes("reduce"), media: q });
      const { el } = tableWithOutsideDialog(3);
      $("#delete-2").focus();
      keyboard();
      openWith(el);

      confirm(el);
      expect(el.open).toBe(false);
      expect(document.activeElement).toBe($("#delete-2"));
      removeRow("row-2");

      expect(document.activeElement).toBe(document.body);
    });

    it("under reduced motion, a dialog inside the row: the next row", () => {
      window.matchMedia = (q) => ({ matches: q.includes("reduce"), media: q });
      const [, row2] = tableWithDialogInRows(3);
      $("#delete-2").focus();
      keyboard();
      click($("#delete-2"));

      confirm(row2.el);
      expect(row2.el.open).toBe(false);
      removeRow("row-2", [row2.hook, row2.trigger]);

      expect(document.activeElement).toBe($("#delete-3"));
    });
  });

  describe("a region that left the page (R3, R7.c)", () => {
    // Each kind on its own, so dropping one from the region selector fails.
    const regions = {
      'role="dialog"': (rows) => `<div role="dialog">${rows}</div>`,
      'aria-modal="true"': (rows) => `<div aria-modal="true">${rows}</div>`,
      "a native <dialog>": (rows) => `<dialog open>${rows}</dialog>`,
    };
    for (const [kind, wrap] of Object.entries(regions)) {
      it(`a modal removed with the row (${kind}): nothing moves`, () => {
        render(`
          <button type="button" id="open-modal">Edit invoices</button>
          <div id="modal">
            ${wrap(`<table><tbody id="rows">${rowWithDialog(1)}${rowWithDialog(2)}</tbody></table>`)}
          </div>`);
        const rows = [1, 2].map(mountRowHooks);
        $("#delete-1").focus();
        keyDown("Enter");
        click($("#delete-1"));
        confirm(rows[0].el);
        endExit(rows[0].el);

        $("#modal").remove();
        destroy(rows.flatMap(({ hook, trigger }) => [hook, trigger]));

        expect(document.activeElement).toBe(document.body);
      });
    }

    it("a modal on its way out (hidden by its phx-remove, still in the page): nothing outside it is used", () => {
      render(`
        <button type="button" id="open-modal">Edit invoices</button>
        <div id="modal">
          <div role="dialog" aria-modal="true">
            <table><tbody id="rows">${rowsHtml(2)}</tbody></table>
          </div>
        </div>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#delete-1").focus();
      keyboard();
      openWith(el);

      confirm(el);
      $("#modal").style.display = "none";
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).not.toBe($("#open-modal"));
      expect(document.querySelector("[tabindex]")).toBe(null);
    });

    it("a LiveView root replaced: nothing moves", () => {
      const root = () => `
        <div id="root" data-phx-session="s">
          <table><tbody id="rows">${rowWithDialog(1)}${rowWithDialog(2)}</tbody></table>
        </div>`;
      const page = render(root());
      const rows = [1, 2].map(mountRowHooks);
      $("#delete-1").focus();
      keyDown("Enter");
      click($("#delete-1"));
      confirm(rows[0].el);
      endExit(rows[0].el);

      $("#root").remove();
      page.insertAdjacentHTML("beforeend", root());
      destroy(rows.flatMap(({ hook, trigger }) => [hook, trigger]));

      expect(document.activeElement).toBe(document.body);
    });
  });

  describe("where focus goes (R7.d, R7.e)", () => {
    it("row removed while the exit plays: the next row", () => {
      const { el } = tableWithOutsideDialog();
      $("#delete-1").focus();
      keyboard();
      openWith(el);

      confirm(el);
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).toBe($("#delete-2"));
    });

    it("the last row removed: the row before it, nearest first", () => {
      const { el } = tableWithOutsideDialog(3);
      $("#delete-3").focus();
      keyboard();
      openWith(el);

      confirm(el);
      removeRow("row-3");
      endExit(el);

      expect(document.activeElement).toBe($("#delete-2"));
    });

    it("the same control in the next row, not its first one", () => {
      const [row1] = tableWithDialogInRows(3);
      $("#delete-1").focus();
      keyboard();
      click($("#delete-1"));
      confirm(row1.el);
      removeRow("row-1", [row1.hook, row1.trigger]);

      expect(document.activeElement).toBe($("#delete-2"));
    });

    it("a next row built differently: its first control", () => {
      render(`
        <table><tbody id="rows">
          <tr id="row-1"><td><a href="/1" id="show-1">Show</a><button type="button" id="delete-1">Delete</button></td></tr>
          <tr id="row-2"><td><a href="/2" id="show-2">Show</a><a href="/2/edit" id="edit-2">Edit</a><button type="button" id="delete-2">Delete</button></td></tr>
        </tbody></table>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#delete-1").focus();
      keyboard();
      openWith(el);
      confirm(el);
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).toBe($("#show-2"));
    });

    it("a neighbour of another tag with as many controls: its first control, not the same position", () => {
      render(`
        <div id="cards">
          <article id="card-1"><a href="/1" id="open-1">Open</a><button type="button" id="delete-1">Delete</button></article>
          <div id="pager"><a href="/page/1" id="prev-page">Previous</a><a href="/page/3" id="next-page">Next</a></div>
        </div>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#delete-1").focus();
      keyboard();
      openWith(el);
      confirm(el);
      removeRow("card-1");
      endExit(el);

      expect(document.activeElement).toBe($("#prev-page"));
    });

    it("the same control in the next row cannot take focus: its first control that can", () => {
      render(`
        <table><tbody id="rows">
          <tr id="row-1"><td><a href="/1" id="show-1">Show</a><button type="button" id="delete-1">Delete</button></td></tr>
          <tr id="row-2"><td><a href="/2" id="show-2">Show</a><button type="button" id="delete-2" disabled>Delete</button></td></tr>
        </tbody></table>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#delete-1").focus();
      keyboard();
      openWith(el);
      confirm(el);
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).toBe($("#show-2"));
    });

    it("a row and its detail row removed together: the next row, past the detail rows", () => {
      render(`
        <table><tbody id="rows">
          ${[1, 2, 3, 4]
            .map(
              (n) =>
                `<tr id="row-${n}"><td><button type="button" id="delete-${n}">Delete</button></td></tr>` +
                `<tr id="detail-${n}"><td>Notes for invoice ${n}</td></tr>`,
            )
            .join("")}
        </tbody></table>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#delete-2").focus();
      keyboard();
      openWith(el);
      confirm(el);
      $("#detail-2").remove();
      removeRow("row-2");
      endExit(el);

      expect(document.activeElement).toBe($("#delete-3"));
    });

    it("the first row and its detail row removed together, nothing recorded beside it left: the child now at its index", () => {
      render(`
        <table><tbody id="rows">
          <tr id="row-1"><td><button type="button" id="delete-1">Delete</button></td></tr>
          <tr id="detail-1"><td>Notes for invoice 1</td></tr>
          ${rowsHtml(3).replace(/<tr id="row-1">.*?<\/tr>/, "")}
        </tbody></table>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#delete-1").focus();
      keyboard();
      openWith(el);
      confirm(el);
      $("#row-1").remove();
      $("#detail-1").remove();
      endExit(el);

      expect(document.activeElement).toBe($("#delete-2"));
    });

    it("a row inserted above while open, then the row and its detail row go: still the row after", () => {
      render(`
        <table><tbody id="rows">
          ${rowsHtml(3)}
          <tr id="detail-3"><td>Notes</td></tr>
          <tr id="row-4"><td><button type="button" id="delete-4">Delete</button></td></tr>
        </tbody></table>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#delete-3").focus();
      keyboard();
      openWith(el);
      $("#rows").insertAdjacentHTML(
        "afterbegin",
        `<tr id="row-0"><td><button type="button" id="delete-0">Delete</button></td></tr>`,
      );
      confirm(el);
      $("#detail-3").remove();
      removeRow("row-3");
      endExit(el);

      expect(document.activeElement).toBe($("#delete-4"));
    });

    it("a row inserted just before the opener's row, which then goes: the row after it, not the new one", () => {
      const { el } = tableWithOutsideDialog(3);
      $("#delete-2").focus();
      keyboard();
      openWith(el);
      $("#row-1").insertAdjacentHTML(
        "afterend",
        `<tr id="row-new"><td><button type="button" id="delete-new">Delete</button></td></tr>`,
      );
      confirm(el);
      removeRow("row-2");
      endExit(el);

      expect(document.activeElement).toBe($("#delete-3"));
    });

    // A stream insert renders the item from scratch, so morphdom replaces
    // every control in the row that has no id, the opener included, while the
    // row and the trigger (both with ids) stay.
    function rerenderRow(n) {
      $(`#show-${n}`).replaceWith(
        Object.assign(document.createElement("a"), {
          href: `/invoices/${n}`,
          id: `show-${n}`,
        }),
      );
      const fresh = document.createElement("button");
      fresh.type = "button";
      fresh.dataset.label = `delete-${n}`;
      $(`#d${n}-trigger`).replaceChildren(fresh);
      return fresh;
    }

    it("the row re-rendered while the dialog is open, then Cancel: focus goes to the replacement opener, not the next row", () => {
      const [, row2] = tableWithDialogInRows(3);
      $("#delete-2").focus();
      keyboard();
      click($("#delete-2"));

      const fresh = rerenderRow(2);
      cancel(row2.el);
      endExit(row2.el);

      expect(document.activeElement).toBe(fresh);
    });

    it("a confirm whose reply re-renders the row it kept (Archive) mid-exit: focus goes to the replacement opener", () => {
      const [, row2] = tableWithDialogInRows(3);
      $("#delete-2").focus();
      keyboard();
      click($("#delete-2"));

      confirm(row2.el);
      const fresh = rerenderRow(2);
      endExit(row2.el);

      expect(document.activeElement).toBe(fresh);
    });

    // <td><a>Edit</a><button>Archive</button></td>, where the reply swaps
    // Archive for Restore (an if/else: a new node).
    function archiveTable() {
      render(`
        <table><tbody id="rows">
          ${[1, 2]
            .map(
              (n) =>
                `<tr id="row-${n}"><td id="cell-${n}"><a href="/${n}/edit" id="edit-${n}">Edit</a><button type="button" id="archive-${n}">Archive</button></td></tr>`,
            )
            .join("")}
        </tbody></table>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#archive-1").focus();
      keyboard();
      openWith(el, { dispatcher: $("#archive-1") });
      return el;
    }
    const restoreButton = () =>
      Object.assign(document.createElement("button"), {
        type: "button",
        id: "restore-1",
      });

    it("the opener replaced in a cell that also holds another control: the replacement, not the other control", () => {
      const el = archiveTable();
      confirm(el);
      $("#archive-1").replaceWith(restoreButton());
      endExit(el);

      expect(document.activeElement).toBe($("#restore-1"));
    });

    it("the same, with every control in the cell replaced: the replacement, found by its old position", () => {
      const el = archiveTable();
      confirm(el);
      $("#cell-1").replaceChildren(
        Object.assign(document.createElement("a"), {
          href: "/1/edit",
          id: "edit-1b",
        }),
        restoreButton(),
      );
      endExit(el);

      expect(document.activeElement).toBe($("#restore-1"));
    });

    // The trigger wrapper is display:contents in the component's CSS, and
    // Chrome's checkVisibility() is false for an element with no box. The
    // walk must agree with the engines that have no checkVisibility().
    const contentsEngines = {
      "Chrome-like checkVisibility": chromeLikeCheckVisibility,
      "no checkVisibility": () => {},
    };
    for (const [engine, setUp] of Object.entries(contentsEngines)) {
      it(`the opener replaced inside its display:contents trigger, a control after it in the cell (${engine}): the replacement`, () => {
        setUp();
        render(`
          ${triggerCss}
          <table><tbody id="rows">
            ${[1, 2]
              .map(
                (n) => `<tr id="row-${n}"><td>
                  <div id="d${n}-trigger" class="pc-alert-dialog__trigger" data-dialog="d${n}">
                    <button type="button" id="archive-${n}">Archive</button>
                  </div>
                  <a href="/${n}/edit" id="edit-${n}">Edit</a>
                  ${dialogHtml(`d${n}`)}
                </td></tr>`,
              )
              .join("")}
          </tbody></table>`);
        const [row1] = [1, 2].map(mountRowHooks);
        $("#archive-1").focus();
        keyboard();
        click($("#archive-1"));
        confirm(row1.el);
        $("#archive-1").replaceWith(
          Object.assign(document.createElement("button"), {
            type: "button",
            id: "restore-1",
          }),
        );
        endExit(row1.el);

        expect(document.activeElement).toBe($("#restore-1"));
      });

      it(`a stream container laid into a grid with display:contents (${engine}): the next card, not the first`, () => {
        setUp();
        render(`
          <div id="grid">
            <div id="cards" style="display: contents">
              ${[1, 2, 3]
                .map(
                  (n) =>
                    `<article id="card-${n}"><a href="/${n}" id="open-${n}">Open</a><button type="button" id="delete-${n}">Delete</button></article>`,
                )
                .join("")}
            </div>
          </div>
          ${dialogHtml("d")}`);
        const el = stubDialog($("#d"));
        mountHook("PetalAlertDialog", el);
        $("#delete-2").focus();
        keyboard();
        openWith(el);
        confirm(el);
        removeRow("card-2");
        endExit(el);

        expect(document.activeElement).toBe($("#delete-3"));
      });

      it(`the opener disabled by the reply, alone in its display:contents trigger (${engine}): no tabindex is lent to the wrapper`, () => {
        setUp();
        render(
          `${triggerCss}<table><tbody id="rows">${rowWithDialog(1)}${rowWithDialog(2)}</tbody></table>`,
        );
        const [row1] = [1, 2].map(mountRowHooks);
        $("#delete-1").focus();
        keyboard();
        click($("#delete-1"));
        confirm(row1.el);
        $("#delete-1").disabled = true;
        toBody();
        endExit(row1.el);

        expect($("#d1-trigger").hasAttribute("tabindex")).toBe(false);
        expect(document.activeElement).toBe(document.body);
      });
    }

    it("an engine-only hiding (checkVisibility false where computed display is not none): the level is chosen by checkVisibility", () => {
      // content-visibility: hidden on #panel skips its contents; jsdom's
      // computed style knows nothing of it, so only checkVisibility can say.
      Element.prototype.checkVisibility = function () {
        return !(this !== $("#panel") && $("#panel")?.contains(this));
      };
      render(`
        <div id="panel">
          <table><tbody id="rows">${rowsHtml(3)}</tbody></table>
        </div>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#delete-1").focus();
      keyboard();
      openWith(el);
      confirm(el);
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).not.toBe($("#delete-2"));
      expect(document.activeElement).toBe($("#panel"));
    });

    it("skips the next row's own closed dialog, disabled controls and tabindex=-1, never even trying them", () => {
      const seen = recordFocus();
      render(`
        <table><tbody id="rows">
          <tr id="row-1"><td><button type="button" id="delete-1">Delete</button></td></tr>
          <tr id="row-2"><td>
            ${dialogHtml("d2")}
            <button type="button" id="disabled-2" disabled>Archive</button>
            <button type="button" id="skip-2" tabindex="-1">Skip</button>
            <a href="/invoices/2" id="show-2">Show</a>
          </td></tr>
        </tbody></table>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      stubDialog($("#d2"));

      $("#delete-1").focus();
      keyboard();
      openWith(el);
      confirm(el);
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).toBe($("#show-2"));
      const tried = seen.map(([id]) => id);
      expect(tried).not.toContain("disabled-2");
      expect(tried).not.toContain("skip-2");
      // d2's buttons have no id; the only id-less focus is d's own Cancel
      expect(tried.filter((id) => id === "")).toHaveLength(1);
    });

    // R8 one part at a time: the next row's only control is the case. A
    // skipped one sends focus on to row 3.
    const r8Cases = [
      [
        "an inert row",
        `<tr id="row-2" inert><td><button type="button" id="c">C</button></td></tr>`,
        "delete-3",
      ],
      [
        "a select",
        `<tr id="row-2"><td><select id="c"><option>A</option></select></td></tr>`,
        "c",
      ],
      [
        "a textarea",
        `<tr id="row-2"><td><textarea id="c"></textarea></td></tr>`,
        "c",
      ],
      [
        "tabindex=0",
        `<tr id="row-2"><td><div tabindex="0" id="c">C</div></td></tr>`,
        "c",
      ],
      [
        'contenteditable="false"',
        `<tr id="row-2"><td><div contenteditable="false" id="c">C</div></td></tr>`,
        "delete-3",
      ],
    ];
    for (const [name, row2, expected] of r8Cases) {
      it(`R8, the next row's only control is ${name}: ${expected === "c" ? "it takes focus" : "skipped"}`, () => {
        render(`
          <table><tbody id="rows">
            <tr id="row-1"><td><button type="button" id="delete-1">Delete</button></td></tr>
            ${row2}
            <tr id="row-3"><td><button type="button" id="delete-3">Delete</button></td></tr>
          </tbody></table>
          ${dialogHtml("d")}`);
        const el = stubDialog($("#d"));
        mountHook("PetalAlertDialog", el);
        $("#delete-1").focus();
        keyboard();
        openWith(el);
        confirm(el);
        removeRow("row-1");
        endExit(el);

        expect(document.activeElement.id).toBe(expected);
      });
    }

    // What is no control is not counted when a row is compared with the
    // gone one, so an extra one of these keeps the same-position landing.
    const notCounted = [
      [
        "a hidden input",
        `<a href="/1" id="show-1">Show</a><button type="button" id="delete-1">Delete</button>`,
        `<input type="hidden" name="id" value="2" /><a href="/2" id="show-2">Show</a><button type="button" id="delete-2">Delete</button>`,
      ],
      [
        "a second <summary>",
        `<details><summary id="sum-1">More</summary></details><button type="button" id="delete-1">Delete</button>`,
        `<details><summary id="sum-2">More</summary><summary>Extra</summary></details><button type="button" id="delete-2">Delete</button>`,
      ],
    ];
    for (const [name, row1, row2] of notCounted) {
      it(`R8, ${name} in the next row is not counted: still the same control`, () => {
        render(`
          <table><tbody id="rows">
            <tr id="row-1"><td>${row1}</td></tr>
            <tr id="row-2"><td>${row2}</td></tr>
          </tbody></table>
          ${dialogHtml("d")}`);
        const el = stubDialog($("#d"));
        mountHook("PetalAlertDialog", el);
        $("#delete-1").focus();
        keyboard();
        openWith(el);
        confirm(el);
        removeRow("row-1");
        endExit(el);

        expect(document.activeElement).toBe($("#delete-2"));
      });
    }

    it("a bulk bar that disappears whole: focus goes to what follows it", () => {
      render(`
        <input type="search" id="search" />
        <div id="bulk-bar">
          <div id="bulk-trigger" data-dialog="bulk">
            <button type="button" id="bulk-delete">Delete selected</button>
          </div>
          ${dialogHtml("bulk")}
        </div>
        <table><tbody id="rows">${rowsHtml(2)}</tbody></table>`);
      const el = stubDialog($("#bulk"));
      const hook = mountHook("PetalAlertDialog", el);
      const trigger = mountHook("PetalAlertDialogTrigger", $("#bulk-trigger"));

      $("#bulk-delete").focus();
      keyboard();
      click($("#bulk-delete"));
      confirm(el);
      endExit(el);
      removeRow("bulk-bar", [hook, trigger]);

      expect(document.activeElement).toBe($("#delete-1"));
    });

    it("an opener that IS a control but can no longer take focus (disabled by the reply) stays in its own row", () => {
      // jsdom, like a browser, refuses focus on a disabled button, so the
      // restore's own focus check is what moves on from it.
      render(`
        <table><tbody id="rows">
          ${[1, 2, 3]
            .map(
              (n) =>
                `<tr id="row-${n}"><td><a href="/${n}" id="show-${n}">Show</a><button type="button" id="delete-${n}">Delete</button></td></tr>`,
            )
            .join("")}
        </tbody></table>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#delete-2").focus();
      keyboard();
      openWith(el);

      confirm(el);
      $("#delete-2").disabled = true;
      toBody();
      endExit(el);

      expect(document.activeElement).toBe($("#show-2"));
    });
  });

  describe("it never climbs, and the parent as a last resort (R7.d, R7.g)", () => {
    it("sidebar, main and footer: the emptied list takes focus with a lent tabindex, nothing else is touched", () => {
      document.body.innerHTML = `
        <div id="root" data-phx-session="s">
          <aside><nav><a href="/" id="logo">Home</a></nav></aside>
          <main id="main">
            <h1>Invoices</h1>
            <ul id="list"><li id="row-1"><button type="button" id="delete-1">Delete</button></li></ul>
            ${dialogHtml("d")}
          </main>
          <footer><a href="/privacy" id="privacy">Privacy</a></footer>
        </div>`;
      const el = stubDialog($("#d"));
      const hook = mountHook("PetalAlertDialog", el);
      $("#delete-1").focus();
      keyboard();
      openWith(el);
      confirm(el);
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).toBe($("#list"));
      expect($("#list").getAttribute("tabindex")).toBe("-1");
      expect(document.querySelectorAll("[tabindex]")).toHaveLength(1);
      expect(hook.focusArmed).toBe(false);
      $("#logo").focus();
      expect($("#list").hasAttribute("tabindex")).toBe(false);
    });

    it("the only row removed: the table body takes focus, never the button beside the table, and it disarms", () => {
      const { el, hook } = tableWithOutsideDialog(1);
      $("#delete-1").focus();
      keyboard();
      openWith(el);

      confirm(el);
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).toBe($("#rows"));
      expect($("#rows").getAttribute("tabindex")).toBe("-1");
      expect(hook.focusArmed).toBe(false);
      expect(hook.opener).toBe(null);
      $("#add").focus();
      expect($("#rows").hasAttribute("tabindex")).toBe(false);
    });

    it("a parent with its own tabindex keeps it after taking focus", () => {
      render(`
        <table><tbody id="rows" tabindex="0">${rowsHtml(1)}</tbody></table>
        <button type="button" id="add">New invoice</button>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#delete-1").focus();
      keyboard();
      openWith(el);
      confirm(el);
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).toBe($("#rows"));
      $("#add").focus();
      expect($("#rows").getAttribute("tabindex")).toBe("0");
    });

    it("a parent that refuses focus gets its lent tabindex back at once", () => {
      refuseFocus((n) => n.id === "list");
      render(`
        <ul id="list"><li id="row-1"><button type="button" id="delete-1">Delete</button></li></ul>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#delete-1").focus();
      keyboard();
      openWith(el);
      confirm(el);
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).not.toBe($("#list"));
      expect($("#list").hasAttribute("tabindex")).toBe(false);
    });
  });

  describe("menus that hide (R7.d, R8)", () => {
    // The real <.dropdown> hides its options with JS.hide: an inline
    // display:none, never the hidden attribute.
    const engines = {
      "with checkVisibility": () => {
        Element.prototype.checkVisibility = function () {
          return !inDisplayNone(this);
        };
      },
      "without checkVisibility (Safari before 17.4)": () => {},
    };

    for (const [engine, setUp] of Object.entries(engines)) {
      it(`an opener in a menu that hides (display:none, ${engine}): the menu's own trigger, no tabindex left`, () => {
        setUp();
        refuseFocus(inDisplayNone);
        render(`
          <div id="dropdown">
            <button type="button" id="menu-button">Actions</button>
            <div id="menu">
              <button type="button" id="item-edit">Edit</button>
              <button type="button" id="item-delete">Delete</button>
            </div>
          </div>
          ${dialogHtml("d")}`);
        const el = stubDialog($("#d"));
        mountHook("PetalAlertDialog", el);

        $("#item-delete").focus();
        keyboard();
        openWith(el, { dispatcher: $("#item-delete") });
        $("#menu").style.display = "none";
        confirm(el);
        endExit(el);

        expect(document.activeElement).toBe($("#menu-button"));
        expect(document.querySelector("[tabindex]")).toBe(null);
      });

      it(`a menu item that is no control, in a menu that hides (${engine}): still the menu's own trigger`, () => {
        setUp();
        refuseFocus(inDisplayNone);
        render(`
          <div id="dropdown">
            <button type="button" id="menu-button">Actions</button>
            <div id="menu"><div id="item-delete" role="menuitem">Delete</div></div>
          </div>
          ${dialogHtml("d")}`);
        const el = stubDialog($("#d"));
        mountHook("PetalAlertDialog", el);

        pointerDown($("#item-delete"));
        toBody();
        openWith(el, { dispatcher: $("#item-delete") });
        $("#menu").style.display = "none";
        keyDown("Enter");
        confirm(el);
        endExit(el);

        expect(document.activeElement).toBe($("#menu-button"));
      });
    }

    it("a hidden opener is never given focus back, even by an engine that would take it", () => {
      // jsdom focuses a display:none button; a browser refuses. Only the
      // native close's focus() (no options) is refused here, so the hook's
      // own focus would succeed: it must not depend on the engine refusing.
      const realFocus = HTMLElement.prototype.focus;
      vi.spyOn(HTMLElement.prototype, "focus").mockImplementation(
        function (opts) {
          if (opts === undefined && inDisplayNone(this)) return;
          realFocus.call(this, opts);
        },
      );
      render(`
        <div id="dropdown">
          <button type="button" id="menu-button">Actions</button>
          <div id="menu"><button type="button" id="item-delete">Delete</button></div>
        </div>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#item-delete").focus();
      keyboard();
      openWith(el, { dispatcher: $("#item-delete") });
      $("#menu").style.display = "none";
      confirm(el);
      endExit(el);

      expect(document.activeElement).toBe($("#menu-button"));
    });

    it("a hidden part starts with the child after itself", () => {
      refuseFocus(inDisplayNone);
      render(`
        <div id="toolbar">
          <button type="button" id="before">Before</button>
          <div id="menu"><button type="button" id="item-delete">Delete</button></div>
          <button type="button" id="after">After</button>
        </div>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#item-delete").focus();
      keyboard();
      openWith(el);
      $("#menu").style.display = "none";
      confirm(el);
      endExit(el);

      expect(document.activeElement).toBe($("#after"));
    });

    it("a row actions menu that hides: the menu's trigger, then on to the next row's when the row goes", () => {
      refuseFocus(inDisplayNone);
      const row = (n) => `
        <tr id="row-${n}"><td>
          <div id="dropdown-${n}">
            <button type="button" id="menu-button-${n}">Actions</button>
            <div id="menu-${n}"><button type="button" id="item-delete-${n}">Delete</button></div>
          </div>
          ${dialogHtml(`d${n}`)}
        </td></tr>`;
      render(`<table><tbody id="rows">${row(1)}${row(2)}</tbody></table>`);
      const el = stubDialog($("#d1"));
      const hook = mountHook("PetalAlertDialog", el);

      $("#item-delete-1").focus();
      keyboard();
      openWith(el, { dispatcher: $("#item-delete-1") });
      $("#menu-1").style.display = "none";
      confirm(el);
      endExit(el);
      expect(document.activeElement).toBe($("#menu-button-1"));

      removeRow("row-1", [hook]);

      expect(document.activeElement).toBe($("#menu-button-2"));
    });

    it("an aria-hidden row is skipped", () => {
      render(`
        <table><tbody id="rows">
          ${rowsHtml(1)}
          <tr id="row-2" aria-hidden="true"><td><button type="button" id="delete-2">Delete</button></td></tr>
          <tr id="row-3"><td><button type="button" id="delete-3">Delete</button></td></tr>
        </tbody></table>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#delete-1").focus();
      keyboard();
      openWith(el);
      confirm(el);
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).toBe($("#delete-3"));
    });

    it("a row whose only control is a <details> menu: its <summary>", () => {
      // A closed <details> renders only its summary (Chrome's checkVisibility
      // says so); jsdom does not know, so the stub does.
      const insideClosedDetails = (n) => {
        const details = n.closest("details:not([open])");
        return !!details && n !== details.querySelector("summary");
      };
      Element.prototype.checkVisibility = function () {
        return !insideClosedDetails(this);
      };
      refuseFocus(insideClosedDetails);
      render(`
        <table><tbody id="rows">
          ${[1, 2]
            .map(
              (n) =>
                `<tr id="row-${n}"><td><details id="menu-${n}"><summary id="sum-${n}">Actions</summary><button type="button" id="in-${n}">Delete</button></details></td></tr>`,
            )
            .join("")}
        </tbody></table>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#menu-1").open = true;
      $("#in-1").focus();
      keyboard();
      openWith(el, { dispatcher: $("#in-1") });
      confirm(el);
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).toBe($("#sum-2"));
    });

    it("a contenteditable is a control (jsdom reports its tabIndex as -1, so only the attribute counts)", () => {
      render(`
        <ul id="list">
          <li id="row-1"><button type="button" id="delete-1">Delete</button></li>
          <li id="row-2"><div contenteditable="true" id="note-2">Note</div></li>
        </ul>
        ${dialogHtml("d")}`);
      const el = stubDialog($("#d"));
      mountHook("PetalAlertDialog", el);
      $("#delete-1").focus();
      keyboard();
      openWith(el);
      confirm(el);
      removeRow("row-1");
      endExit(el);

      expect(document.activeElement).toBe($("#note-2"));
    });
  });

  describe("how focus is given (R1, R7.f)", () => {
    it("every focus asks for the ring and no page scroll: a walked landing, an opener restore, the parent", () => {
      const seen = recordFocus();
      const [row1, row2] = tableWithDialogInRows(2);
      keyboard();
      // opener restore: the trigger named it, nothing had focus
      toBody();
      click($("#delete-1"));
      cancel(row1.el);
      endExit(row1.el);
      // walked landing
      $("#delete-1").focus();
      click($("#delete-1"));
      confirm(row1.el);
      removeRow("row-1", [row1.hook, row1.trigger]);
      expect(document.activeElement).toBe($("#delete-2"));
      // the parent
      click($("#delete-2"));
      confirm(row2.el);
      removeRow("row-2", [row2.hook, row2.trigger]);
      expect(document.activeElement).toBe($("#rows"));

      const ours = seen.filter(([, opts]) => opts?.preventScroll);
      expect(ours.map(([id]) => id)).toEqual(["delete-1", "delete-2", "rows"]);
      for (const [, opts] of ours)
        expect(opts).toEqual({ preventScroll: true, focusVisible: true });
    });

    it("scrollIntoView, nearest/nearest, once on a walked landing; never on an opener restore or the parent", () => {
      const scrolled = [];
      Element.prototype.scrollIntoView = function (opts) {
        scrolled.push([this.id, opts]);
      };
      const [row1, row2] = tableWithDialogInRows(2);
      keyboard();
      toBody();
      click($("#delete-1"));
      cancel(row1.el);
      endExit(row1.el);
      expect(document.activeElement).toBe($("#delete-1"));
      expect(scrolled).toEqual([]);

      click($("#delete-1"));
      confirm(row1.el);
      removeRow("row-1", [row1.hook, row1.trigger]);
      expect(scrolled).toEqual([
        ["delete-2", { block: "nearest", inline: "nearest" }],
      ]);

      click($("#delete-2"));
      confirm(row2.el);
      removeRow("row-2", [row2.hook, row2.trigger]);
      expect(document.activeElement).toBe($("#rows"));
      expect(scrolled).toHaveLength(1);
    });
  });
});
