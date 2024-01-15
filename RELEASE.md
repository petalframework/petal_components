RELEASE_TYPE: minor

- Updated deps
- Use new PhoenixHTMLHelpers lib
- Fix bug where the close_modal event gets sent twice to the LiveView if you push_patch from the close_modal handle_event in the LiveView - thanks @axelclark
