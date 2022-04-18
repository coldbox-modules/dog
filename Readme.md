# Dog

Welcome to a ColdFusion developer's and a logistic worker's best friend: Dog! 

Dog(Delivery Observation Gadget, yes it's a bit forced!) is a Coldbox module
and API client for multiple tracking services. Using it in your own code
looks like this:


```
property name="dog"     inject="deliveryObservationGadget@dog";
trackingInformation = dog.fetch("fedex", "403934084723025", "struct");
```


Shipment 403934084723025's tracking information is returned by the dog object's
fetch method.

DOG can provide tracking information from the following services:

-FedEx

-UPS

-Dayton Freight

-Holland Frieght

-YRC Freight



VERSION 0.5.2
	-API clients still under construction: R+L Carriers, Aftership, XPO Logistics



### Installation

To install dog, just run the following command in commandbox:

```
box install dog
```

This should create a 'dog' folder in your modules folder which contains all
the files you need!

Additionally, you should take the jsoup.jar file which comes with this module and 
move it into your libs folder (if you don't already have a version of jsoup there).
Jsoup is used to parse HTML API responses, which some shipping providers deal in.
If you don't have a libs folder, you must add this to this part of your
application.cfc (the one stored in the root directory of your ColdFusion server):

```
this.javaSettings = {
		loadPaths               : [ expandPath( "insertPathToJsoup.jarHere" ) ],
		loadColdFusionClassPath : true,
		reloadOnChange          : false
	};
```

Lastly, dog operates by using the APIs provided by the shipping services.
You must supply your API credentials for each service you plan to use in
the module settings for dog. To acquire credentials for the APIs, refer
to the following links:

Fedex: https://www.fedex.com/en-us/developer/web-services.html
UPS: https://www.ups.com/upsdeveloperkit?loc=en_US
Dayton Freight: Public - no credentials required
R+L Carriers: https://www.rlcarriers.com/freight/shipping-software/b2b-login-required?ReturnURL=/freight/shipping-software/freight-api-setup
Holland Freight: Public - no credentials required
YRC Freight: Public - no credentials required
Aftership: https://developers.aftership.com/reference/get-trackings
XPO Logistics: https://ltl-solutions.xpo.com/help-center/api/



# User Guide

To use dog, simply inject it into one of your scripts with the following code:

```
property name="dog"      inject="deliveryObservationGadget@dog";
```

To fetch tracking information, simply call the fetch method:

```
trackingInformation = dog.fetch(required string service, required string shipment, string format);
```


### Arguments for fetch()

@service The name of shipping service you want to track a package from. The following
		 shipping services are supported on dog:
		"fedex ground"
		"fedex freight ltl"
		"ups ground"
		"dayton freight"
		"r+l carriers"
		"holland freight"
		"yrc freight"
		"xpo logistics"
		Aftership (Multiple services are able to make use of the Aftership API, they are listed indented below)
			"tazmanian freight"
@shipment The tracking number or identifer of the package that you are trying to track.
@format The format in which you want dog.fetch() to return information. If no argument is provided,
		"standard" is the default parameter.
		"standard : The unedited original response from the API.
		"structure" : The API response filecontent formatted as a series of nested structs.
		"json" : The API response filecontent formatted as a JSON string.
		"xml" : The API response filecontent formatted as a coldfusion XML document object.


### What fetch() returns

Depending on the format argument that you use in your fetch() function call, what fetch()
returns is slightly different. 

If you don't specify a format or if you pass in "standard":
	A struct containing 12 key-value pairs that is the standard ColdFusion HTTP response
	struct. These key-value pairs give information about the HTTP request to the API.
	The key-value pairs are listed below:
		"charset" : string
		"cookies" : queryObject
		"errordetail" : string
		"fileContent" : string (contains the relevant API response data)
		"header" : string
		"http_version" : string
		"mimetype" : string
		"responseheader" : struct (contains data from the API's server)
		"status_code" : number
		"status_text" : string
		"statuscode" : string
		"text" : string

If you pass in "structure", "json", or "xml":
	A struct containing 4 key-value pairs, which are the following:
		"tracking" : Either a struct, json string, or XML document object (depending on what format you specified)
			Contains all relevant tracking information from the API response. This will be what you'll mainly
			referencing when you're working with the tracking information fetched by dog. Each service will have a
			different way they structure their API responses, but dog will format them to be the ColdFusion data
			type that you request, so you may need to experiment with dumping the result of fetch to the view
			to see what information you might like to reference.
		"success" : boolean
			Indicates whether or not the request was able to successfully obtain tracking information.
		"errors" : array
			Contains any specific error messages that the API may have returned, conveniently accessible at the top level
			of the struct.
		"metaData" : struct
			A struct equivalent to the struct described that "standard" returns. Essentially hold all general information
			about the API repsonse.


### Service-specific function calls for fetch
Note well that you may also directly accees the fetch functions for certain APIs if you
do not wish to use the general fetch function. These are listed below:

```
fetchFedex(required string shipment, string format="standard", string carrierCode="FDXG")
```
The carrier code for fetchFedex() specifies what type of FedEx service is being used for the
shipment. Valid carrier codes are listed below:
	"FDXG" : FedEx Ground Shipping
    "FXFR" : FedEx Freight
    "FDXE" : FedEx Express
    "FDXS" : FedEx Smartpost
    "FDCC" : FedEx Custom Critical

```
fetchUPS(required string shipment, string format="standard)
fetchDaytonFreight(required string shipment, string format="standard")
fetchRLC(required string shipment, string format="standard")
fetchHolland(required string shipment, string format="standard")
fetchYRC(required string shipment, string format="standard"
fetchAftership(required string shipment, string format="standard",  required string shipper)
```
The shipper argument for fetchAftership allows you to choose which shipper you would like to get tracking information from,
as multiple shippers use Aftership. For example, if you would like to use fetchAftership() to get tracking information on 
a package from Tazmanian Freight, pass in the following for the shipper argument: "tazmanian freight".
