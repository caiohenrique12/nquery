import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
  static values = { type: String, data: Object }

  connect() {
    if (typeof Chart === "undefined") return
    const demo = this.hasDataValue ? this.dataValue : {
      columns: ["month", "revenue"],
      rows: [["Jan", 1200], ["Feb", 1800], ["Mar", 2400]]
    }
    const labels = demo.rows.map(r => r[0])
    const values = demo.rows.map(r => Number(r[1]) || 0)

    new Chart(this.canvasTarget, {
      type: this.typeValue === "pie" ? "pie" : "bar",
      data: {
        labels,
        datasets: [{ label: demo.columns[1] || "Value", data: values, backgroundColor: "#509ee3" }]
      },
      options: { responsive: true, maintainAspectRatio: false }
    })
  }
}
