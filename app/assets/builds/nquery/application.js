// Simplified Stimulus-style controllers without importmap
function setButtonLoading(button, loading) {
  if (!button) return
  if (loading) {
    button.classList.add("is-loading")
    button.setAttribute("aria-busy", "true")
    if ("disabled" in button) button.disabled = true
  } else {
    button.classList.remove("is-loading")
    button.removeAttribute("aria-busy")
    if ("disabled" in button) button.disabled = false
  }
}

function initButtonLoaders() {
  document.addEventListener("submit", (event) => {
    const submitter = event.submitter || event.target.querySelector("button[type=submit], input[type=submit]")
    if (!submitter?.matches(".nq-btn, .nq-menu-item-button")) return
    setButtonLoading(submitter, true)
  })

  document.addEventListener("click", (event) => {
    const button = event.target.closest("a.nq-btn, button.nq-btn[type=button], input.nq-btn[type=button]")
    if (!button || button.classList.contains("is-loading")) return
    setButtonLoading(button, true)
  })

  document.addEventListener("turbo:submit-end", (event) => {
    const submitter = event.detail?.formSubmission?.submitter
    if (submitter) setButtonLoading(submitter, false)
  })

  window.addEventListener("pageshow", (event) => {
    if (!event.persisted) return
    document.querySelectorAll(".is-loading").forEach((button) => setButtonLoading(button, false))
  })
}

function initChartPreviews() {
  if (typeof Chart === "undefined") {
    requestAnimationFrame(initChartPreviews)
    return
  }

  document.querySelectorAll("[data-controller='chart-preview']").forEach(el => {
    const canvas = el.querySelector("canvas")
    if (!canvas || Chart.getChart(canvas)) return

    const type = el.dataset.chartPreviewTypeValue || "bar"
    let data
    try {
      data = el.dataset.chartPreviewDataValue ? JSON.parse(el.dataset.chartPreviewDataValue) : null
    } catch {
      data = null
    }

    const demo = data?.rows ? data : {
      columns: ["month", "revenue"],
      rows: [["Jan", 1200], ["Feb", 1800], ["Mar", 2400], ["Apr", 2100]]
    }
    const labels = demo.rows.map(r => r[0])
    const values = demo.rows.map(r => Number(r[1]) || 0)

    new Chart(canvas, {
      type: type === "pie" ? "pie" : "bar",
      data: {
        labels,
        datasets: [{ label: demo.columns[1] || "Value", data: values, backgroundColor: "#509ee3" }]
      },
      options: { responsive: true, maintainAspectRatio: false }
    })
  })
}

function initChartBuilders() {
  document.querySelectorAll("[data-controller='chart-builder']").forEach(root => {
    const statement = root.querySelector("[data-chart-builder-target='statement']")
    const dataSource = root.querySelector("[data-chart-builder-target='dataSource']")
    const schema = root.querySelector("[data-chart-builder-target='schema']")
    const nameInput = root.querySelector("[data-chart-builder-target='name']")
    const queryNameInput = root.querySelector("[data-chart-builder-target='queryName']")
    const meta = root.querySelector("[data-chart-builder-target='meta']")
    const tabList = root.querySelector("[data-chart-builder-target='tabList']")
    const outputTabs = root.querySelectorAll("[data-chart-builder-target='outputTab']")
    const emptyState = root.querySelector("[data-chart-builder-target='emptyState']")
    const errorBox = root.querySelector("[data-chart-builder-target='error']")
    const tablePanel = root.querySelector("[data-chart-builder-target='tablePanel']")
    const tableWrap = root.querySelector("[data-chart-builder-target='table']")
    const chartPanel = root.querySelector("[data-chart-builder-target='chartPanel']")
    const chartWrap = root.querySelector("[data-chart-builder-target='chartWrap']")
    const canvas = root.querySelector("[data-chart-builder-target='canvas']")
    const numberWrap = root.querySelector("[data-chart-builder-target='number']")
    const mapping = root.querySelector("[data-chart-builder-target='mapping']")
    const xMapping = root.querySelector("[data-chart-builder-target='xMapping']")
    const xAxis = root.querySelector("[data-chart-builder-target='xAxis']")
    const yAxis = root.querySelector("[data-chart-builder-target='yAxis']")
    const typeField = root.querySelector("[data-chart-builder-target='typeField']")
    const xField = root.querySelector("[data-chart-builder-target='xField']")
    const yField = root.querySelector("[data-chart-builder-target='yField']")
    const typeButtons = root.querySelectorAll("[data-chart-builder-target='typeButton']")

    let currentResult = null
    let chartInstance = null
    let currentOutputTab = "table"
    let currentChartType = "bar"

    const syncName = () => {
      if (nameInput && queryNameInput) queryNameInput.value = nameInput.value
    }

    const hideResults = () => {
      emptyState?.removeAttribute("hidden")
      errorBox?.setAttribute("hidden", "")
      tabList?.setAttribute("hidden", "")
      setActivePanel(null)
    }

    const setActivePanel = (panel) => {
      const showTable = panel === "table"
      const showChart = panel === "chart"

      tablePanel?.classList.toggle("is-active", showTable)
      chartPanel?.classList.toggle("is-active", showChart)
      tablePanel?.toggleAttribute("hidden", !showTable)
      chartPanel?.toggleAttribute("hidden", !showChart)
    }

    const showError = (message) => {
      hideResults()
      emptyState?.setAttribute("hidden", "")
      if (errorBox) {
        errorBox.textContent = message
        errorBox.removeAttribute("hidden")
      }
      meta?.setAttribute("hidden", "")
    }

    const columnIndex = (columns, name) => columns.indexOf(name)

    const guessAxes = (columns, rows) => {
      const x = columns[0]
      let y = columns[1] || columns[0]
      for (let i = 0; i < columns.length; i++) {
        if (columns[i] === x) continue
        if (rows.some(row => !Number.isNaN(Number(row[i])))) {
          y = columns[i]
          break
        }
      }
      return { x, y }
    }

    const populateAxisSelects = (columns, rows) => {
      if (!xAxis || !yAxis) return
      const { x, y } = guessAxes(columns, rows)
      const options = columns.map(col => `<option value="${col}">${col}</option>`).join("")
      xAxis.innerHTML = options
      yAxis.innerHTML = options
      xAxis.value = x
      yAxis.value = y
      if (xField) xField.value = x
      if (yField) yField.value = y
    }

    const destroyChart = () => {
      if (chartInstance) {
        chartInstance.destroy()
        chartInstance = null
      }
    }

    const renderTable = (result) => {
      const table = document.createElement("table")
      table.className = "nq-data-table"
      const thead = document.createElement("thead")
      const headRow = document.createElement("tr")
      result.columns.forEach(col => {
        const th = document.createElement("th")
        th.textContent = col
        headRow.appendChild(th)
      })
      thead.appendChild(headRow)
      table.appendChild(thead)

      const tbody = document.createElement("tbody")
      result.rows.forEach(row => {
        const tr = document.createElement("tr")
        row.forEach(cell => {
          const td = document.createElement("td")
          td.textContent = cell ?? ""
          tr.appendChild(td)
        })
        tbody.appendChild(tr)
      })
      table.appendChild(tbody)

      tableWrap.innerHTML = ""
      tableWrap.appendChild(table)
    }

    const renderNumber = (result) => {
      const yCol = yAxis?.value || result.columns[1] || result.columns[0]
      const yIndex = columnIndex(result.columns, yCol)
      const value = result.rows[0]?.[yIndex] ?? "—"
      numberWrap.innerHTML = `<div class="nq-number-display">${value}</div>`
      chartWrap?.setAttribute("hidden", "")
      numberWrap?.removeAttribute("hidden")
    }

    const chartJsType = (type) => {
      if (type === "area") return "line"
      if (type === "scatter") return "scatter"
      if (type === "pie") return "pie"
      return type === "line" ? "line" : "bar"
    }

    const renderChart = (result, type) => {
      if (typeof Chart === "undefined" || !canvas) return

      destroyChart()
      numberWrap?.setAttribute("hidden", "")
      chartWrap?.removeAttribute("hidden")

      const xCol = xAxis?.value || result.columns[0]
      const yCol = yAxis?.value || result.columns[1] || result.columns[0]
      const xIndex = columnIndex(result.columns, xCol)
      const yIndex = columnIndex(result.columns, yCol)
      const labels = result.rows.map(row => row[xIndex])
      const values = result.rows.map(row => Number(row[yIndex]) || 0)
      const color = "#509ee3"

      let config
      if (type === "scatter") {
        config = {
          type: "scatter",
          data: {
            datasets: [{
              label: yCol,
              data: result.rows.map(row => ({ x: Number(row[xIndex]) || 0, y: Number(row[yIndex]) || 0 })),
              backgroundColor: color
            }]
          },
          options: { responsive: true, maintainAspectRatio: false }
        }
      } else if (type === "pie") {
        config = {
          type: "pie",
          data: {
            labels,
            datasets: [{ data: values, backgroundColor: [color, "#7db8ea", "#a8d0f0", "#d4e8f8", "#2d7ec1"] }]
          },
          options: { responsive: true, maintainAspectRatio: false }
        }
      } else {
        const jsType = chartJsType(type)
        config = {
          type: jsType,
          data: {
            labels,
            datasets: [{
              label: yCol,
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

      chartInstance = new Chart(canvas, config)
    }

    const updateChartPreview = () => {
      if (!currentResult?.columns) return

      destroyChart()
      chartWrap?.setAttribute("hidden", "")
      numberWrap?.setAttribute("hidden", "")

      if (currentChartType === "number") {
        xMapping?.setAttribute("hidden", "")
        renderNumber(currentResult)
        return
      }

      xMapping?.removeAttribute("hidden")
      renderChart(currentResult, currentChartType)
    }

    const selectOutputTab = (tab) => {
      currentOutputTab = tab
      outputTabs.forEach(btn => {
        const active = btn.dataset.tab === tab
        btn.classList.toggle("is-active", active)
        btn.setAttribute("aria-selected", active ? "true" : "false")
      })

      if (tab === "table") {
        if (typeField) typeField.value = "table"
        setActivePanel("table")
      } else {
        setActivePanel("chart")
        if (typeField?.value === "table") selectChartType("bar")
        else updateChartPreview()
      }
    }

    const selectChartType = (type) => {
      currentChartType = type
      if (typeField) typeField.value = type
      typeButtons.forEach(btn => btn.classList.toggle("is-active", btn.dataset.type === type))
      if (currentResult) updateChartPreview()
    }

    const updateMapping = () => {
      if (xField && xAxis) xField.value = xAxis.value
      if (yField && yAxis) yField.value = yAxis.value
      if (currentResult && currentOutputTab === "chart") updateChartPreview()
    }

    const showResults = () => {
      emptyState?.setAttribute("hidden", "")
      errorBox?.setAttribute("hidden", "")
      tabList?.removeAttribute("hidden")
      selectOutputTab(currentOutputTab)
    }

    const runQuery = async (button) => {
      setButtonLoading(button, true)
      try {
        const csrf = document.querySelector('meta[name="csrf-token"]')?.content
        const res = await fetch("/queries/run", {
          method: "POST",
          headers: { "Content-Type": "application/json", "X-CSRF-Token": csrf },
          body: JSON.stringify({ statement: statement?.value, data_source_id: dataSource?.value })
        })
        const data = await res.json()
        if (!res.ok || data.error) {
          showError(data.error || "Query failed.")
          return
        }

        currentResult = data
        currentOutputTab = "table"
        populateAxisSelects(data.columns, data.rows)
        renderTable(data)
        if (meta) {
          const parts = []
          if (data.row_count != null) parts.push(`${data.row_count} rows`)
          if (data.duration_ms != null) parts.push(`${data.duration_ms} ms`)
          meta.textContent = parts.join(" · ")
          meta.removeAttribute("hidden")
        }
        showResults()
      } catch (e) {
        showError(e.message)
      } finally {
        setButtonLoading(button, false)
      }
    }

    const loadSchema = async () => {
      if (!schema || !dataSource) return
      const response = await fetch(`/queries/schema?data_source_id=${dataSource.value}`)
      const data = await response.json()
      schema.innerHTML = data.tables.map(table =>
        `<li class="nq-tree-item" data-table="${table}">${table}</li>`
      ).join("")
      schema.querySelectorAll("[data-table]").forEach(item => {
        item.addEventListener("click", () => {
          if (statement) statement.value = `SELECT * FROM ${item.dataset.table} LIMIT 100`
        })
      })
    }

    const insertTable = (table) => {
      if (statement) statement.value = `SELECT * FROM ${table} LIMIT 100`
    }

    syncName()
    nameInput?.addEventListener("input", syncName)

    root.querySelector("[data-action*='chart-builder#run']")?.addEventListener("click", (event) => {
      runQuery(event.currentTarget)
    })

    dataSource?.addEventListener("change", loadSchema)

    outputTabs.forEach(btn => {
      btn.addEventListener("click", (event) => {
        event.preventDefault()
        selectOutputTab(btn.dataset.tab)
      })
    })

    typeButtons.forEach(btn => {
      btn.addEventListener("click", () => selectChartType(btn.dataset.type))
    })

    xAxis?.addEventListener("change", updateMapping)
    yAxis?.addEventListener("change", updateMapping)

    root.querySelectorAll("[data-action*='chart-builder#insertTable']").forEach(item => {
      item.addEventListener("click", () => insertTable(item.dataset.table))
    })
  })
}

function initQueryEditors() {
  document.querySelectorAll("[data-controller='query-editor']").forEach(el => {
    const statement = el.querySelector("[data-query-editor-target='statement']")
    const results = el.querySelector("[data-query-editor-target='results']")
    const dataSource = el.querySelector("[data-query-editor-target='dataSource']")
    el.querySelector("[data-action*='query-editor#run']")?.addEventListener("click", async (event) => {
      const button = event.currentTarget
      setButtonLoading(button, true)
      try {
        const csrf = document.querySelector('meta[name="csrf-token"]')?.content
        const res = await fetch("/queries/run", {
          method: "POST",
          headers: { "Content-Type": "application/json", "X-CSRF-Token": csrf },
          body: JSON.stringify({ statement: statement?.value, data_source_id: dataSource?.value })
        })
        results.textContent = JSON.stringify(await res.json(), null, 2)
      } finally {
        setButtonLoading(button, false)
      }
    })
    el.querySelectorAll("[data-action*='insertTable']").forEach(item => {
      item.addEventListener("click", () => {
        if (statement) statement.value = `SELECT * FROM ${item.dataset.table} LIMIT 100`
      })
    })
  })
}

function initPage() {
  initButtonLoaders()
  initQueryEditors()
  initChartBuilders()
  initChartPreviews()
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initPage)
} else {
  initPage()
}
