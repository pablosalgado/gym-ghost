import { Controller } from "@hotwired/stimulus"

const DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

export default class extends Controller {
  static targets = ["dayButton", "cityFilter", "facilityFilter", "activityFilter", "sessionList"]
  static values  = { sessions: Array }

  connect() {
    this.selectedDay = 0
    this.sortedSessions = [...this.sessionsValue].sort((a, b) => a.time.localeCompare(b.time))
    this.renderDayLabels()
    this.renderSessions()
  }

  selectDay(event) {
    this.selectedDay = parseInt(event.currentTarget.dataset.day, 10)

    this.dayButtonTargets.forEach((btn) => {
      const isSelected = parseInt(btn.dataset.day, 10) === this.selectedDay
      btn.classList.toggle("border-indigo-600",  isSelected)
      btn.classList.toggle("bg-indigo-600",      isSelected)
      btn.classList.toggle("text-white",         isSelected)
      btn.classList.toggle("border-gray-200",    !isSelected)
      btn.classList.toggle("bg-white",           !isSelected)
      btn.classList.toggle("text-gray-700",      !isSelected)
    })

    this.renderSessions()
  }

  filter() {
    this.renderSessions()
  }

  // private

  renderDayLabels() {
    const today = new Date()

    this.dayButtonTargets.forEach((btn) => {
      const offset = parseInt(btn.dataset.day, 10)
      const date   = new Date(today)
      date.setDate(today.getDate() + offset)

      btn.querySelector(".day-label").textContent  = DAY_NAMES[date.getDay()]
      btn.querySelector(".day-number").textContent = date.getDate()
    })
  }

  renderSessions() {
    const city     = this.cityFilterTarget.value
    const facility = this.facilityFilterTarget.value
    const activity = this.activityFilterTarget.value

    const filtered = this.sortedSessions.filter((s) => {
      if (s.day_offset !== this.selectedDay) return false
      if (city     && s.city     !== city)     return false
      if (facility && s.facility !== facility) return false
      if (activity && s.activity !== activity) return false
      return true
    })

    if (filtered.length === 0) {
      this.sessionListTarget.innerHTML = `
        <p class="text-gray-400 text-sm text-center py-8">No sessions available for the selected day and filters.</p>
      `
      return
    }

    const rows = filtered
      .map((s) => `
        <div class="flex items-center justify-between bg-white rounded-xl border border-gray-100 shadow-sm px-4 py-3">
          <div class="flex items-center gap-4">
            <span class="text-indigo-600 font-bold text-base w-14 shrink-0">${s.time}</span>
            <span class="inline-block bg-indigo-50 text-indigo-700 text-xs font-semibold px-2 py-1 rounded-full">${s.activity}</span>
          </div>
          <div class="text-right text-sm text-gray-500">
            <span class="font-medium text-gray-700">${s.facility}</span>
            <span class="mx-1">·</span>
            <span>${s.city}</span>
          </div>
        </div>
      `)
      .join("")

    this.sessionListTarget.innerHTML = `<div class="flex flex-col gap-3">${rows}</div>`
  }
}
