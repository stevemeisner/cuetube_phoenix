// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html'
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'
import { hooks as colocatedHooks } from 'phoenix-colocated/cuetube'
import topbar from '../vendor/topbar'

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content')
const liveSocket = new LiveSocket('/live', Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: { ...colocatedHooks },
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' })
window.addEventListener('phx:page-loading-start', (_info) => topbar.show(300))
window.addEventListener('phx:page-loading-stop', (_info) => {
  topbar.hide()
  if (window.gtag && window.GA_TRACKING_ID) {
    window.gtag('config', window.GA_TRACKING_ID, {
      page_path: window.location.pathname,
    })
  }
})

// Track initial LiveView connection state to suppress false error messages during page load
let initialConnectionTimeout = null
document.body.dataset.lvInitialConnection = 'pending'

// Set timeout for initial connection (4 seconds)
initialConnectionTimeout = setTimeout(() => {
  if (document.body.dataset.lvInitialConnection === 'pending') {
    document.body.dataset.lvInitialConnection = 'failed'
  }
}, 4000)

// Track successful connection
window.addEventListener('phx:connected', () => {
  if (document.body.dataset.lvInitialConnection === 'pending') {
    document.body.dataset.lvInitialConnection = 'connected'
    if (initialConnectionTimeout) {
      clearTimeout(initialConnectionTimeout)
      initialConnectionTimeout = null
    }
  }
})

// Helper function to check if error should be shown
window.shouldShowConnectionError = function () {
  const state = document.body.dataset.lvInitialConnection
  // Show error if we've connected before (real disconnection) or if initial connection failed
  return state === 'connected' || state === 'failed'
}

// Listen for phx:disconnected events and conditionally hide errors if still in initial connection window
window.addEventListener('phx:disconnected', () => {
  // If we're still in the initial connection window, hide any error messages that were shown
  if (document.body.dataset.lvInitialConnection === 'pending') {
    const clientError = document.querySelector('#client-error')
    const serverError = document.querySelector('#server-error')

    if (clientError && !clientError.hasAttribute('hidden')) {
      clientError.setAttribute('hidden', '')
    }
    if (serverError && !serverError.hasAttribute('hidden')) {
      serverError.setAttribute('hidden', '')
    }
  }
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === 'development') {
  window.addEventListener(
    'phx:live_reload:attached',
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs()

      // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
      //
      //   * click with "c" key pressed to open at caller location
      //   * click with "d" key pressed to open at function component definition location
      let keyDown
      window.addEventListener('keydown', (e) => (keyDown = e.key))
      window.addEventListener('keyup', (_e) => (keyDown = null))
      window.addEventListener(
        'click',
        (e) => {
          if (keyDown === 'c') {
            e.preventDefault()
            e.stopImmediatePropagation()
            reloader.openEditorAtCaller(e.target)
          } else if (keyDown === 'd') {
            e.preventDefault()
            e.stopImmediatePropagation()
            reloader.openEditorAtDef(e.target)
          }
        },
        true
      )

      window.liveReloader = reloader
    }
  )
}
