# Repository Guidelines

## Project Structure & Module Organization
Source code lives in `Sources/`, organized by Swift Package targets such as `CatalystCLI` (entry point), `CatalystCore` (core orchestration), and feature modules like `MicroAppGenerator` and `WorkspaceManager`. Companion resources (Stencil templates) sit under `Sources/TemplateEngine/Templates`. Integration tests for each module live in `Tests/<TargetName>Tests`. Reusable templates or examples are kept in `Custom/`, while automation scripts are collected in `scripts/`. Use `Modules/` for generated fixtures when validating the CLI locally.

## Build, Test, and Development Commands
Run `swift build` for a debug compile and `swift run catalyst --help` to exercise the CLI. Execute `swift test` before every commit; add `--enable-code-coverage` when you need local coverage stats. `swift build -c release` mirrors the release configuration, and `scripts/build-release.sh` wraps the full release pipeline (archive + checksum). Use `catalyst doctor` to validate environment dependencies and `catalyst install packages` to bootstrap helper tooling.

## Coding Style & Naming Conventions
Follow the Swift API Design Guidelines with 4-space indentation and a 120-column hard wrap. Types use `PascalCase`, functions and variables `camelCase`, and test helpers may suffix `TestsSupport`. Prefer `// MARK:` to separate concerns, and document public APIs with `///` comments. Run `swiftformat .` and `swiftlint --fix` when available to align with CI expectations.

## Testing Guidelines
Tests rely on XCTest; mirror source modules with suites named `<ModuleName>Tests`. Favor descriptive method names such as `testGeneratesFeatureMicroApp()` and keep fixtures under `Tests/.../Fixtures`. Use `swift test --filter ModuleTests/testName` to iterate quickly. Aim for coverage on new code paths and add regression cases whenever a bug is fixed.

## Commit & Pull Request Guidelines
Commits typically prefix the summary with a ticket token (e.g., `[ABC-123] Implement workspace sync`); fall back to `[NO-TICKET]` for maintenance work. Write imperatively and keep messages under 72 characters. Pull requests should describe the change, list manual verification (commands run), and reference related issues. Include screenshots or sample output when CLI UX changes, and ensure workflow checks pass before requesting review.
