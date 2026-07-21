import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card"]

  connect() {
    this.cardTargets.forEach(card => {
      card.addEventListener("dragstart", this.dragStart.bind(this))
      card.addEventListener("dragover", e => e.preventDefault())
      card.addEventListener("drop", this.drop.bind(this))
    })
  }

  dragStart(event) {
    this.dragged = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
  }

  drop(event) {
    event.preventDefault()
    if (this.dragged && event.currentTarget !== this.dragged) {
      event.currentTarget.parentNode.insertBefore(this.dragged, event.currentTarget)
    }
  }
}
