import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  navigate(event) {
    const link = event.currentTarget
    const offcanvasEl = this.element.closest(".offcanvas")
    const offcanvas = bootstrap.Offcanvas.getInstance(offcanvasEl)

    if (offcanvas) {
      event.preventDefault()
      offcanvas.hide()
      offcanvasEl.addEventListener("hidden.bs.offcanvas", () => {
        Turbo.visit(link.href)
      }, { once: true })
    }
  }
}
