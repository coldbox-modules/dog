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
		// Module Settings
		settings = {
			fedexApiKey             : "",
			fedexPassword           : "",
			fedexAccountNumber      : "",
			fedexMeterNumber        : "",
			upsApiKey               : "",
			upsUsername             : "",
			upsPassword             : "",
			aftershipApiKey         : "",
			daytonFreightBasicAuth  : "",
			XPOLogisticsAccessToken : "",
			XPOLogisticsUserId      : "",
			XPOLogisticsPassword    : ""
		};
	}

	function onLoad(){
		binder
			.map( "dog@deliveryObservationGadget" )
			.to( "#moduleMapping#.models.deliveryObservationGadget" )
			.asSingleton()

		binder.mapDirectory( packagePath = "#moduleMapping.replace('/','.', 'all').listChangeDelims('.','.')#", namespace = "@deliveryObservationGadget" );
	}

}
