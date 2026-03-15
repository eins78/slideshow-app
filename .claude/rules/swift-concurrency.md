# Swift 6 Strict Concurrency Rules

These rules apply when writing or modifying any Swift file in this project.

## Actor isolation

- Every `@Observable` class referenced by a SwiftUI view MUST be annotated `@MainActor`
- Use a dedicated `actor` for shared mutable state (e.g., `ImageCache`)
- Do NOT add `Sendable` conformance to `@Observable` classes — they are reference types with mutable state
- Value types (structs, enums) should conform to `Sendable` when they cross isolation boundaries

## Structured vs unstructured concurrency

- PREFER structured concurrency: `async let`, `TaskGroup`, `withThrowingTaskGroup`
- AVOID bare `Task { }` — it creates unstructured concurrency with unclear lifecycle
- `Task.detached` is permitted ONLY for CPU-heavy work that must not inherit the actor context:
  - EXIF metadata reading via `CGImageSource`
  - Thumbnail generation via `CGImageSource`
  - Batch file rename operations
- When using `Task.detached`, always specify the return type and capture list explicitly
- Actors MUST NOT perform synchronous file I/O (CGImageSource, FileManager reads) directly — use `Task.detached` for I/O and the actor only for cache storage. Blocking I/O on the cooperative thread pool triggers "unsafeForcedSync" warnings and risks thread starvation.

## Sendable closures

- Use `@Sendable` closures when required by the compiler — do not suppress with `@preconcurrency`
- Prefer passing value types into closures over capturing reference types
- If a closure needs data from an `@Observable` object, pass the specific values, not the object itself

## Forbidden patterns

- No `@unchecked Sendable` conformances
- No `nonisolated(unsafe)` annotations
- No `Thread.sleep` — use `Task.sleep(for:)` or `Clock.sleep(for:)`
- No `MainActor.run { }` as a band-aid — fix the isolation properly

## Async patterns

- File I/O: use async methods on the model, not blocking calls on the main actor
- Prefer `AsyncStream` over callback-based patterns for ongoing events
- Use `async let` for concurrent loading (e.g., preloading next 2 slides in presentation mode)
