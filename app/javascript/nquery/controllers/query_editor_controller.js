import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["statement", "results", "dataSource", "schema"]

  insertTable(event) {
    const table = event.currentTarget.dataset.table
    const textarea = this.statementTarget
    const insert = `SELECT * FROM ${table} LIMIT 100`
    textarea.value = insert
  }

  async run() {
    const statement = this.statementTarget.value
    const dataSourceId = this.dataSourceTarget?.value
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch("/queries/run", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrf },
        body: JSON.stringify({ statement, data_source_id: dataSourceId })
      })
      const data = await response.json()
      this.resultsTarget.textContent = JSON.stringify(data, null, 2)
    } catch (e) {
      this.resultsTarget.textContent = e.message
    }
  }

  async loadSchema() {
    if (!this.hasSchemaTarget) return
    const dataSourceId = this.dataSourceTarget.value
    const response = await fetch(`/queries/schema?data_source_id=${dataSourceId}`)
    const data = await response.json()
    this.schemaTarget.innerHTML = data.tables.map(t => {
      const name = typeof t === "string" ? t : t.name
      return `<li class="nq-tree-item" data-action="click->query-editor#insertTable" data-table="${name}">${name}</li>`
    }).join("")
  }
}
