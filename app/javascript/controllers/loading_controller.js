import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]

  connect() {
    this.boundShow = this.#show.bind(this)
    this.boundHide = this.#hide.bind(this)
    document.addEventListener("turbo:before-fetch-request", this.boundShow)
    document.addEventListener("turbo:before-fetch-response", this.boundHide)
    document.addEventListener("turbo:frame-load", this.boundHide)
  }

  disconnect() {
    document.removeEventListener("turbo:before-fetch-request", this.boundShow)
    document.removeEventListener("turbo:before-fetch-response", this.boundHide)
    document.removeEventListener("turbo:frame-load", this.boundHide)
  }

  #show() {
    if (this.hasOverlayTarget) this.overlayTarget.classList.remove("d-none")
  }

  #hide() {
    if (this.hasOverlayTarget) this.overlayTarget.classList.add("d-none")
  }
}
