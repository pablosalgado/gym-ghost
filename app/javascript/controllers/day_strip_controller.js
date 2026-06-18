import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.#scrollToActive()
  }

  #scrollToActive() {
    const active = this.element.querySelector(".btn-primary")
    if (active) {
      active.scrollIntoView({ behavior: "instant", inline: "center", block: "nearest" })
    }
  }
}
