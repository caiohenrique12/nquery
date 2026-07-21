# Simplified Stimulus-style controllers without importmap
document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("[data-controller='query-editor']").forEach(el => {
    const statement = el.querySelector("[data-query-editor-target='statement']")
    const results = el.querySelector("[data-query-editor-target='results']")
    const dataSource = el.querySelector("[data-query-editor-target='dataSource']")
    el.querySelector("[data-action*='query-editor#run']")?.addEventListener("click", async () => {
      const csrf = document.querySelector('meta[name="csrf-token"]')?.content
      const res = await fetch("/queries/run", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrf },
        body: JSON.stringify({ statement: statement?.value, data_source_id: dataSource?.value })
      })
      results.textContent = JSON.stringify(await res.json(), null, 2)
    })
    el.querySelectorAll("[data-action*='insertTable']").forEach(item => {
      item.addEventListener("click", () => {
        if (statement) statement.value = `SELECT * FROM ${item.dataset.table} LIMIT 100`
      })
    })
  })

  document.querySelectorAll("[data-controller='chart-preview']").forEach(el => {
    if (typeof Chart === "undefined") return
    const canvas = el.querySelector("canvas")
    const type = el.dataset.chartPreviewTypeValue || "bar"
    const labels = ["Jan", "Feb", "Mar", "Apr"]
    const values = [1200, 1800, 2400, 2100]
    new Chart(canvas, {
      type: type === "pie" ? "pie" : "bar",
      data: { labels, datasets: [{ label: "Revenue", data: values, backgroundColor: "#509ee3" }] },
      options: { responsive: true, maintainAspectRatio: false }
    })
  })
})
