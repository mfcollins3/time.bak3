// Adds `getHooks` to the `live_react` package types, which do not declare it.
// This file has an import so that it augments the module instead of replacing it.
import "live_react"

declare module "live_react" {
  export function getHooks(components: Record<string, unknown>): Record<string, unknown>
}
