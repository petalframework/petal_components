// PetalDataTable hook: link-mode wiring for quick search and rows-per-page.
// The markup here mirrors what PetalComponents.DataTable renders in link
// mode - test/petal/data_table_test.exs pins that structure on the Elixir
// side; update both together if the anatomy changes.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import hooks from "../../assets/js/petal_components.js";

const mounted = [];

function mount({ searchTemplate, pageSizeTemplate, debounce } = {}) {
  const el = document.createElement("div");
  el.id = "dt";
  el.className = "pc-data-table";
  if (searchTemplate) el.dataset.searchTemplate = searchTemplate;
  if (pageSizeTemplate) el.dataset.pageSizeTemplate = pageSizeTemplate;
  if (debounce) el.dataset.debounce = debounce;
  el.innerHTML = `
    <a data-pc-dt-nav data-phx-link="patch" data-phx-link-state="push" hidden></a>
    <input type="text" data-pc-dt-search />
    <select data-pc-dt-page-size>
      <option value="10">10</option>
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

  it("debounces typing, then patches the :term template with the encoded value", () => {
    const { el, patched } = mount({
      searchTemplate: "/orders?search=:term&order_by=name",
      debounce: "300",
    });

    type(el, "a");
    type(el, "am y");
    expect(patched).toEqual([]);

    vi.advanceTimersByTime(299);
    expect(patched).toEqual([]);
    vi.advanceTimersByTime(1);
    expect(patched).toEqual(["/orders?search=am%20y&order_by=name"]);
  });

  it("a blank term drops the search param and any dangling joiner", () => {
    const { el, patched } = mount({ searchTemplate: "/orders?search=:term" });
    type(el, "   ");
    vi.advanceTimersByTime(300);
    expect(patched).toEqual(["/orders"]);

    const withRest = mount({
      searchTemplate: "/orders?search=:term&page_size=20",
    });
    type(withRest.el, "");
    vi.advanceTimersByTime(300);
    expect(withRest.patched).toEqual(["/orders?page_size=20"]);
  });

  it("page-size changes patch immediately, no debounce", () => {
    const { el, patched } = mount({
      pageSizeTemplate: "/orders?page_size=:page_size",
    });
    const select = el.querySelector("[data-pc-dt-page-size]");
    select.value = "20";
    select.dispatchEvent(new Event("change", { bubbles: true }));
    expect(patched).toEqual(["/orders?page_size=20"]);
  });

  it("destroyed cancels a pending search patch", () => {
    const { hook, el, patched } = mount({
      searchTemplate: "/orders?search=:term",
    });
    type(el, "amy");
    hook.destroyed();
    mounted.splice(mounted.indexOf(hook), 1);
    vi.advanceTimersByTime(300);
    expect(patched).toEqual([]);
    el.remove();
  });
});
