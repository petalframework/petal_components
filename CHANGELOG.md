# Changelog
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
