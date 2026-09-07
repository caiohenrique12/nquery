import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  async copy(event) {
    event.preventDefault()
    const button = event.currentTarget
    const targetSelector = button.dataset.copyTarget
    const target = targetSelector ? document.querySelector(targetSelector) : null
    const text = target ? target.textContent : this.textValue
    const original = button.textContent

    try {
      await navigator.clipboard.writeText(text.trim())
      button.textContent = "Copied"
    } catch {
      button.textContent = "Copy failed"
    }

    setTimeout(() => { button.textContent = original }, 1500)
  }
}
