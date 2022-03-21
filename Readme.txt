Welcome to a ColdFusion developer's and a logistic worker's best friend: Dog! 

Dog(Delivery Observation Gadget, yes it's a bit forced!) is a Coldbox module
and API client for using FedEx and UPS tracking services. Using it looks like
this:


property name="dog"     inject="dog@deliveryObservationGadget";

trackReplyStruct = dog.fetch("fedex", "403934084723025", "struct");


Shipment 403934084723025's tracking information is returned by the dog object's
fetch method.


/******************************************************************************
*******************************   INSTALLATION   ******************************
*******************************************************************************/

To install dog, run the following command:


box install dog


This should create a 'dog' folder in your modules folder which contains all
the files you need!


Additionally, you should take the jsoup.jar file which comes with this module and 
move it into your libs folder (if you don't already have a version of jsoup there).
Jsoup is used to parse HTML API responses, which some shipping providers deal in.
If you don't have a libs folder, you must add this to this part of your
application.cfc:

this.javaSettings = {
		loadPaths               : [ expandPath( "insertPathToJsoup.jarHere" ) ],
		loadColdFusionClassPath : true,
		reloadOnChange          : false
	};


Lastly, dog operates by using the APIs provided by the shipping services.
You must supply your API credentials for each service you plan to use in
the module settings for dog. To acquire credentials for the APIs, refer
to the following links:

Fedex: https://www.fedex.com/en-us/developer/web-services.html
UPS: https://www.ups.com/upsdeveloperkit?loc=en_US
Dayton Freight: https://api.daytonfreight.com/documentation/index.html
R+L Carriers: https://www.rlcarriers.com/freight/shipping-software/b2b-login-required?ReturnURL=/freight/shipping-software/freight-api-setup
Holland Freight: https://hollandregional.com/api-registration/
YRC Freight: https://yrc.com/api-registration/
Aftership: https://developers.aftership.com/reference/get-trackings 

/******************************************************************************
*******************************   USER GUIDE   ********************************
*******************************************************************************/

To use dog, simply inject it into one of your scripts with the following code:


property name="dog"      inject="deliveryObservationGadget@dog";


To fetch tracking information, simply call the fetch method:


dog.fetch(required string service, required string shipment, string format)


Arguments:
@service The name of shipping service you want to track a package from. The following
		 shipping services are supported on dog:
		-Fedex
		-UPS
		-Dayton Freight
		-R+L Carriers
		-Holland Freight
		-YRC Freight
		-Aftership
@shipment The tracking number or identifer of the package that you are trying to track.
@format The format in which you want dog.fetch() to return information. Currently,
        we support "structure", "xml", "json" and the unedited original response with 
        "standard". If no argument is provided, "standard" is the default parameter.




