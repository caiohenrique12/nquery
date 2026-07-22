// Simplified Stimulus-style controllers without importmap
function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
}

const schemaToggleIcon = `<svg class="nq-schema-toggle-icon" width="12" height="12" viewBox="0 0 12 12" aria-hidden="true"><path d="M4 2l4 4-4 4" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>`

function renderSchemaTable(table) {
  const name = typeof table === "string" ? table : table.name
  const columns = typeof table === "string" ? [] : (table.columns || [])
  const columnsHtml = columns.map(column => `
    <li class="nq-schema-column">
      <span class="nq-schema-column-name">${escapeHtml(column.name)}</span>
      <span class="nq-schema-column-type">${escapeHtml(column.type)}</span>
    </li>
  `).join("")

  return `
    <li class="nq-schema-table">
      <div class="nq-schema-table-header">
        <button type="button" class="nq-schema-toggle" aria-expanded="false" aria-label="Toggle ${escapeHtml(name)} columns">
          ${schemaToggleIcon}
        </button>
        <span class="nq-schema-table-name">${escapeHtml(name)}</span>
      </div>
      <ul class="nq-schema-columns" hidden>${columnsHtml}</ul>
    </li>
  `
}

function bindSchemaTree(container) {
  if (!container) return

  container.querySelectorAll(".nq-schema-table").forEach(tableEl => {
    const toggle = tableEl.querySelector(".nq-schema-toggle")
    const columns = tableEl.querySelector(".nq-schema-columns")

    toggle?.addEventListener("click", (event) => {
      event.stopPropagation()
      const expanded = tableEl.classList.toggle("is-expanded")
      toggle.setAttribute("aria-expanded", expanded ? "true" : "false")
      columns?.toggleAttribute("hidden", !expanded)
    })
  })
}

function renderSchemaTree(container, tables) {
  if (!container) return
  container.innerHTML = tables.map(renderSchemaTable).join("")
  bindSchemaTree(container)
}

function formatSql(sql) {
  if (!sql?.trim()) return sql || ""

  if (typeof sqlFormatter !== "undefined") {
    try {
      return sqlFormatter.format(sql, {
        language: "sql",
        tabWidth: 2,
        keywordCase: "upper",
        linesBetweenQueries: 2
      })
    } catch {
      // Fall back to the lightweight formatter below.
    }
  }

  const breakBefore = [
    "UNION ALL", "UNION", "EXCEPT", "INTERSECT",
    "GROUP BY", "ORDER BY", "LEFT JOIN", "RIGHT JOIN", "INNER JOIN", "FULL JOIN", "CROSS JOIN",
    "INSERT INTO", "DELETE FROM",
    "SELECT", "FROM", "WHERE", "HAVING", "LIMIT", "OFFSET", "JOIN", "SET", "VALUES", "WITH"
  ]

  let formatted = sql.replace(/([(),;])/g, " $1 ").replace(/\s+/g, " ").trim()

  breakBefore.forEach(keyword => {
    const pattern = new RegExp(`\\s*\\b${keyword.replace(/ /g, "\\s+")}\\b`, "gi")
    formatted = formatted.replace(pattern, match => `\n${match.trim().toUpperCase()}`)
  })

  formatted = formatted.replace(/\s+\b(AND|OR)\b/gi, "\n  $1")

  return formatted
    .split("\n")
    .map(line => line.trim())
    .filter(Boolean)
    .join("\n")
}

function initSqlEditor(textarea, options = {}) {
  if (!textarea || textarea.dataset.sqlEditorInitialized === "true") return textarea._sqlEditor || null
  if (typeof CodeMirror === "undefined") return null

  const editor = CodeMirror.fromTextArea(textarea, {
    mode: "text/x-sql",
    theme: "eclipse",
    lineNumbers: true,
    indentWithTabs: false,
    indentUnit: 2,
    tabSize: 2,
    lineWrapping: true,
    matchBrackets: true,
    autoCloseBrackets: true,
    styleActiveLine: true,
    viewportMargin: Infinity,
    extraKeys: {
      Tab: (cm) => {
        if (cm.somethingSelected()) cm.indentSelection("add")
        else cm.replaceSelection("  ", "end")
      },
      "Shift-Tab": (cm) => cm.indentSelection("subtract"),
      ...(options.extraKeys || {})
    }
  })

  textarea.dataset.sqlEditorInitialized = "true"
  textarea._sqlEditor = editor
  editor.getWrapperElement().classList.add("nq-codemirror")

  editor.on("change", () => {
    editor.save()
  })

  return editor
}

function syncSqlEditorValue(editor) {
  if (editor) editor.save()
}

function setButtonLoading(button, loading, { keepDisabled = false } = {}) {
  if (!button) return
  if (loading) {
    button.classList.add("is-loading")
    button.setAttribute("aria-busy", "true")
    if ("disabled" in button) button.disabled = true
  } else {
    button.classList.remove("is-loading")
    button.removeAttribute("aria-busy")
    if ("disabled" in button) button.disabled = keepDisabled
  }
}

function showClientFlash(message, type = "notice") {
  const main = document.getElementById("main_content")
  if (!main || !message) return

  main.querySelectorAll(".nq-flash-client").forEach((el) => el.remove())

  const flash = document.createElement("div")
  flash.className = `nq-flash nq-flash-${type} nq-flash-client`
  flash.setAttribute("role", "status")
  flash.textContent = message
  main.prepend(flash)

  window.clearTimeout(flash._nqTimeout)
  flash._nqTimeout = window.setTimeout(() => flash.remove(), 4000)
}

function initButtonLoaders() {
  document.addEventListener("submit", (event) => {
    const submitter = event.submitter || event.target.querySelector("button[type=submit], input[type=submit]")
    if (!submitter?.matches(".nq-btn, .nq-menu-item-button")) return
    setButtonLoading(submitter, true)
  })

  document.addEventListener("click", (event) => {
    const button = event.target.closest("a.nq-btn, button.nq-btn[type=button], input.nq-btn[type=button]")
    if (!button || button.classList.contains("is-loading") || button.dataset.managesLoading === "true") return
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
  document.querySelectorAll("[data-controller='chart-builder']:not([data-chart-builder-initialized])").forEach(root => {
    root.dataset.chartBuilderInitialized = "true"
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
    const runButton = root.querySelector("[data-action*='chart-builder#run']")
    const formatButton = root.querySelector("[data-chart-builder-target='formatButton']") ||
      root.querySelector("[data-action*='chart-builder#format']")
    const saveStatus = root.querySelector("[data-chart-builder-target='saveStatus']")
    const querySaveUrl = root.dataset.querySaveUrl

    let currentResult = null
    let chartInstance = null
    let currentChartType = typeField?.value && typeField.value !== "table" ? typeField.value : "bar"
    let currentOutputTab = typeField?.value && typeField.value !== "table" ? "chart" : "table"
    let statementEditor = null
    let lastFormattedSql = null
    let lastSavedSql = statement?.value ?? ""
    let ignoreEditorChanges = false
    let autosaveTimer = null
    let saveChain = Promise.resolve()

    const syncStatementField = () => {
      syncSqlEditorValue(statementEditor)
    }

    const getStatement = () => statementEditor ? statementEditor.getValue() : (statement?.value ?? "")

    const setStatement = (value, { focus = true } = {}) => {
      if (statementEditor) {
        statementEditor.setValue(value)
        statementEditor.save()
      }

      if (statement) statement.value = value

      if (focus) {
        if (statementEditor) statementEditor.focus()
        else statement?.focus()
      }
    }

    const setFormatEnabled = (enabled) => {
      if (!formatButton) return
      formatButton.disabled = !enabled
      formatButton.setAttribute("aria-disabled", enabled ? "false" : "true")
    }

    const setSaveStatus = (message, { hidden = !message } = {}) => {
      if (!saveStatus) return
      saveStatus.textContent = message || ""
      saveStatus.toggleAttribute("hidden", hidden)
    }

    const saveQueryStatement = ({ notice } = {}) => {
      if (!querySaveUrl) return Promise.resolve({ saved: false })

      const run = async () => {
        const statementText = getStatement()
        syncStatementField()

        if (statementText === lastSavedSql) {
          if (notice) showClientFlash(notice)
          return { saved: true, skipped: true }
        }

        const csrf = document.querySelector('meta[name="csrf-token"]')?.content
        const res = await fetch(querySaveUrl, {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
            "X-CSRF-Token": csrf
          },
          body: JSON.stringify({ query: { statement: statementText } })
        })
        const data = await res.json().catch(() => ({}))
        if (!res.ok) throw new Error(data.error || "Failed to save query.")

        lastSavedSql = statementText
        if (notice) showClientFlash(notice)
        return { saved: true }
      }

      const queued = saveChain.then(run, run)
      saveChain = queued.then(() => undefined, () => undefined)
      return queued
    }

    const scheduleAutosave = () => {
      if (!querySaveUrl || ignoreEditorChanges) return

      clearTimeout(autosaveTimer)
      setSaveStatus("Saving…")
      autosaveTimer = window.setTimeout(() => {
        saveQueryStatement()
          .then(() => setSaveStatus("Saved"))
          .catch((error) => {
            setSaveStatus("")
            showClientFlash(error.message || "Failed to save query.", "alert")
          })
      }, 800)
    }

    const handleStatementChange = () => {
      if (ignoreEditorChanges) return

      const current = getStatement()
      if (lastFormattedSql === null || current !== lastFormattedSql) setFormatEnabled(true)
      scheduleAutosave()
    }

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
      const guessed = guessAxes(columns, rows)
      const x = xField?.value && columns.includes(xField.value) ? xField.value : guessed.x
      const y = yField?.value && columns.includes(yField.value) ? yField.value : guessed.y
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
      syncStatementField()
      setButtonLoading(button, true)
      try {
        const csrf = document.querySelector('meta[name="csrf-token"]')?.content
        const res = await fetch("/queries/run", {
          method: "POST",
          headers: { "Content-Type": "application/json", "X-CSRF-Token": csrf },
          body: JSON.stringify({ statement: getStatement(), data_source_id: dataSource?.value })
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
      renderSchemaTree(schema, data.tables)
    }

    const formatStatement = async (button) => {
      if (formatButton?.disabled) return

      const sql = getStatement().trim()
      if (!sql) return

      if (button) setButtonLoading(button, true)
      ignoreEditorChanges = true
      clearTimeout(autosaveTimer)

      try {
        const formatted = formatSql(sql)
        setStatement(formatted)
        syncStatementField()
        lastFormattedSql = formatted

        if (querySaveUrl) {
          setSaveStatus("Saving…")
          await saveQueryStatement({ notice: "SQL formatted and saved." })
          setSaveStatus("Saved")
        } else {
          showClientFlash("SQL formatted.")
        }

        setFormatEnabled(false)
      } catch (error) {
        showClientFlash(error.message || "Failed to format SQL.", "alert")
        setFormatEnabled(true)
      } finally {
        ignoreEditorChanges = false
        if (button) setButtonLoading(button, false, { keepDisabled: formatButton?.disabled })
      }
    }

    statementEditor = initSqlEditor(statement, {
      extraKeys: {
        "Cmd-Enter": () => runQuery(runButton),
        "Ctrl-Enter": () => runQuery(runButton),
        "Cmd-Shift-F": () => formatStatement(formatButton),
        "Ctrl-Shift-F": () => formatStatement(formatButton)
      }
    })

    lastSavedSql = getStatement()
    if (statementEditor) statementEditor.on("change", handleStatementChange)
    else statement?.addEventListener("input", handleStatementChange)

    const form = root.closest("form")
    form?.addEventListener("submit", syncStatementField, true)
    form?.addEventListener("turbo:submit-start", syncStatementField)

    syncName()
    nameInput?.addEventListener("input", syncName)
    bindSchemaTree(schema)

    formatButton?.addEventListener("click", (event) => {
      formatStatement(event.currentTarget)
    })

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

function bootPage() {
  initPage()
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", bootPage)
} else {
  bootPage()
}

document.addEventListener("turbo:load", bootPage)
