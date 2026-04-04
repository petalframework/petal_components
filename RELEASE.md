RELEASE_TYPE: minor

- Added composable JS hook attrs to components (modal, slide over, dropdown, accordion, menu, alert, tabs) so users can compose additional JS commands onto component lifecycle events (#239)
- Added `compose_js/2` helper for combining user and component JS structs
- Added `on_open` to modal and slide over
- Added `on_close` to slide over and dropdown
- Added `on_toggle` to accordion and menu
- Added `on_dismiss` to alert (with built-in hide behavior)
- Added `on_change` to tabs
