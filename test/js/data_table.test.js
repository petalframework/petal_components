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
  const wrap = document.createElement("div");
  wrap.className = "pc-popover__panel";
  wrap.id = "pop";
  wrap.innerHTML = formHtml;
  el.appendChild(wrap);
  return { hook, el, patched, form: wrap.querySelector("form") };
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
    const { el, patched, form } = mountWithFilter({
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

    submit(form);

    expect(patched).toHaveLength(1);
    const url = decodeURIComponent(patched[0]);
    expect(url).toContain("filters[0][field]=amount");
    expect(url).toContain("filters[1][field]=email");
    expect(url).toContain("filters[1][op]=starts_with");
    expect(url).toContain("filters[1][value]=amy");
    expect(el.querySelector(".pc-popover__panel").style.display).toBe("none");
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

  it("closes a top-layer panel through the native popover API", () => {
    const { el, patched, form } = mountWithFilter({
      navTemplate: "/orders?:filters",
      filters: [],
      formHtml: `
        <form class="pc-data-table__filter-form" data-pc-dt-filter data-field="email">
          <select name="filter_op"><option value="contains" selected>contains</option></select>
          <input name="value" value="x" />
        </form>
      `,
    });

    const panel = el.querySelector(".pc-popover__panel");
    panel.setAttribute("popover", "auto");
    const hidden = [];
    panel.hidePopover = () => hidden.push(true);

    submit(form);
    expect(hidden).toEqual([true]);
    expect(patched).toHaveLength(1);
  });

  it("event mode: submit only closes the popover - no interception, no navigation", () => {
    const { el, patched } = mountBase({});
    delete el.dataset.navTemplate;
    const wrap = document.createElement("div");
    wrap.className = "pc-popover__panel";
    wrap.innerHTML = `
      <form class="pc-data-table__filter-form" phx-submit="table">
        <input name="value" value="x" />
      </form>
    `;
    el.appendChild(wrap);

    const form = wrap.querySelector("form");
    const e = new Event("submit", { bubbles: true, cancelable: true });
    form.dispatchEvent(e);

    expect(e.defaultPrevented).toBe(false);
    expect(patched).toEqual([]);
    expect(wrap.style.display).toBe("none");
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
