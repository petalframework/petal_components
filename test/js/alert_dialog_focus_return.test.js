// Where focus goes when an alert dialog closes and the element that opened
// it is gone: the Delete button of a table row that the confirm deleted
// (a LiveView stream delete removes the whole <tr>). The native close only
// restores focus to an opener that is still in the page, so without help
// focus falls to <body> and a keyboard or screen reader user loses their
// place.
//
// Half of these specs guard the other direction: focus the user or the
// browser put somewhere is never taken, a live navigation's teardown moves
// nothing, and an idle dialog listens to nothing at document level.
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
const openWith = (el, detail) =>
  el.dispatchEvent(new CustomEvent("pc:alert-dialog-open", { detail }));
const pointerDown = (el) =>
  el.dispatchEvent(new Event("pointerdown", { bubbles: true }));
const keyDown = (key) =>
  document.dispatchEvent(new KeyboardEvent("keydown", { key, bubbles: true }));
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

describe("PetalAlertDialog focus return when the opener is removed", () => {
  afterEach(() => {
    vi.restoreAllMocks();
    live.splice(0).forEach((h) => h.destroyed());
    document.body.innerHTML = "";
  });

  it("row removed while the exit plays: focus goes to the next row", () => {
    const { el } = tableWithOutsideDialog();
    $("#delete-1").focus();
    openWith(el);

    confirm(el);
    removeRow("row-1");
    endExit(el);

    expect(document.activeElement).toBe($("#delete-2"));
  });

  it("the last row removed: focus goes to the row before it", () => {
    const { el } = tableWithOutsideDialog();
    $("#delete-2").focus();
    openWith(el);

    confirm(el);
    removeRow("row-2");
    endExit(el);

    expect(document.activeElement).toBe($("#delete-1"));
  });

  it("the only row removed: focus goes one level up, to what sits beside the table", () => {
    const { el } = tableWithOutsideDialog(1);
    $("#delete-1").focus();
    openWith(el);

    confirm(el);
    removeRow("row-1");
    endExit(el);

    // the table's previous sibling; the closed dialog after it is skipped
    expect(document.activeElement).toBe($("#add"));
    expect(document.querySelector("[tabindex]")).toBe(null);
  });

  it("the only row removed with nothing beside it: the surviving container takes focus, and tidies up after", () => {
    render(`
      <table><tbody id="rows">${rowsHtml(1)}</tbody></table>
      ${dialogHtml("d")}`);
    const el = stubDialog($("#d"));
    mountHook("PetalAlertDialog", el);
    document.body.insertAdjacentHTML(
      "beforeend",
      `<button type="button" id="add">Outside the page wrapper</button>`,
    );
    $("#delete-1").focus();
    openWith(el);

    confirm(el);
    removeRow("row-1");
    endExit(el);

    expect(document.activeElement).toBe($("#rows"));
    expect($("#rows").getAttribute("tabindex")).toBe("-1");
    $("#add").focus();
    expect($("#rows").hasAttribute("tabindex")).toBe(false);
  });

  it("the Pro shape: close finishes, THEN the row (with the dialog in it) is removed", () => {
    const [row1] = tableWithDialogInRows();
    $("#delete-1").focus();
    click($("#delete-1"));

    confirm(row1.el);
    endExit(row1.el);
    // the native close put focus back on the opener
    expect(document.activeElement).toBe($("#delete-1"));

    removeRow("row-1", [row1.hook, row1.trigger]);

    expect(document.activeElement).toBe($("#show-2"));
  });

  it("the Pro shape: the row is removed while the dialog is still open", () => {
    const [row1] = tableWithDialogInRows();
    $("#delete-1").focus();
    click($("#delete-1"));
    confirm(row1.el);

    removeRow("row-1", [row1.hook, row1.trigger]);

    expect(document.activeElement).toBe($("#show-2"));
  });

  it("an opener still in the page keeps its focus: nothing else is touched", () => {
    const { el } = tableWithOutsideDialog();
    $("#delete-1").focus();
    openWith(el);

    cancel(el);
    endExit(el);

    expect(document.activeElement).toBe($("#delete-1"));
    expect(document.querySelector("[tabindex]")).toBe(null);
  });

  it("focus the user has moved on with is left alone when the row goes later", () => {
    const [row1] = tableWithDialogInRows();
    $("#delete-1").focus();
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
    click($("#delete-1"));
    confirm(row1.el);
    endExit(row1.el);

    // Tab on to another control, which a later patch removes
    $("#elsewhere").focus();
    $("#elsewhere").remove();
    removeRow("row-1", [row1.hook, row1.trigger]);

    expect(document.activeElement).toBe(document.body);
  });

  it("the trigger names the clicked button, so a click that focused nothing (Safari) still returns focus", () => {
    const [row1] = tableWithDialogInRows();
    // Safari does not focus a button on click: activeElement stays <body>
    toBody();
    click($("#delete-1"));
    expect(row1.el.open).toBe(true);

    cancel(row1.el);
    endExit(row1.el);

    expect(document.activeElement).toBe($("#delete-1"));
  });

  it("Safari shape, confirm: focus goes back to the living opener, then on to the next row when the row goes", () => {
    const [row1] = tableWithDialogInRows();
    toBody();
    click($("#delete-1"));

    confirm(row1.el);
    endExit(row1.el);
    expect(document.activeElement).toBe($("#delete-1"));

    removeRow("row-1", [row1.hook, row1.trigger]);
    expect(document.activeElement).toBe($("#show-2"));
  });

  it("a live navigation's teardown (the page still connected) moves nothing", () => {
    const [row1, row2] = tableWithDialogInRows();
    $("#delete-1").focus();
    click($("#delete-1"));
    confirm(row1.el);
    endExit(row1.el);
    // the click that starts the navigation blurs to <body>
    toBody();

    // LiveView destroys every hook while the old page is still in the DOM
    destroy([row1.hook, row1.trigger, row2.hook, row2.trigger]);

    expect(document.activeElement).toBe(document.body);
  });

  it("a pointerdown elsewhere that focuses nothing disarms it: a later removal moves nothing", () => {
    const [row1, row2] = tableWithDialogInRows();
    $("#delete-1").focus();
    click($("#delete-1"));
    confirm(row1.el);
    endExit(row1.el);

    // a mouse click on a plain table cell (or any click in Safari)
    pointerDown($("#row-2 td"));
    toBody();
    removeRow("row-1", [row1.hook, row1.trigger]);

    expect(document.activeElement).toBe(document.body);
    expect(row2.el.open).toBe(false);
  });

  it("a Cancel that ends on the living opener disarms it: a later removal moves nothing", () => {
    const [row1] = tableWithDialogInRows();
    $("#delete-1").focus();
    click($("#delete-1"));
    cancel(row1.el);
    endExit(row1.el);
    expect(document.activeElement).toBe($("#delete-1"));

    // the row goes later for an unrelated reason (a filter, another user)
    removeRow("row-1", [row1.hook, row1.trigger]);

    expect(document.activeElement).toBe(document.body);
  });

  it("Escape closes through the same cancel path and disarms the same way", () => {
    const [row1] = tableWithDialogInRows();
    $("#delete-1").focus();
    click($("#delete-1"));
    row1.el.dispatchEvent(new Event("cancel", { cancelable: true }));
    endExit(row1.el);
    expect(document.activeElement).toBe($("#delete-1"));

    removeRow("row-1", [row1.hook, row1.trigger]);

    expect(document.activeElement).toBe(document.body);
  });

  it("a shared dialog opened from row 3 after an earlier open from row 1 goes to row 4", () => {
    const { el } = tableWithOutsideDialog(4);
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

  it("an open with neither opener nor dispatcher uses activeElement, and never an earlier opener", () => {
    const { el } = tableWithOutsideDialog(3);
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
    const { el } = tableWithOutsideDialog(3);
    $("#delete-1").focus();
    openWith(el, {});
    cancel(el);
    endExit(el);

    toBody();
    openWith(el, {});
    confirm(el);
    removeRow("row-1");
    endExit(el);

    // Left where the native close leaves it (<body> in a browser, a hidden
    // button in this stub), not sent to row 1's neighbour.
    expect(document.activeElement).not.toBe($("#delete-2"));
    const active = document.activeElement;
    expect(active === document.body || el.contains(active)).toBe(true);
  });

  it("reopening from the same button after a row was inserted uses the rows as they are now", () => {
    const { el } = tableWithOutsideDialog(3);
    $("#delete-2").focus();
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

  it("an opener in a menu that hides: focus goes to the menu's own trigger, and no tabindex is left behind", () => {
    // jsdom lets hidden elements take focus; real browsers do not.
    const realFocus = HTMLElement.prototype.focus;
    vi.spyOn(HTMLElement.prototype, "focus").mockImplementation(function (opts) {
      if (this.closest("[hidden]")) return;
      realFocus.call(this, opts);
    });
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
    openWith(el, { dispatcher: $("#item-delete") });
    $("#menu").hidden = true;
    confirm(el);
    endExit(el);

    expect(document.activeElement).toBe($("#menu-button"));
    expect(document.querySelector("[tabindex]")).toBe(null);
  });

  it("a container that refuses focus gets no stray tabindex", () => {
    const realFocus = HTMLElement.prototype.focus;
    vi.spyOn(HTMLElement.prototype, "focus").mockImplementation(function (opts) {
      if (this.closest("[hidden]")) return;
      realFocus.call(this, opts);
    });
    render(`
      <section id="panel">
        <div id="menu"><button type="button" id="item-delete">Delete</button></div>
      </section>
      ${dialogHtml("d")}`);
    const el = stubDialog($("#d"));
    mountHook("PetalAlertDialog", el);

    $("#item-delete").focus();
    openWith(el);
    $("#panel").hidden = true;
    confirm(el);
    endExit(el);

    expect($("#menu").hasAttribute("tabindex")).toBe(false);
    expect($("#panel").hasAttribute("tabindex")).toBe(false);
  });

  it("skips the next row's own closed dialog and lands on its first real control", () => {
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
    openWith(el);
    confirm(el);
    removeRow("row-1");
    endExit(el);

    expect(document.activeElement).toBe($("#show-2"));
  });

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
    click($("#bulk-delete"));
    confirm(el);
    endExit(el);
    removeRow("bulk-bar", [hook, trigger]);

    expect(document.activeElement).toBe($("#delete-1"));
  });

  it("a keyboard open restores with a focus ring, a mouse open without, never scrolling", () => {
    const seen = [];
    const realFocus = HTMLElement.prototype.focus;
    vi.spyOn(HTMLElement.prototype, "focus").mockImplementation(function (opts) {
      if (this.id === "delete-2") seen.push(opts);
      realFocus.call(this, opts);
    });

    // keyboard: Tab to the button, Enter
    let { el } = tableWithOutsideDialog(3);
    $("#delete-1").focus();
    keyDown("Enter");
    openWith(el);
    confirm(el);
    removeRow("row-1");
    endExit(el);
    expect(document.activeElement).toBe($("#delete-2"));

    // mouse
    pointerDown($("#delete-3"));
    $("#delete-3").focus();
    openWith(el);
    confirm(el);
    removeRow("row-3");
    endExit(el);
    expect(document.activeElement).toBe($("#delete-2"));

    expect(seen).toEqual([
      { preventScroll: true, focusVisible: true },
      { preventScroll: true, focusVisible: false },
    ]);
  });

  it("an idle dialog adds no document listeners; an open adds them and the close-out removes them", () => {
    const added = vi.spyOn(document, "addEventListener");
    const removed = vi.spyOn(document, "removeEventListener");
    const { el } = tableWithOutsideDialog();
    const focusins = (spy) =>
      spy.mock.calls.filter(([type]) => type === "focusin").length;
    expect(focusins(added)).toBe(0);

    $("#delete-1").focus();
    openWith(el);
    expect(focusins(added)).toBe(1);

    cancel(el);
    endExit(el);
    expect(focusins(removed)).toBe(1);
  });
});
