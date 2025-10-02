component {

	// Module Properties
	this.title          = "dog";
	this.author         = "Jeff Stevens";
	this.description    = "A ColdFusion tracking API client for Fedex and UPS. Easily fetch all of the tracking information for your shipments!"
	this.modelNamespace = "dog";
	this.cfmapping      = "dog";

	/**
	 * Module Config
	 */
	function configure(){
		variables.settings = {
			// Fedex Information
			fedexApiKey : '',
			fedexSecretKey : '',
			// Legacy SOAP credentials, not used with REST API
			fedexPassword : '',
			fedexAccountNumber : '',
			fedexMeterNumber : '',
			fedexUseSandbox : '',

			// UPS Information

			UPSClientId : '',
			UPSClientSecret : '',
			UPSMerchantId : '',
			UPSUseSandbox : false,

			// legacy
			UPSApiKey : '',
			UPSUsername : '',
			UPSPassword : '',

			// USPS Information
			uspsUserId : '',
			uspsPassword : '',

			// Dayton Freight information
			daytonFreightBasicAuth : '',

			// RLC information

			// Aftership Information (Tazmanian Freight)
			aftershipApiKey : '',

			// XPO Logistics
			XPOLogisticsAccessToken : '',
			XPOLogisticsUserId : '',
			XPOLogisticsPassword : ''
		}
	}

	function onLoad(){
		binder
			.map( "dog@deliveryObservationGadget" )
			.to( "#moduleMapping#.models.deliveryObservationGadget" )
			.asSingleton()

		binder.mapDirectory( packagePath = "#moduleMapping.replace('/','.', 'all').listChangeDelims('.','.')#", namespace = "@deliveryObservationGadget" );
	}

}
