import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "output" ]

  connect() {
    console.log("HelloController connected!");
    this.outputTarget.textContent = "Stimulus controller is active!"
  }

  greet() {
    const now = new Date().toLocaleTimeString();
    this.outputTarget.textContent = `Hello from Stimulus at ${now}!`
    console.log("Stimulus greet action triggered.")
  }
}
