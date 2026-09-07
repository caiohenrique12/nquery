# Changelog

## [0.1.1] - 2026-09-07

Host apps should `bundle update nquery` and run `rails db:migrate`. Re-run `rails generate nquery:install` if you installed 0.1.0 and need the updated initializer.

### Added
- PostgreSQL data sources with a Test Connection action on the admin form
- Dashboard creation from the home page, with dashboards belonging to a collection
- Post-install setup (`nquery:setup`) and first-admin onboarding via Devise
- Encrypted data source credentials and improved admin data source forms
- GitHub Actions CI with a shared `bin/ci` suite

### Changed
- Hide the home New dashboard CTA when the user cannot curate
- Tighten Devise (`>= 5.0.4`) and Puma (`>= 7.2.1`) minimums for known CVEs
- Bump sqlite3 to `>= 2.9.6` (GHSA-mwm8-39rw-8826)
- Point gem homepage and source URLs to https://github.com/caiohenrique12/nquery

### Fixed
- PostgreSQL adapter connections
- Read-only SQL enforcement on query create/save
- JSON error when a test-connection data source id is missing

## [0.1.0] - 2026-07-22

Initial public release.
