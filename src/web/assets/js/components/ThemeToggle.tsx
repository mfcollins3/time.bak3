// React port of Layouts.theme_toggle/1. The root layout script listens for
// `phx:set-theme` events and reads `data-phx-theme` from the event target.
const THEMES = [
  {value: "system", icon: "hero-computer-desktop-micro", label: "System theme"},
  {value: "light", icon: "hero-sun-micro", label: "Light theme"},
  {value: "dark", icon: "hero-moon-micro", label: "Dark theme"},
] as const

export function ThemeToggle() {
  return (
    <div className="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div className="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />
      {THEMES.map(({value, icon, label}) => (
        <button
          key={value}
          type="button"
          aria-label={label}
          className="flex p-2 cursor-pointer w-1/3"
          data-phx-theme={value}
          onClick={e => e.currentTarget.dispatchEvent(new CustomEvent("phx:set-theme", {bubbles: true}))}
        >
          <span className={`${icon} size-4 opacity-75 hover:opacity-100`} aria-hidden="true" />
        </button>
      ))}
    </div>
  )
}
