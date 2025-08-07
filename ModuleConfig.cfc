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
			fedexApiKey             : "insertYourCredentialsHere",
			fedexPassword           : "insertYourCredentialsHere",
			fedexAccountNumber      : "insertYourCredentialsHere",
			fedexMeterNumber        : "insertYourCredentialsHere",
			upsApiKey               : "insertYourCredentialsHere",
			upsUsername             : "insertYourCredentialsHere",
			upsPassword             : "insertYourCredentialsHere",
			aftershipApiKey         : "insertYourCredentialsHere",
			daytonFreightBasicAuth  : "insertYourCredentialsHere",
			XPOLogisticsAccessToken : "insertYourCredentialsHere",
			XPOLogisticsUserId      : "insertYourCredentialsHere",
			XPOLogisticsPassword    : "insertYourCredentialsHere"
		};
	}

	function onLoad(){
		binder
			.map( "dog@deliveryObservationGadget" )
			.to( "#moduleMapping#.models.deliveryObservationGadget" )
			.asSingleton()
		binder.mapDirectory( packagePath = "#moduleMapping#", namespace = "@deliveryObservationGadget" );
	}

}
