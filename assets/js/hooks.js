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

export default Hooks
