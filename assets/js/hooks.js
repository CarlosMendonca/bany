const Hooks = {}

Hooks.FocusOnSlash = {
  mounted() {
    this._handler = (e) => {
      const tag = document.activeElement.tagName
      if (e.key === "/" && tag !== "INPUT" && tag !== "TEXTAREA" && tag !== "SELECT") {
        e.preventDefault()
        this.el.focus()
        this.el.select()
      }
    }
    window.addEventListener("keydown", this._handler)
  },
  destroyed() {
    window.removeEventListener("keydown", this._handler)
  }
}

Hooks.FilterDropdown = {
  mounted() {
    this._outsideClick = (e) => {
      if (!this.el.contains(e.target)) {
        this.el.removeAttribute("open")
      }
    }
    document.addEventListener("mousedown", this._outsideClick)
  },
  beforeUpdate() {
    this._wasOpen = this.el.hasAttribute("open")
  },
  updated() {
    if (this._wasOpen) {
      this.el.setAttribute("open", "")
    }
  },
  destroyed() {
    document.removeEventListener("mousedown", this._outsideClick)
  }
}

Hooks.TransactionTable = {
  mounted() {
    this.cursorIndex = null
    this.selectedIds = new Set()
    this.pendingCursor = null // "first" | "last" | null

    this.tbody = this.el.querySelector("tbody")
    this.deleteBtn = document.getElementById("delete-selected-btn")
    this.deleteCount = document.getElementById("delete-selected-count")
    this.selectedCountDisplay = document.getElementById("selected-count-display")
    this.selectedCountN = document.getElementById("selected-count-n")

    this._keyHandler = (e) => {
      const tag = document.activeElement.tagName
      if (["INPUT", "TEXTAREA", "SELECT"].includes(tag)) return
      if (e.key === "j") { e.preventDefault(); this.moveCursor(+1) }
      else if (e.key === "k") { e.preventDefault(); this.moveCursor(-1) }
      else if (e.key === "x") { e.preventDefault(); this.toggleSelection() }
    }
    window.addEventListener("keydown", this._keyHandler)

    // Checkbox click delegation
    this._checkboxHandler = (e) => {
      if (!e.target.matches('input[type="checkbox"]')) return
      const tr = e.target.closest("tr")
      if (!tr || !tr.dataset.id) return
      const rows = this.getRows()
      const idx = rows.indexOf(tr)
      if (idx !== -1) this.cursorIndex = idx
      this.toggleId(tr.dataset.id)
      this.applyVisuals()
      this.updateDeleteBar()
      e.target.blur()
    }
    this.el.addEventListener("click", this._checkboxHandler)

    // Delete button
    this._deleteHandler = () => {
      if (this.selectedIds.size === 0) return
      this.pushEvent("delete_selected", { ids: Array.from(this.selectedIds) })
      this.selectedIds.clear()
      this.cursorIndex = null
      this.updateDeleteBar()
    }
    this.deleteBtn.addEventListener("click", this._deleteHandler)

    // Server signals filter change → clear selection
    this.handleEvent("clear-table-selection", () => {
      this.selectedIds.clear()
      this.cursorIndex = null
      this.pendingCursor = null
      this.updateDeleteBar()
    })
  },

  updated() {
    let scrollToCursor = false
    if (this.pendingCursor !== null) {
      const rows = this.getRows()
      if (rows.length > 0) {
        this.cursorIndex = this.pendingCursor === "last" ? rows.length - 1 : 0
        this.pendingCursor = null
        scrollToCursor = true
      }
    }
    this.applyVisuals()
    this.updateDeleteBar()
    if (scrollToCursor && this.cursorIndex !== null) {
      const row = this.getRows()[this.cursorIndex]
      if (row) row.scrollIntoView({ block: "nearest" })
    }
  },

  destroyed() {
    window.removeEventListener("keydown", this._keyHandler)
  },

  getRows() {
    return Array.from(this.tbody.querySelectorAll("tr[data-id]"))
  },

  moveCursor(delta) {
    const rows = this.getRows()
    if (rows.length === 0) return
    if (this.cursorIndex === null) {
      this.cursorIndex = delta > 0 ? 0 : rows.length - 1
      this.applyVisuals()
      return
    }
    const next = this.cursorIndex + delta
    if (next < 0) {
      this.pendingCursor = "last"
      this.cursorIndex = null
      this.pushEvent("prev_page", {})
    } else if (next >= rows.length) {
      this.pendingCursor = "first"
      this.cursorIndex = null
      this.pushEvent("next_page", {})
    } else {
      this.cursorIndex = next
      this.applyVisuals()
      rows[next].scrollIntoView({ block: "nearest" })
    }
  },

  toggleSelection() {
    if (this.cursorIndex === null) return
    const row = this.getRows()[this.cursorIndex]
    if (!row) return
    this.toggleId(row.dataset.id)
    this.applyVisuals()
    this.updateDeleteBar()
  },

  toggleId(id) {
    if (this.selectedIds.has(id)) this.selectedIds.delete(id)
    else this.selectedIds.add(id)
  },

  applyVisuals() {
    this.getRows().forEach((tr, i) => {
      const isCursor = i === this.cursorIndex
      const isSelected = this.selectedIds.has(tr.dataset.id)
      const cb = tr.querySelector('input[type="checkbox"]')

      tr.classList.remove(
        "outline", "outline-2", "outline-primary/60",
        "bg-primary/10", "bg-warning/10", "outline-warning/40"
      )

      if (isCursor && isSelected) {
        tr.classList.add("bg-warning/10", "outline", "outline-2", "outline-warning/40")
      } else if (isCursor) {
        tr.classList.add("outline", "outline-2", "outline-primary/60")
      } else if (isSelected) {
        tr.classList.add("bg-primary/10")
      }

      if (cb) cb.checked = isSelected
    })
  },

  updateDeleteBar() {
    const n = this.selectedIds.size
    this.deleteBtn.disabled = n === 0
    this.deleteCount.textContent = n
    this.selectedCountDisplay.classList.toggle("hidden", n === 0)
    this.selectedCountN.textContent = n
  },
}

export default Hooks
