RELEASE_TYPE: major

Petal Components v4 drops Alpine.js, adds an AI chat component family, and makes markdown rendering an optional dependency. See the [Upgrade Guide](UPGRADE_GUIDE.md) for migration steps.

### Breaking

- **Dropped Alpine.js — all components are Phoenix.LiveView.JS only.** Components no longer emit `x-*` attributes, and apps no longer need Alpine.js for Petal Components. Register the bundled JS hooks in your LiveSocket instead (see the upgrade guide).
- **Removed the `js_lib` attribute** from `dropdown/1`, `accordion/1`, and the vertical menu components. Passing it now raises.
- **`input/1` and `field/1`** `viewable` (password), `copyable`, and `clearable` variants now rely on bundled JS hooks (`PetalPasswordToggle`, `PetalCopyInput`, `PetalClearableInput`) instead of Alpine. Register the hooks or these controls won't be interactive.
- **`PetalComponents.default_js_lib/0` is deprecated** and always returns `"live_view_js"`.

### Added

- **Chat component family** (`PetalComponents.Chat`) for building streaming AI chat UIs — the LiveView-native answer to React's AI Elements / assistant-ui: `conversation`, `chat_message`, `streaming_text`, `prompt_input`, `markdown`, `tool_call`, `rich_text`, `reasoning`, `message_actions`, `copy_button`, `suggestions`, `chat_error`.
- **Bundled JS hooks** shipped at `assets/js/petal_components.js` (Petal Components now ships JS for the first time): `PetalChatStream`, `PetalChatComposer`, `PetalCopy`, `PetalCodeCopy`, `PetalChatScroll`, `PetalPasswordToggle`, `PetalCopyInput`, `PetalClearableInput`.
- **`MDEx` as an optional dependency** for `markdown/1` / `to_html/1` (sanitized, syntax-highlighted markdown, with live-streaming support via `streaming_text format="markdown"`). Add `{:mdex, "~> 0.12"}` to your deps to use it.

### Fixed

- Accordion now finds its container by `container_id` from the toggle event, so a custom `container_id` works (previously only the auto-generated id worked).
