# Changelog
### 0.15.0 - 2022-04-19 00:06:22
- Switch - new form component
### 0.14.0 - 2022-04-08 00:49:03
- Slide Over
### 0.13.7 - 2022-03-28 00:02:41
- Added info, warning and gray variants to buttons
- Added gray variant to progress
- Fixed progress test
- Form does not leak the class assign as it's already set from classes
- Made tabs text in dark mode lighter and changed assigns_to_attributes to be consistent with other components
### 0.13.6 - 2022-03-27 23:59:54
- Added info, warning and gray variants to buttons
- Added gray variant to progress
- Fixed progress test
- Form does not leak the class assign as it's already set from classes
- Made tabs text in dark mode lighter and changed assigns_to_attributes to be consistent with other components
### 0.13.5 - 2022-03-09 04:53:41
- Excluded label and sub_label in the user_inner_td
- Fixed pagination to work when less than 5 pages
- Fixed corners of red bg on file input error
- Removed prop references to size_class, rename size_class / css_class to :string
- Updated the heroicons generator to use "extra_assigns" instead of "extra_attributes"
### 0.13.4 - 2022-03-07 03:11:28
- Fixed table to accept extra attributes and updated table tests
### 0.13.3 - 2022-03-06 23:47:24
- added user_inner_td and fixed formatting where thead and tbody are required
### 0.13.2 - 2022-02-28 02:23:54
- added row layout to radio group
### 0.13.1 - 2022-02-25 20:17:55
- Fixed button type not working
### 0.13.0 - 2022-02-25 03:50:18
- Table
### 0.12.0 - 2022-02-22 21:25:39
- Icon buttons
- Made a link type button and refactored dropdown
- Removed negative margin on spinner
- Removed unnecessary underline statement in tabs
### 0.11.4 - 2022-02-21 00:52:06
- Removed excess class "border-transparent" from white button
### 0.11.3 - 2022-02-17 23:24:49
- Fixed bug with placeholder avatars
### 0.11.2 - 2022-02-16 05:40:24
- Fix issue where untouched inputs were highlighted red
### 0.11.1 - 2022-02-16 04:15:40
- Added object-cover to card_media
### 0.11.0 - 2022-02-15 22:00:59
- Heroicons.Solid icons size defaults to "w-5 h-5" as recommended in their docs
- Form inputs no longer show errors before they have been touched by the user. To get this to work, I had to remove the error classes off the inputs themselves, so they no longer turn red on error by default. However, you can turn this back on by adding these rules to your app.css file (we will update the install docs with this):

```
label.has-error:not(.phx-no-feedback) {
  @apply !text-red-900 dark:!text-red-200;
}

textarea.has-error:not(.phx-no-feedback), input.has-error:not(.phx-no-feedback), select.has-error:not(.phx-no-feedback) {
  @apply !border-red-500 focus:!border-red-500 !text-red-900 !placeholder-red-700 !bg-red-50 dark:!text-red-100 dark:!placeholder-red-300 dark:!bg-red-900;
}

input[type=file_input].has-error:not(.phx-no-feedback) {
  @apply !border-red-500 !rounded-md focus:!border-red-500 !text-red-900 !placeholder-red-700 !bg-red-50 file:!border-none dark:!border-none dark:!bg-[#160B0B] dark:text-red-400;
}

input[type=checkbox].has-error:not(.phx-no-feedback) {
  @apply !border-red-500 !text-red-900 dark:!text-red-200;
}

input[type=radio].has-error:not(.phx-no-feedback) {
  @apply !border-red-500;
}
```
### 0.10.8 - 2022-02-15 01:11:32
- Fixed <.link> emitting white spaces
### 0.10.7 - 2022-02-14 03:44:45
- Fixed white button background
### 0.10.6 - 2022-02-14 03:31:50
- Removed pure_white button shadow variant and fixed white bg for shadow
### 0.10.5 - 2022-02-11 22:30:21
- Fixed Heroicons sometimes failing
### 0.10.4 - 2022-02-10 19:49:47
- Fixed card_media not working properly on Safari
### 0.10.3 - 2022-02-03 01:18:38
- Added <.card_footer> for content you would like fixed to the bottom of a card
- Added `category_color_class` to <.card_content> so that you can customize category colors
### 0.10.2 - 2022-01-29 01:51:55
- <.h1>, <.h2> etc now turn into those underlying html elements (h1, h2 etc)
- <.card_media> utilises Tailwinds aspect-ratio classes
- Fix <.card> `class` assigns appearing twice
### 0.10.1 - 2022-01-26 04:02:41
- Buttons can now take custom classes
### 0.10.0 - 2022-01-26 01:18:58
- [BREAKING CHANGE] Rename alert property "state" to "color"
- Add checkbox_group form field type
- Fix z-index issue with dropdown
- Update Alert colors
- Add icons to badges
### 0.9.3 - 2022-01-19 19:28:35
- Fixed z-index issue with dropdowns
### 0.9.2 - 2022-01-19 05:33:26
- Fixed `<.dropdown_menu_item>` where extra_attributes weren't being passed to underlying button
- Fixed z-index issue on dropdowns
### 0.9.1 - 2022-01-19 02:55:17
- New form component `<.date_select ...>`
- New form component `<.date_input ...>`
- Add dark mode to components
- Fix dropdown failing when no label provided
- Fix dropdown button not having type=button
- Allow dropdown to have custom trigger buttons
### 0.9.0 - 2022-01-07 04:43:03
- New component: Card
- Button colored shadow option
- Improve styling on disabled inputs
- Allow custom attributes to be forwarded to underlying svg element on Heroicons
### 0.8.0 - 2021-12-15 20:17:41
- New component: Tabs
- Fix button that was failing when in a loading state and no size given
- Avatar now uses the `object-cover` class for non-square images
- New badge variations
- Badge can now accept a class prop
### 0.7.0 - 2021-12-07 03:54:41
- Breadcrumbs no longer need a parent flex container
### 0.6.1 - 2021-12-07 00:51:25
- Default the modal max_width to md
### 0.6.0 - 2021-12-07 00:14:21
- New component: `<.modal>`
- Fixed container not defaulting to full width when inside a flex
- Add docs for `<.p>` and heading params
### 0.5.1 - 2021-11-26 00:54:25
- `<.link>`, `<.button>` and `<.dropdown_menu_item>` all now take `method` as a parameter. eg. `<.link method={:delete} to="/logout" label="Logout" />`
### 0.5.0 - 2021-11-22 02:00:02
- Added `<.pagination>`
- Added `<.progress>`
- Improved `<.link>` to work as a live_patch or live_rediect
### 0.4.0 - 2021-11-18 02:18:16
- Added new form components ("email_input", "number_input", "password_input", "search_input", "telephone_input", "url_input", "time_input", "time_select", "datetime_local_input", "datetime_select", "color_input", "file_input", "range_input")
- `<.spinner>` defaults to visible
### 0.3.2 - 2021-11-15 02:50:45
- Add new component Avatar
- `<.form_field>` now shows errors from changesets
### 0.3.1 - 2021-11-09 07:36:13
- Added breadcrumbs components
- Removed unnecessary badge colors
### 0.3.0 - 2021-11-07 20:11:56
- import instead of alias the functions
- removed references to assigns in the HEEX templates to allow proper change tracking
- form functions like text_input now only create an input without the label
- added a `form_field` function that will include the label
- fixed the spinner on different button sizes
- removed alert sizing - stick with on size for now
### 0.2.2 - 2021-11-06 01:34:48
- Fixed Alert.alert not allowing wrapping
- Added heading parameter to Alert.alert
### 0.2.1 - 2021-11-04 22:45:38
- Updated dropdown to include live_patch and live_redirect
### 0.2.0 - 2021-11-04 06:43:01
- Added new component Alert
  - Added new component Loading
  - Added some tests
