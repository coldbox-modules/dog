component{

	// Configure ColdBox Application
	function configure(){

		// coldbox directives
		variables.coldbox = {
			//Application Setup
			appName 				= "Module Tester",

			//Development Settings
			reinitPassword			= "",
			handlersIndexAutoReload = true,
			modulesExternalLocation = [],

			//Implicit Events
			defaultEvent			= "",
			requestStartHandler		= "",
			requestEndHandler		= "",
			applicationStartHandler = "",
			applicationEndHandler	= "",
			sessionStartHandler 	= "",
			sessionEndHandler		= "",
			missingTemplateHandler	= "",

			//Error/Exception Handling
			exceptionHandler		= "",
			onInvalidEvent			= "",

			//Application Aspects
			handlerCaching 			= false,
			eventCaching			= false,

			customErrorTemplate 	= "/coldbox/system/exceptions/Whoops.cfm"
		};

		// environment settings, create a detectEnvironment() method to detect it yourself.
		// create a function with the name of the environment so it can be executed if that environment is detected
		// the value of the environment is a list of regex patterns to match the cgi.http_host.
		variables.environments = {
			development = "localhost,127\.0\.0\.1"
		};

		// Module Directives
		variables.modules = {
			// An array of modules names to load, empty means all of them
			include = [],
			// An array of modules names to NOT load, empty means none
			exclude = []
		};

		//Register interceptors as an array, we need order
		variables.interceptors = [
		];

		//LogBox DSL
		variables.logBox = {
			// Define Appenders
			appenders = {
				ConsoleAppender = {
					class="coldbox.system.logging.appenders.ConsoleAppender"
				}
			},
			// Root Logger
			root = { levelmax="DEBUG", appenders="*" },
			// Implicit Level Categories
			info = [ "coldbox.system" ]
		};

		variables.moduleSettings = {
			DOG = {
				fedexApiKey             : getSystemSetting( "fedexApiKey", "" ),
				fedexPassword           : getSystemSetting( "fedexPassword", "" ),
				fedexSecretKey          : getSystemSetting( "fedexSecretKey", "" ),
				fedexAccountNumber      : getSystemSetting( "fedexAccountNumber", "" ),
				fedexMeterNumber        : getSystemSetting( "fedexMeterNumber", "" ),
				fedexUseSandbox         : getSystemSetting( "fedexUseSandbox", "false" ),
				upsApiKey               : getSystemSetting( "upsApiKey", "" ),
				upsUsername             : getSystemSetting( "upsUsername", "" ),
				upsPassword             : getSystemSetting( "upsPassword", "" ),
				aftershipApiKey         : getSystemSetting( "aftershipApiKey", "" ),
				daytonFreightBasicAuth  : getSystemSetting( "daytonFreightBasicAuth", "" ),
				XPOLogisticsAccessToken : getSystemSetting( "XPOLogisticsAccessToken", "" ),
				XPOLogisticsUserId      : getSystemSetting( "XPOLogisticsUserId", "" ),
				XPOLogisticsPassword    : getSystemSetting( "XPOLogisticsPassword", "" ),
				uspsUserId              : getSystemSetting( "uspsUserId", "" ),
				uspsPassword            : getSystemSetting( "uspsPassword", "" ),
				UPSClientId				: getSystemSetting( "UPSClientId", "" ),
				UPSClientSecret			: getSystemSetting( "UPSClientSecret", "" ),
				UPSMerchantId			: getSystemSetting( "UPSMerchantId", "" ),
				UPSUseSandbox			: getSystemSetting( "UPSUseSandbox", "false" )
			}
		};

	}

	/**
	 * Load the Module you are testing
	 */
	function afterAspectsLoad( event, interceptData, rc, prc ){
		controller.getModuleService()
			.registerAndActivateModule(
				moduleName 		= request.MODULE_NAME,
				invocationPath 	= "moduleroot"
			);
	}

}