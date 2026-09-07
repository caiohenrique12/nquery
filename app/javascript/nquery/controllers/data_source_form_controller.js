import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["adapter", "remoteFields", "sqliteFields", "railsHint", "port", "testButton", "testStatus"]
  static values = { adapter: String, testUrl: String, id: String }

  connect() {
    this.toggle()
  }

  toggle() {
    const adapter = this.adapterTarget?.value || this.element.dataset.dataSourceFormAdapterValue || "postgresql"
    const isRemote = adapter === "postgresql" || adapter === "mysql"
    const isSqlite = adapter === "sqlite"
    const isRails = adapter === "rails"

    this.remoteFieldsTarget?.toggleAttribute("hidden", !isRemote)
    this.sqliteFieldsTarget?.toggleAttribute("hidden", !isSqlite)
    this.railsHintTarget?.toggleAttribute("hidden", !isRails)

    if (this.hasPortTarget) {
      this.portTarget.placeholder = adapter === "mysql" ? "3306" : "5432"
    }
  }
}
