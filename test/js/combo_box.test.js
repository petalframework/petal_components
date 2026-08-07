// PetalComboBox hook behavior.
//
// The markup built here mirrors what PetalComponents.ComboBox renders -
// test/petal/combo_box_test.exs pins that structure on the Elixir side;
// update both together if the anatomy changes. These specs pin the hook's
// contracts: open/close paths (including the iOS ones that only exist
// because Safari never blurs on static-content taps), filter ranking,
// the boundary cycle, selection through the hidden select, and the
// keystroke containment that keeps typing out of enclosing phx-change
// forms.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import hooks from "../../assets/js/petal_components.js";

import { pointerEvent } from "./helpers.js";

const mounted = [];

function option(value, label, disabled = false) {
  return { value, label, disabled };
}

function optionHtml(opt) {
  return `
    <div role="option" class="pc-combo-box__option" data-pc-combo-item
      data-value="${opt.value}" data-label="${opt.label}"
      ${opt.disabled ? 'data-disabled="true" aria-disabled="true"' : ""}
      aria-selected="false">
      <span class="pc-combo-box__option-label">${opt.label}</span>
      <span class="hero-check-mini pc-combo-box__check"></span>
    </div>`;
}

function mountCombo({
  id = "combo",
  options = [],
  groups = [],
  multiple = false,
  maxItems = null,
  clearable = false,
  trigger = false,
} = {}) {
  const selectOptions = [...options, ...groups.flatMap((g) => g.options)]
    .map(
      (o) =>
        `<option value="${o.value}" ${o.disabled ? "disabled" : ""}>${o.label}</option>`,
    )
    .join("");

  const listHtml =
    options.map(optionHtml).join("") +
    groups
      .map(
        (g) => `
        <div class="pc-combo-box__group" role="group" data-pc-combo-group>
          <div class="pc-combo-box__group-heading" aria-hidden="true">${g.label}</div>
          ${g.options.map(optionHtml).join("")}
        </div>`,
      )
      .join("");

  const el = document.createElement("div");
  el.id = id;
  el.className = "pc-combo-box";
  el.setAttribute("phx-hook", "PetalComboBox");
  if (maxItems) el.setAttribute("data-max-items", String(maxItems));
  const inputHtml = `<input type="text" id="${id}-input" class="pc-combo-box__input" role="combobox"
          aria-expanded="false" aria-autocomplete="list" aria-controls="${id}-listbox"
          autocomplete="off" placeholder="Pick..." />`;

  const bodyHtml = trigger
    ? `<button type="button" id="${id}-trigger" class="pc-combo-box__trigger" role="combobox"
        aria-haspopup="listbox" aria-expanded="false" aria-controls="${id}-listbox"
        data-pc-combo-trigger data-placeholder="true">
        <span class="pc-combo-box__trigger-label" data-pc-combo-trigger-label
          data-placeholder-text="Pick..." data-count-label="selected">Pick...</span>
      </button>${clearable ? '<button type="button" class="pc-combo-box__trigger-clear" data-pc-combo-clear aria-label="Clear selection"><span class="hero-x-mark-mini pc-combo-box__clear-icon"></span></button>' : ""}`
    : `<div class="pc-combo-box__control">
      <div class="pc-combo-box__content">
        ${multiple ? '<div class="pc-combo-box__chips" data-pc-combo-chips data-remove-label="Remove"></div>' : ""}
        ${inputHtml}
      </div>
      ${clearable ? '<button type="button" class="pc-combo-box__clear" data-pc-combo-clear aria-label="Clear selection"><span class="hero-x-mark-mini pc-combo-box__clear-icon"></span></button>' : ""}
      ${multiple ? "" : '<span class="hero-chevron-down-mini pc-combo-box__chevron"></span>'}
    </div>`;

  el.innerHTML = `
    <select id="${id}-select" name="city${multiple ? "[]" : ""}" class="pc-combo-box__select" tabindex="-1" aria-hidden="true" inert ${multiple ? "multiple" : ""}>
      ${multiple ? "" : '<option value=""></option>'}
      ${selectOptions}
    </select>
    ${bodyHtml}
    <div class="pc-combo-box__panel" data-pc-combo-panel hidden>
      ${trigger ? '<div class="pc-combo-box__search"><span class="hero-magnifying-glass-mini pc-combo-box__search-icon"></span>' + inputHtml + "</div>" : ""}
      <div role="listbox" id="${id}-listbox" class="pc-combo-box__list" aria-label="Options">
        ${listHtml}
        <div class="pc-combo-box__empty" data-pc-combo-empty hidden>No results found</div>
      </div>
    </div>
    <div class="pc-combo-box__live" data-pc-combo-live data-results-label="results" data-no-results-text="No results found" aria-live="polite"></div>`;
  document.body.appendChild(el);

  const hook = Object.create(hooks.PetalComboBox);
  hook.el = el;
  hook.mounted();
  mounted.push(hook);

  return {
    hook,
    el,
    input: el.querySelector(".pc-combo-box__input"),
    select: el.querySelector(".pc-combo-box__select"),
    control: el.querySelector(".pc-combo-box__control"),
    panel: el.querySelector("[data-pc-combo-panel]"),
    chevron: el.querySelector(".pc-combo-box__chevron"),
    items: () => [...el.querySelectorAll("[data-pc-combo-item]")],
    visible: () => [
      ...el.querySelectorAll("[data-pc-combo-item]:not([hidden])"),
    ],
    highlighted: () => el.querySelector("[data-highlighted]"),
    empty: () => el.querySelector("[data-pc-combo-empty]"),
    chips: () => [...el.querySelectorAll("[data-pc-combo-chip]")],
    live: () => el.querySelector("[data-pc-combo-live]"),
    trigger: el.querySelector("[data-pc-combo-trigger]"),
    triggerLabel: () => el.querySelector("[data-pc-combo-trigger-label]"),
  };
}

const CITIES = [
  option("syd", "Sydney"),
  option("tyo", "Tokyo"),
  option("lis", "Lisbon"),
  option("sto", "Stockholm"),
];

function type(input, text) {
  input.value = text;
  input.dispatchEvent(new Event("input", { bubbles: true }));
}

function key(target, k) {
  const ev = new KeyboardEvent("keydown", {
    key: k,
    bubbles: true,
    cancelable: true,
  });
  target.dispatchEvent(ev);
  return ev;
}

beforeEach(() => {
  document.body.innerHTML = "";
  // jsdom has no scrollIntoView
  Element.prototype.scrollIntoView = () => {};
});

afterEach(() => {
  mounted.splice(0).forEach((hook) => hook.destroyed());
});

describe("open and close", () => {
  it("opens on control click with aria-expanded, all options visible", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    expect(c.panel.hidden).toBe(false);
    expect(c.input.getAttribute("aria-expanded")).toBe("true");
    expect(c.visible()).toHaveLength(4);
  });

  it("a click on the open input is caret work - panel and query survive", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    type(c.input, "syd");
    c.input.click();
    expect(c.panel.hidden).toBe(false);
    expect(c.input.value).toBe("syd");
  });

  it("a chevron tap closes even when iOS snaps the click onto the input", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    expect(c.panel.hidden).toBe(false);
    // the pointerdown hit-tests the REAL touch point (control chrome);
    // iOS tap-target correction then rewrites the synthesized click's
    // target AND coordinates onto the nearby text field
    c.control.dispatchEvent(pointerEvent("pointerdown", "touch"));
    c.input.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(c.panel.hidden).toBe(true);
  });

  it("an input press is caret work even if the click reports the control", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    type(c.input, "syd");
    c.input.dispatchEvent(pointerEvent("pointerdown", "touch"));
    c.control.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(c.panel.hidden).toBe(false);
    expect(c.input.value).toBe("syd");
  });

  it("an abandoned chrome press never poisons a later caret click", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    type(c.input, "syd");
    // press the chevron but release outside the control - no control
    // click ever fires to consume the record
    c.control.dispatchEvent(pointerEvent("pointerdown", "touch"));
    document.body.dispatchEvent(pointerEvent("pointerup", "touch"));
    // a later synthetic caret click (assistive tech) must stay caret work
    c.input.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(c.panel.hidden).toBe(false);
    expect(c.input.value).toBe("syd");
  });

  it("interleaved pointers disarm - one finger's click never consumes another's verdict", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    type(c.input, "syd");
    // finger 1 rests on the input (caret), finger 2 presses the chevron
    c.input.dispatchEvent(
      pointerEvent("pointerdown", "touch", { pointerId: 1 }),
    );
    c.control.dispatchEvent(
      pointerEvent("pointerdown", "touch", { pointerId: 2 }),
    );
    // finger 1's click must NOT consume finger 2's chrome verdict
    c.input.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(c.panel.hidden).toBe(false);
    expect(c.input.value).toBe("syd");
    // both released; a normal single chevron press still toggles
    document.body.dispatchEvent(
      pointerEvent("pointerup", "touch", { pointerId: 1 }),
    );
    document.body.dispatchEvent(
      pointerEvent("pointerup", "touch", { pointerId: 2 }),
    );
    c.control.dispatchEvent(
      pointerEvent("pointerdown", "touch", { pointerId: 3 }),
    );
    c.control.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(c.panel.hidden).toBe(true);
  });

  it("reverse release order: the chevron press still closes after the other finger lifts", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    // finger 1 presses the chevron (chrome), finger 2 brushes the input,
    // finger 2 lifts off-control FIRST, then finger 1 completes its press
    c.control.dispatchEvent(
      pointerEvent("pointerdown", "touch", { pointerId: 1 }),
    );
    c.input.dispatchEvent(
      pointerEvent("pointerdown", "touch", { pointerId: 2 }),
    );
    document.body.dispatchEvent(
      pointerEvent("pointerup", "touch", { pointerId: 2 }),
    );
    // the click arrives carrying finger 1's pointerId (modern browsers)
    c.input.dispatchEvent(pointerEvent("click", "touch", { pointerId: 1 }));
    expect(c.panel.hidden).toBe(true);
  });

  it("a trailing click from the same gesture never reopens a deliberate chrome close", () => {
    const clock = vi.spyOn(performance, "now").mockReturnValue(10_000);
    const c = mountCombo({ options: CITIES });
    c.control.click();
    expect(c.panel.hidden).toBe(false);
    // finger 1 presses and clicks the chevron - deliberate close
    c.control.dispatchEvent(
      pointerEvent("pointerdown", "touch", { pointerId: 1 }),
    );
    c.control.dispatchEvent(pointerEvent("click", "touch", { pointerId: 1 }));
    expect(c.panel.hidden).toBe(true);
    // finger 2's trailing click (same burst) must not reopen
    c.input.dispatchEvent(pointerEvent("click", "touch", { pointerId: 2 }));
    expect(c.panel.hidden).toBe(true);
    // a RAPID follow-up tap (same instant, fresh pointerdown) reopens -
    // suppression ends at the next pointerdown, not a time window
    c.control.dispatchEvent(
      pointerEvent("pointerdown", "touch", { pointerId: 3 }),
    );
    c.control.dispatchEvent(pointerEvent("click", "touch", { pointerId: 3 }));
    expect(c.panel.hidden).toBe(false);
    clock.mockRestore();
  });

  it("Safari's late-synthesized click still finds its verdict - no timer race", () => {
    const clock = vi.spyOn(performance, "now").mockReturnValue(20_000);
    const c = mountCombo({ options: CITIES });
    c.control.click();
    // chevron press releases ON the control; the click arrives later
    // than every queued task (iOS synthesis delay)
    c.control.dispatchEvent(
      pointerEvent("pointerdown", "touch", { pointerId: 1 }),
    );
    c.control.dispatchEvent(
      pointerEvent("pointerup", "touch", { pointerId: 1 }),
    );
    clock.mockReturnValue(20_400);
    c.input.dispatchEvent(pointerEvent("click", "touch", { pointerId: 1 }));
    expect(c.panel.hidden).toBe(true);
    clock.mockRestore();
  });

  it("a leftover verdict older than a second cannot poison a synthetic caret click", () => {
    const clock = vi.spyOn(performance, "now").mockReturnValue(30_000);
    const c = mountCombo({ options: CITIES });
    c.control.click();
    type(c.input, "syd");
    // chevron press whose click never arrives (released on-control)
    c.control.dispatchEvent(
      pointerEvent("pointerdown", "touch", { pointerId: 1 }),
    );
    c.control.dispatchEvent(
      pointerEvent("pointerup", "touch", { pointerId: 1 }),
    );
    // much later, a synthetic caret click (assistive tech)
    clock.mockReturnValue(31_500);
    c.input.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(c.panel.hidden).toBe(false);
    expect(c.input.value).toBe("syd");
    clock.mockRestore();
  });

  it("a cancelled chrome press clears the same way", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    c.control.dispatchEvent(pointerEvent("pointerdown", "touch"));
    document.body.dispatchEvent(pointerEvent("pointercancel", "touch"));
    c.input.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(c.panel.hidden).toBe(false);
  });

  it("chrome pointerdowns are preventDefaulted so the input never blurs mid-press (the desktop flash)", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    const onChrome = pointerEvent("pointerdown", "mouse", { cancelable: true });
    c.control.dispatchEvent(onChrome);
    expect(onChrome.defaultPrevented).toBe(true);
    c.control.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(c.panel.hidden).toBe(true);
    // ...but a press on the input itself keeps its default (caret, focus)
    const onInput = pointerEvent("pointerdown", "mouse", { cancelable: true });
    c.input.dispatchEvent(onInput);
    expect(onInput.defaultPrevented).toBe(false);
  });

  it("a click on control chrome (the chevron) toggles closed", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    c.chevron.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(c.panel.hidden).toBe(true);
  });

  it("an outside tap (press completed in place) closes - the iOS Safari path where focusout never fires", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    document.body.dispatchEvent(
      pointerEvent("pointerdown", "touch", { clientX: 10, clientY: 10 }),
    );
    expect(c.panel.hidden).toBe(false);
    document.body.dispatchEvent(
      pointerEvent("pointerup", "touch", { clientX: 10, clientY: 10 }),
    );
    expect(c.panel.hidden).toBe(true);
  });

  it("a touch-scroll that starts outside does not dismiss - pointercancel path", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    document.body.dispatchEvent(
      pointerEvent("pointerdown", "touch", { clientX: 10, clientY: 200 }),
    );
    document.body.dispatchEvent(pointerEvent("pointercancel", "touch"));
    document.body.dispatchEvent(
      pointerEvent("pointerup", "touch", { clientX: 10, clientY: 40 }),
    );
    expect(c.panel.hidden).toBe(false);
    // a clean tap afterwards still closes
    document.body.dispatchEvent(
      pointerEvent("pointerdown", "touch", { clientX: 10, clientY: 10 }),
    );
    document.body.dispatchEvent(
      pointerEvent("pointerup", "touch", { clientX: 10, clientY: 10 }),
    );
    expect(c.panel.hidden).toBe(true);
  });

  it("a drag that never cancels (unscrollable page) still reads as a scroll, not a press", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    document.body.dispatchEvent(
      pointerEvent("pointerdown", "touch", { clientX: 10, clientY: 200 }),
    );
    document.body.dispatchEvent(
      pointerEvent("pointerup", "touch", { clientX: 10, clientY: 80 }),
    );
    expect(c.panel.hidden).toBe(false);
  });

  it("a second finger disarms - multi-touch is a gesture, not a press", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    document.body.dispatchEvent(
      pointerEvent("pointerdown", "touch", {
        clientX: 10,
        clientY: 10,
        pointerId: 1,
      }),
    );
    document.body.dispatchEvent(
      pointerEvent("pointerdown", "touch", {
        clientX: 60,
        clientY: 10,
        pointerId: 2,
      }),
    );
    document.body.dispatchEvent(
      pointerEvent("pointerup", "touch", {
        clientX: 10,
        clientY: 10,
        pointerId: 1,
      }),
    );
    document.body.dispatchEvent(
      pointerEvent("pointerup", "touch", {
        clientX: 60,
        clientY: 10,
        pointerId: 2,
      }),
    );
    expect(c.panel.hidden).toBe(false);
    // a clean single-finger tap afterwards still closes
    document.body.dispatchEvent(
      pointerEvent("pointerdown", "touch", {
        clientX: 10,
        clientY: 10,
        pointerId: 3,
      }),
    );
    document.body.dispatchEvent(
      pointerEvent("pointerup", "touch", {
        clientX: 10,
        clientY: 10,
        pointerId: 3,
      }),
    );
    expect(c.panel.hidden).toBe(true);
  });

  it("a pointerup from a different pointer never completes another pointer's press", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    document.body.dispatchEvent(
      pointerEvent("pointerdown", "touch", {
        clientX: 10,
        clientY: 10,
        pointerId: 1,
      }),
    );
    document.body.dispatchEvent(
      pointerEvent("pointerup", "touch", {
        clientX: 10,
        clientY: 10,
        pointerId: 9,
      }),
    );
    expect(c.panel.hidden).toBe(false);
  });

  it("the trigger variant's clear empties the value, restores the placeholder label, and never toggles the panel", () => {
    const c = mountCombo({ options: CITIES, trigger: true, clearable: true });
    c.trigger.click();
    c.items()[1].click();
    expect(c.select.value).toBe("tyo");
    expect(c.triggerLabel().textContent).toBe("Tokyo");
    expect(c.panel.hidden).toBe(true);
    let changes = 0;
    c.select.addEventListener("change", () => changes++);
    c.el.querySelector("[data-pc-combo-clear]").click();
    expect(c.select.value).toBe("");
    expect(c.triggerLabel().textContent).toBe("Pick...");
    expect(c.trigger.getAttribute("data-placeholder")).toBe("true");
    expect(c.el.hasAttribute("data-has-value")).toBe(false);
    expect(c.panel.hidden).toBe(true);
    expect(changes).toBe(1);
  });

  it("the input variant's clear dispatches exactly one change through the direct binding", () => {
    const c = mountCombo({ options: CITIES, clearable: true });
    c.control.click();
    c.items()[0].click();
    expect(c.select.value).toBe("syd");
    let changes = 0;
    c.select.addEventListener("change", () => changes++);
    c.el.querySelector("[data-pc-combo-clear]").click();
    expect(c.select.value).toBe("");
    expect(c.input.value).toBe("");
    expect(changes).toBe(1);
    expect(c.panel.hidden).toBe(true);
  });

  it("a press that starts inside the combobox and releases outside does not dismiss", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    c.input.dispatchEvent(
      pointerEvent("pointerdown", "touch", { clientX: 50, clientY: 10 }),
    );
    document.body.dispatchEvent(
      pointerEvent("pointerup", "touch", { clientX: 50, clientY: 10 }),
    );
    expect(c.panel.hidden).toBe(false);
  });

  it("inside pointerdown does not close before the option click lands", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    c.items()[0].dispatchEvent(pointerEvent("pointerdown", "touch"));
    expect(c.panel.hidden).toBe(false);
  });

  it("focusout to an element outside closes and restores the display", async () => {
    const c = mountCombo({ options: CITIES });
    c.select.value = "tyo";
    c.hook.syncFromSelect();
    c.control.click();
    type(c.input, "sy");
    // focus genuinely leaves the component, then the event reports it
    c.input.blur();
    c.el.dispatchEvent(
      new FocusEvent("focusout", { relatedTarget: document.body }),
    );
    // the close verifies where focus actually landed one tick later
    await new Promise((r) => setTimeout(r, 0));
    expect(c.panel.hidden).toBe(true);
    expect(c.input.value).toBe("Tokyo");
  });

  it("a null-relatedTarget focusout does NOT close when focus stayed inside (the iOS trigger flash)", async () => {
    // iOS reports relatedTarget null even when focus moves WITHIN the
    // component - trusting it closed the panel mid-tap and the trigger
    // click then reopened it, an endless flash (device-log verified)
    const c = mountCombo({ options: CITIES });
    c.control.click();
    c.input.focus();
    c.el.dispatchEvent(new FocusEvent("focusout", { relatedTarget: null }));
    await new Promise((r) => setTimeout(r, 0));
    expect(c.panel.hidden).toBe(false);
  });

  it("the trigger variant closes on a second trigger tap even when focusout reports null", async () => {
    const c = mountCombo({ options: CITIES, trigger: true });
    c.trigger.click();
    expect(c.panel.hidden).toBe(false);
    // iOS tap on the trigger: input blurs with relatedTarget null while
    // focus actually lands on the button - the panel must survive the
    // focusout and let the click toggle it closed
    c.trigger.focus();
    c.el.dispatchEvent(new FocusEvent("focusout", { relatedTarget: null }));
    c.trigger.click();
    await new Promise((r) => setTimeout(r, 0));
    expect(c.panel.hidden).toBe(true);
  });

  it("Escape closes when open and is consumed; passes through when closed", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    const first = key(c.input, "Escape");
    expect(first.defaultPrevented).toBe(true);
    expect(c.panel.hidden).toBe(true);
    const second = key(c.input, "Escape");
    expect(second.defaultPrevented).toBe(false);
  });
});

describe("filtering", () => {
  it("the best-scoring match wins the highlight, not the first in DOM order", () => {
    // The original playground bug: Stockholm's fuzzy s-t-o-k subsequence
    // sat ABOVE Tokyo's prefix match in DOM order and stole the highlight,
    // so Enter committed the wrong value. The fixture pins that ordering.
    const c = mountCombo({
      options: [
        option("sto", "Stockholm"),
        option("lis", "Lisbon"),
        option("tyo", "Tokyo"),
      ],
    });
    c.control.click();
    type(c.input, "tok");
    expect(c.visible().map((i) => i.dataset.value)).toEqual(["sto", "tyo"]);
    expect(c.highlighted()?.dataset.value).toBe("tyo");
  });

  it("no match shows the empty state; clearing hides it and restores options", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    type(c.input, "zzz");
    expect(c.visible()).toHaveLength(0);
    expect(c.empty().hidden).toBe(false);
    type(c.input, "");
    expect(c.visible()).toHaveLength(4);
    expect(c.empty().hidden).toBe(true);
  });

  it("a group hides itself when the query filters out every option inside", () => {
    const c = mountCombo({
      groups: [
        { label: "Oceania", options: [option("syd", "Sydney")] },
        { label: "Europe", options: [option("lis", "Lisbon")] },
      ],
    });
    c.control.click();
    type(c.input, "lis");
    const [oceania] = c.el.querySelectorAll("[data-pc-combo-group]");
    expect(oceania.hidden).toBe(true);
  });
});

describe("selection through the hidden select", () => {
  it("click chooses: select value, bubbled input+change, display, close, check", () => {
    const c = mountCombo({ options: CITIES });
    let inputs = 0;
    let changes = 0;
    c.select.addEventListener("input", () => inputs++);
    c.select.addEventListener("change", () => changes++);
    c.control.click();
    c.items()[1].click();
    expect(c.select.value).toBe("tyo");
    expect(inputs).toBe(1);
    expect(changes).toBe(1);
    expect(c.input.value).toBe("Tokyo");
    expect(c.panel.hidden).toBe(true);
    expect(c.items()[1].getAttribute("aria-selected")).toBe("true");
  });

  it("Enter chooses the highlighted option and is consumed; closed Enter is not", () => {
    const c = mountCombo({ options: CITIES });
    const closedEnter = key(c.input, "Enter");
    expect(closedEnter.defaultPrevented).toBe(false);
    c.control.click();
    type(c.input, "lis");
    const openEnter = key(c.input, "Enter");
    expect(openEnter.defaultPrevented).toBe(true);
    expect(c.select.value).toBe("lis");
  });

  it("disabled options are skipped by highlight and inert to clicks", () => {
    const c = mountCombo({
      options: [option("syd", "Sydney"), option("sto", "Stockholm", true)],
    });
    c.control.click();
    type(c.input, "sto");
    expect(c.highlighted()).toBe(null);
    c.items()[1].click();
    expect(c.select.value).toBe("");
  });

  it("opening with a chosen value homes the highlight on it", () => {
    const c = mountCombo({ options: CITIES });
    c.select.value = "lis";
    c.hook.syncFromSelect();
    c.control.click();
    expect(c.highlighted()?.dataset.value).toBe("lis");
  });
});

describe("the boundary cycle", () => {
  it("wraps through an empty stop in both directions", () => {
    const c = mountCombo({ options: CITIES });
    key(c.input, "ArrowDown"); // opens, homes on first
    key(c.input, "End");
    expect(c.highlighted()?.dataset.value).toBe("sto");
    key(c.input, "ArrowDown");
    expect(c.highlighted()).toBe(null);
    expect(c.input.hasAttribute("aria-activedescendant")).toBe(false);
    key(c.input, "ArrowDown");
    expect(c.highlighted()?.dataset.value).toBe("syd");
    key(c.input, "ArrowUp");
    expect(c.highlighted()).toBe(null);
    key(c.input, "ArrowUp");
    expect(c.highlighted()?.dataset.value).toBe("sto");
  });
});

describe("multiple with chips", () => {
  it("choosing toggles, keeps the panel open, clears the query, builds a chip", () => {
    const c = mountCombo({ options: CITIES, multiple: true });
    c.control.click();
    type(c.input, "syd");
    key(c.input, "Enter");
    expect(c.select.querySelector('option[value="syd"]').selected).toBe(true);
    expect(c.panel.hidden).toBe(false);
    expect(c.input.value).toBe("");
    expect(c.chips()).toHaveLength(1);
    expect(c.chips()[0].textContent).toContain("Sydney");
  });

  it("the highlight stays on the item just picked, and arrows resume from it", () => {
    const c = mountCombo({ options: CITIES, multiple: true });
    c.control.click();
    const last = c.items()[c.items().length - 1];
    last.click();
    expect(last.hasAttribute("data-highlighted")).toBe(true);
    expect(c.input.getAttribute("aria-activedescendant")).toBe(last.id);
    // Down from the last item enters the empty stop, not the top
    key(c.input, "ArrowDown");
    expect(c.el.querySelector("[data-highlighted]")).toBeNull();
  });

  it("a filtered pick clears the query but keeps the picked item highlighted", () => {
    const c = mountCombo({ options: CITIES, multiple: true });
    c.control.click();
    type(c.input, "tok");
    key(c.input, "Enter");
    const tokyo = c.items().find((i) => i.dataset.value === "tyo");
    expect(tokyo.hasAttribute("data-highlighted")).toBe(true);
    expect(c.items().filter((i) => !i.hidden).length).toBeGreaterThan(1);
  });

  it("the placeholder attribute is server truth - the hook never rewrites it", () => {
    // the cap-rest is pure CSS on [data-max-reached]; the attribute must
    // survive every selection transition so live server changes always win
    const c = mountCombo({ options: CITIES, multiple: true, maxItems: 2 });
    c.control.click();
    c.items()[0].click();
    expect(c.input.getAttribute("placeholder")).toBe("Pick...");
    c.items()[1].click();
    expect(c.el.hasAttribute("data-max-reached")).toBe(true);
    expect(c.input.getAttribute("placeholder")).toBe("Pick...");
    // server changes it while capped - updated() must not revert it
    c.input.setAttribute("placeholder", "Añadir…");
    c.hook.updated();
    expect(c.input.getAttribute("placeholder")).toBe("Añadir…");
    c.chips()[0].querySelector("[data-pc-combo-chip-remove]").click();
    expect(c.el.hasAttribute("data-max-reached")).toBe(false);
    expect(c.input.getAttribute("placeholder")).toBe("Añadir…");
  });

  it("server-rendered rich chips survive updated() when the selection matches", () => {
    const c = mountCombo({ options: CITIES, multiple: true });
    // simulate the LiveView patch: server marked options selected and
    // rendered rich :chip content with matching data-values
    c.select.querySelector('option[value="syd"]').selected = true;
    c.chips_el = c.el.querySelector("[data-pc-combo-chips]");
    c.chips_el.innerHTML =
      '<span class="pc-combo-box__chip" data-pc-combo-chip data-value="syd">' +
      '<span class="pc-combo-box__chip-label"><em>RICH</em> Sydney</span>' +
      '<button type="button" class="pc-combo-box__chip-remove" data-pc-combo-chip-remove data-value="syd" tabindex="-1"></button></span>';
    c.hook.updated();
    expect(c.chips_el.querySelector("em")).not.toBeNull();
    // incremental sync: a client-side pick APPENDS a plain chip and never
    // touches the existing rich one - zero flash, server upgrades later
    c.control.click();
    c.items()[1].click();
    expect(c.chips()).toHaveLength(2);
    expect(c.chips()[0].querySelector("em")).not.toBeNull();
    expect(c.chips()[1].querySelector("em")).toBeNull();
    expect(c.chips().map((x) => x.dataset.value)).toEqual(["syd", "tyo"]);
    // unpicking removes exactly the right chip, leaving the rich one alone
    c.items()[1].click();
    expect(c.chips()).toHaveLength(1);
    expect(c.chips()[0].querySelector("em")).not.toBeNull();
  });

  it("server-rendered :selected content survives sync when it matches; client picks go optimistic", () => {
    const c = mountCombo({ options: CITIES, trigger: true, multiple: true });
    // simulate the patch: server chose syd+tyo and rendered rich label content
    c.select.querySelector('option[value="syd"]').selected = true;
    c.select.querySelector('option[value="tyo"]').selected = true;
    const label = c.triggerLabel();
    label.dataset.customLabel = "true";
    label.dataset.values = JSON.stringify(["syd", "tyo"]);
    label.innerHTML =
      '<span class="pc-combo-box__selected-content"><em>RICH</em></span>';
    c.hook.updated();
    expect(label.querySelector("em")).not.toBeNull();
    // a client-side pick diverges from the rendered values -> optimistic text
    c.trigger.click();
    c.items()
      .find((i) => i.dataset.value === "lis")
      .click();
    expect(label.querySelector("em")).toBeNull();
    expect(label.textContent).toBe("3 selected");
    expect(label.dataset.values).toBeUndefined();
  });

  it("freshness is a set check - chosen-order stamps and chips survive against option-order reads", () => {
    const c = mountCombo({ options: CITIES, trigger: true, multiple: true });
    c.select.querySelector('option[value="syd"]').selected = true;
    c.select.querySelector('option[value="tyo"]').selected = true;
    const label = c.triggerLabel();
    label.dataset.customLabel = "true";
    // server stamped CHOSEN order (tyo picked first); hook reads option order
    label.dataset.values = JSON.stringify(["tyo", "syd"]);
    label.innerHTML =
      '<span class="pc-combo-box__selected-content"><em>RICH</em></span>';
    c.hook.updated();
    expect(label.querySelector("em")).not.toBeNull();
  });

  it("values containing old-delimiter bytes can never falsely match a different selection", () => {
    const c = mountCombo({ options: CITIES, trigger: true, multiple: true });
    c.select.querySelector('option[value="syd"]').selected = true;
    c.select.querySelector('option[value="tyo"]').selected = true;
    const label = c.triggerLabel();
    label.dataset.customLabel = "true";
    // a single weird value whose contents embed both real values - JSON
    // keeps it one value, so it must NOT match the two-value selection
    label.dataset.values = JSON.stringify(["syd\u001ftyo"]);
    label.innerHTML =
      '<span class="pc-combo-box__selected-content"><em>WRONG</em></span>';
    c.hook.updated();
    expect(label.querySelector("em")).toBeNull();
  });

  it("duplicate values stay fresh - multiset counting, never set flattening", () => {
    const c = mountCombo({ options: CITIES, multiple: true });
    // two selected options sharing a value (degenerate but legal HTML)
    const dup = document.createElement("option");
    dup.value = "syd";
    dup.textContent = "Sydney 2";
    c.select.appendChild(dup);
    c.select
      .querySelectorAll('option[value="syd"]')
      .forEach((o) => (o.selected = true));
    c.chips_el = c.el.querySelector("[data-pc-combo-chips]");
    c.chips_el.innerHTML =
      '<span class="pc-combo-box__chip" data-pc-combo-chip data-value="syd"><span class="pc-combo-box__chip-label"><em>R1</em></span></span>' +
      '<span class="pc-combo-box__chip" data-pc-combo-chip data-value="syd"><span class="pc-combo-box__chip-label"><em>R2</em></span></span>';
    c.hook.updated();
    expect(c.chips_el.querySelectorAll("em")).toHaveLength(2);
  });

  it("inside a phx-change form, a stale rich label is kept until the patch (no text flash)", () => {
    const c = mountCombo({ options: CITIES, trigger: true, multiple: true });
    const form = document.createElement("form");
    form.setAttribute("phx-change", "changed");
    c.el.parentNode.insertBefore(form, c.el);
    form.appendChild(c.el);
    c.select.querySelector('option[value="syd"]').selected = true;
    const label = c.triggerLabel();
    label.dataset.customLabel = "true";
    label.dataset.values = JSON.stringify(["syd"]);
    label.innerHTML =
      '<span class="pc-combo-box__selected-content"><em>RICH</em></span>';
    c.hook.updated();
    // pick another: wired form -> patch is coming -> rich content stays
    c.trigger.click();
    c.items()
      .find((i) => i.dataset.value === "tyo")
      .click();
    expect(label.querySelector("em")).not.toBeNull();
  });

  it("a wired form whose handler never re-renders self-heals to optimistic text after the grace window", () => {
    vi.useFakeTimers();
    const now = vi.spyOn(performance, "now");
    now.mockReturnValue(0);
    const c = mountCombo({ options: CITIES, trigger: true, multiple: true });
    const form = document.createElement("form");
    form.setAttribute("phx-change", "changed");
    c.el.parentNode.insertBefore(form, c.el);
    form.appendChild(c.el);
    c.select.querySelector('option[value="syd"]').selected = true;
    const label = c.triggerLabel();
    label.dataset.customLabel = "true";
    label.dataset.values = JSON.stringify(["syd"]);
    label.innerHTML =
      '<span class="pc-combo-box__selected-content"><em>RICH</em></span>';
    c.hook.updated();
    c.trigger.click();
    c.items()
      .find((i) => i.dataset.value === "tyo")
      .click();
    // grace window: stale rich kept while the patch is presumed en route
    expect(label.querySelector("em")).not.toBeNull();
    // no patch ever arrives - the timer degrades to honest optimistic text
    now.mockReturnValue(2100);
    vi.advanceTimersByTime(2100);
    expect(label.querySelector("em")).toBeNull();
    expect(label.textContent).toBe("2 selected");
    now.mockRestore();
    vi.useRealTimers();
  });

  it("continuing picks never extend the grace window - it anchors to the first divergence", () => {
    vi.useFakeTimers();
    const now = vi.spyOn(performance, "now");
    now.mockReturnValue(0);
    const c = mountCombo({ options: CITIES, trigger: true, multiple: true });
    const form = document.createElement("form");
    form.setAttribute("phx-change", "changed");
    c.el.parentNode.insertBefore(form, c.el);
    form.appendChild(c.el);
    c.select.querySelector('option[value="syd"]').selected = true;
    const label = c.triggerLabel();
    label.dataset.customLabel = "true";
    label.dataset.values = JSON.stringify(["syd"]);
    label.innerHTML =
      '<span class="pc-combo-box__selected-content"><em>RICH</em></span>';
    c.hook.updated();
    // divergence begins
    c.trigger.click();
    c.items()
      .find((i) => i.dataset.value === "tyo")
      .click();
    expect(label.querySelector("em")).not.toBeNull();
    // keep interacting inside the window - must NOT re-arm it
    now.mockReturnValue(1500);
    vi.advanceTimersByTime(1500);
    c.items()
      .find((i) => i.dataset.value === "lis")
      .click();
    expect(label.querySelector("em")).not.toBeNull();
    // past 2s from the FIRST divergence: degrade despite recent activity
    now.mockReturnValue(2100);
    vi.advanceTimersByTime(600);
    expect(label.querySelector("em")).toBeNull();
    now.mockRestore();
    vi.useRealTimers();
  });

  it("the panel stays open across LiveView patches mid-multi-pick", () => {
    const c = mountCombo({ options: CITIES, multiple: true });
    c.control.click();
    c.items()[0].click();
    expect(c.panel.hidden).toBe(false);
    // the phx-change patch: server always renders the panel hidden and
    // aria-expanded false - open-state belongs to the client
    c.panel.hidden = true;
    c.input.setAttribute("aria-expanded", "false");
    c.hook.updated();
    expect(c.panel.hidden).toBe(false);
    expect(c.input.getAttribute("aria-expanded")).toBe("true");
    // a panel the user closed stays closed through patches
    key(c.input, "Escape");
    c.hook.updated();
    expect(c.panel.hidden).toBe(true);
  });

  it("client-built chips clone the server-rendered :chip template - rich immediately", () => {
    const c = mountCombo({ options: CITIES, multiple: true });
    const tpl = document.createElement("template");
    tpl.setAttribute("data-pc-combo-chip-template", "");
    tpl.dataset.value = "tyo";
    tpl.innerHTML = '<em class="rich-bit">T</em><span>Tokyo</span>';
    c.el.appendChild(tpl);
    c.control.click();
    c.items()
      .find((i) => i.dataset.value === "tyo")
      .click();
    const chip = c.chips().find((x) => x.dataset.value === "tyo");
    expect(chip.querySelector("em.rich-bit")).not.toBeNull();
    // options without a template still build plain text chips
    c.items()
      .find((i) => i.dataset.value === "syd")
      .click();
    const plain = c.chips().find((x) => x.dataset.value === "syd");
    expect(plain.querySelector("em")).toBeNull();
    expect(plain.textContent).toContain("Sydney");
  });

  it("a server reorder reaches hook-owned chips via data-order; unstamped client picks stay last", () => {
    const c = mountCombo({ options: CITIES, multiple: true });
    c.chips_el = c.el.querySelector("[data-pc-combo-chips]");
    c.control.click();
    c.items()[0].click(); // syd
    c.items()[1].click(); // tyo
    expect(c.chips().map((x) => x.dataset.value)).toEqual(["syd", "tyo"]);
    // the patch updates data-order (attrs update even on ignored nodes)
    c.chips_el.dataset.order = JSON.stringify(["tyo", "syd"]);
    c.hook.updated();
    expect(c.chips().map((x) => x.dataset.value)).toEqual(["tyo", "syd"]);
    // a fresh client pick the server has not stamped yet appends last
    c.items()[2].click(); // lis
    expect(c.chips().map((x) => x.dataset.value)).toEqual([
      "tyo",
      "syd",
      "lis",
    ]);
  });

  it("the highlight survives LiveView patches - no re-homing on the first item", () => {
    const c = mountCombo({ options: CITIES, multiple: true });
    c.control.click();
    const third = c.items()[2];
    third.click();
    expect(third.hasAttribute("data-highlighted")).toBe(true);
    // the patch: server renders options without client highlight state
    for (const i of c.items()) i.removeAttribute("data-highlighted");
    c.hook.updated();
    expect(third.hasAttribute("data-highlighted")).toBe(true);
    expect(c.items()[0].hasAttribute("data-highlighted")).toBe(false);
  });

  it("choosing a chosen option un-chooses it", () => {
    const c = mountCombo({ options: CITIES, multiple: true });
    c.control.click();
    c.items()[0].click();
    c.items()[0].click();
    expect(c.select.querySelector('option[value="syd"]').selected).toBe(false);
    expect(c.chips()).toHaveLength(0);
  });

  it("the chip remove button unselects and dispatches through the select", () => {
    const c = mountCombo({ options: CITIES, multiple: true });
    let changes = 0;
    c.select.addEventListener("change", () => changes++);
    c.control.click();
    c.items()[0].click();
    c.items()[1].click();
    expect(c.chips()).toHaveLength(2);
    c.chips()[0].querySelector("[data-pc-combo-chip-remove]").click();
    expect(c.chips()).toHaveLength(1);
    expect(c.select.querySelector('option[value="syd"]').selected).toBe(false);
    expect(changes).toBe(3);
  });

  it("Backspace in an empty input removes the last chip", () => {
    const c = mountCombo({ options: CITIES, multiple: true });
    c.control.click();
    c.items()[0].click();
    c.items()[1].click();
    key(c.input, "Backspace");
    expect(c.chips()).toHaveLength(1);
    expect(c.chips()[0].textContent).toContain("Sydney");
  });

  it("Backspace with a query is just editing - chips survive", () => {
    const c = mountCombo({ options: CITIES, multiple: true });
    c.control.click();
    c.items()[0].click();
    type(c.input, "to");
    key(c.input, "Backspace");
    expect(c.chips()).toHaveLength(1);
  });

  it("max_items blocks new choices and marks the root; removal unblocks", () => {
    const c = mountCombo({ options: CITIES, multiple: true, maxItems: 2 });
    c.control.click();
    c.items()[0].click();
    c.items()[1].click();
    expect(c.el.hasAttribute("data-max-reached")).toBe(true);
    c.items()[2].click();
    expect(c.select.querySelector('option[value="lis"]').selected).toBe(false);
    c.chips()[0].querySelector("[data-pc-combo-chip-remove]").click();
    expect(c.el.hasAttribute("data-max-reached")).toBe(false);
    c.items()[2].click();
    expect(c.select.querySelector('option[value="lis"]').selected).toBe(true);
  });
});

describe("clearable", () => {
  it("the clear button empties the select, dispatches, and clears the display", () => {
    const c = mountCombo({ options: CITIES, clearable: true });
    let changes = 0;
    c.select.addEventListener("change", () => changes++);
    c.control.click();
    c.items()[1].click();
    expect(c.input.value).toBe("Tokyo");
    expect(c.el.hasAttribute("data-has-value")).toBe(true);
    c.el.querySelector("[data-pc-combo-clear]").click();
    expect(c.select.value).toBe("");
    expect(c.input.value).toBe("");
    expect(c.el.hasAttribute("data-has-value")).toBe(false);
    expect(changes).toBe(2);
  });
});

describe("hardening riders", () => {
  it("form.reset() re-syncs chips and display from the select", () => {
    const form = document.createElement("form");
    document.body.appendChild(form);
    const c = mountCombo({ options: CITIES });
    form.appendChild(c.el);
    // re-mount so the hook binds to the form it now lives in
    c.hook.destroyed();
    c.hook.mounted();
    c.control.click();
    c.items()[1].click();
    expect(c.input.value).toBe("Tokyo");
    form.reset();
    return new Promise((resolve) =>
      setTimeout(() => {
        expect(c.input.value).toBe("");
        resolve();
      }, 5),
    );
  });

  it("the live region announces counts and the empty state", () => {
    const c = mountCombo({ options: CITIES });
    c.control.click();
    expect(c.live().textContent).toBe("4 results");
    type(c.input, "tok");
    expect(c.live().textContent).toBe("2 results");
    type(c.input, "zzz");
    expect(c.live().textContent).toBe("No results found");
  });
});

describe("trigger variant", () => {
  it("the button opens the panel, focuses the search input, mirrors aria-expanded", () => {
    const c = mountCombo({ options: CITIES, trigger: true });
    c.trigger.click();
    expect(c.panel.hidden).toBe(false);
    expect(c.trigger.getAttribute("aria-expanded")).toBe("true");
    expect(document.activeElement).toBe(c.input);
  });

  it("choosing closes, returns focus to the trigger, and updates the label", () => {
    const c = mountCombo({ options: CITIES, trigger: true });
    c.trigger.click();
    type(c.input, "lis");
    key(c.input, "Enter");
    expect(c.panel.hidden).toBe(true);
    expect(c.trigger.getAttribute("aria-expanded")).toBe("false");
    expect(document.activeElement).toBe(c.trigger);
    expect(c.triggerLabel().textContent).toBe("Lisbon");
    expect(c.trigger.hasAttribute("data-placeholder")).toBe(false);
  });

  it("multiple keeps the panel open and the count label live", () => {
    const c = mountCombo({ options: CITIES, trigger: true, multiple: true });
    c.trigger.click();
    c.items()[0].click();
    c.items()[1].click();
    expect(c.panel.hidden).toBe(false);
    expect(c.triggerLabel().textContent).toBe("2 selected");
  });

  it("ArrowDown on the trigger opens; Escape closes back to the trigger", () => {
    const c = mountCombo({ options: CITIES, trigger: true });
    c.trigger.focus();
    key(c.trigger, "ArrowDown");
    expect(c.panel.hidden).toBe(false);
    key(c.input, "Escape");
    expect(c.panel.hidden).toBe(true);
    expect(document.activeElement).toBe(c.trigger);
  });

  it("updated() reconciles the trigger label from the server-patched select", () => {
    const c = mountCombo({ options: CITIES, trigger: true });
    // the server patched a value in
    c.select.value = "tyo";
    c.hook.updated();
    expect(c.triggerLabel().textContent).toBe("Tokyo");
    expect(c.trigger.hasAttribute("data-placeholder")).toBe(false);
    // and patched it back out
    c.select.value = "";
    c.hook.updated();
    expect(c.triggerLabel().textContent).toBe("Pick...");
    expect(c.trigger.hasAttribute("data-placeholder")).toBe(true);
  });

  it("clearing every choice restores the placeholder state", () => {
    const c = mountCombo({ options: CITIES, trigger: true, multiple: true });
    c.trigger.click();
    c.items()[0].click();
    c.items()[0].click();
    expect(c.triggerLabel().textContent).toBe("Pick...");
    expect(c.trigger.hasAttribute("data-placeholder")).toBe(true);
  });
});

describe("panel flip", () => {
  function withRects(
    c,
    { controlTop, controlBottom, panelHeight, viewport = 800 },
  ) {
    c.control.getBoundingClientRect = () => ({
      top: controlTop,
      bottom: controlBottom,
      left: 0,
      right: 200,
      width: 200,
      height: controlBottom - controlTop,
    });
    Object.defineProperty(c.panel, "offsetHeight", {
      configurable: true,
      value: panelHeight,
    });
    Object.defineProperty(window, "innerHeight", {
      configurable: true,
      value: viewport,
      writable: true,
    });
  }

  it("stays below when there is room", () => {
    const c = mountCombo({ options: CITIES });
    withRects(c, { controlTop: 100, controlBottom: 140, panelHeight: 200 });
    c.control.click();
    expect(c.panel.hasAttribute("data-flip")).toBe(false);
  });

  it("flips above when the viewport has no room below and more above", () => {
    const c = mountCombo({ options: CITIES });
    withRects(c, { controlTop: 700, controlBottom: 740, panelHeight: 200 });
    c.control.click();
    expect(c.panel.hasAttribute("data-flip")).toBe(true);
  });

  it("re-measures on scroll while open and clears the flip when room returns", () => {
    const c = mountCombo({ options: CITIES });
    withRects(c, { controlTop: 700, controlBottom: 740, panelHeight: 200 });
    c.control.click();
    expect(c.panel.hasAttribute("data-flip")).toBe(true);
    withRects(c, { controlTop: 100, controlBottom: 140, panelHeight: 200 });
    window.dispatchEvent(new Event("resize"));
    expect(c.panel.hasAttribute("data-flip")).toBe(false);
  });

  it("re-measures when filtering changes the panel height", () => {
    const c = mountCombo({ options: CITIES });
    // short panel fits below at first...
    withRects(c, { controlTop: 700, controlBottom: 740, panelHeight: 40 });
    c.control.click();
    expect(c.panel.hasAttribute("data-flip")).toBe(false);
    // ...then broadening the query grows it past the available space
    Object.defineProperty(c.panel, "offsetHeight", {
      configurable: true,
      value: 200,
    });
    type(c.input, "");
    expect(c.panel.hasAttribute("data-flip")).toBe(true);
  });

  it("caps the scroll area when neither side fits, on the winning side", () => {
    const c = mountCombo({ options: CITIES });
    // viewport 300: above the control 172px, below 52px, panel wants 200px
    withRects(c, {
      controlTop: 180,
      controlBottom: 220,
      panelHeight: 200,
      viewport: 300,
    });
    Object.defineProperty(
      c.el.querySelector(".pc-combo-box__list"),
      "offsetHeight",
      {
        configurable: true,
        value: 190,
      },
    );
    c.control.click();
    expect(c.panel.hasAttribute("data-flip")).toBe(true);
    // room above = 180-8=172, chrome = 200-190=10 -> cap 162
    expect(c.el.querySelector(".pc-combo-box__list").style.maxHeight).toBe(
      "162px",
    );
  });

  it("never crosses the edge even when less than a row fits", () => {
    const c = mountCombo({ options: CITIES });
    // room above = 40-8=32, chrome 10 -> cap 22: a sliver, but contained
    withRects(c, {
      controlTop: 40,
      controlBottom: 80,
      panelHeight: 200,
      viewport: 100,
    });
    Object.defineProperty(
      c.el.querySelector(".pc-combo-box__list"),
      "offsetHeight",
      {
        configurable: true,
        value: 190,
      },
    );
    c.control.click();
    expect(c.el.querySelector(".pc-combo-box__list").style.maxHeight).toBe(
      "22px",
    );
  });

  it("the cap clears when room returns", () => {
    const c = mountCombo({ options: CITIES });
    withRects(c, {
      controlTop: 180,
      controlBottom: 220,
      panelHeight: 200,
      viewport: 300,
    });
    Object.defineProperty(
      c.el.querySelector(".pc-combo-box__list"),
      "offsetHeight",
      {
        configurable: true,
        value: 190,
      },
    );
    c.control.click();
    expect(c.el.querySelector(".pc-combo-box__list").style.maxHeight).not.toBe(
      "",
    );
    withRects(c, {
      controlTop: 100,
      controlBottom: 140,
      panelHeight: 200,
      viewport: 800,
    });
    window.dispatchEvent(new Event("resize"));
    expect(c.el.querySelector(".pc-combo-box__list").style.maxHeight).toBe("");
    expect(c.panel.hasAttribute("data-flip")).toBe(false);
  });

  it("close clears the flip so the next open measures fresh", () => {
    const c = mountCombo({ options: CITIES });
    withRects(c, { controlTop: 700, controlBottom: 740, panelHeight: 200 });
    c.control.click();
    key(c.input, "Escape");
    expect(c.panel.hasAttribute("data-flip")).toBe(false);
  });
});

describe("server ownership", () => {
  it("updated() re-syncs from the select - the server wins", () => {
    const c = mountCombo({ options: CITIES });
    c.select.value = "syd";
    c.hook.updated();
    expect(c.input.value).toBe("Sydney");
    expect(c.items()[0].getAttribute("aria-selected")).toBe("true");
  });

  it("typing keystrokes never reach an enclosing form; selection does", () => {
    const c = mountCombo({ options: CITIES });
    const form = document.createElement("form");
    document.body.appendChild(form);
    form.appendChild(c.el);
    let formInputs = 0;
    form.addEventListener("input", () => formInputs++);
    c.control.click();
    type(c.input, "to");
    type(c.input, "tok");
    expect(formInputs).toBe(0);
    key(c.input, "Enter");
    expect(formInputs).toBe(1);
  });
});
