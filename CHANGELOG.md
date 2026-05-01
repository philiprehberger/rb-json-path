# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-05-01

### Added
- `JsonPath.update(data, path, &block)` — apply a block to every JSONPath match, replacing each with the block's return value. Mutates `data` in place; returns it for chaining. Raises when the path resolves to the root document.

## [0.4.0] - 2026-04-19

### Added
- `JsonPath.last(data, path)` — last matching value; symmetric with existing `.first`; returns `nil` on no match

## [0.3.0] - 2026-04-17

### Added
- `JsonPath.paths(data, expression)` returns the canonical JSONPath strings of every match (complement to `.values`)

## [0.2.0] - 2026-04-03

### Added
- Recursive descent operator `..` for matching keys at any nesting depth
- `JsonPath.count(data, path)` method to return number of matches
- `JsonPath.values(data, path)` method as an alias for `query`
- Negation filter `!` support: `$[?(!@.key)]` matches items without a key
- Filter comparison with `@.key.length` for arrays and strings

## [0.1.7] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.6] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.5] - 2026-03-24

### Fixed
- Standardize README code examples to use double-quote require statements

## [0.1.4] - 2026-03-24

### Fixed
- Fix Installation section quote style to double quotes
- Remove inline comments from Development section to match template

## [0.1.3] - 2026-03-23

### Fixed
- Standardize README description to match template guide
- Update gemspec summary to match README description

## [0.1.2] - 2026-03-22

### Changed
- Expand test coverage with edge cases, filter operators, slices, and boundary conditions

## [0.1.1] - 2026-03-22

### Added
- Add bug_tracker_uri metadata to gemspec

## [0.1.0] - 2026-03-22

### Added
- Initial release
- JSONPath expression parsing and evaluation
- Dot notation and bracket notation for key access
- Array indexing with positive and negative indices
- Wildcard operator for arrays and hashes
- Array slicing with start:end syntax
- Filter expressions with comparison operators
- Existence filter for checking key presence
