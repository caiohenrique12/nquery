import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["file", "preview", "mapping"]

  preview() {
    const file = this.fileTarget.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      const lines = e.target.result.split("\n").slice(0, 6)
      const headers = lines[0]?.split(",") || []
      this.mappingTarget.value = JSON.stringify(
        headers.map(h => ({ source: h.trim(), target: h.trim().toLowerCase().replace(/\s+/g, "_") }))
      )
      this.previewTarget.innerHTML = `<table class="nq-table"><tbody>${lines.map(l =>
        `<tr>${l.split(",").map(c => `<td>${c.trim()}</td>`).join("")}</tr>`
      ).join("")}</tbody></table>`
    }
    reader.readAsText(file)
  }
}
