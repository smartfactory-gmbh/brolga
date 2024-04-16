export const Popover =  {
  mounted() {
    this.el.addEventListener("mouseenter", () => {
        const target = document.querySelector(this.el.getAttribute("data-target"))
        target.classList.remove("hidden")
    })
    this.el.addEventListener("mouseleave", () => {
        const target = document.querySelector(this.el.getAttribute("data-target"))
        target.classList.add("hidden")
    })
  },
}
