import ContainerJS  from "container-js"
import Deferred     from "../utils/deferred"

export default class Application {

  constructor() {

    this.xhrManager        = ContainerJS.Inject;
    this.errorHandler      = ContainerJS.Inject;
    this.eventQueue        = ContainerJS.Inject;

    this.navigator         = ContainerJS.Inject;
    this.viewModelFactory  = ContainerJS.Inject;
    this.authenticator     = ContainerJS.Inject;
    this.agentSourceEditor = ContainerJS.Inject;

    this.rates           = ContainerJS.Inject;
    this.preferences     = ContainerJS.Inject;
    this.versionService  = ContainerJS.Inject;

    this.backtests       = ContainerJS.Inject;
    this.backtestBuilder = ContainerJS.Inject;

    this.homePageModel              = ContainerJS.Inject;
    this.rmtTradingSummaryPageModel = ContainerJS.Inject;
    this.rmtChartPageModel          = ContainerJS.Inject;
    this.rmtPositionsPageModel      = ContainerJS.Inject;
    this.rmtAgentSettingPageModel   = ContainerJS.Inject;
    this.rmtLogPageModel            = ContainerJS.Inject;

    this.newBacktestPageModel       = ContainerJS.Inject;
    this.backtestsPageModel         = ContainerJS.Inject;

    this.notificationsPageModel     = ContainerJS.Inject;
    this.agentsPageModel            = ContainerJS.Inject;
    this.settingsPageModel          = ContainerJS.Inject;
    this.loginPageModel             = ContainerJS.Inject;
    this.initialSettingsPageModel   = ContainerJS.Inject;

    this.googleAnalytics = ContainerJS.Inject;
  }

  initialize() {
    if ( !this.initializationDeferred ) {
      this.initializationDeferred =
        this.initialSettingsPageModel.initialize().then(
          () => this.initialSettingsPageModel.isInitialized ? null : "/initial-settings",
          () => null
        );
      this.retrieveVersion();
    }
    return this.initializationDeferred;
  }

  retrieveVersion() {
    this.versionService.getVersion().then((result) => {
      this.googleAnalytics.version = result.version;
    }, (error) => {
      this.googleAnalytics.version = "unknown";
      error.preventDefault = true;
    });
  }

}
