window.MailglassAdminHooks = {
      ModalFocusTrap: {
        mounted() {
          this.handleFocusIn = (event) => {
            const sentinel = event.target.closest?.("[data-focus-trap]")
            if (!sentinel || !this.el.contains(sentinel)) return

            const controls = [...this.el.querySelectorAll(
              "a[href], area[href], input:not([disabled]):not([type='hidden']), select:not([disabled]), textarea:not([disabled]), button:not([disabled]), iframe, object, embed, [contenteditable='true'], [tabindex]:not([tabindex='-1'])"
            )].filter((element) =>
              !element.hasAttribute("data-focus-trap") &&
              element.getClientRects().length > 0 &&
              getComputedStyle(element).visibility !== "hidden"
            )

            const target = sentinel.dataset.focusTrap === "start"
              ? controls[controls.length - 1]
              : controls[0]
            target?.focus()
          }
          this.el.addEventListener("focusin", this.handleFocusIn)
        },
        destroyed() {
          this.el.removeEventListener("focusin", this.handleFocusIn)
        }
      },
      SuppressionRefreshFocus: {
        mounted() {
          this.handleEvent("mailglass:suppression-refresh-complete", () => {
            window.requestAnimationFrame(() => {
              if (this.el.isConnected && !this.el.disabled) {
                this.el.focus({ preventScroll: true })
              }
            })
          })
        }
      },
      PreviewTabs: {
        mounted() {
          this.syncTabStops = () => {
            const tabs = [...this.el.querySelectorAll('[role="tab"]')]
            const focusedTab = tabs.find((tab) => tab.id === this.focusedTabId)
            const selectedTab = tabs.find((tab) => tab.getAttribute("aria-selected") === "true")
            const tabStop = focusedTab || selectedTab

            tabs.forEach((tab) => {
              tab.tabIndex = tab === tabStop ? 0 : -1
            })
          }

          this.handleFocusIn = (event) => {
            const tab = event.target.closest?.('[role="tab"]')
            if (!tab || !this.el.contains(tab)) return
            this.focusedTabId = tab.id
            this.syncTabStops()
          }

          this.handleKeydown = (event) => {
            if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return

            const current = event.target.closest?.('[role="tab"]')
            if (!current || !this.el.contains(current)) return

            const tabs = [...this.el.querySelectorAll('[role="tab"]')]
            const currentIndex = tabs.indexOf(current)
            let nextIndex

            if (event.key === "ArrowRight") nextIndex = (currentIndex + 1) % tabs.length
            else if (event.key === "ArrowLeft") nextIndex = (currentIndex - 1 + tabs.length) % tabs.length
            else if (event.key === "Home") nextIndex = 0
            else if (event.key === "End") nextIndex = tabs.length - 1
            else return

            event.preventDefault()
            const next = tabs[nextIndex]
            this.focusedTabId = next.id
            this.syncTabStops()
            next.focus()
          }

          this.el.addEventListener("focusin", this.handleFocusIn)
          this.el.addEventListener("keydown", this.handleKeydown)
          this.syncTabStops()
        },
        updated() {
          this.syncTabStops()
        },
        destroyed() {
          this.el.removeEventListener("focusin", this.handleFocusIn)
          this.el.removeEventListener("keydown", this.handleKeydown)
        }
      },
      PreviewPanelScroll: {
        mounted() {
          this.handleKeydown = (event) => {
            if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return

            let distance
            if (event.key === "PageDown" || event.key === " ") distance = this.el.clientHeight * 0.8
            else if (event.key === "PageUp") distance = -this.el.clientHeight * 0.8
            else if (event.key === "ArrowDown") distance = 40
            else if (event.key === "ArrowUp") distance = -40
            else return

            event.preventDefault()
            this.el.scrollTop += distance
          }

          this.el.addEventListener("keydown", this.handleKeydown)
        },
        destroyed() {
          this.el.removeEventListener("keydown", this.handleKeydown)
        }
      }
    }
