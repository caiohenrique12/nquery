import { Controller } from "@hotwired/stimulus"

function columnIndex(columns, name) {
  const index = columns.indexOf(name)
  return index >= 0 ? index : 0
}

function chartJsType(type) {
  if (type === "area") return "line"
  if (type === "scatter") return "scatter"
  if (type === "pie") return "pie"
  return type === "line" ? "line" : "bar"
}

function buildPreviewChartConfig(type, data, xCol, yCol) {
  const columns = data.columns || []
  const rows = data.rows || []
  const xIndex = columnIndex(columns, xCol || columns[0])
  const yIndex = columnIndex(columns, yCol || columns[1] || columns[0])
  const labels = rows.map(row => row[xIndex])
  const values = rows.map(row => Number(row[yIndex]) || 0)
  const color = "#509ee3"
  const yLabel = yCol || columns[yIndex] || "Value"

  if (type === "scatter") {
    return {
      type: "scatter",
      data: {
        datasets: [{
          label: yLabel,
          data: rows.map(row => ({ x: Number(row[xIndex]) || 0, y: Number(row[yIndex]) || 0 })),
          backgroundColor: color
        }]
      },
      options: { responsive: true, maintainAspectRatio: false }
    }
  }

  if (type === "pie") {
    return {
      type: "pie",
      data: {
        labels,
        datasets: [{ data: values, backgroundColor: [color, "#7db8ea", "#a8d0f0", "#d4e8f8", "#2d7ec1"] }]
      },
      options: { responsive: true, maintainAspectRatio: false }
    }
  }

  const jsType = chartJsType(type)
  return {
    type: jsType,
    data: {
      labels,
      datasets: [{
        label: yLabel,
        data: values,
        backgroundColor: color,
        borderColor: color,
        fill: type === "area",
        tension: type === "line" || type === "area" ? 0.3 : 0
      }]
    },
    options: { responsive: true, maintainAspectRatio: false }
  }
}

export default class extends Controller {
  static targets = ["canvas"]
  static values = { type: String, data: Object, x: String, y: String }

  connect() {
    if (typeof Chart === "undefined") return

    const demo = this.hasDataValue ? this.dataValue : {
      columns: ["month", "revenue"],
      rows: [["Jan", 1200], ["Feb", 1800], ["Mar", 2400]]
    }
    const type = this.typeValue || "bar"
    const xCol = this.hasXValue ? this.xValue : ""
    const yCol = this.hasYValue ? this.yValue : ""

    if (type === "number") {
      const yIndex = columnIndex(demo.columns || [], yCol || demo.columns?.[1] || demo.columns?.[0])
      const value = demo.rows?.[0]?.[yIndex] ?? "—"
      this.element.classList.add("is-number")
      this.element.innerHTML = `<div class="nq-number-display">${value}</div>`
      return
    }

    if (type === "table") {
      const columns = demo.columns || []
      const rows = (demo.rows || []).slice(0, 8)
      const table = document.createElement("table")
      table.className = "nq-data-table"
      const thead = document.createElement("thead")
      const headRow = document.createElement("tr")
      columns.forEach(col => {
        const th = document.createElement("th")
        th.textContent = col
        headRow.appendChild(th)
      })
      thead.appendChild(headRow)
      table.appendChild(thead)
      const tbody = document.createElement("tbody")
      rows.forEach(row => {
        const tr = document.createElement("tr")
        row.forEach(cell => {
          const td = document.createElement("td")
          td.textContent = cell ?? ""
          tr.appendChild(td)
        })
        tbody.appendChild(tr)
      })
      table.appendChild(tbody)
      this.element.innerHTML = ""
      this.element.appendChild(table)
      return
    }

    if (!this.hasCanvasTarget) return

    new Chart(this.canvasTarget, buildPreviewChartConfig(type, demo, xCol, yCol))
  }
}
