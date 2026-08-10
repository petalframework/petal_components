// PetalDataTable hook: link-mode wiring for quick search and rows-per-page.
// The markup here mirrors what PetalComponents.DataTable renders in link
// mode - test/petal/data_table_test.exs pins that structure on the Elixir
// side; update both together if the anatomy changes.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import hooks from "../../assets/js/petal_components.js";

const mounted = [];

function mountBase({ navTemplate, debounce } = {}) {
  const el = document.createElement("div");
  el.id = "dt";
  el.className = "pc-data-table";
  if (navTemplate) el.dataset.navTemplate = navTemplate;
  if (debounce) el.dataset.debounce = debounce;
  el.innerHTML = `
    <a data-pc-dt-nav data-phx-link="patch" data-phx-link-state="push" hidden></a>
    <input type="text" data-pc-dt-search />
    <select data-pc-dt-page-size>
      <option value="10" selected>10</option>
      <option value="20">20</option>
    </select>
  `;
  document.body.appendChild(el);

  const hook = Object.create(hooks.PetalDataTable);
  hook.el = el;
  hook.mounted();
  mounted.push(hook);

  const patched = [];
  el.querySelector("[data-pc-dt-nav]").addEventListener("click", (e) => {
    e.preventDefault();
    patched.push(e.target.getAttribute("href"));
  });

  return { hook, el, patched };
}

const mount = mountBase;

function mountWithFilter({ navTemplate, filters, formHtml }) {
  const { hook, el, patched } = mountBase({ navTemplate });
  if (filters) el.dataset.filters = JSON.stringify(filters);

  // the in-page menu anatomy: trigger and panel as siblings under a
  // relatively positioned wrapper, panel hidden until the hook shows it
  const anchor = document.createElement("div");
  anchor.className = "pc-popover";
  anchor.innerHTML = `
    <button type="button" data-pc-menu-trigger="pop" aria-expanded="false">Filter</button>
    <div id="pop" class="pc-popover__panel" data-pc-menu hidden></div>
  `;
  el.appendChild(anchor);
  const panel = anchor.querySelector("#pop");
  panel.innerHTML = formHtml;

  return {
    hook,
    el,
    patched,
    panel,
    trigger: anchor.querySelector("button"),
    form: panel.querySelector("form"),
  };
}

// pointer gestures: jsdom has no PointerEvent, but a MouseEvent named
// "pointerdown"/"pointerup" carries the clientX/Y the hook reads
function pointer(type, target, x = 0, y = 0, pointerId = 1) {
  const event = new MouseEvent(type, { bubbles: true, clientX: x, clientY: y });
  // jsdom's MouseEvent has no pointerId, and the hook keys presses by it
  Object.defineProperty(event, "pointerId", { value: pointerId });
  target.dispatchEvent(event);
}

function tapOutside(x = 5, y = 5) {
  pointer("pointerdown", document.body, x, y);
  pointer("pointerup", document.body, x, y);
}

function submit(form) {
  form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
}

function type(el, value) {
  const input = el.querySelector("[data-pc-dt-search]");
  input.value = value;
  input.dispatchEvent(new Event("input", { bubbles: true }));
}

describe("PetalDataTable", () => {
  beforeEach(() => vi.useFakeTimers());

  afterEach(() => {
    mounted.splice(0).forEach((hook) => {
      hook.destroyed();
      hook.el.remove();
    });
    vi.useRealTimers();
  });

  it("debounces typing, then patches with the encoded term and current page size", () => {
    const { el, patched } = mount({
      navTemplate: "/orders?search=:term&page_size=:page_size&order_by=name",
      debounce: "300",
    });

    type(el, "a");
    type(el, "am y");
    expect(patched).toEqual([]);

    vi.advanceTimersByTime(299);
    expect(patched).toEqual([]);
    vi.advanceTimersByTime(1);
    expect(patched).toEqual([
      "/orders?search=am%20y&page_size=10&order_by=name",
    ]);
  });

  it("a blank term drops the search param and any dangling joiner", () => {
    const { el, patched } = mount({ navTemplate: "/orders?search=:term" });
    type(el, "   ");
    vi.advanceTimersByTime(300);
    expect(patched).toEqual(["/orders"]);

    const withRest = mount({
      navTemplate: "/orders?search=:term&order_by=name",
    });
    type(withRest.el, "");
    vi.advanceTimersByTime(300);
    expect(withRest.patched).toEqual(["/orders?order_by=name"]);
  });

  it("page-size changes patch immediately and carry the live search term", () => {
    const { el, patched } = mount({
      navTemplate: "/orders?search=:term&page_size=:page_size",
    });
    const input = el.querySelector("[data-pc-dt-search]");
    input.value = "amy";
    const select = el.querySelector("[data-pc-dt-page-size]");
    select.value = "20";
    select.dispatchEvent(new Event("change", { bubbles: true }));
    expect(patched).toEqual(["/orders?search=amy&page_size=20"]);
  });

  it("a page-size pick cancels a pending search patch instead of racing it", () => {
    const { el, patched } = mount({
      navTemplate: "/orders?search=:term&page_size=:page_size",
      debounce: "300",
    });

    type(el, "amy");
    vi.advanceTimersByTime(100);

    const select = el.querySelector("[data-pc-dt-page-size]");
    select.value = "20";
    select.dispatchEvent(new Event("change", { bubbles: true }));
    expect(patched).toEqual(["/orders?search=amy&page_size=20"]);

    // the debounced search patch must NOT fire a second, stale navigation
    vi.advanceTimersByTime(1000);
    expect(patched).toEqual(["/orders?search=amy&page_size=20"]);
  });

  it("filter apply replaces this field's committed entry and closes the popover", () => {
    const { hook, patched, form } = mountWithFilter({
      navTemplate: "/orders?:filters",
      filters: [
        { field: "email", op: "contains", value: "d" },
        { field: "amount", op: "gt", value: "5" },
      ],
      formHtml: `
        <form class="pc-data-table__filter-form" data-pc-dt-filter data-field="email">
          <select name="filter_op">
            <option value="contains">contains</option>
            <option value="starts_with" selected>starts with</option>
          </select>
          <input name="value" value="amy" />
        </form>
      `,
    });

    hook.toggleMenu("pop");
    submit(form);

    expect(patched).toHaveLength(1);
    const url = decodeURIComponent(patched[0]);
    expect(url).toContain("filters[0][field]=amount");
    expect(url).toContain("filters[1][field]=email");
    expect(url).toContain("filters[1][op]=starts_with");
    expect(url).toContain("filters[1][value]=amy");
    expect(hook.openMenu).toBe(null);
  });

  it("a select editor posts checked values as :in; none checked removes the filter", () => {
    const { patched, form } = mountWithFilter({
      navTemplate: "/orders?:filters&order_by=name",
      filters: [{ field: "status", op: "in", value: ["pending"] }],
      formHtml: `
        <form class="pc-data-table__filter-form" data-pc-dt-filter data-field="status">
          <input type="checkbox" name="values[]" value="paid" checked />
          <input type="checkbox" name="values[]" value="refunded" checked />
          <input type="checkbox" name="values[]" value="pending" />
        </form>
      `,
    });

    submit(form);
    const url = decodeURIComponent(patched[0]);
    expect(url).toContain("filters[0][value][]=paid");
    expect(url).toContain("filters[0][value][]=refunded");
    expect(url).not.toContain("pending");

    form.querySelectorAll("input:checked").forEach((i) => (i.checked = false));
    submit(form);
    expect(patched[1]).toBe("/orders?order_by=name");
  });

  it("a half-empty between range reads as removal", () => {
    const { patched, form } = mountWithFilter({
      navTemplate: "/orders?:filters",
      filters: [{ field: "amount", op: "between", value: ["1", "9"] }],
      formHtml: `
        <form class="pc-data-table__filter-form" data-pc-dt-filter data-field="amount">
          <select name="filter_op"><option value="between" selected>between</option></select>
          <input name="value" value="10" />
          <input name="value2" value="" />
        </form>
      `,
    });

    submit(form);
    expect(patched).toEqual(["/orders"]);
  });

  it("search patches carry the committed filters through :filters", () => {
    const { el, patched } = mountBase({
      navTemplate: "/orders?search=:term&:filters",
      debounce: "300",
    });
    el.dataset.filters = JSON.stringify([
      { field: "email", op: "contains", value: "d" },
    ]);

    type(el, "amy");
    vi.advanceTimersByTime(300);
    const url = decodeURIComponent(patched[0]);
    expect(url).toContain("search=amy");
    expect(url).toContain("filters[0][field]=email");
  });

  it("opens and closes a menu from its trigger, and on outside press and Escape", () => {
    const { hook, panel, trigger } = mountWithFilter({
      navTemplate: "/orders?:filters",
      filters: [],
      formHtml: `<form class="pc-data-table__filter-form"></form>`,
    });

    trigger.click();
    expect(hook.openMenu).toBe("pop");
    expect(panel.hidden).toBe(false);
    expect(trigger.getAttribute("aria-expanded")).toBe("true");

    trigger.click(); // same trigger toggles shut
    expect(hook.openMenu).toBe(null);
    expect(trigger.getAttribute("aria-expanded")).toBe("false");

    trigger.click();
    tapOutside();
    expect(hook.openMenu).toBe(null);

    trigger.click();
    const escape = new KeyboardEvent("keydown", {
      key: "Escape",
      bubbles: true,
    });
    panel.dispatchEvent(escape);
    expect(hook.openMenu).toBe(null);
    expect(document.activeElement).toBe(trigger);
  });

  it("keeps an open menu open across a patch that restores `hidden`", () => {
    const { hook, panel, trigger } = mountWithFilter({
      navTemplate: "/orders?:filters",
      filters: [],
      formHtml: `<form class="pc-data-table__filter-form"></form>`,
    });

    trigger.click();
    expect(panel.hidden).toBe(false);

    // what a LiveView patch does: server markup wins, so `hidden` is back
    panel.hidden = true;
    panel.removeAttribute("data-pc-open");
    hook.updated();

    expect(panel.hidden).toBe(false);
    expect(panel.hasAttribute("data-pc-open")).toBe(true);
    expect(hook.openMenu).toBe("pop");
  });

  it("survives a drag on the page - only a tap outside dismisses", () => {
    const { hook, trigger } = mountWithFilter({
      navTemplate: "/orders?:filters",
      filters: [],
      formHtml: `<form class="pc-data-table__filter-form"></form>`,
    });

    // dragging the page to scroll it: press outside, move, release far away
    trigger.click();
    pointer("pointerdown", document.body, 100, 400);
    pointer("pointerup", document.body, 100, 180);
    expect(hook.openMenu).toBe("pop");

    // a gesture the browser hands to the scroller never releases at all
    pointer("pointerdown", document.body, 100, 400);
    pointer("pointercancel", document.body, 100, 400);
    pointer("pointerup", document.body, 100, 120);
    expect(hook.openMenu).toBe("pop");

    // and a real tap still dismisses
    tapOutside(100, 400);
    expect(hook.openMenu).toBe(null);
  });

  it("ignores multi-finger gestures outside the panel", () => {
    const { hook, trigger } = mountWithFilter({
      navTemplate: "/orders?:filters",
      filters: [],
      formHtml: `<form class="pc-data-table__filter-form"></form>`,
    });

    trigger.click();

    // a pinch: two fingers land, both lift roughly where they started
    pointer("pointerdown", document.body, 100, 400, 1);
    pointer("pointerdown", document.body, 200, 400, 2);
    pointer("pointerup", document.body, 100, 401, 1);
    pointer("pointerup", document.body, 200, 401, 2);
    expect(hook.openMenu).toBe("pop");

    // one finger cancelling must not disarm a later single-finger tap
    pointer("pointerdown", document.body, 100, 400, 3);
    pointer("pointercancel", document.body, 100, 400, 3);
    tapOutside(100, 400);
    expect(hook.openMenu).toBe(null);
  });

  it("does not dismiss when a press outside releases inside the panel", () => {
    const { hook, panel, trigger } = mountWithFilter({
      navTemplate: "/orders?:filters",
      filters: [],
      formHtml: `<form class="pc-data-table__filter-form"></form>`,
    });

    trigger.click();
    pointer("pointerdown", document.body, 10, 10);
    pointer("pointerup", panel, 10, 10);
    expect(hook.openMenu).toBe("pop");
  });

  it("hides a panel that loses focus to a sibling inside the fade window", () => {
    const { hook, el, panel, trigger } = mountWithFilter({
      navTemplate: "/orders?:filters",
      filters: [],
      formHtml: `<form class="pc-data-table__filter-form"></form>`,
    });

    // a second menu in the same table
    const other = document.createElement("div");
    other.className = "pc-popover";
    other.innerHTML = `
      <button type="button" data-pc-menu-trigger="pop2" aria-expanded="false">Other</button>
      <div id="pop2" class="pc-popover__panel" data-pc-menu hidden></div>
    `;
    el.appendChild(other);

    trigger.click();
    expect(panel.hidden).toBe(false);

    // switch menus well inside the 120ms fade
    vi.advanceTimersByTime(40);
    other.querySelector("button").click();
    expect(hook.openMenu).toBe("pop2");

    vi.advanceTimersByTime(200);

    // the first panel must be out of the layout, not merely transparent -
    // an invisible panel still swallows taps
    expect(panel.hidden).toBe(true);
    expect(document.getElementById("pop2").hidden).toBe(false);
  });

  it("never repositions on scroll - the page carries the panel", () => {
    const { hook, trigger } = mountWithFilter({
      navTemplate: "/orders?:filters",
      filters: [],
      formHtml: `<form class="pc-data-table__filter-form"></form>`,
    });

    trigger.click();

    let aligns = 0;
    const real = hook.alignMenu.bind(hook);
    hook.alignMenu = () => {
      aligns += 1;
      real();
    };

    // scroll the world in every way the old implementation listened for
    window.dispatchEvent(new Event("scroll"));
    document.dispatchEvent(new Event("scroll", { bubbles: true }));
    if (window.visualViewport) {
      window.visualViewport.dispatchEvent?.(new Event("scroll"));
    }

    // this is the architecture, pinned: nothing recomputes on scroll,
    // so there is nothing to lag behind the page
    expect(aligns).toBe(0);

    // a resize is the one thing that does invalidate the geometry
    window.dispatchEvent(new Event("resize"));
    expect(aligns).toBe(1);
  });

  it("event mode: submit closes the menu without intercepting or navigating", () => {
    const { hook, patched, trigger, form } = mountWithFilter({
      navTemplate: undefined,
      filters: [],
      // no data-pc-dt-filter: event mode posts its own phx-submit
      formHtml: `<form class="pc-data-table__filter-form" phx-submit="table">
        <input name="value" value="x" />
      </form>`,
    });

    trigger.click();
    expect(hook.openMenu).toBe("pop");

    const e = new Event("submit", { bubbles: true, cancelable: true });
    form.dispatchEvent(e);

    expect(e.defaultPrevented).toBe(false);
    expect(patched).toEqual([]);
    expect(hook.openMenu).toBe(null);
  });

  it("mirrors the indeterminate stamp onto the DOM property on mount and update", () => {
    const { hook, el } = mountBase({});
    const box = document.createElement("input");
    box.type = "checkbox";
    box.dataset.pcDtIndeterminate = "true";
    box.setAttribute("data-pc-dt-indeterminate", "true");
    el.appendChild(box);

    hook.syncIndeterminate();
    expect(box.indeterminate).toBe(true);

    // a patch flips the stamp; updated() must mirror it back off
    box.dataset.pcDtIndeterminate = "false";
    hook.updated();
    expect(box.indeterminate).toBe(false);
  });

  it("destroyed cancels a pending search patch", () => {
    const { hook, el, patched } = mount({
      navTemplate: "/orders?search=:term",
    });
    type(el, "amy");
    hook.destroyed();
    mounted.splice(mounted.indexOf(hook), 1);
    vi.advanceTimersByTime(300);
    expect(patched).toEqual([]);
    el.remove();
  });
});
