// Ambient declarations for the client bundle.

// The `phoenix_live_view` Hex package does not ship built type declarations,
// so declare the small surface that this app uses.
declare module "phoenix_live_view" {
  import type {Socket} from "phoenix"

  export interface LiveSocketOptions {
    longPollFallbackMs?: number
    params?: Record<string, unknown> | (() => Record<string, unknown>)
    hooks?: Record<string, unknown>
    [option: string]: unknown
  }

  export class LiveSocket {
    constructor(endPoint: string, socket: typeof Socket, opts?: LiveSocketOptions)
    connect(): void
    disconnect(callback?: () => void): void
    enableDebug(): void
    disableDebug(): void
    enableLatencySim(upperBoundMs: number): void
    disableLatencySim(): void
  }
}

// Hooks generated from colocated `<script :type={Phoenix.LiveView.ColocatedHook}>`
// tags in HEEx templates.
declare module "phoenix-colocated/*" {
  export const hooks: Record<string, unknown>
}

interface LiveReloader {
  enableServerLogs(): void
  disableServerLogs(): void
  openEditorAtCaller(target: HTMLElement): void
  openEditorAtDef(target: HTMLElement): void
}

interface Window {
  liveSocket: import("phoenix_live_view").LiveSocket
  liveReloader?: LiveReloader
}

interface WindowEventMap {
  "phx:page-loading-start": CustomEvent
  "phx:page-loading-stop": CustomEvent
  "phx:live_reload:attached": CustomEvent<LiveReloader>
}
