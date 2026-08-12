// PetalSortable: the reorder maths and the keyboard lift state machine.
//
// Everything that decides an ORDER lives in SortableCore as a pure function,
// so most of this file needs no DOM at all. The hook specs at the bottom
// cover only the wiring - which key does what, what reaches the server, and
// what a long press has to earn before it counts as a lift.
//
// The markup mirrors what PetalComponents.Sortable renders;
// test/petal/sortable_test.exs pins that structure on the Elixir side, so
// update both together if the anatomy changes.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import hooks, { SortableCore } from "../../assets/js/petal_components.js";

// ---------------------------------------------------------------------------
// Pure: the reorder maths
// ---------------------------------------------------------------------------

describe("SortableCore.arrayMove", () => {
  const list = ["a", "b", "c", "d"];

  it("moves an item down", () => {
    expect(SortableCore.arrayMove(list, 0, 2)).toEqual(["b", "c", "a", "d"]);
  });

  it("moves an item up", () => {
    expect(SortableCore.arrayMove(list, 3, 1)).toEqual(["a", "d", "b", "c"]);
  });

  it("moving to the same index is a no-op", () => {
    expect(SortableCore.arrayMove(list, 2, 2)).toEqual(list);
  });

  it("clamps a destination past either end", () => {
    expect(SortableCore.arrayMove(list, 0, 99)).toEqual(["b", "c", "d", "a"]);
    expect(SortableCore.arrayMove(list, 3, -5)).toEqual(["d", "a", "b", "c"]);
  });

  it("never mutates the input", () => {
    const original = list.slice();
    SortableCore.arrayMove(list, 0, 3);
    expect(list).toEqual(original);
  });

  it("ignores an out-of-range source", () => {
    expect(SortableCore.arrayMove(list, 9, 0)).toEqual(list);
  });
});

describe("SortableCore.indexFromPoint - vertical", () => {
  // four 40px rows stacked from y=0, so midpoints are 20, 60, 100, 140
  const rects = [0, 1, 2, 3].map((i) => ({
    top: i * 40,
    left: 0,
    width: 200,
    height: 40,
  }));

  const at = (y, activeIndex = 0) =>
    SortableCore.indexFromPoint({ rects, x: 100, y, activeIndex });

  it("stays put above the first midpoint it has not crossed", () => {
    expect(at(5)).toBe(0);
  });

  it("counts each midpoint the pointer has passed", () => {
    // dragging row 0 downward: row 1's midpoint is 60, row 2's is 100
    expect(at(70)).toBe(1);
    expect(at(110)).toBe(2);
    expect(at(150)).toBe(3);
  });

  it("clamps past the end of the list", () => {
    expect(at(10_000)).toBe(3);
  });

  it("skips the dragged item's own rect", () => {
    // dragging the LAST row up to y=70: it has passed rows 0 and 1, so it
    // lands at index 2. Row 3's own rect must not count towards that.
    expect(SortableCore.indexFromPoint({ rects, x: 100, y: 70, activeIndex: 3 })).toBe(2);
  });

  it("a pointer above everything lands at index 0", () => {
    expect(SortableCore.indexFromPoint({ rects, x: 100, y: -50, activeIndex: 3 })).toBe(0);
  });
});

describe("SortableCore.indexFromPoint - grid", () => {
  // 2 columns x 2 rows of 100x100 cells at (0,0), (100,0), (0,100), (100,100)
  const rects = [
    { top: 0, left: 0, width: 100, height: 100 },
    { top: 0, left: 100, width: 100, height: 100 },
    { top: 100, left: 0, width: 100, height: 100 },
    { top: 100, left: 100, width: 100, height: 100 },
  ];

  const at = (x, y, activeIndex = 0) =>
    SortableCore.indexFromPoint({ rects, x, y, orientation: "grid", activeIndex });

  it("the cell under the pointer is the slot being asked for", () => {
    // this is the case reading-order counting gets wrong: dragged from the
    // top-left, the pointer is over the bottom-left cell, so index 2 - not
    // the top-right cell that counting midpoints in reading order produces
    expect(at(20, 150)).toBe(2);
    expect(at(180, 150)).toBe(3);
    expect(at(180, 50)).toBe(1);
  });

  it("anywhere inside a cell counts, not just past its midpoint", () => {
    // uniform cells reflow into each other, so the dragged item lands where
    // the pointer already is and stays put - no midpoint hysteresis needed
    expect(at(120, 50)).toBe(1);
    expect(at(190, 50)).toBe(1);
  });

  it("hovering its own cell asks for no move", () => {
    expect(at(50, 50)).toBe(0);
    expect(SortableCore.indexFromPoint({
      rects,
      x: 150,
      y: 150,
      orientation: "grid",
      activeIndex: 3,
    })).toBe(3);
  });

  it("falls back to reading order in the gutters and past the end", () => {
    // below every cell: the whole grid is behind the pointer
    expect(at(50, 500)).toBe(3);
    // above every cell
    expect(SortableCore.indexFromPoint({
      rects,
      x: 50,
      y: -100,
      orientation: "grid",
      activeIndex: 3,
    })).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// Pure: arrow-key stepping
// ---------------------------------------------------------------------------

describe("SortableCore.nextKeyboardIndex", () => {
  it("vertical lists move one row per press", () => {
    expect(SortableCore.nextKeyboardIndex({ index: 2, key: "ArrowUp", count: 5 })).toBe(1);
    expect(SortableCore.nextKeyboardIndex({ index: 2, key: "ArrowDown", count: 5 })).toBe(3);
  });

  it("vertical lists ignore the horizontal arrows", () => {
    expect(SortableCore.nextKeyboardIndex({ index: 2, key: "ArrowLeft", count: 5 })).toBe(null);
    expect(SortableCore.nextKeyboardIndex({ index: 2, key: "ArrowRight", count: 5 })).toBe(null);
  });

  it("grids step by one horizontally and by a full row vertically", () => {
    const grid = { orientation: "grid", columns: 3, count: 9 };

    expect(SortableCore.nextKeyboardIndex({ ...grid, index: 4, key: "ArrowLeft" })).toBe(3);
    expect(SortableCore.nextKeyboardIndex({ ...grid, index: 4, key: "ArrowRight" })).toBe(5);
    expect(SortableCore.nextKeyboardIndex({ ...grid, index: 4, key: "ArrowUp" })).toBe(1);
    expect(SortableCore.nextKeyboardIndex({ ...grid, index: 4, key: "ArrowDown" })).toBe(7);
  });

  it("clamps at both ends rather than wrapping", () => {
    expect(SortableCore.nextKeyboardIndex({ index: 0, key: "ArrowUp", count: 5 })).toBe(0);
    expect(SortableCore.nextKeyboardIndex({ index: 4, key: "ArrowDown", count: 5 })).toBe(4);

    const grid = { orientation: "grid", columns: 3, count: 9 };
    expect(SortableCore.nextKeyboardIndex({ ...grid, index: 1, key: "ArrowUp" })).toBe(0);
    expect(SortableCore.nextKeyboardIndex({ ...grid, index: 7, key: "ArrowDown" })).toBe(8);
  });

  it("returns null for keys the component does not own", () => {
    expect(SortableCore.nextKeyboardIndex({ index: 0, key: "Tab", count: 5 })).toBe(null);
    expect(SortableCore.nextKeyboardIndex({ index: 0, key: "a", count: 5 })).toBe(null);
  });

  it("treats a zero column count as a single column", () => {
    expect(
      SortableCore.nextKeyboardIndex({
        index: 0,
        key: "ArrowDown",
        orientation: "grid",
        columns: 0,
        count: 4,
      }),
    ).toBe(1);
  });
});

// ---------------------------------------------------------------------------
// Pure: announcements
// ---------------------------------------------------------------------------

describe("SortableCore.announce", () => {
  it("reports 1-based positions to humans", () => {
    expect(SortableCore.announce("lift", "Demo", 1, 7)).toBe(
      "Picked up Demo, position 2 of 7",
    );
    expect(SortableCore.announce("move", "Demo", 2, 7)).toBe(
      "Moved Demo to position 3 of 7",
    );
    expect(SortableCore.announce("drop", "Demo", 2, 7)).toBe(
      "Dropped Demo at position 3 of 7",
    );
    expect(SortableCore.announce("cancel", "Demo", 1, 7)).toBe(
      "Reorder cancelled. Demo returned to position 2 of 7",
    );
  });

  it("is empty for an unknown phase", () => {
    expect(SortableCore.announce("wat", "Demo", 0, 1)).toBe("");
  });
});

// ---------------------------------------------------------------------------
// Pure: the keyboard lift state machine
// ---------------------------------------------------------------------------

describe("SortableCore.keyboardReduce", () => {
  const order = ["a", "b", "c", "d"];
  const lift = (overrides = {}) =>
    SortableCore.keyboardReduce(null, {
      type: "lift",
      id: "a",
      label: "Alpha",
      order,
      ...overrides,
    });

  it("lift captures the order and announces the position", () => {
    const r = lift();

    expect(r.handled).toBe(true);
    expect(r.state).toMatchObject({ id: "a", label: "Alpha", from: 0, index: 0 });
    expect(r.state.order).toEqual(order);
    expect(r.announcement).toBe("Picked up Alpha, position 1 of 4");
    expect(r.event).toBe(null);
    expect(r.order).toBe(null);
  });

  it("lift falls back to the id when there is no label", () => {
    expect(lift({ label: null }).announcement).toBe("Picked up a, position 1 of 4");
  });

  it("a disabled item cannot be lifted, and the key is not swallowed", () => {
    const r = lift({ disabled: true });

    expect(r.state).toBe(null);
    expect(r.handled).toBe(false);
    expect(r.announcement).toBe(null);
  });

  it("an unknown id cannot be lifted", () => {
    expect(lift({ id: "zzz" }).state).toBe(null);
  });

  it("moving reorders the captured order and announces the new position", () => {
    const lifted = lift().state;
    const r = SortableCore.keyboardReduce(lifted, { type: "move", key: "ArrowDown" });

    expect(r.order).toEqual(["b", "a", "c", "d"]);
    expect(r.state.index).toBe(1);
    expect(r.state.from).toBe(0);
    expect(r.announcement).toBe("Moved Alpha to position 2 of 4");
    expect(r.handled).toBe(true);
  });

  it("moves compose across presses", () => {
    let state = lift().state;

    for (const key of ["ArrowDown", "ArrowDown"]) {
      const r = SortableCore.keyboardReduce(state, { type: "move", key });
      state = r.state;
    }

    expect(state.order).toEqual(["b", "c", "a", "d"]);
    expect(state.index).toBe(2);
  });

  it("a move clamped at the end is swallowed but announces nothing", () => {
    const lifted = lift().state;
    const r = SortableCore.keyboardReduce(lifted, { type: "move", key: "ArrowUp" });

    expect(r.handled).toBe(true);
    expect(r.order).toBe(null);
    expect(r.announcement).toBe(null);
    expect(r.state).toBe(lifted);
  });

  it("arrows do nothing at all when nothing is lifted", () => {
    const r = SortableCore.keyboardReduce(null, { type: "move", key: "ArrowDown" });

    expect(r.handled).toBe(false);
    expect(r.state).toBe(null);
    expect(r.order).toBe(null);
  });

  it("dropping is the only thing that produces an event", () => {
    const moved = SortableCore.keyboardReduce(lift().state, {
      type: "move",
      key: "ArrowDown",
    }).state;

    const r = SortableCore.keyboardReduce(moved, { type: "drop" });

    expect(r.event).toEqual({ id: "a", from: 0, to: 1 });
    expect(r.announcement).toBe("Dropped Alpha at position 2 of 4");
    expect(r.state).toBe(null);
  });

  it("dropping where it started announces but pushes nothing", () => {
    const r = SortableCore.keyboardReduce(lift().state, { type: "drop" });

    expect(r.event).toBe(null);
    expect(r.announcement).toBe("Dropped Alpha at position 1 of 4");
    expect(r.state).toBe(null);
  });

  it("escape restores the original order and fires nothing", () => {
    const moved = SortableCore.keyboardReduce(lift().state, {
      type: "move",
      key: "ArrowDown",
    }).state;

    const r = SortableCore.keyboardReduce(moved, { type: "cancel" });

    expect(r.order).toEqual(order);
    expect(r.event).toBe(null);
    expect(r.state).toBe(null);
    expect(r.announcement).toBe("Reorder cancelled. Alpha returned to position 1 of 4");
  });

  it("escape with nothing lifted is not swallowed", () => {
    expect(SortableCore.keyboardReduce(null, { type: "cancel" }).handled).toBe(false);
  });

  it("an unknown action changes nothing", () => {
    const lifted = lift().state;
    const r = SortableCore.keyboardReduce(lifted, { type: "nope" });

    expect(r.state).toBe(lifted);
    expect(r.handled).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// The hook: wiring only
// ---------------------------------------------------------------------------

const mounted = [];

function mount({ handle = false, disabled = false, orientation = "vertical" } = {}) {
  const el = document.createElement("div");
  el.id = "sortable";
  el.className = "pc-sortable";
  el.dataset.onReorder = "reorder";
  el.dataset.orientation = orientation;
  if (handle) el.dataset.handle = "true";
  if (disabled) el.dataset.disabled = "true";

  el.innerHTML = ["a", "b", "c"]
    .map(
      (id) => `
      <div class="pc-sortable__item" id="${id}" data-sortable-id="${id}"
           data-sortable-label="Item ${id}" role="listitem" tabindex="0"
           ${id === "c" ? 'data-disabled="true"' : ""}>
        ${handle ? '<button type="button" data-sortable-handle>grip</button>' : ""}
        <span>Item ${id}</span>
      </div>`,
    )
    .join("");

  // the live region is a sibling of the container, exactly as the component
  // renders it (a child would break phx-update="stream")
  const live = document.createElement("div");
  live.id = "sortable-live";
  live.setAttribute("aria-live", "polite");

  document.body.appendChild(el);
  document.body.appendChild(live);

  const hook = Object.create(hooks.PetalSortable);
  hook.el = el;
  hook.pushed = [];
  hook.pushEvent = (name, payload) => hook.pushed.push([name, payload]);
  hook.pushEventTo = (target, name, payload) =>
    hook.pushed.push(["to", name, payload]);
  hook.mounted();
  mounted.push(hook);

  const custom = [];
  el.addEventListener("petal:sortable", (e) => custom.push(e.detail));

  return {
    hook,
    el,
    live,
    custom,
    ids: () => Array.from(el.children).map((c) => c.dataset.sortableId),
    item: (id) => el.querySelector(`[data-sortable-id="${id}"]`),
  };
}

function key(target, k) {
  const ev = new KeyboardEvent("keydown", { key: k, bubbles: true, cancelable: true });
  target.dispatchEvent(ev);
  return ev;
}

// jsdom has no PointerEvent; a MouseEvent with the pointer fields defined on
// it is indistinguishable to addEventListener.
function pointer(type, props = {}) {
  const { pointerType = "mouse", pointerId = 1, ...rest } = props;
  const ev = new MouseEvent(type, { bubbles: true, cancelable: true, ...rest });
  Object.defineProperty(ev, "pointerType", { value: pointerType });
  Object.defineProperty(ev, "pointerId", { value: pointerId });
  return ev;
}

afterEach(() => {
  mounted.splice(0).forEach((hook) => hook.destroyed());
  document.body.innerHTML = "";
  vi.useRealTimers();
});

describe("PetalSortable - keyboard", () => {
  it("space lifts, arrows move the DOM, space drops and pushes once", () => {
    const s = mount();
    const a = s.item("a");

    key(a, " ");
    expect(a.classList.contains("pc-sortable__item--lifted")).toBe(true);
    expect(s.live.textContent).toBe("Picked up Item a, position 1 of 3");

    key(a, "ArrowDown");
    expect(s.ids()).toEqual(["b", "a", "c"]);
    expect(s.live.textContent).toBe("Moved Item a to position 2 of 3");
    expect(s.hook.pushed).toEqual([]);

    key(a, " ");
    expect(s.live.textContent).toBe("Dropped Item a at position 2 of 3");
    expect(s.hook.pushed).toEqual([["reorder", { id: "a", from: 0, to: 1 }]]);
    expect(a.classList.contains("pc-sortable__item--lifted")).toBe(false);
  });

  it("the drop also dispatches petal:sortable for dead views", () => {
    const s = mount();

    key(s.item("a"), " ");
    key(s.item("a"), "ArrowDown");
    key(s.item("a"), " ");

    expect(s.custom).toEqual([{ id: "a", from: 0, to: 1 }]);
  });

  it("escape restores the order and pushes nothing", () => {
    const s = mount();
    const a = s.item("a");

    key(a, " ");
    key(a, "ArrowDown");
    key(a, "ArrowDown");
    expect(s.ids()).toEqual(["b", "c", "a"]);

    key(a, "Escape");
    expect(s.ids()).toEqual(["a", "b", "c"]);
    expect(s.hook.pushed).toEqual([]);
    expect(s.custom).toEqual([]);
    expect(s.live.textContent).toBe("Reorder cancelled. Item a returned to position 1 of 3");
  });

  it("dropping back where it started pushes nothing", () => {
    const s = mount();
    const a = s.item("a");

    key(a, " ");
    key(a, "ArrowDown");
    key(a, "ArrowUp");
    key(a, " ");

    expect(s.ids()).toEqual(["a", "b", "c"]);
    expect(s.hook.pushed).toEqual([]);
  });

  it("swallows the keys it owns so the page does not scroll under a lift", () => {
    const s = mount();
    const a = s.item("a");

    expect(key(a, " ").defaultPrevented).toBe(true);
    expect(key(a, "ArrowDown").defaultPrevented).toBe(true);
    // clamped at the top: still ours, still swallowed
    key(a, "ArrowUp");
    expect(key(a, "ArrowUp").defaultPrevented).toBe(true);
  });

  it("leaves keys it does not own alone", () => {
    const s = mount();
    const a = s.item("a");

    expect(key(a, "Tab").defaultPrevented).toBe(false);
    expect(key(a, "ArrowDown").defaultPrevented).toBe(false);
    expect(key(a, "Escape").defaultPrevented).toBe(false);
  });

  it("a disabled item cannot be lifted", () => {
    const s = mount();

    key(s.item("c"), " ");

    expect(s.live.textContent).toBe("");
    expect(s.item("c").classList.contains("pc-sortable__item--lifted")).toBe(false);
  });

  it("a disabled container short-circuits everything", () => {
    const s = mount({ disabled: true });

    key(s.item("a"), " ");
    key(s.item("a"), "ArrowDown");

    expect(s.ids()).toEqual(["a", "b", "c"]);
    expect(s.live.textContent).toBe("");
    expect(s.hook.pushed).toEqual([]);
  });

  it("in handle mode the drop returns focus to the grip", () => {
    const s = mount({ handle: true });
    const grip = s.item("a").querySelector("[data-sortable-handle]");

    grip.focus();
    key(grip, " ");
    key(grip, "ArrowDown");
    key(grip, " ");

    expect(s.ids()).toEqual(["b", "a", "c"]);
    expect(document.activeElement).toBe(grip);
  });

  it("keeps announcing when the same string comes round twice", () => {
    const s = mount();
    const a = s.item("a");

    key(a, " ");
    key(a, "ArrowDown");
    key(a, "ArrowUp");
    key(a, "ArrowDown");

    expect(s.live.textContent).toBe("Moved Item a to position 2 of 3");
  });

  it("pushes to a live component when phx-target is set", () => {
    const s = mount();
    s.el.setAttribute("phx-target", "3");

    key(s.item("a"), " ");
    key(s.item("a"), "ArrowDown");
    key(s.item("a"), " ");

    expect(s.hook.pushed).toEqual([["to", "reorder", { id: "a", from: 0, to: 1 }]]);
  });
});

describe("PetalSortable - a patch mid-lift", () => {
  it("re-resolves a keyboard lift by data-sortable-id, not by index", () => {
    const s = mount();
    const a = s.item("a");

    key(a, " ");

    // the server pushed an unrelated update that put another row first
    s.el.insertBefore(s.item("c"), a);
    s.hook.updated();

    expect(s.hook.kb.index).toBe(1);
    expect(s.hook.kb.order).toEqual(["c", "a", "b"]);
  });

  it("drops the lift entirely when the item is gone", () => {
    const s = mount();

    key(s.item("a"), " ");
    s.item("a").remove();
    s.hook.updated();

    expect(s.hook.kb).toBe(null);
  });
});

describe("PetalSortable - the long-press threshold", () => {
  beforeEach(() => vi.useFakeTimers());

  it("a short touch does not lift", () => {
    const s = mount();
    const a = s.item("a");

    a.dispatchEvent(pointer("pointerdown", { pointerType: "touch", clientX: 0, clientY: 0 }));
    vi.advanceTimersByTime(100);
    window.dispatchEvent(pointer("pointerup", { pointerType: "touch" }));

    expect(s.hook.drag).toBe(null);
    expect(s.live.textContent).toBe("");
  });

  it("a long press lifts", () => {
    const s = mount();
    const a = s.item("a");

    a.dispatchEvent(pointer("pointerdown", { pointerType: "touch", clientX: 0, clientY: 0 }));
    vi.advanceTimersByTime(SortableCore.LONG_PRESS_MS);

    expect(s.hook.drag).not.toBe(null);
    expect(a.classList.contains("pc-sortable__item--dragging")).toBe(true);
    expect(s.live.textContent).toBe("Picked up Item a, position 1 of 3");
  });

  it("a finger that moves before the timer is scrolling, not lifting", () => {
    const s = mount();
    const a = s.item("a");

    a.dispatchEvent(pointer("pointerdown", { pointerType: "touch", clientX: 0, clientY: 0 }));
    window.dispatchEvent(
      pointer("pointermove", { pointerType: "touch", clientX: 0, clientY: 40 }),
    );
    vi.advanceTimersByTime(SortableCore.LONG_PRESS_MS * 2);

    expect(s.hook.drag).toBe(null);
    expect(s.live.textContent).toBe("");
  });

  it("a mouse lifts on movement, not on the press itself", () => {
    const s = mount();
    const a = s.item("a");

    a.dispatchEvent(pointer("pointerdown", { clientX: 0, clientY: 0 }));
    expect(s.hook.drag).toBe(null);

    // under the slop: still just a click
    window.dispatchEvent(pointer("pointermove", { clientX: 2, clientY: 0 }));
    expect(s.hook.drag).toBe(null);

    window.dispatchEvent(pointer("pointermove", { clientX: 30, clientY: 0 }));
    expect(s.hook.drag).not.toBe(null);
  });

  it("a disabled item and a disabled container never start a press", () => {
    const s = mount();
    s.item("c").dispatchEvent(pointer("pointerdown", { clientX: 0, clientY: 0 }));
    expect(s.hook.press).toBe(null);

    const off = mount({ disabled: true });
    off.item("a").dispatchEvent(pointer("pointerdown", { clientX: 0, clientY: 0 }));
    expect(off.hook.press).toBe(null);
  });

  it("in handle mode only the grip starts a press", () => {
    const s = mount({ handle: true });
    const a = s.item("a");

    a.querySelector("span").dispatchEvent(pointer("pointerdown", { clientX: 0, clientY: 0 }));
    expect(s.hook.press).toBe(null);

    a.querySelector("[data-sortable-handle]")
      .dispatchEvent(pointer("pointerdown", { clientX: 0, clientY: 0 }));
    expect(s.hook.press).not.toBe(null);
  });

  it("a right-click is not a drag", () => {
    const s = mount();
    s.item("a").dispatchEvent(pointer("pointerdown", { button: 2, clientX: 0, clientY: 0 }));
    expect(s.hook.press).toBe(null);
  });
});

describe("PetalSortable - teardown", () => {
  it("destroyed stops listening on the window", () => {
    const s = mount();
    mounted.splice(mounted.indexOf(s.hook), 1);
    s.hook.destroyed();

    s.item("a").dispatchEvent(pointer("pointerdown", { clientX: 0, clientY: 0 }));
    window.dispatchEvent(pointer("pointermove", { clientX: 99, clientY: 0 }));

    expect(s.hook.drag).toBe(null);
  });
});
