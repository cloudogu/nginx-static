# nginx-static Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- [#8] Configuration options for resource requirements
- [#8] Defaults for CPU and memory requests

## [v1.23.1-4] - 2023-05-09
### Added
- Automatically refresh dogu is starting page

### Changed
- Use `wget` instead of `curl` to fix several CVEs
- Update:
  - base image to 3.15.8-1
  - ces-build-lib to 1.64.2
  - dogu-build-lib to 2.1.0
  - makefiles to 7.5.0
  - warp-menu to 1.7.2
  - ces-theme to 0.7.1

### Fixed
- Show custom error pages for HTTP error codes

## [v1.23.1-3] - 2022-12-01
### Changed
- [#5] Update `dogu.json` with new `menu-json` volume definition.

### Removed
- [#5] All static kubernetes resources including the `k8s` folder. These are no longer necessary as they are replaced 
   by new `dogu.json` definitions.

## [v1.23.1-2] - 2022-08-31
### Added
- [#3] Template maintenance page at the start of the nginx dogu.

## [v1.23.1-1] - 2022-08-24
### Added
- Initial release for the nginx-static dogu. The dogu provides the following static content: ces-theme, ces-about page, warp menu