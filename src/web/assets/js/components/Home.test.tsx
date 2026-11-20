import {render, screen} from "@testing-library/react"
import {describe, expect, it} from "vitest"
import {Home} from "./Home"

describe("Home", () => {
  it("renders the headline and Phoenix version", () => {
    render(<Home phoenixVersion="1.8.0" />)

    expect(screen.getByText("Peace of mind from prototype to production.")).toBeInTheDocument()
    expect(screen.getByText("v1.8.0")).toBeInTheDocument()
  })

  it("links the changelog to the Phoenix version", () => {
    render(<Home phoenixVersion="1.8.0" />)

    expect(screen.getByRole("link", {name: "Changelog"})).toHaveAttribute(
      "href",
      "https://github.com/phoenixframework/phoenix/blob/v1.8.0/CHANGELOG.md",
    )
  })
})
