
/**
 * Update the content of the element with the given date,
 * using the local format from the browser.
 *
 * @param {HTMLTimeElement} el The <time> tag to update
 * @param {Date} date The datetime object to format
 */
function updateContent(el, date) {
    el.innerText = date.toLocaleTimeString() 
}

export const LocalTime =  {
  mounted() {
    const value = this.el.getAttribute("data-value")
    this.date = new Date(value)
    updateContent(this.el, this.date)
  },

  updated() {
    const value = this.el.getAttribute("data-value")
    this.date = new Date(value)
    updateContent(this.el, this.date)
  }
}
