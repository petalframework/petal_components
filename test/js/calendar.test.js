// PetalCalendar / PetalDatePicker hook behaviour.
//
// The markup built here mirrors what PetalComponents.Calendar and
// PetalComponents.DatePicker render - test/petal/calendar_test.exs and
// test/petal/date_picker_test.exs pin that structure on the Elixir side, so
// update both together if the anatomy changes.
//
// The contracts these specs exist to hold: exactly one tabbable day at a time,
// the full APG arrow map including the month rollovers the server has to render
// for, a parse-on-blur that reverts rather than silently clearing a value, and
// - see "the parity lock" at the bottom - a client-painted selection that is
// class-for-class what the server would have rendered for the same dates.
import { readFileSync } from "node:fs";

import { afterEach, beforeEach, describe, expect, it } from "vitest";

import hooks from "../../assets/js/petal_components.js";

// The class matrix, shared with test/petal/calendar_test.exs. Read off disk by
// the same project-root-relative path the Elixir twin uses (vitest and mix both
// run from the project root), so the two specs are provably reading one file
// rather than two copies that can drift.
const fixture = JSON.parse(
  readFileSync("test/fixtures/calendar_selection_classes.json", "utf8"),
);

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

// Monday-first, same order the day_names_long attr takes.
const DAYS_LONG = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
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
  selectTarget = null,
  selected = null,
  disabled = [],
  linkNav = false,
  min = null,
  max = null,
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
        // Mirrors the day button the Elixir side renders: an enabled day in
        // event mode carries the click wiring, a disabled one never does.
        const wiring =
          selectEvent && !off
            ? `phx-click="${selectEvent}" phx-value-date="${d}"${selectTarget ? ` phx-target="${selectTarget}"` : ""}`
            : "";
        return `<td role="gridcell"${d === selected ? ' aria-selected="true"' : ""} class="pc-calendar__cell">
          <button type="button" class="pc-calendar__day" data-date="${d}"
            ${outside ? 'data-outside="true"' : ""} ${off ? 'data-disabled="true" aria-disabled="true"' : ""}
            ${wiring}
            tabindex="${d === focus ? "0" : "-1"}">${Number(d.slice(8))}</button>
        </td>`;
      })
      .join("");
    rows.push(`<tr role="row">${cells}</tr>`);
  }

  return `
    <div id="${id}" class="pc-calendar" data-month="${month}" data-starts-on="${startsOn}"
      ${selectEvent ? `data-select-event="${selectEvent}"` : ""}
      ${min ? `data-min="${min}"` : ""} ${max ? `data-max="${max}"` : ""}
      data-day-names-long="${DAYS_LONG.join(",")}"
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
  selectTarget = null,
  clearEvent = null,
  value = "",
  display = "",
  clearable = false,
  month = "2026-03-01",
  startsOn = 1,
} = {}) {
  const hiddens =
    mode === "range"
      ? `<input type="hidden" data-pc-date-from value="${value}" />
         <input type="hidden" data-pc-date-to value="" />`
      : `<input type="hidden" data-pc-date-value value="${value}" />`;

  return `
    <div id="dp" class="pc-date-picker" data-mode="${mode}" data-format="${format}"
      ${clearEvent ? `data-clear-event="${clearEvent}"` : ""}
      data-close="close-command"
      data-range-separator="${separator}">
      <div class="pc-date-picker__control">
        <input type="text" id="dp-input" data-pc-date-input value="${display}" />
        ${clearable ? '<button type="button" data-pc-date-clear></button>' : ""}
        <button type="button" id="dp-toggle" data-pc-date-toggle></button>
      </div>
      ${hiddens}
      <div id="dp-panel" class="pc-date-picker__panel">
        ${calendarMarkup({ selectEvent, selectTarget, month, startsOn, id: "dp-calendar" })}
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

  // Stand in for the LiveView hook API. A hook only ever runs under a
  // LiveSocket, so these always exist in the real thing.
  const pushes = [];
  hook.pushEvent = (event, payload) => pushes.push({ event, payload });
  hook.pushEventTo = (target, event, payload) =>
    pushes.push({ target, event, payload });

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
    pushes,
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
    expect(c.hook.pendingFocus).toEqual({ iso: "2026-04-12", focus: true });

    c.repaint({ month: "2026-04-01" });
    expect(document.activeElement.dataset.date).toBe("2026-04-12");
  });

  it("Shift pages by a year, across the year boundary in both directions", () => {
    const c = mountCalendar({ month: "2026-01-01" });

    key(c.day("2026-01-15"), "PageUp", { shiftKey: true });
    expect(c.navClicks).toEqual(["prev"]);
    expect(c.hook.pendingFocus).toEqual({ iso: "2025-01-15", focus: true });

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
    expect(c.hook.pendingFocus).toEqual({ iso: "2025-09-23", focus: true });
  });

  it("retargets the link-mode arrow's month param", () => {
    const c = mountCalendar({ month: "2026-09-01", linkNav: true });
    expect(c.nav("next").getAttribute("href")).toBe("?month=2026-10-01");

    key(c.day("2026-09-23"), "PageDown", { shiftKey: true });
    expect(c.nav("next").getAttribute("href")).toBe("?month=2027-09-01");
    expect(c.hook.pendingFocus).toEqual({ iso: "2027-09-23", focus: true });
  });

  it("retargets for an ordinary one-month page too, so both paths agree", () => {
    const c = mountCalendar({ month: "2026-09-01" });
    key(c.day("2026-09-23"), "PageDown");
    expect(c.nav("next").getAttribute("phx-value-month")).toBe("2026-10-01");
  });

  it("clamps a day the target month does not have", () => {
    const c = mountCalendar({ month: "2026-01-01" });
    key(c.day("2026-01-31"), "PageDown");
    expect(c.hook.pendingFocus).toEqual({ iso: "2026-02-28", focus: true });
  });

  it("PageUp from January asks for December of the year before", () => {
    const c = mountCalendar({ month: "2026-01-01" });
    key(c.day("2026-01-15"), "PageUp");
    expect(c.navClicks).toEqual(["prev"]);
    expect(c.hook.pendingFocus).toEqual({ iso: "2025-12-15", focus: true });
  });

  it("an arrow that lands in the next month pages too, even when the day is on screen", () => {
    const c = mountCalendar();
    // 31 March 2026 is rendered with 1 April beside it as an outside day
    expect(c.day("2026-04-01")).not.toBeNull();

    key(c.day("2026-03-31"), "ArrowRight");
    expect(c.navClicks).toEqual(["next"]);
    expect(c.hook.pendingFocus).toEqual({ iso: "2026-04-01", focus: true });
  });

  it("an arrow off the top of the grid pages backwards", () => {
    const c = mountCalendar();
    key(c.day("2026-03-02"), "ArrowUp");
    expect(c.navClicks).toEqual(["prev"]);
    expect(c.hook.pendingFocus).toEqual({ iso: "2026-02-23", focus: true });
  });

  it("keeps the clamped day through the repaint", () => {
    const c = mountCalendar({ month: "2026-01-01" });
    key(c.day("2026-01-31"), "PageDown");
    c.repaint({ month: "2026-02-01" });
    expect(document.activeElement.dataset.date).toBe("2026-02-28");
  });

  it("falls back to the first day of the month when the requested day is not rendered", () => {
    const c = mountCalendar({ month: "2026-03-01" });
    c.hook.pendingFocus = { iso: "2029-09-09", focus: true };
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

// Paging past a min/max window used to retarget the nav into a month where
// every day is disabled - a dead end you can only get out of by paging back.
describe("PetalCalendar min/max window", () => {
  it("does not page above max", () => {
    const c = mountCalendar({ month: "2026-03-01", max: "2026-03-20" });
    key(c.day("2026-03-12"), "PageDown");
    expect(c.navClicks).toEqual([]);
    expect(document.activeElement.dataset.date).toBe("2026-03-20");
  });

  it("does not page below min", () => {
    const c = mountCalendar({ month: "2026-03-01", min: "2026-03-05" });
    key(c.day("2026-03-12"), "PageUp", { shiftKey: true });
    expect(c.navClicks).toEqual([]);
    expect(document.activeElement.dataset.date).toBe("2026-03-05");
  });

  it("still pages when the target lands inside the window", () => {
    const c = mountCalendar({
      month: "2026-03-01",
      min: "2026-01-01",
      max: "2026-12-31",
    });
    key(c.day("2026-03-12"), "PageDown");
    expect(c.navClicks).toEqual(["next"]);
    expect(c.hook.pendingFocus).toEqual({ iso: "2026-04-12", focus: true });
  });

  it("pages to the edge month when the window ends part way in", () => {
    const c = mountCalendar({ month: "2026-03-01", max: "2026-04-10" });
    key(c.day("2026-03-12"), "PageDown");
    expect(c.navClicks).toEqual(["next"]);
    expect(c.hook.pendingFocus).toEqual({ iso: "2026-04-10", focus: true });
  });

  it("leaves arrow movement alone when no window is set", () => {
    const c = mountCalendar();
    key(c.day("2026-03-12"), "ArrowLeft");
    expect(document.activeElement.dataset.date).toBe("2026-03-11");
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

  // The hook must never write a value the server owns, but dropping the parse
  // on the floor is worse: the typed date has to reach handle_event or typing
  // is a lie. It goes out as the same event a click on that day would push.
  it("pushes the wired select event when the server owns the value", () => {
    const p = mountPicker({ selectEvent: "pick" });
    p.input.value = "2026-03-14";
    p.input.dispatchEvent(new Event("blur"));

    expect(p.hidden("value").value).toBe("");
    expect(p.pushes).toEqual([
      { event: "pick", payload: { date: "2026-03-14" } },
    ]);
  });

  it("respects phx-target when it pushes", () => {
    const p = mountPicker({ selectEvent: "pick", selectTarget: "3" });
    p.input.value = "2026-03-14";
    p.input.dispatchEvent(new Event("blur"));

    expect(p.pushes).toEqual([
      { target: "3", event: "pick", payload: { date: "2026-03-14" } },
    ]);
  });

  it("pushes both ends of a typed range, in the order two clicks would", () => {
    const p = mountPicker({ mode: "range", selectEvent: "pick" });
    p.input.value = "2026-03-09 - 2026-03-17";
    p.input.dispatchEvent(new Event("blur"));

    expect(p.pushes.map((push) => push.payload.date)).toEqual([
      "2026-03-09",
      "2026-03-17",
    ]);
  });

  it("does not push anything for text that will not parse", () => {
    const p = mountPicker({
      selectEvent: "pick",
      display: "2026-03-14",
      value: "2026-03-14",
    });
    p.input.value = "next tuesday";
    p.input.dispatchEvent(new Event("blur"));

    expect(p.pushes).toEqual([]);
    expect(p.input.value).toBe("2026-03-14");
  });

  // Emptying the input cannot clear a server-owned value, so the display has to
  // go back rather than sit there disagreeing with what will post.
  it("reverts an emptied input when the server owns the value and nothing handles clearing", () => {
    const p = mountPicker({
      selectEvent: "pick",
      display: "2026-03-14",
      value: "2026-03-14",
    });
    p.input.value = "";
    p.input.dispatchEvent(new Event("blur"));

    expect(p.input.value).toBe("2026-03-14");
    expect(p.pushes).toEqual([]);
  });

  it("pushes on_clear instead when one is wired", () => {
    const p = mountPicker({
      selectEvent: "pick",
      clearEvent: "wipe",
      display: "2026-03-14",
      value: "2026-03-14",
    });
    p.input.value = "";
    p.input.dispatchEvent(new Event("blur"));

    expect(p.pushes).toEqual([{ event: "wipe", payload: {} }]);
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

  // A smoke test for the shape of it; the exhaustive per-cell matrix is the
  // parity lock at the bottom of this file.
  it("range mode paints the band between the ends", () => {
    const p = mountPicker({ mode: "range" });
    p.day("2026-03-09").click();
    p.day("2026-03-12").click();

    const cell = (d) => p.day(d).closest("td");

    expect(p.day("2026-03-10").classList.contains("pc-calendar__day--in-range")).toBe(true);
    expect(p.day("2026-03-13").classList.contains("pc-calendar__day--in-range")).toBe(false);

    expect(cell("2026-03-09").classList.contains("pc-calendar__cell--range-start")).toBe(true);
    expect(cell("2026-03-12").classList.contains("pc-calendar__cell--range-end")).toBe(true);
    expect(cell("2026-03-10").classList.contains("pc-calendar__cell--in-range")).toBe(true);
  });

  it("range mode parses both sides of a typed range", () => {
    const p = mountPicker({ mode: "range", format: "%d %b %Y" });
    p.input.value = "09 Mar 2026 - 17 Mar 2026";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.hidden("from").value).toBe("2026-03-09");
    expect(p.hidden("to").value).toBe("2026-03-17");
  });

  // The default format is ISO and the default separator is " - ", so splitting
  // on a bare "-" tears the year off the first date. Split on the separator as
  // configured, not on its trimmed remains.
  it("range mode parses a typed range in the default ISO format", () => {
    const p = mountPicker({ mode: "range" });
    p.input.value = "2026-03-09 - 2026-03-17";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.hidden("from").value).toBe("2026-03-09");
    expect(p.hidden("to").value).toBe("2026-03-17");
  });

  it("range mode tolerates missing padding around the separator", () => {
    const p = mountPicker({ mode: "range", format: "%d %b %Y" });
    p.input.value = "09 Mar 2026 -17 Mar 2026";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.hidden("from").value).toBe("2026-03-09");
    expect(p.hidden("to").value).toBe("2026-03-17");
  });

  it("range mode keeps a half-typed range rather than clearing it", () => {
    const p = mountPicker({ mode: "range" });
    p.input.value = "2026-03-09 - ";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.hidden("from").value).toBe("2026-03-09");
    expect(p.hidden("to").value).toBe("");
  });

  it("the clear button empties both the hidden value and the display", () => {
    const p = mountPicker({ clearable: true, value: "2026-03-14", display: "2026-03-14" });
    p.el.querySelector("[data-pc-date-clear]").click();
    expect(p.hidden("value").value).toBe("");
    expect(p.input.value).toBe("");
  });
});

// The client half formats the display itself when it owns the value, so it has
// to render every directive the server-side Calendar.strftime/2 can - a literal
// "%a" in the input is the tell that it does not.
describe("PetalDatePicker display formatting", () => {
  it("renders day names from the calendar's own labels", () => {
    const p = mountPicker({ format: "%a %d %b %Y" });
    p.day("2026-03-14").click();
    expect(p.input.value).toBe("Sat 14 Mar 2026");
  });

  it("renders the long day name too", () => {
    const p = mountPicker({ format: "%A, %-d %B %Y" });
    p.day("2026-03-14").click();
    expect(p.input.value).toBe("Saturday, 14 March 2026");
  });

  it("round-trips its own output back through the parser", () => {
    const p = mountPicker({ format: "%a %d %b %Y" });
    p.day("2026-03-14").click();
    p.input.dispatchEvent(new Event("blur"));
    expect(p.hidden("value").value).toBe("2026-03-14");
  });
});

// ---------------------------------------------------------------------------
// The parity lock.
//
// The picker has two selection paths. With a select event wired the server owns
// it and every click re-renders through Calendar.build_day/4. Without one this
// hook paints the classes itself, in the browser, with no round trip - and for
// a while it painted a vocabulary the server had stopped speaking: a chip on
// every day of a range, no band on the cells, no outward-only rounding. Same
// component, same dates, two different pictures.
//
// So both painters are now held to one file. The matrix below comes from
// test/fixtures/calendar_selection_classes.json, and its twin in
// test/petal/calendar_test.exs ("the class matrix the client hook is held to")
// renders the server against the same JSON. Change the range styling and both
// specs go red together.
// ---------------------------------------------------------------------------
describe("PetalDatePicker parity with the server's range anatomy", () => {
  const present = (el, vocabulary) =>
    vocabulary.filter((name) => el.classList.contains(name)).sort();

  const blank = { aria_selected: false, cell: [], day: [] };

  // Every day in the grid is checked, not just the ones the fixture names: a
  // class left behind on day 20 is exactly the bug this lock exists to catch.
  const assertMatrix = (p, days) => {
    for (const iso of Object.keys(days)) {
      expect(p.day(iso), `fixture names ${iso}, grid does not render it`).not.toBeNull();
    }

    for (const day of p.el.querySelectorAll("[data-date]")) {
      const iso = day.dataset.date;
      const cell = day.closest('[role="gridcell"]');
      const want = days[iso] || blank;

      expect({
        iso,
        ariaSelected: cell.getAttribute("aria-selected") === "true",
        cell: present(cell, fixture.cell_vocabulary),
        day: present(day, fixture.day_vocabulary),
      }).toEqual({
        iso,
        ariaSelected: want.aria_selected === true,
        cell: [...want.cell].sort(),
        day: [...want.day].sort(),
      });
    }
  };

  const pick = (scenario) => {
    const p = mountPicker({
      mode: scenario.mode,
      month: fixture.month,
      startsOn: fixture.starts_on,
      clearable: true,
    });
    for (const iso of scenario.clicks) p.day(iso).click();
    return p;
  };

  for (const scenario of fixture.scenarios) {
    it(`paints ${scenario.name}`, () => {
      assertMatrix(pick(scenario), scenario.days);
    });
  }

  const spanning = fixture.scenarios.find(
    (s) => s.from === "2026-03-09" && s.to === "2026-03-17",
  );

  // range_position/2 sorts the pair, so a backwards typed range is the same
  // picture as a forwards one. Only typing can produce it - two clicks are
  // ordered on the way in.
  it("sorts a backwards typed range the way the server does", () => {
    const p = mountPicker({ mode: "range", clearable: true });
    p.input.value = `${spanning.to} - ${spanning.from}`;
    p.input.dispatchEvent(new Event("blur"));

    assertMatrix(p, spanning.days);
  });

  it("leaves nothing behind when the range restarts", () => {
    const p = pick(spanning);
    p.day("2026-03-25").click();

    assertMatrix(p, {
      "2026-03-25": {
        aria_selected: true,
        cell: [],
        day: ["pc-calendar__day--selected"],
      },
    });
  });

  it("leaves nothing behind when the clear button empties the value", () => {
    const p = pick(spanning);
    p.el.querySelector("[data-pc-date-clear]").click();

    assertMatrix(p, {});
  });

  // Month nav is a patch link when nothing is wired to change the month, so the
  // grid that comes back is painted from the server's assigns - the selection
  // as it was on page load, over the one the user just made client-side.
  it("repaints from the hidden inputs when a patch replaces the panel", () => {
    const p = pick(spanning);

    const panel = document.createElement("div");
    panel.innerHTML = pickerMarkup({ mode: "range" });
    const patched = panel.querySelector(".pc-date-picker__panel");

    // The stale selection the server would have rendered for its own assigns.
    const anchor = patched.querySelector('[data-date="2026-03-02"]');
    anchor.classList.add("pc-calendar__day--selected");
    anchor.closest("td").setAttribute("aria-selected", "true");

    p.el.querySelector(".pc-date-picker__panel").replaceWith(patched);
    p.hook.updated();

    assertMatrix(p, spanning.days);

    // and the new panel is wired, so the next click still lands
    p.day("2026-03-25").click();
    expect(p.hidden("from").value).toBe("2026-03-25");
  });

  it("leaves a server-owned grid alone on update", () => {
    const p = mountPicker({ mode: "range", selectEvent: "pick" });
    const day = p.day("2026-03-11");
    day.classList.add("pc-calendar__day--selected");
    day.closest("td").setAttribute("aria-selected", "true");

    p.hook.updated();

    assertMatrix(p, {
      "2026-03-11": {
        aria_selected: true,
        cell: [],
        day: ["pc-calendar__day--selected"],
      },
    });
  });
});

describe("PetalCalendar silent month jump", () => {
  // The date picker's typed commit pages the grid to the committed month
  // WITHOUT taking focus - the caret is in the input and must survive.
  it("show-date on the visible month moves the tabindex, not the focus", () => {
    const c = mountCalendar();
    document.body.focus();
    c.el.dispatchEvent(
      new CustomEvent("pc:calendar:show-date", {
        detail: { date: "2026-03-20", focus: false },
      }),
    );
    expect(c.tabbable().map((d) => d.dataset.date)).toEqual(["2026-03-20"]);
    expect(document.activeElement).toBe(document.body);
  });

  it("show-date across months pages silently", () => {
    const c = mountCalendar();
    document.body.focus();
    c.el.dispatchEvent(
      new CustomEvent("pc:calendar:show-date", {
        detail: { date: "2026-05-09", focus: false },
      }),
    );
    expect(c.hook.pendingFocus).toEqual({ iso: "2026-05-09", focus: false });
    c.repaint({ month: "2026-05-01" });
    // repaint replaces the element, so query through hook.el - the mount
    // helper's closures still point at the detached March grid
    const tabbable = Array.from(
      c.hook.el.querySelectorAll('[data-date][tabindex="0"]'),
    );
    expect(tabbable.map((d) => d.dataset.date)).toEqual(["2026-05-09"]);
    expect(document.activeElement).toBe(document.body);
  });
});

describe("PetalDatePicker focus", () => {
  // Focus follows INTENT (the open event's detail), not the panel. Opening
  // from the toggle carries focus: "grid"; opening from the input's own
  // click carries nothing, and the caret must stay in the input - the
  // maintainer found the grid stealing focus made the input untypeable and
  // blur-parse fire on half-typed text.
  it("moves focus into the grid when the open asks for it", async () => {
    const p = mountPicker();
    p.el.dispatchEvent(
      new CustomEvent("pc:date-picker:open", { detail: { focus: "grid" } }),
    );
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(document.activeElement.dataset.date).toBe("2026-03-01");
  });

  it("leaves the caret in the input when the input opened the panel", async () => {
    const p = mountPicker();
    p.input.focus();
    p.el.dispatchEvent(
      new CustomEvent("pc:date-picker:open", { detail: { focus: "" } }),
    );
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(document.activeElement).toBe(p.input);
  });

  it("ArrowDown is the keyboard road into the grid", async () => {
    const p = mountPicker();
    p.input.focus();
    // panel visible: straight to the grid
    p.input.dispatchEvent(
      new KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }),
    );
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(document.activeElement.dataset.date).toBe("2026-03-01");
  });

  it("a typed commit asks the calendar to show the month, silently", () => {
    const p = mountPicker();
    const shown = [];
    p.el
      .querySelector(".pc-calendar")
      .addEventListener("pc:calendar:show-date", (e) => shown.push(e.detail));
    p.input.value = "2027-03-14";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.hidden("value").value).toBe("2027-03-14");
    expect(shown).toEqual([{ date: "2027-03-14", focus: false }]);
  });

  it("Enter on a complete value closes the panel through data-close", () => {
    const p = mountPicker();
    const executed = [];
    p.hook.liveSocket = { execJS: (el, js) => executed.push(js) };
    p.input.value = "2026-03-14";
    p.input.dispatchEvent(
      new KeyboardEvent("keydown", { key: "Enter", bubbles: true }),
    );
    expect(p.hidden("value").value).toBe("2026-03-14");
    expect(executed).toEqual(["close-command"]);
  });

  it("Enter on a half-open range commits the end it has and stays open", () => {
    const p = mountPicker({ mode: "range" });
    const executed = [];
    p.hook.liveSocket = { execJS: (el, js) => executed.push(js) };
    p.input.value = "2026-03-10 - ";
    p.input.dispatchEvent(
      new KeyboardEvent("keydown", { key: "Enter", bubbles: true }),
    );
    expect(executed).toEqual([]);
  });

  it("ArrowDown on a closed panel opens through the toggle", () => {
    const p = mountPicker();
    p.el.querySelector(".pc-date-picker__panel").style.display = "none";
    let toggled = 0;
    document
      .getElementById("dp-toggle")
      .addEventListener("click", () => toggled++);
    p.input.focus();
    p.input.dispatchEvent(
      new KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }),
    );
    expect(toggled).toBe(1);
  });

  it("unbinds on destroy", () => {
    const p = mountPicker();
    p.hook.destroyed();
    mounted.splice(mounted.indexOf(p.hook), 1);
    p.day("2026-03-14").click();
    expect(p.hidden("value").value).toBe("");
  });
});

describe("PetalDatePicker across patches", () => {
  // The maintainer's repro: type a date, Enter, reopen - right month, no
  // highlight. The month jump is a patch, the patch morphs the hidden inputs
  // back to the server's assigns (which in a client-owned picker never
  // learned the value), and the old updated() then faithfully repainted
  // "nothing". LiveView only shields the FOCUSED input; the hiddens are fair
  // game. The hook's own memory has to win.
  it("a month patch cannot wipe a committed value", () => {
    const p = mountPicker({ format: "%d %b %Y" });
    p.input.value = "14 Mar 2027";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.hidden("value").value).toBe("2027-03-14");

    // The patch: server repaints the subtree from its own assigns - hiddens
    // come back empty, the grid comes back on the new month, unpainted.
    p.hidden("value").value = "";
    p.el.querySelector("#dp-panel").innerHTML = calendarMarkup({
      month: "2027-03-01",
      id: "dp-calendar",
    });
    p.hook.updated();

    expect(p.hidden("value").value).toBe("2027-03-14");
    expect(
      p.day("2027-03-14").classList.contains("pc-calendar__day--selected"),
    ).toBe(true);
    expect(p.input.value).toBe("14 Mar 2027");
  });

  it("a server re-render that actually changes the value is adopted, not fought", () => {
    const p = mountPicker({ display: "2026-03-14", value: "2026-03-14" });
    // A real re-render: the server changes the hidden's value ATTRIBUTE,
    // which nothing on the client ever touches - reconfigured picker, reset
    // form. The hook's memory yields.
    p.hidden("value").setAttribute("value", "2026-03-20");
    p.hidden("value").value = "2026-03-20";
    p.hook.updated();
    expect(p.hidden("value").value).toBe("2026-03-20");
    expect(
      p.day("2026-03-20").classList.contains("pc-calendar__day--selected"),
    ).toBe(true);
    expect(p.input.value).toBe("2026-03-20");
  });

  it("a patch cannot resurrect a cleared value either", () => {
    const p = mountPicker({ display: "2026-03-14", value: "2026-03-14" });
    p.input.value = "";
    p.input.dispatchEvent(new Event("blur"));
    expect(p.hidden("value").value).toBe("");

    // Server still holds the mount-time seed; the patch puts it back.
    p.hidden("value").value = "2026-03-14";
    p.hook.updated();

    expect(p.hidden("value").value).toBe("");
    expect(
      p.day("2026-03-14").classList.contains("pc-calendar__day--selected"),
    ).toBe(false);
  });
});

describe("PetalDatePicker live preview", () => {
  const debounce = () => new Promise((resolve) => setTimeout(resolve, 200));

  it("a complete date previews as you type - committed, paged, text untouched", async () => {
    const p = mountPicker({ format: "%d %b %Y" });
    const shown = [];
    p.el
      .querySelector(".pc-calendar")
      .addEventListener("pc:calendar:show-date", (e) => shown.push(e.detail));

    p.input.focus();
    p.input.value = "14 Mar 2027";
    p.input.dispatchEvent(new Event("input", { bubbles: true }));
    await debounce();

    expect(p.hidden("value").value).toBe("2027-03-14");
    expect(shown).toEqual([{ date: "2027-03-14", focus: false }]);
    // The two thefts this feature must not commit: the text and the caret.
    expect(p.input.value).toBe("14 Mar 2027");
    expect(document.activeElement).toBe(p.input);
  });

  it("incomplete text previews nothing - %Y wants all four digits", async () => {
    const p = mountPicker({ format: "%d %b %Y" });
    p.input.value = "14 Mar 2";
    p.input.dispatchEvent(new Event("input", { bubbles: true }));
    await debounce();
    expect(p.hidden("value").value).toBe("");
    expect(p.input.value).toBe("14 Mar 2");
  });

  it("a closed panel and a server-owned picker both sit it out", async () => {
    const closed = mountPicker({ format: "%d %b %Y" });
    closed.el.querySelector("#dp-panel").style.display = "none";
    closed.input.value = "14 Mar 2027";
    closed.input.dispatchEvent(new Event("input", { bubbles: true }));
    await debounce();
    expect(closed.hidden("value").value).toBe("");

    document.body.innerHTML = "";
    const owned = mountPicker({ selectEvent: "pick" });
    owned.input.value = "2027-03-14";
    owned.input.dispatchEvent(new Event("input", { bubbles: true }));
    await debounce();
    expect(owned.pushes).toEqual([]);
    expect(owned.hidden("value").value).toBe("");
  });

  it("a range previews only once both ends are in", async () => {
    const p = mountPicker({ mode: "range" });
    p.input.value = "2026-03-10 - ";
    p.input.dispatchEvent(new Event("input", { bubbles: true }));
    await debounce();
    expect(p.hidden("from").value).toBe("");

    p.input.value = "2026-03-10 - 2026-03-14";
    p.input.dispatchEvent(new Event("input", { bubbles: true }));
    await debounce();
    expect(p.hidden("from").value).toBe("2026-03-10");
    expect(p.hidden("to").value).toBe("2026-03-14");
    expect(p.input.value).toBe("2026-03-10 - 2026-03-14");
  });
});
