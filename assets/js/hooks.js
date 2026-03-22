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

export default Hooks
