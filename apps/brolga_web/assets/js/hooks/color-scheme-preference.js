function updateTheme(el) {
    let theme = localStorage.getItem("theme")
    const chosenTheme = theme || ""

    if(!theme) {
        theme = detectBrowserPref()
    }
    const classList = document.querySelector("html").classList
    const isLight = theme === "light"

    classList.toggle("dark", !isLight)
    classList.toggle("light", isLight)
    
    if(el) {
        const options = el.querySelectorAll("option")
        options.forEach(option => {
            option.selected = option.value === chosenTheme
        })
    }
}

function detectBrowserPref() {
    const darkThemeMq = window.matchMedia("(prefers-color-scheme: dark)");
    if (darkThemeMq.matches) {
      return "dark"
    } else {
      return "light"
    }
}


function onChange(event) {
    localStorage.setItem('theme', event.target.value)
    updateTheme(event.target)
}

export const ColorSchemePreference = {
    mounted() {
        updateTheme(this.el)

        this.el.addEventListener("change", onChange)
    },
    destroyed() {
        this.el.removeEventListener("change", onChange)
    }
}

updateTheme()