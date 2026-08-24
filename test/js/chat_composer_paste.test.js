// Pasting a screenshot into the composer.
//
// LiveView's upload machinery only ever watches the hidden file input, so a
// clipboard image has to be handed to that input and announced with an input
// event. Getting this wrong is silent - the paste looks like it did nothing -
// so the contract is pinned here: files land in the input, an input event
// fires and bubbles, and a plain text paste is left entirely alone.
import { beforeEach, describe, expect, it } from "vitest";

import { PetalChatComposer } from "../../assets/js/petal_components.js";

// jsdom ships neither DataTransfer nor a settable input.files, both of which
// every real browser has. Stand them up so the spec exercises the hook's
// actual path instead of a mock of it.
class FakeDataTransfer {
  constructor() {
    this._files = [];
    this.items = { add: (file) => this._files.push(file) };
  }

  get files() {
    return this._files;
  }
}

globalThis.DataTransfer = FakeDataTransfer;

function makeFilesWritable(input) {
  let current = [];
  Object.defineProperty(input, "files", {
    get: () => current,
    set: (files) => {
      current = files;
    },
    configurable: true,
  });
}

function mountComposer({
  withFileInput = true,
  withForeignFileInput = false,
} = {}) {
  document.body.innerHTML = "";

  const form = document.createElement("form");
  form.id = "composer";
  const textarea = document.createElement("textarea");
  form.appendChild(textarea);

  // A consumer's own file input in the :actions slot, rendered before the
  // paperclip. The hook must not mistake it for the upload's input.
  let foreignInput = null;
  if (withForeignFileInput) {
    foreignInput = document.createElement("input");
    foreignInput.type = "file";
    makeFilesWritable(foreignInput);
    form.appendChild(foreignInput);
  }

  if (withFileInput) {
    const label = document.createElement("label");
    label.className = "pc-chat__composer-attach";
    const fileInput = document.createElement("input");
    fileInput.type = "file";
    fileInput.multiple = true;
    makeFilesWritable(fileInput);
    label.appendChild(fileInput);
    form.appendChild(label);
  }

  document.body.appendChild(form);

  const hook = Object.create(PetalChatComposer);
  hook.el = form;
  hook.handleEvent = () => {};
  hook.mounted();

  return {
    hook,
    form,
    textarea,
    foreignInput,
    fileInput: form.querySelector(".pc-chat__composer-attach input[type=file]"),
  };
}

// jsdom's ClipboardEvent doesn't carry a settable clipboardData, so build the
// event and attach the payload the way the browser would.
function pasteEvent(files) {
  const event = new Event("paste", { bubbles: true, cancelable: true });
  Object.defineProperty(event, "clipboardData", {
    value: { files, items: [] },
  });
  return event;
}

function pngFile(name = "screenshot.png") {
  return new File([new Uint8Array([1, 2, 3])], name, { type: "image/png" });
}

describe("PetalChatComposer paste handler", () => {
  beforeEach(() => {
    document.body.innerHTML = "";
  });

  it("puts pasted files on the hidden file input", () => {
    const { textarea, fileInput } = mountComposer();

    textarea.dispatchEvent(pasteEvent([pngFile()]));

    expect(fileInput.files).toHaveLength(1);
    expect(fileInput.files[0].name).toBe("screenshot.png");
  });

  it("fires a bubbling input event so LiveView picks the upload up", () => {
    const { textarea, fileInput } = mountComposer();
    const seen = [];
    fileInput.addEventListener("input", (e) => seen.push(e.bubbles));

    textarea.dispatchEvent(pasteEvent([pngFile()]));

    expect(seen).toEqual([true]);
  });

  it("carries every pasted file, not just the first", () => {
    const { textarea, fileInput } = mountComposer();

    textarea.dispatchEvent(pasteEvent([pngFile("a.png"), pngFile("b.png")]));

    expect(fileInput.files).toHaveLength(2);
  });

  it("leaves a text paste alone", () => {
    const { textarea, fileInput } = mountComposer();
    let fired = 0;
    fileInput.addEventListener("input", () => (fired += 1));

    const event = pasteEvent([]);
    textarea.dispatchEvent(event);

    expect(fired).toBe(0);
    expect(event.defaultPrevented).toBe(false);
    expect(fileInput.files).toHaveLength(0);
  });

  it("ignores a consumer's own file input and uses the paperclip's", () => {
    const { textarea, fileInput, foreignInput } = mountComposer({
      withForeignFileInput: true,
    });

    textarea.dispatchEvent(pasteEvent([pngFile()]));

    expect(foreignInput.files).toHaveLength(0);
    expect(fileInput.files).toHaveLength(1);
  });

  it("does nothing when the composer has no upload input", () => {
    const { textarea } = mountComposer({ withFileInput: false });

    const event = pasteEvent([pngFile()]);
    expect(() => textarea.dispatchEvent(event)).not.toThrow();
    expect(event.defaultPrevented).toBe(false);
  });

  it("stops listening once the hook is destroyed", () => {
    const { hook, textarea, fileInput } = mountComposer();
    hook.destroyed();

    textarea.dispatchEvent(pasteEvent([pngFile()]));

    expect(fileInput.files).toHaveLength(0);
  });
});
