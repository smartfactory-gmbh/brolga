// Interval before the auto scroll alternates between scroll up and down, in seconds
const DEFAULT_SCROLL_INTERVAL = 10

function autoScrollUp(el, lastScrollTop) {
  el.scrollBy(0, -1)
  if(el.scrollTop !== lastScrollTop) {
    setTimeout(() => autoScrollUp(el, el.scrollTop), 10)
  } else{
    const interval = el.dataset.scrollInterval || DEFAULT_SCROLL_INTERVAL
    setTimeout(() => autoScrollDown(el, el.scrollTop), parseInt(interval) * 1000)
  }
}

function autoScrollDown(el, lastScrollTop) {
  el.scrollBy(0, 1)
  if(el.scrollTop !== lastScrollTop) {
    setTimeout(() => autoScrollDown(el, el.scrollTop), 10)
  } else{
    const interval = el.dataset.scrollInterval || DEFAULT_SCROLL_INTERVAL
    setTimeout(() => autoScrollUp(el, el.scrollTop), parseInt(interval) * 1000)
  }
}

export const MonitorDashboard =  {
  mounted() {
    autoScrollDown(this.el)
  }
}
