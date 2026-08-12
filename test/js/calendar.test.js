// PetalCalendar / PetalDatePicker hook behaviour.
//
// The markup built here mirrors what PetalComponents.Calendar and
// PetalComponents.DatePicker render - test/petal/calendar_test.exs and
// test/petal/date_picker_test.exs pin that structure on the Elixir side, so
// update both together if the anatomy changes.
//
// The contracts these specs exist to hold: exactly one tabbable day at a time,
// the full APG arrow map including the month rollovers the server has to render
// for, and a parse-on-blur that reverts rather than silently clearing a value.
import { afterEach, beforeEach, describe, expect, it } from "vitest";

import hooks from "../../assets/js/petal_components.js";

const mounted = [];

const MONTHS = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

const utc = (iso) => {
  const [y, m, d] = iso.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d));
};

const iso = (date) => date.toISOString().slice(0, 10);

const plus = (isoStr, n) => {
  const d = utc(isoStr);
  d.setUTCDate(d.getUTCDate() + n);
  return iso(d);
};

// Same grid maths the Elixir side does, so a fixture can never disagree with
// the real markup about which days are on screen.
function monthGrid(monthIso, startsOn) {
  const first = utc(monthIso);
  first.setUTCDate(1);
  const dow = first.getUTCDay() === 0 ? 7 : first.getUTCDay();
  const offset = (dow - startsOn + 7) % 7;
  const daysInMonth = new Date(
    Date.UTC(first.getUTCFullYear(), first.getUTCMonth() + 1, 0),
  ).getUTCDate();
  const rows = Math.ceil((offset + daysInMonth) / 7);
  const start = plus(iso(first), -offset);
  return Array.from({ length: rows * 7 }, (_, i) => plus(start, i));
}

const addMonthsIso = (monthIso, n) => {
  const d = utc(monthIso);
  d.setUTCDate(1);
  d.setUTCMonth(d.getUTCMonth() + n);
  return iso(d);
};

// Event mode renders a button carrying phx-value-month; link mode renders a
// patch anchor carrying the month query param. The hook has to retarget either.
const navMarkup = (direction, monthIso, linkNav) =>
  linkNav
    ? `<a data-pc-nav="${direction}" href="?month=${monthIso}" data-phx-link="patch"></a>`
    : `<button type="button" data-pc-nav="${direction}" phx-value-month="${monthIso}"></button>`;

function calendarMarkup({
  month = "2026-03-01",
  startsOn = 1,
  selectEvent = null,
  selected = null,
  disabled = [],
  linkNav = false,
  id = "cal",
} = {}) {
  const days = monthGrid(month, startsOn);
  const monthNumber = month.slice(0, 7);
  const focus = selected || days.find((d) => d.slice(0, 7) === monthNumber);

  const rows = [];
  for (let i = 0; i < days.length; i += 7) {
    const cells = days
      .slice(i, i + 7)
      .map((d) => {
        const outside = d.slice(0, 7) !== monthNumber;
        const off = disabled.includes(d);
        return `<td role="gridcell"${d === selected ? ' aria-selected="true"' : ""} class="pc-calendar__cell">
          <button type="button" class="pc-calendar__day" data-date="${d}"
            ${outside ? 'data-outside="true"' : ""} ${off ? 'data-disabled="true" aria-disabled="true"' : ""}
            tabindex="${d === focus ? "0" : "-1"}">${Number(d.slice(8))}</button>
        </td>`;
      })
      .join("");
    rows.push(`<tr role="row">${cells}</tr>`);
  }

  return `
    <div id="${id}" class="pc-calendar" data-month="${month}" data-starts-on="${startsOn}"
      ${selectEvent ? `data-select-event="${selectEvent}"` : ""}
      data-month-names="${MONTHS.join(",")}">
      <div class="pc-calendar__header">
        ${navMarkup("prev", addMonthsIso(month, -1), linkNav)}
        <div class="pc-calendar__caption">caption</div>
        ${navMarkup("next", addMonthsIso(month, 1), linkNav)}
      </div>
      <table role="grid"><tbody>${rows.join("")}</tbody></table>
    </div>
  `;
}

function mountCalendar(opts = {}) {
  const wrap = document.createElement("div");
  wrap.innerHTML = calendarMarkup(opts);
  document.body.appendChild(wrap);

  const el = wrap.querySelector(".pc-calendar");
  const hook = Object.create(hooks.PetalCalendar);
  hook.el = el;
  hook.mounted();
  mounted.push(hook);

  const navClicks = [];
  for (const nav of el.querySelectorAll("[data-pc-nav]")) {
    nav.addEventListener("click", (e) => {
      // jsdom cannot navigate, and a patch anchor would try
      e.preventDefault();
      navClicks.push(nav.dataset.pcNav);
    });
  }

  return {
    hook,
    el,
    wrap,
    navClicks,
    nav: (d) => el.querySelector(`[data-pc-nav="${d}"]`),
    day: (d) => el.querySelector(`[data-date="${d}"]`),
    tabbable: () => Array.from(el.querySelectorAll('[data-date][tabindex="0"]')),
    // Stand in for a LiveView patch: swap the grid for another month, then let
    // the hook's updated() put focus back where it asked for it.
    repaint: (opts2) => {
      const next = document.createElement("div");
      next.innerHTML = calendarMarkup({ ...opts, ...opts2 });
      el.replaceWith(next.firstElementChild);
      hook.el = wrap.querySelector(".pc-calendar");
      hook.grid = hook.el.querySelector('[role="grid"]');
      hook.updated();
    },
  };
}

function key(target, k, props = {}) {
  const ev = new KeyboardEvent("keydown", {
    key: k,
    bubbles: true,
    cancelable: true,
    ...props,
  });
  target.dispatchEvent(ev);
  return ev;
}

function pickerMarkup({
  mode = "single",
  format = "%Y-%m-%d",
  separator = " - ",
  selectEvent = null,
  value = "",
  display = "",
  clearable = false,
} = {}) {
  const hiddens =
    mode === "range"
      ? `<input type="hidden" data-pc-date-from value="${value}" />
         <input type="hidden" data-pc-date-to value="" />`
      : `<input type="hidden" data-pc-date-value value="${value}" />`;

  return `
    <div id="dp" class="pc-date-picker" data-mode="${mode}" data-format="${format}"
      data-range-separator="${separator}">
      <div class="pc-date-picker__control">
        <input type="text" id="dp-input" data-pc-date-input value="${display}" />
        ${clearable ? '<button type="button" data-pc-date-clear></button>' : ""}
        <button type="button" id="dp-toggle" data-pc-date-toggle></button>
      </div>
      ${hiddens}
      <div id="dp-panel" class="pc-date-picker__panel">
        ${calendarMarkup({ selectEvent, id: "dp-calendar" })}
      </div>
    </div>
  `;
}

function mountPicker(opts = {}) {
  const wrap = document.createElement("div");
  wrap.innerHTML = pickerMarkup(opts);
  document.body.appendChild(wrap);

  const el = wrap.querySelector(".pc-date-picker");
  const hook = Object.create(hooks.PetalDatePicker);
  hook.el = el;
  hook.mounted();
  mounted.push(hook);

  const changes = [];
  for (const hidden of el.querySelectorAll("input[type=hidden]")) {
    hidden.addEventListener("change", (e) => changes.push(e.target.value));
  }

  return {
    hook,
    el,
    changes,
    input: el.querySelector("[data-pc-date-input]"),
    hidden: (role) => el.querySelector(`[data-pc-date-${role}]`),
    day: (d) => el.querySelector(`[data-date="${d}"]`),
  };
}

beforeEach(() => {
  document.body.innerHTML = "";
});

afterEach(() => {
  mounted.splice(0).forEach((hook) => hook.destroyed());
  document.body.innerHTML = "";
});

describe("PetalCalendar roving tabindex", () => {
  it("starts with exactly one tabbable day", () => {
    const c = mountCalendar();
    expect(c.tabbable()).toHaveLength(1);
    expect(c.tabbable()[0].dataset.date).toBe("2026-03-01");
  });

  it("moves the tabbable day to whatever gains focus", () => {
    const c = mountCalendar();
    c.day("2026-03-12").dispatchEvent(new Event("focusin", { bubbles: true }));
    expect(c.tabbable()).toHaveLength(1);
    expect(c.tabbable()[0].dataset.date).toBe("2026-03-12");
  });
});

describe("PetalCalendar keyboard map", () => {
  it("arrows move by a day and by a week", () => {
    const c = mountCalendar();
    const cases = [
      ["ArrowRight", "2026-03-12", "2026-03-13"],
      ["ArrowLeft", "2026-03-12", "2026-03-11"],
      ["ArrowDown", "2026-03-12", "2026-03-19"],
      ["ArrowUp", "2026-03-12", "2026-03-05"],
    ];

    for (const [k, from, to] of cases) {
      key(c.day(from), k);
      expect(document.activeElement.dataset.date).toBe(to);
      expect(c.tabbable()[0].dataset.date).toBe(to);
    }
  });

  it("Home and End jump to the bounds of the week, Monday-first", () => {
    const c = mountCalendar();
    key(c.day("2026-03-12"), "Home");
    expect(document.activeElement.dataset.date).toBe("2026-03-09");
    key(c.day("2026-03-12"), "End");
    expect(document.activeElement.dataset.date).toBe("2026-03-15");
  });

  it("Home and End follow starts_on", () => {
    const c = mountCalendar({ startsOn: 7 });
    key(c.day("2026-03-12"), "Home");
    expect(document.activeElement.dataset.date).toBe("2026-03-08");
    key(c.day("2026-03-12"), "End");
    expect(document.activeElement.dataset.date).toBe("2026-03-14");
  });

  it("swallows Enter and Space on a disabled day but leaves enabled days alone", () => {
    const c = mountCalendar({ disabled: ["2026-03-05"] });

    for (const k of ["Enter", " "]) {
      expect(key(c.day("2026-03-05"), k).defaultPrevented).toBe(true);
      expect(key(c.day("2026-03-12"), k).defaultPrevented).toBe(false);
    }
  });

  it("ignores keys it does not own", () => {
    const c = mountCalendar();
    expect(key(c.day("2026-03-12"), "a").defaultPrevented).toBe(false);
  });
});

describe("PetalCalendar month paging", () => {
  it("PageUp and PageDown page the month and keep the day", () => {
    const c = mountCalendar();

    key(c.day("2026-03-12"), "PageDown");
    expect(c.navClicks).toEqual(["next"]);
    expect(c.hook.pendingFocus).toBe("2026-04-12");

    c.repaint({ month: "2026-04-01" });
    expect(document.activeElement.dataset.date).toBe("2026-04-12");
  });

  it("Shift pages by a year, across the year boundary in both directions", () => {
    const c = mountCalendar({ month: "2026-01-01" });

    key(c.day("2026-01-15"), "PageUp", { shiftKey: true });
    expect(c.navClicks).toEqual(["prev"]);
    expect(c.hook.pendingFocus).toBe("2025-01-15");

    c.repaint({ month: "2025-01-01" });
    expect(document.activeElement.dataset.date).toBe("2025-01-15");
  });

  // The arrow as rendered only ever moves one month, so a year jump has to
  // retarget it or it lands eleven months short.
  it("retargets the event-mode arrow at the month it actually wants", () => {
    const c = mountCalendar({ month: "2026-09-01" });
    expect(c.nav("prev").getAttribute("phx-value-month")).toBe("2026-08-01");

    key(c.day("2026-09-23"), "PageUp", { shiftKey: true });
    expect(c.nav("prev").getAttribute("phx-value-month")).toBe("2025-09-01");
    expect(c.hook.pendingFocus).toBe("2025-09-23");
  });

  it("retargets the link-mode arrow's month param", () => {
    const c = mountCalendar({ month: "2026-09-01", linkNav: true });
    expect(c.nav("next").getAttribute("href")).toBe("?month=2026-10-01");

    key(c.day("2026-09-23"), "PageDown", { shiftKey: true });
    expect(c.nav("next").getAttribute("href")).toBe("?month=2027-09-01");
    expect(c.hook.pendingFocus).toBe("2027-09-23");
  });

  it("retargets for an ordinary one-month page too, so both paths agree", () => {
    const c = mountCalendar({ month: "2026-09-01" });
    key(c.day("2026-09-23"), "PageDown");
    expect(c.nav("next").getAttribute("phx-value-month")).toBe("2026-10-01");
  });

  it("clamps a day the target month does not have", () => {
    const c = mountCalendar({ month: "2026-01-01" });
    key(c.day("2026-01-31"), "PageDown");
    expect(c.hook.pendingFocus).toBe("2026-02-28");
  });

  it("PageUp from January asks for December of the year before", () => {
    const c = mountCalendar({ month: "2026-01-01" });
    key(c.day("2026-01-15"), "PageUp");
    expect(c.navClicks).toEqual(["prev"]);
    expect(c.hook.pendingFocus).toBe("2025-12-15");
  });

  it("an arrow that lands in the next month pages too, even when the day is on screen", () => {
    const c = mountCalendar();
    // 31 March 2026 is rendered with 1 April beside it as an outside day
    expect(c.day("2026-04-01")).not.toBeNull();

    key(c.day("2026-03-31"), "ArrowRight");
    expect(c.navClicks).toEqual(["next"]);
    expect(c.hook.pendingFocus).toBe("2026-04-01");
  });

  it("an arrow off the top of the grid pages backwards", () => {
    const c = mountCalendar();
    key(c.day("2026-03-02"), "ArrowUp");
    expect(c.navClicks).toEqual(["prev"]);
    expect(c.hook.pendingFocus).toBe("2026-02-23");
  });

  it("keeps the clamped day through the repaint", () => {
    const c = mountCalendar({ month: "2026-01-01" });
    key(c.day("2026-01-31"), "PageDown");
    c.repaint({ month: "2026-02-01" });
    expect(document.activeElement.dataset.date).toBe("2026-02-28");
  });

  it("falls back to the first day of the month when the requested day is not rendered", () => {
    const c = mountCalendar({ month: "2026-03-01" });
    c.hook.pendingFocus = "2029-09-09";
    c.repaint({ month: "2026-04-01" });
    expect(document.activeElement.dataset.date).toBe("2026-04-01");
  });

  it("stops cleanly when there is no nav to click", () => {
    const c = mountCalendar();
    for (const nav of c.el.querySelectorAll("[data-pc-nav]")) nav.remove();
    key(c.day("2026-03-31"), "ArrowRight");
    expect(c.hook.pendingFocus).toBeNull();
  });

  it("unbinds on destroy", () => {
    const c = mountCalendar();
    c.hook.destroyed();
    mounted.splice(mounted.indexOf(c.hook), 1);
    key(c.day("2026-03-12"), "ArrowRight");
    expect(document.activeElement.dataset.date).toBeUndefined();
  });
});

describe("PetalDatePicker parse on blur", () => {
  it("accepts ISO whatever the display format is", () => {
    const p = mountPicker({ format: "%d %b %Y" });
    p.input.value = "2026-03-14";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.hidden("value").value).toBe("2026-03-14");
    expect(p.input.value).toBe("14 Mar 2026");
  });

  it("accepts the configured format", () => {
    const p = mountPicker({ format: "%d %b %Y" });
    p.input.value = "9 mar 2026";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.hidden("value").value).toBe("2026-03-09");
  });

  it("accepts a full month name and a leading day name", () => {
    const p = mountPicker({ format: "%A %-d %B %Y" });
    p.input.value = "Saturday 14 March 2026";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.hidden("value").value).toBe("2026-03-14");
  });

  it("reverts rather than clearing when the text will not parse", () => {
    const p = mountPicker({ format: "%d %b %Y", display: "14 Mar 2026", value: "2026-03-14" });
    p.input.value = "next tuesday";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.input.value).toBe("14 Mar 2026");
    expect(p.hidden("value").value).toBe("2026-03-14");
  });

  it("rejects a date that does not exist", () => {
    const p = mountPicker({ display: "2026-03-14", value: "2026-03-14" });
    p.input.value = "2026-02-31";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.input.value).toBe("2026-03-14");
  });

  it("clears the value when the input is emptied", () => {
    const p = mountPicker({ display: "2026-03-14", value: "2026-03-14" });
    p.input.value = "";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.hidden("value").value).toBe("");
  });

  it("Enter parses without waiting for blur", () => {
    const p = mountPicker();
    p.input.value = "2026-03-14";
    const ev = key(p.input, "Enter");
    expect(ev.defaultPrevented).toBe(true);
    expect(p.hidden("value").value).toBe("2026-03-14");
  });

  it("leaves the value alone when the server owns it", () => {
    const p = mountPicker({ selectEvent: "pick" });
    p.input.value = "2026-03-14";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.hidden("value").value).toBe("");
  });
});

describe("PetalDatePicker selection", () => {
  it("a day click writes the hidden input and dispatches change", () => {
    const p = mountPicker({ format: "%d %b %Y" });
    p.day("2026-03-14").click();
    expect(p.hidden("value").value).toBe("2026-03-14");
    expect(p.input.value).toBe("14 Mar 2026");
    expect(p.changes).toEqual(["2026-03-14"]);
  });

  it("repaints the grid so the click is visible without a server round trip", () => {
    const p = mountPicker();
    p.day("2026-03-14").click();
    expect(p.day("2026-03-14").classList.contains("pc-calendar__day--selected")).toBe(true);
    expect(p.day("2026-03-14").closest("td").getAttribute("aria-selected")).toBe("true");
    expect(p.day("2026-03-13").classList.contains("pc-calendar__day--selected")).toBe(false);
  });

  it("a disabled day is not selectable", () => {
    const p = mountPicker();
    const day = p.day("2026-03-14");
    day.dataset.disabled = "true";
    day.click();
    expect(p.hidden("value").value).toBe("");
  });

  it("does nothing on click when the server owns selection", () => {
    const p = mountPicker({ selectEvent: "pick" });
    p.day("2026-03-14").click();
    expect(p.hidden("value").value).toBe("");
  });

  it("range mode takes two clicks and orders them", () => {
    const p = mountPicker({ mode: "range" });

    p.day("2026-03-17").click();
    expect(p.hidden("from").value).toBe("2026-03-17");
    expect(p.hidden("to").value).toBe("");

    p.day("2026-03-09").click();
    expect(p.hidden("from").value).toBe("2026-03-09");
    expect(p.hidden("to").value).toBe("2026-03-17");
    expect(p.input.value).toBe("2026-03-09 - 2026-03-17");

    // a third click starts a new range
    p.day("2026-03-25").click();
    expect(p.hidden("from").value).toBe("2026-03-25");
    expect(p.hidden("to").value).toBe("");
  });

  it("range mode paints the band between the ends", () => {
    const p = mountPicker({ mode: "range" });
    p.day("2026-03-09").click();
    p.day("2026-03-12").click();

    expect(p.day("2026-03-10").classList.contains("pc-calendar__day--in-range")).toBe(true);
    expect(p.day("2026-03-09").classList.contains("pc-calendar__day--range-start")).toBe(true);
    expect(p.day("2026-03-12").classList.contains("pc-calendar__day--range-end")).toBe(true);
    expect(p.day("2026-03-13").classList.contains("pc-calendar__day--in-range")).toBe(false);
  });

  it("range mode parses both sides of a typed range", () => {
    const p = mountPicker({ mode: "range", format: "%d %b %Y" });
    p.input.value = "09 Mar 2026 - 17 Mar 2026";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.hidden("from").value).toBe("2026-03-09");
    expect(p.hidden("to").value).toBe("2026-03-17");
  });

  it("the clear button empties both the hidden value and the display", () => {
    const p = mountPicker({ clearable: true, value: "2026-03-14", display: "2026-03-14" });
    p.el.querySelector("[data-pc-date-clear]").click();
    expect(p.hidden("value").value).toBe("");
    expect(p.input.value).toBe("");
  });
});

describe("PetalDatePicker focus", () => {
  it("moves focus into the grid when the panel opens", async () => {
    const p = mountPicker();
    p.el.dispatchEvent(new Event("pc:date-picker:open"));
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(document.activeElement.dataset.date).toBe("2026-03-01");
  });

  it("unbinds on destroy", () => {
    const p = mountPicker();
    p.hook.destroyed();
    mounted.splice(mounted.indexOf(p.hook), 1);
    p.day("2026-03-14").click();
    expect(p.hidden("value").value).toBe("");
  });
});
