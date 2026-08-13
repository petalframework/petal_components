// PetalTree hook: the WAI-ARIA TreeView keyboard map over a roving tabindex.
// The markup here mirrors what PetalComponents.Tree renders (test/petal/
// tree_test.exs pins that structure on the Elixir side) - update both together
// if the anatomy changes.
import { afterEach, describe, expect, it } from "vitest";

import hooks from "../../assets/js/petal_components.js";

const mounted = [];

// lib/                 branch, expanded
//   petal/             branch, collapsed
//     app.ex           leaf
//   petal.ex           leaf
// mix.exs              leaf
// blocked              leaf, disabled
const TREE = `
  <li id="t-node-lib" role="treeitem" aria-level="1" aria-posinset="1" aria-setsize="4"
      aria-expanded="true" aria-selected="false" tabindex="0"
      data-pc-tree-node data-node-id="lib" data-branch="true" data-expanded="true"
      class="pc-tree__item">
    <div class="pc-tree__row">
      <span class="pc-tree__chevron" data-pc-tree-chevron></span>
      <span id="t-label-lib" class="pc-tree__content" data-pc-tree-select>lib</span>
    </div>
    <div class="pc-tree__group-wrap">
      <ul role="group" class="pc-tree__group">
        <li id="t-node-petal" role="treeitem" aria-level="2" aria-posinset="1" aria-setsize="2"
            aria-expanded="false" aria-selected="false" tabindex="-1"
            data-pc-tree-node data-node-id="petal" data-branch="true" data-expanded="false"
            class="pc-tree__item">
          <div class="pc-tree__row">
            <span class="pc-tree__chevron" data-pc-tree-chevron></span>
            <span id="t-label-petal" class="pc-tree__content" data-pc-tree-select>petal</span>
          </div>
          <div class="pc-tree__group-wrap">
            <ul role="group" class="pc-tree__group">
              <li id="t-node-app" role="treeitem" aria-level="3" aria-posinset="1" aria-setsize="1"
                  aria-selected="false" tabindex="-1"
                  data-pc-tree-node data-node-id="app" class="pc-tree__item">
                <div class="pc-tree__row">
                  <span class="pc-tree__chevron pc-tree__chevron--leaf"></span>
                  <span id="t-label-app" class="pc-tree__content" data-pc-tree-select>app.ex</span>
                </div>
              </li>
            </ul>
          </div>
        </li>
        <li id="t-node-petalex" role="treeitem" aria-level="2" aria-posinset="2" aria-setsize="2"
            aria-selected="false" tabindex="-1"
            data-pc-tree-node data-node-id="petalex" class="pc-tree__item">
          <div class="pc-tree__row">
            <span class="pc-tree__chevron pc-tree__chevron--leaf"></span>
            <span id="t-label-petalex" class="pc-tree__content" data-pc-tree-select>petal.ex</span>
          </div>
        </li>
      </ul>
    </div>
  </li>
  <li id="t-node-mix" role="treeitem" aria-level="1" aria-posinset="2" aria-setsize="4"
      aria-selected="false" tabindex="-1"
      data-pc-tree-node data-node-id="mix" class="pc-tree__item">
    <div class="pc-tree__row">
      <span class="pc-tree__chevron pc-tree__chevron--leaf"></span>
      <span id="t-label-mix" class="pc-tree__content" data-pc-tree-select>mix.exs</span>
    </div>
  </li>
  <li id="t-node-assets" role="treeitem" aria-level="1" aria-posinset="3" aria-setsize="4"
      aria-expanded="false" aria-selected="false" tabindex="-1"
      data-pc-tree-node data-node-id="assets" data-branch="true" data-expanded="false"
      class="pc-tree__item">
    <div class="pc-tree__row">
      <span class="pc-tree__chevron" data-pc-tree-chevron></span>
      <span id="t-label-assets" class="pc-tree__content" data-pc-tree-select>assets</span>
    </div>
    <div class="pc-tree__group-wrap">
      <ul role="group" class="pc-tree__group">
        <li id="t-node-css" role="treeitem" aria-level="2" aria-posinset="1" aria-setsize="1"
            aria-selected="false" tabindex="-1"
            data-pc-tree-node data-node-id="css" class="pc-tree__item">
          <div class="pc-tree__row">
            <span class="pc-tree__chevron pc-tree__chevron--leaf"></span>
            <span id="t-label-css" class="pc-tree__content" data-pc-tree-select>app.css</span>
          </div>
        </li>
      </ul>
    </div>
  </li>
  <li id="t-node-blocked" role="treeitem" aria-level="1" aria-posinset="4" aria-setsize="4"
      aria-selected="false" aria-disabled="true" tabindex="-1"
      data-pc-tree-node data-node-id="blocked" class="pc-tree__item pc-tree__item--disabled">
    <div class="pc-tree__row">
      <span class="pc-tree__chevron pc-tree__chevron--leaf"></span>
      <span id="t-label-blocked" class="pc-tree__content" data-pc-tree-select>_build</span>
    </div>
  </li>
`;

function mount() {
  const el = document.createElement("ul");
  el.id = "t";
  el.setAttribute("role", "tree");
  el.className = "pc-tree";
  el.innerHTML = TREE;
  document.body.appendChild(el);

  const hook = Object.create(hooks.PetalTree);
  hook.el = el;
  hook.mounted();
  mounted.push(hook);

  // The component wires the chevron to a JS command (client mode) or a server
  // event; either way the hook's only contract with it is a click, so record
  // clicks and apply the client-mode toggle by hand.
  const chevronClicks = [];
  el.querySelectorAll("[data-pc-tree-chevron]").forEach((chevron) => {
    chevron.addEventListener("click", () => {
      const node = chevron.closest("[data-pc-tree-node]");
      chevronClicks.push(node.dataset.nodeId);
      const open = node.dataset.expanded === "true";
      node.dataset.expanded = open ? "false" : "true";
      node.setAttribute("aria-expanded", open ? "false" : "true");
    });
  });

  const selectClicks = [];
  el.querySelectorAll("[data-pc-tree-select]").forEach((label) => {
    label.addEventListener("click", () =>
      selectClicks.push(label.closest("[data-pc-tree-node]").dataset.nodeId),
    );
  });

  const node = (id) => el.querySelector(`[data-node-id="${id}"]`);
  const focus = (id) => node(id).focus();
  const key = (k, props = {}) =>
    document.activeElement.dispatchEvent(
      new window.KeyboardEvent("keydown", {
        key: k,
        bubbles: true,
        cancelable: true,
        ...props,
      }),
    );
  const activeId = () => document.activeElement.dataset.nodeId;

  return { hook, el, node, focus, key, activeId, chevronClicks, selectClicks };
}

afterEach(() => {
  mounted.splice(0).forEach((hook) => hook.destroyed());
  document.body.innerHTML = "";
});

describe("roving tabindex", () => {
  it("leaves modified keys to the browser - Cmd+ArrowDown is page-end, not tree nav", () => {
    // the APG maps unmodified keys only; intercepting Cmd/Ctrl/Alt combos
    // would eat OS and browser shortcuts
    const { focus, activeId } = mount();
    focus("lib");

    const ev = new window.KeyboardEvent("keydown", {
      key: "ArrowDown",
      metaKey: true,
      bubbles: true,
      cancelable: true,
    });
    document.activeElement.dispatchEvent(ev);

    expect(ev.defaultPrevented).toBe(false);
    expect(activeId()).toBe("lib");
  });

  it("keeps exactly one node at tabindex=0", () => {
    const { el, focus } = mount();
    const stops = () => el.querySelectorAll('[data-pc-tree-node][tabindex="0"]');

    expect(stops()).toHaveLength(1);
    expect(stops()[0].dataset.nodeId).toBe("lib");

    focus("mix");
    expect(stops()).toHaveLength(1);
    expect(stops()[0].dataset.nodeId).toBe("mix");
  });

  it("moves the tab stop when a row is clicked", () => {
    const { el, node } = mount();

    node("mix").querySelector("[data-pc-tree-select]").click();

    expect(el.querySelector('[tabindex="0"]').dataset.nodeId).toBe("mix");
  });

  it("restores the tab stop after a server patch reset it", () => {
    const { hook, el, focus, node } = mount();

    focus("mix");
    // what a re-render looks like: the server's own guess lands on the first node
    el.querySelectorAll("[data-pc-tree-node]").forEach((n) =>
      n.setAttribute("tabindex", n.dataset.nodeId === "lib" ? "0" : "-1"),
    );
    hook.updated();

    expect(node("mix").getAttribute("tabindex")).toBe("0");
    expect(node("lib").getAttribute("tabindex")).toBe("-1");
  });

  it("hands the tab stop back when its branch collapses under it", () => {
    const { hook, focus, key, node } = mount();

    focus("petalex");
    expect(node("petalex").getAttribute("tabindex")).toBe("0");

    focus("lib");
    key("ArrowLeft"); // collapses lib, hiding petalex
    hook.updated();

    expect(node("petalex").getAttribute("tabindex")).toBe("-1");
  });
});

describe("Down and Up", () => {
  it("walk visible nodes only, skipping collapsed subtrees", () => {
    const { focus, key, activeId } = mount();

    focus("lib");
    key("ArrowDown");
    expect(activeId()).toBe("petal");
    key("ArrowDown");
    // app.ex is inside collapsed petal, so it is skipped
    expect(activeId()).toBe("petalex");
    key("ArrowDown");
    expect(activeId()).toBe("mix");
    key("ArrowDown");
    expect(activeId()).toBe("assets");
    key("ArrowUp");
    expect(activeId()).toBe("mix");
  });

  it("stop at the ends rather than wrapping", () => {
    const { focus, key, activeId } = mount();

    focus("lib");
    key("ArrowUp");
    expect(activeId()).toBe("lib");

    focus("blocked");
    key("ArrowDown");
    expect(activeId()).toBe("blocked");
  });

  it("descend into a branch that is already open", () => {
    const { focus, key, activeId } = mount();

    focus("assets");
    key("ArrowRight"); // expands
    key("ArrowDown");
    expect(activeId()).toBe("css");
  });
});

describe("Right", () => {
  it("expands a collapsed branch without moving focus", () => {
    const { focus, key, activeId, node, chevronClicks } = mount();

    focus("petal");
    key("ArrowRight");

    expect(chevronClicks).toEqual(["petal"]);
    expect(node("petal").getAttribute("aria-expanded")).toBe("true");
    expect(activeId()).toBe("petal");
  });

  it("moves into the first child of an already expanded branch", () => {
    const { focus, key, activeId } = mount();

    focus("lib");
    key("ArrowRight");

    expect(activeId()).toBe("petal");
  });

  it("does nothing on a leaf", () => {
    const { focus, key, activeId, chevronClicks } = mount();

    focus("mix");
    key("ArrowRight");

    expect(activeId()).toBe("mix");
    expect(chevronClicks).toEqual([]);
  });
});

describe("Left", () => {
  it("collapses an expanded branch without moving focus", () => {
    const { focus, key, activeId, node, chevronClicks } = mount();

    focus("lib");
    key("ArrowLeft");

    expect(chevronClicks).toEqual(["lib"]);
    expect(node("lib").getAttribute("aria-expanded")).toBe("false");
    expect(activeId()).toBe("lib");
  });

  it("moves to the parent from a collapsed branch", () => {
    const { focus, key, activeId } = mount();

    focus("petal");
    key("ArrowLeft");

    expect(activeId()).toBe("lib");
  });

  it("moves to the parent from a leaf", () => {
    const { focus, key, activeId } = mount();

    focus("petalex");
    key("ArrowLeft");

    expect(activeId()).toBe("lib");
  });

  it("does nothing at the root level", () => {
    const { focus, key, activeId } = mount();

    focus("mix");
    key("ArrowLeft");

    expect(activeId()).toBe("mix");
  });
});

describe("Home and End", () => {
  it("jump to the first and last visible nodes", () => {
    const { focus, key, activeId } = mount();

    focus("mix");
    key("Home");
    expect(activeId()).toBe("lib");

    key("End");
    expect(activeId()).toBe("blocked");
  });

  it("End respects collapsed subtrees", () => {
    const { focus, key, activeId } = mount();

    focus("assets");
    key("ArrowRight"); // open assets, so app.css becomes visible
    focus("blocked");
    key("ArrowUp");
    expect(activeId()).toBe("css");
  });
});

describe("Enter and Space", () => {
  it("select the focused node", () => {
    const { focus, key, selectClicks } = mount();

    focus("mix");
    key("Enter");
    expect(selectClicks).toEqual(["mix"]);

    focus("petalex");
    key(" ");
    expect(selectClicks).toEqual(["mix", "petalex"]);
  });

  it("do not select a disabled node", () => {
    const { focus, key, selectClicks } = mount();

    focus("blocked");
    key("Enter");
    key(" ");

    expect(selectClicks).toEqual([]);
  });
});

describe("asterisk", () => {
  it("expands every collapsed sibling branch at the focused level", () => {
    const { focus, key, node, chevronClicks } = mount();

    focus("assets");
    key("*");

    // lib was already open and is left alone; assets opens; leaves are skipped
    expect(chevronClicks).toEqual(["assets"]);
    expect(node("assets").getAttribute("aria-expanded")).toBe("true");
    expect(node("lib").getAttribute("aria-expanded")).toBe("true");
  });

  it("only touches the focused node's own sibling group", () => {
    const { focus, key, node } = mount();

    focus("petal");
    key("*");

    expect(node("petal").getAttribute("aria-expanded")).toBe("true");
    // a branch one level up is not a sibling
    expect(node("assets").getAttribute("aria-expanded")).toBe("false");
  });
});

describe("event handling", () => {
  it("swallows the keys it handles so the page does not scroll", () => {
    const { focus } = mount();
    focus("lib");

    const event = new window.KeyboardEvent("keydown", {
      key: "ArrowDown",
      bubbles: true,
      cancelable: true,
    });
    document.activeElement.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
  });

  it("leaves keys it does not handle alone", () => {
    const { focus } = mount();
    focus("lib");

    const event = new window.KeyboardEvent("keydown", {
      key: "a",
      bubbles: true,
      cancelable: true,
    });
    document.activeElement.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(false);
  });

  it("stops listening once destroyed", () => {
    const { hook, el, focus, activeId } = mount();
    focus("lib");

    hook.destroyed();
    mounted.splice(mounted.indexOf(hook), 1);

    el.querySelector('[data-node-id="lib"]').dispatchEvent(
      new window.KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true, cancelable: true }),
    );

    expect(activeId()).toBe("lib");
  });

  it("does nothing on an empty tree", () => {
    const el = document.createElement("ul");
    el.id = "empty";
    el.setAttribute("role", "tree");
    document.body.appendChild(el);

    const hook = Object.create(hooks.PetalTree);
    hook.el = el;

    expect(() => hook.mounted()).not.toThrow();
    expect(() =>
      el.dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true })),
    ).not.toThrow();

    hook.destroyed();
  });
});
