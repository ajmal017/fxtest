import ContainerJS   from "container-js"
import ErrorMessages from "./error-messages"

export default class ErrorHandler {

  constructor() {
    super();

    this.xhrManager      = ContainerJS.Inject;
    this.errorEventQueue = ContainerJS.Inject;
  }

  handle(error) {
    if (error.preventDefault) return;
    const message = ErrorMessages.getMessageFor(error);
    if (message) this.errorEventQueue.push({message:message});
  }

  registerHandlers() {
    this.registerNetworkErrorHandler();
    this.registerUnauthorizedErrorHandler();
  }
  registerNetworkErrorHandler() {
    this.xhrManager.addObserver("error", (n, error) => this.handle(error));
  }
  registerUnauthorizedErrorHandler() {
    this.xhrManager.addObserver("startBlocking", () => {
      this.errorEventQueue.push({route: "/login"});
    });
  }
}
