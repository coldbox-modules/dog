/**
 * A model used to communicate with shipping service APIs and retrieve information from them in the format
 * of your choice.
 *
 * The following is the list of Dog's supported APIS:
 * - FedEx
 * - UPS
 * - Dayton Freight
 * - Holland Freight
 * - YRC Freight
 */
component {

	// Other models used
	property name="formatter" inject="formatter@xmlTool";
	
	// Settings
	property name="settings" inject="coldbox:modulesettings:dog";
	property name="coldboxSettings" inject="coldbox:coldboxSettings";


	// Default constructor
	deliveryObservationGadget function init(){
		// Holds the bearer and refresh tokens used with the XPO Logistics API
		this.XPOLogisticsTokenStruct = {};

		// Holds the bearer and refresh tokens used with the Fedex Logistics API
		this.FedexTokenStruct = {};

		// Holds the bearer and refresh tokens used with the UPS API
		this.UPSTokenStruct = {};

		return this;
	}

	function onDIComplete() {
		
		// For backwards compat, mix in any coldbox settings that may have been set
		var possibleSettingNames = [
			"fedexApiKey",
			"fedexPassword",
			"fedexAccountNumber",
			"fedexMeterNumber",
			"fedexUseSandbox",
			"upsApiKey",
			"upsUsername",
			"upsPassword",
			"uspsUserId",
			"uspsPassword",
			"daytonFreightBasicAuth",
			"aftershipApiKey",
			"XPOLogisticsAccessToken",
			"XPOLogisticsUserId",
			"XPOLogisticsPassword"
		]
		for( var key in coldboxSettings ){
			// If the key in ColdBox settings matches one of our module settings, has length, and we DON'T have it already declared as a module setting
			if( arrayContains( possibleSettingNames, key ) && len( coldboxSettings[ key ] ) && !len( settings[ key ] ?: '' ) ){
				// If the key exists in the possible setting names, mix it in
				settings[ key ] = coldboxSettings[ key] ;
			}
		}

	}


	/**
	 * Takes in an HTTP response and reads the status code. If it is
	 * within the error range (400 <= statusCode) and (600 > statusCode)
	 * we return true. Otherwise return false.
	 *
	 * @response An HTTP response structure
	 *
	 * @return A boolean variable indicating whether the response had an error or not
	 */
	private boolean function badResponseStatus( required struct response ){
		if ( ( 400 <= arguments.response.status_code ) && ( 600 > arguments.response.status_code ) ) {
			return true;
		} else if (  arguments.response.status_code == 0 ) {
			return true;
		} else {
			return false;
		}
	}


	/**
	 * Given a FedEx tracking number, returns the information of the shipment in the desired format.
	 *
	 *         -standard: The raw API response contained within a struct
	 *         -structure: The API response data formatted as a struct along with the raw data within a struct
	 *         -xml: The API response data formatted in XML along with the raw data within a struct
	 *         -json: The API response data formatted in JSON along with the raw data within a struct
	 *              we use FedEx ground, FDXG.
	 *              -FDXG: FedEx Ground Shipping
	 *              -FXFR: FedEx Freight
	 *              -FDXE: FedEx Express
	 *              -FDXS: FedEx Smartpost
	 *              -FDCC: FedEx Custom Critical
	 *
	 * @shipment    The tracking number of a shipment
	 * @format      The format by which we will return the tracking information to the user:
	 * @carrierCode The specific type of Fedex carrying service the package in question is using. By default,
	 *
	 * @return The shipment information
	 */
	public struct function fetchFedExSOAP(
		required string shipment,
		string format      = "standard",
		string carrierCode = "FDXG"
	){
		local.httpService = new HTTPShim();

		/* Set attributes using implicit setters */
		local.httpService.setMethod( "post" );
		local.httpService.setCharset( "utf-8" );
		if( variables.settings.fedexUseSandbox ) {
			local.httpService.setUrl( "https://wsbeta.fedex.com:443/web-services/track" );
		} else {
			local.httpService.setUrl( "https://ws.fedex.com:443/web-services/track" );
		}

		/* Create SOAP format API request */
		local.fileContent =
		"
        <soapenv:Envelope xmlns:soapenv=""http://schemas.xmlsoap.org/soap/envelope/"" xmlns=""http://fedex.com/ws/track/v20"">
            <soapenv:Header/>
            <soapenv:Body>
                <TrackRequest>
                    <WebAuthenticationDetail>
                        <ParentCredential>
                            <Key>#variables.settings.fedexAPIKey#</Key>
                            <Password>#variables.settings.fedexPassword#</Password>
                        </ParentCredential>
                        <UserCredential>
                            <Key>#variables.settings.fedexAPIKey#</Key>
                            <Password>#variables.settings.fedexPassword#</Password>
                        </UserCredential>
                    </WebAuthenticationDetail>
                    <ClientDetail>
                        <AccountNumber>#variables.settings.fedexAccountNumber#</AccountNumber>
                        <MeterNumber>#variables.settings.fedexMeterNumber#</MeterNumber>
                    </ClientDetail>
                    <TransactionDetail>
                        <CustomerTransactionId>Track By Number_v20</CustomerTransactionId>
                        <Localization>
                            <LanguageCode>EN</LanguageCode>
                            <LocaleCode>US</LocaleCode>
                        </Localization>
                    </TransactionDetail>
                    <Version>
                        <ServiceId>trck</ServiceId>
                        <Major>20</Major>
                        <Intermediate>0</Intermediate>
                        <Minor>0</Minor>
                    </Version>
                    <SelectionDetails>
                        <CarrierCode>#arguments.carrierCode#</CarrierCode>
                        <PackageIdentifier>
                            <Type>TRACKING_NUMBER_OR_DOORTAG</Type>
                            <Value>#arguments.shipment#</Value>
                        </PackageIdentifier>
                        <ShipmentAccountNumber/>
                        <SecureSpodAccount/>
                        <Destination>
                            <GeographicCoordinates>rates evertitque aequora</GeographicCoordinates>
                        </Destination>
                    </SelectionDetails>
                </TrackRequest>
            </soapenv:Body>
        </soapenv:Envelope>
        ";

		/* Give the API request to the http request object */
		httpService.addParam(
			type  = "body",
			name  = "API_XML_Request",
			value = local.fileContent
		);

		/* Send the request to the FedEx API */
		local.response = local.httpService.send().getPrefix();

		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// /////////*            Account for possible errors          *////////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		// Check status code, first of all
		if ( badResponseStatus( local.response ) ) {
			// If we receive a bad status code from the API, we return an error
			return {
				"success"  : false,
				"errors"   : [ "error: API returned status code #local.response.statusCode#" ],
				"metaData" : local.response,
				"tracking" : {}
			}
		}

		local.responseStruct[ "success" ] = true;
		local.responseStruct[ "errors" ]  = [];
		// Check to see if we successfully retrieved the tracking information
		local.responseXML                 = xmlParse( local.response.fileContent );
		local.trackingRetrieved           = xmlSearch(
			local.responseXML,
			"//*[local-name()='TrackReply']/*[local-name()='HighestSeverity']"
		);
		if ( local.trackingRetrieved[ 1 ].xmlText == "SUCCESS" ) {
			// If we receive a success message, let's make sure of some other things to be absolutely certain we have retrieved the correct tracking information
			local.trackingDetails = xmlSearch(
				local.responseXML,
				"//*[local-name()='TrackDetails']/*[local-name()='Notification']/*[local-name()='Severity']"
			);
			if ( local.trackingDetails[ 1 ].xmlText != "SUCCESS" ) {
				// There was a 'soft-error' in trying to retrieve the tracking information. One known cause of this is using the wrong carrier code for your package
				local.responseStruct[ "errors" ].append(
					xmlSearch(
						local.responseXML,
						"//*[local-name()='TrackDetails']/*[local-name()='Notification']/*[local-name()='Message']"
					)[ 1 ].xmlText
				);
				local.responseStruct[ "success" ] = false;
			}
		} else {
			// If we do not receive a success notification from our fedex package tracking reply, we assume we didn't get the information successfully
			local.responseStruct[ "success" ] = false;
		}
		// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		/* Choose a format with which to return the API's response to the user */
		if ( arguments.format == "standard" ) {
			// Return the response as-is
			return local.response;
		} else if ( arguments.format == "structure" ) {
			// Create a struct full of information from the response
			local.responseStruct[ "metaData" ] = local.response;
			local.responseStruct[ "tracking" ] = formatter.convertXMLtoStruct( local.responseXML );
			return local.responseStruct;
		} else if ( arguments.format == "xml" ) {
			local.responseStruct[ "tracking" ] = local.responseXML;
			local.responseStruct[ "metaData" ] = local.response;
			return local.responseStruct;
		} else if ( arguments.format == "json" ) {
			local.responseJSON                 = formatter.convertXMLtoJSON( local.responseXML );
			local.responseStruct[ "tracking" ] = local.responseJSON;
			local.responseStruct[ "metaData" ] = local.response;
			return local.responseStruct;
		} else {
			return { "error" : "Unknown response format specified" }
		}
	}
	
	/**
	* Given a FedEx tracking number, returns the information of the shipment in the desired format.
	* 
	* REST API version - replaces SOAP implementation
	*
	* @shipment    The tracking number of a shipment
	* @format      The format by which we will return the tracking information to the user:
	*              -standard: The raw API response contained within a struct
	*              -structure: The API response data formatted as a struct along with the raw data within a struct
	*              -xml: The API response data formatted in XML along with the raw data within a struct
	*              -json: The API response data formatted in JSON along with the raw data within a struct
	*
	* @return The shipment information
	*/
	public struct function fetchFedEx(
		required string shipment,
		string format = "standard"
	) {
		
		// Step 1: Get OAuth token if not cached or expired
		local.accessToken = getOrRefreshAccessToken();
		if (!local.accessToken.success) {
			return {
				"success": false,
				"errors": ["Failed to obtain access token: " & local.accessToken.error],
				"metaData": {},
				"tracking": {}
			};
		}

		// Step 2: Make tracking request
		local.httpService = new HTTPShim();
		local.httpService.setMethod("post");
		local.httpService.setCharset("utf-8");
		
		// REST API endpoints
		if (variables.settings.fedexUseSandbox) {
			local.httpService.setUrl("https://apis-sandbox.fedex.com/track/v1/trackingnumbers");
		} else {
			local.httpService.setUrl("https://apis.fedex.com/track/v1/trackingnumbers");
		}
		
		// Set headers for REST API
		local.httpService.addParam(
			type = "header",
			name = "Authorization",
			value = "Bearer " & local.accessToken.token
		);
		local.httpService.addParam(
			type = "header", 
			name = "Content-Type",
			value = "application/json"
		);
		local.httpService.addParam(
			type = "header",
			name = "X-locale",
			value = "en_US"
		);
		
		// Create JSON request body (much simpler than SOAP XML)
		local.requestBody = {
			"includeDetailedScans": true,
			"trackingInfo": [
				{
					"trackingNumberInfo": {
						"trackingNumber": arguments.shipment
					}
				}
			]
		};
		
		// Convert to JSON string
		local.jsonRequest = serializeJSON(local.requestBody);
		
		// Add request body
		local.httpService.addParam(
			type = "body",
			name = "json_request", 
			value = local.jsonRequest
		);
		
		// Send the request
		local.response = local.httpService.send().getPrefix();
		
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// /////////*            Account for possible errors          *////////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		// Check status code
		if (badResponseStatus(local.response)) {
			return {
				"success": false,
				"errors": ["error: API returned status code " & local.response.statusCode],
				"metaData": local.response,
				"tracking": {}
			};
		}
		
		local.responseStruct = {};
		local.responseStruct["success"] = true;
		local.responseStruct["errors"] = [];
		
		try {
			// Parse JSON response (much simpler than XML parsing)
			local.responseJSON = deserializeJSON(local.response.fileContent);
			
			// Check for API-level errors
			if (structKeyExists(local.responseJSON, "errors")) {
				local.responseStruct["success"] = false;
				for (local.error in local.responseJSON.errors) {
					local.responseStruct["errors"].append(local.error.message);
				}
			}
			
			// Check tracking results
			if (structKeyExists(local.responseJSON, "output") && 
				structKeyExists(local.responseJSON.output, "completeTrackResults") &&
				arrayLen(local.responseJSON.output.completeTrackResults) > 0) {
				
				local.trackResult = local.responseJSON.output.completeTrackResults[1];
				
				// Check for tracking-specific errors
				if (structKeyExists(local.trackResult, "trackResults") && 
					arrayLen(local.trackResult.trackResults) > 0) {
					
					local.firstResult = local.trackResult.trackResults[1];
					
					// Check for error notifications in track results
					if (structKeyExists(local.firstResult, "error")) {
						local.responseStruct["success"] = false;
						local.responseStruct["errors"].append(local.firstResult.error.message);
					}
				} else {
					local.responseStruct["success"] = false;
					local.responseStruct["errors"].append("No tracking results found for tracking number");
				}
			} else {
				local.responseStruct["success"] = false;
				local.responseStruct["errors"].append("Invalid response structure from FedEx API");
			}
			
		} catch (any e) {
			local.responseStruct["success"] = false;
			local.responseStruct["errors"].append("Error parsing JSON response: " & e.message);
		}
		
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/* Choose a format with which to return the API's response to the user */
		if (arguments.format == "standard") {
			// Return the response as-is
			return local.response;
		} else if (arguments.format == "structure") {
			// Return structured data
			local.responseStruct["metaData"] = local.response;
			local.responseStruct["tracking"] = local.responseJSON;
			return local.responseStruct;
		} else if (arguments.format == "xml") {
			// Convert JSON to XML for backward compatibility
			local.responseXML = formatter.convertJSONtoXML(local.responseJSON);
			local.responseStruct["tracking"] = local.responseXML;
			local.responseStruct["metaData"] = local.response;
			return local.responseStruct;
		} else if (arguments.format == "json") {
			local.responseStruct["tracking"] = local.responseJSON;
			local.responseStruct["metaData"] = local.response;
			return local.responseStruct;
		} else {
			return {"error": "Unknown response format specified"};
		}
	}

	/**
	 * Gets or refreshes the OAuth access token for FedEx REST API
	 * Caches token until near expiration
	 */
	private struct function getOrRefreshAccessToken() {
		
		// Check if we have a cached token that's still valid
		if (structKeyExists(this.FedexTokenStruct, "fedexToken") && 
			structKeyExists(this.FedexTokenStruct.fedexToken, "expires") &&
			this.FedexTokenStruct.fedexToken.expires > now()) {
			return {
				"success": true,
				"token": this.FedexTokenStruct.fedexToken.access_token
			};
		}
		
		// Get new token
		local.httpService = new HTTPShim();
		local.httpService.setMethod("post");
		local.httpService.setCharset("utf-8");
		
		if (variables.settings.fedexUseSandbox) {
			local.httpService.setUrl("https://apis-sandbox.fedex.com/oauth/token");
		} else {
			local.httpService.setUrl("https://apis.fedex.com/oauth/token");
		}
		
		// Set headers
		local.httpService.addParam(
			type = "header",
			name = "Content-Type", 
			value = "application/x-www-form-urlencoded"
		);
		
		// Create form data for OAuth request
		local.formData = "grant_type=client_credentials&client_id=" & 
						urlEncodedFormat(variables.settings.fedexAPIKey) & 
						"&client_secret=" & urlEncodedFormat(variables.settings.fedexSecretKey);
		
		local.httpService.addParam(
			type = "body",
			name = "form_data",
			value = local.formData
		);
		
		local.response = local.httpService.send().getPrefix();

		if (badResponseStatus(local.response)) {
			return {
				"success": false,
				"error": "OAuth request failed with status " & local.response.statusCode
			};
		}
		
		try {
			local.tokenResponse = deserializeJSON(local.response.fileContent);
			
			if (structKeyExists(local.tokenResponse, "access_token")) {
				// Cache the token (expires in 1 hour, cache for 55 minutes to be safe)
				this.FedexTokenStruct.fedexToken = {
					"access_token": local.tokenResponse.access_token,
					"expires": dateAdd("n", 55, now())
				};
				
				return {
					"success": true,
					"token": local.tokenResponse.access_token
				};
			} else {
				return {
					"success": false,
					"error": "No access token in OAuth response"
				};
			}
			
		} catch (any e) {
			return {
				"success": false, 
				"error": "Error parsing OAuth response: " & e.message
			};
		}
	}


	/**
	 * Given a UPS tracking number, returns the information of the shipment in the desired format.
	 *
	 *           parameter for UPS.
	 *
	 * @shipment The tracking number of the shipment
	 * @standard The format with which to return the tracking information. Standard is the only available
	 *
	 * @return The shipment information
	 */
	public struct function fetchUPSLegacy( required string shipment, string format = "standard" ){
		local.httpService = new HTTPShim();

		/* Set attributes using implicit setters */
		local.httpService.setMethod( "get" );
		local.httpService.setCharset( "utf-8" );
		local.httpService.setUrl( "https://onlinetools.ups.com/track/v1/details/#arguments.shipment#" );

		/* Add header elements to authorize and specify the API request */
		local.httpService.addParam(
			type  = "header",
			name  = "transId",
			value = "12345"
		);
		local.httpService.addParam(
			type  = "header",
			name  = "transcationSrc",
			value = "TestTrack"
		);
		local.httpService.addParam(
			type  = "header",
			name  = "Username",
			value = variables.settings.upsUsername
		);
		local.httpService.addParam(
			type  = "header",
			name  = "Password",
			value = variables.settings.upsPassword
		);
		local.httpService.addParam(
			type  = "header",
			name  = "AccessLicenseNumber",
			value = variables.settings.upsApiKey
		);
		local.httpService.addParam(
			type  = "header",
			name  = "Content-Type",
			value = "application/json"
		);
		local.httpService.addParam(
			type  = "header",
			name  = "Accept",
			value = "application/json"
		);

		/* Send the request to the UPS API */
		local.response = local.httpService.send().getPrefix();

		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// /////////*            Account for possible errors          *////////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		// Check status code, first of all
		if ( badResponseStatus( local.response ) ) {
			// If we receive a bad status code from the API, we return an error
			return {
				"success"  : false,
				"errors"   : [ "error: API returned status code #local.response.statusCode#" ],
				"metaData" : local.response,
				"tracking" : {}
			}
		}

		local.responseStructJSON          = deserializeJSON( local.response.fileContent );
		local.responseStruct[ "success" ] = true;
		local.responseStruct[ "errors" ]  = []
		// Check to see if the API response contained errors
		if ( isDefined( "local.responseStructJSON['response']['errors']" ) ) {
			if ( local.responseStructJSON[ "response" ][ "errors" ].len() > 0 ) {
				for ( local.i = 0; local.i <= local.responseStructJSON.len(); local.i++ ) {
					local.responseStruct[ "errors" ].append(
						local.responseStructJSON[ "response" ][ "errors" ][ local.i ][ "message" ]
					);
					local.responseStruct[ "success" ] = false;
				}
			}
		}

		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		/* Choose a format with which to return the API's response to the user */
		if ( arguments.format == "standard" ) {
			// No edits made to the standard response
			return local.response;
		} else if ( arguments.format == "structure" ) {
			// Return a struct and metadata within a struct
			local.responseMetaData             = local.response;
			local.responseStruct[ "tracking" ] = local.responseStructJSON;
			local.responseStruct[ "metaData" ] = local.responseMetaData;
			return local.responseStruct;
		} else if ( arguments.format == "json" ) {
			// Return a JSON formatted string and the metadata in a struct
			local.responseMetaData             = local.response;
			local.responseStruct[ "tracking" ] = local.response.fileContent;
			local.responseStruct[ "metaData" ] = local.responseMetaData;
			return local.responseStruct;
		} else if ( arguments.format == "xml" ) {
			// Return an xml document object and the metadata in a struct
			local.responseMetaData             = local.response;
			local.responseStruct[ "tracking" ] = formatter.convertJSONtoXML( local.response.fileContent );
			local.responseStruct[ "metaData" ] = local.responseMetaData;
			return local.responseStruct;
		} else {
			return { "errors" : "Unknown response format specified" };
		}
	}

	private String function getUPSDomain() {
		if (variables.settings.upsUseSandbox) {
			return "wwwcie.ups.com";
		} else {
			return "onlinetools.ups.com";
		}
	}
	
	/**
	* Given a UPS tracking number, returns the information of the shipment in the desired format.
	* Updated to use the new OAuth 2.0 REST API
	*
	* @shipment The tracking number of the shipment
	* @format   The format with which to return the tracking information
	*
	* @return The shipment information
	*/
	public struct function fetchUPS(required string shipment, string format = "standard") {
		
		// Step 1: Get OAuth token
		local.accessToken = getUPSAccessToken();
		if (!local.accessToken.success) {
			return {
				"success": false,
				"errors": ["Failed to obtain UPS access token: " & local.accessToken.error],
				"metaData": {},
				"tracking": {}
			};
		}
		
		// Step 2: Make tracking request with new API
		local.httpService = new HTTPShim();
		
		/* Set attributes using implicit setters */
		local.httpService.setMethod("get");
		local.httpService.setCharset("utf-8");
		
		// Use the new API endpoint
		local.httpService.setUrl("https://#getUPSDomain()#/api/track/v1/details/#arguments.shipment#");
		
		/* Add headers for OAuth authentication */
		local.httpService.addParam(
			type = "header",
			name = "Authorization",
			value = "Bearer " & local.accessToken.token
		);
		local.httpService.addParam(
			type = "header",
			name = "transId",
			value = createUUID() // Generate unique transaction ID
		);
		local.httpService.addParam(
			type = "header",
			name = "transactionSrc",
			value = "TrackAPI"
		);
		local.httpService.addParam(
			type = "header",
			name = "Content-Type",
			value = "application/json"
		);
		local.httpService.addParam(
			type = "header",
			name = "Accept",
			value = "application/json"
		);
		
		/* Send the request to the UPS API */
		local.response = local.httpService.send().getPrefix();
		
		// ////////////////////////////////////////////////////////////////////////////////////////////////
		// /////////*            Account for possible errors          */////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////
		
		// Check status code, first of all
		if (badResponseStatus(local.response)) {
			// If we receive a bad status code from the API, we return an error
			return {
				"success": false,
				"errors": ["error: API returned status code #local.response.statusCode#"],
				"metaData": local.response,
				"tracking": {}
			}
		}
		
		local.responseStructJSON = deserializeJSON(local.response.fileContent);
		local.responseStruct["success"] = true;
		local.responseStruct["errors"] = [];
		
		// Check to see if the API response contained errors
		if (isDefined("local.responseStructJSON.response.errors")) {
			if (local.responseStructJSON["response"]["errors"].len() > 0) {
				for (local.i = 1; local.i <= arrayLen(local.responseStructJSON["response"]["errors"]); local.i++) {
					local.responseStruct["errors"].append(
						local.responseStructJSON["response"]["errors"][local.i]["message"]
					);
					local.responseStruct["success"] = false;
				}
			}
		}
		
		// ////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////
		
		/* Choose a format with which to return the API's response to the user */
		if (arguments.format == "standard") {
			// No edits made to the standard response
			return local.response;
		} else if (arguments.format == "structure") {
			// Return a struct and metadata within a struct
			local.responseMetaData = local.response;
			local.responseStruct["tracking"] = local.responseStructJSON;
			local.responseStruct["metaData"] = local.responseMetaData;
			return local.responseStruct;
		} else if (arguments.format == "json") {
			// Return a JSON formatted string and the metadata in a struct
			local.responseMetaData = local.response;
			local.responseStruct["tracking"] = local.response.fileContent;
			local.responseStruct["metaData"] = local.responseMetaData;
			return local.responseStruct;
		} else if (arguments.format == "xml") {
			// Return an xml document object and the metadata in a struct
			local.responseMetaData = local.response;
			local.responseStruct["tracking"] = formatter.convertJSONtoXML(local.response.fileContent);
			local.responseStruct["metaData"] = local.responseMetaData;
			return local.responseStruct;
		} else {
			return {"errors": "Unknown response format specified"};
		}
	}

	/**
	 * Gets or refreshes the OAuth access token for UPS REST API
	 * Caches token until near expiration
	 * 
	 * @return Struct with success status and token or error message
	 */
	private struct function getUPSAccessToken() {
		
		// Check if we have a cached token that's still valid (with 5 minute buffer)
		if ( structKeyExists(this.UPSTokenStruct, "upsToken") &&
			structKeyExists(this.UPSTokenStruct.upsToken, "expires") &&
			this.UPSTokenStruct.upsToken.expires > dateAdd("n", 5, now())) {
			
			return {
				"success": true,
				"token": this.UPSTokenStruct.upsToken.access_token
			};
		}
		
		// Get new token
		local.httpService = new HTTPShim();
		local.httpService.setMethod("post");
		local.httpService.setCharset("utf-8");
		local.httpService.setUrl("https://#getUPSDomain()#/security/v1/oauth/token");
		
		// Set headers for OAuth request
		local.httpService.addParam(
			type = "header",
			name = "Content-Type",
			value = "application/x-www-form-urlencoded"
		);
		
		// Create Basic Auth header from Client ID and Client Secret
		// Basic Auth = base64(clientId:clientSecret)
		local.authString = toBase64(variables.settings.upsClientId & ":" & variables.settings.upsClientSecret);
		local.httpService.addParam(
			type = "header",
			name = "Authorization",
			value = "Basic " & local.authString
		);
		
		// Add x-merchant-id header if you have one (optional but recommended)
		if (structKeyExists(variables.settings, "upsMerchantId") && len(variables.settings.upsMerchantId)) {
			local.httpService.addParam(
				type = "header",
				name = "x-merchant-id",
				value = variables.settings.upsMerchantId
			);
		}
		
		// Create form data for OAuth request
		local.formData = "grant_type=client_credentials";
		
		local.httpService.addParam(
			type = "body",
			value = local.formData
		);
		
		try {
			local.response = local.httpService.send().getPrefix();
			
			if (badResponseStatus(local.response)) {
				return {
					"success": false,
					"error": "OAuth request failed with status " & local.response.statusCode & ": " & local.response.fileContent
				};
			}
			
			local.tokenResponse = deserializeJSON(local.response.fileContent);
			
			if (structKeyExists(local.tokenResponse, "access_token")) {
				// Cache the token
				// UPS tokens typically expire in 14399 seconds (about 4 hours)
				// We'll cache for slightly less to be safe
				local.expiresIn = structKeyExists(local.tokenResponse, "expires_in") ? 
								local.tokenResponse.expires_in : 14399;
				
				// Subtract 5 minutes (300 seconds) for safety margin
				local.cacheSeconds = local.expiresIn - 300;
				
				this.UPSTokenStruct.upsToken = {
					"access_token": local.tokenResponse.access_token,
					"expires": dateAdd("s", local.cacheSeconds, now()),
					"token_type": local.tokenResponse.token_type
				};
				
				return {
					"success": true,
					"token": local.tokenResponse.access_token
				};
			} else {
				return {
					"success": false,
					"error": "No access token in OAuth response: " & local.response.fileContent
				};
			}
			
		} catch (any e) {
			rethrow;
			return {
				"success": false,
				"error": "Error during OAuth request: " & e.message
			};
		}
	}


	/**
	 * Given a tracking number from Dayton Freight, makes a request to their API
	 * to return tracking information.
	 *
	 * Note that SSL is REQUIRED when using the Dayton Freight API. It will not work otherwise due
	 * to the fact that credentials are sent on each request.
	 *
	 */
	public struct function fetchDaytonFreight( required string shipment, string format = "standard" ){
		local.httpService = new HTTPShim();

		/* Set attributes using implicit setters */
		local.httpService.setMethod( "get" );
		local.httpService.setCharset( "utf-8" );
		local.httpService.setUrl( "https://api.daytonfreight.com/api/Tracking/ByNumber?number=#shipment#&type=Pro" );

		/* Add credentials to the API request */
		local.httpService.addParam(
			type  = "header",
			name  = "Authorization",
			value = "#variables.settings.daytonFreightBasicAuth#"
		);

		/* Send the request to the Dayton Freight API */
		local.response = local.httpService.send().getPrefix();

		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// /////////*            Account for possible errors          *////////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		// Check status code, first of all
		if ( badResponseStatus( local.response ) ) {
			// If we receive a bad status code from the API, we return an error
			return {
				"success"  : false,
				"errors"   : [ "error: API returned status code #local.response.statusCode#" ],
				"metaData" : local.response,
				"tracking" : {}
			}
		}

		local.responseStructJSON          = deserializeJSON( local.response.filecontent );
		local.responseStruct[ "errors" ]  = [];
		local.responseStruct[ "success" ] = true;
		// If our API response does not hold any information, we say our fetch of the tracking information was unsuccessful
		if ( local.responseStructJSON[ "results" ].len() == 0 ) {
			local.responseStruct[ "errors" ].append( "No information returned for the requested tracking number" );
			local.responseStruct[ "success" ] = false;
		}

		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		/* Format the Api response based on the requested format by the user */
		if ( arguments.format == "standard" ) {
			return local.response;
		} else if ( arguments.format == "structure" ) {
			local.responseStruct[ "metadata" ] = local.response;
			local.responseStruct[ "tracking" ] = local.responseStructJSON;
			return local.responseStruct;
		} else if ( arguments.format == "json" ) {
			local.responseStruct[ "metadata" ] = local.response;
			local.responseStruct[ "tracking" ] = local.response.filecontent;
			return local.responseStruct;
		} else if ( arguments.format == "xml" ) {
			local.responseStruct[ "metadata" ] = local.response;
			local.responseStruct[ "tracking" ] = formatter.JSONtoXML( local.response.filecontent );
			return local.responseStruct;
		} else {
			return {
				"error" : "The service you requested to fetch shipping information from was not found or is unsupported"
			};
		}
	}


	// TODO
	/**
	 * Given a tracking number from R+L carriers, makes a request to their API
	 * to return tracking information.
	 *
	 * Ask Alyssa about this one!!!!
	 *
	 */
	private struct function fetchRLC( required string shipment, string format = "standard" ){
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// /////////*            Account for possible errors          *////////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		// Check status code, first of all
		if ( badResponseStatus( local.response ) ) {
			// If we receive a bad status code from the API, we return an error
			return {
				"success"  : false,
				"errors"   : [ "error: API returned status code #local.response.statusCode#" ],
				"metaData" : local.response,
				"tracking" : {}
			}
		}

		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	}

	/**
	 * Given a Holland freight tracking number, makes a request to their API
	 * to return tracking information.
	 *
	 * N.B. It appears that using the tracking numbers that look like 607-461842-4 for Holland Freight's non-public API
	 * (which is literally the same endpoint with the addition of another variable in the queryString that looks like '?accessKey=XXXXXX')
	 * is not retrieving tracking information. For now, DOG will remain a client for the public Holland API.
	 *
	 * @shipment The tracking number of the shipment
	 * @format   The format with which to return the API response
	 *
	 * @return The tracking information of the shipment
	 */
	public struct function fetchHolland( required string shipment, string format = "standard" ){
		local.httpService = new HTTPShim();

		/* Set attributes using implicit setters */
		local.httpService.setMethod( "get" );
		local.httpService.setCharset( "utf-8" );
		local.httpService.setUrl( "https://api.hollandregional.com/api/TrackShipments/doTrackDetail?searchBy=PRO&number=#arguments.shipment#" );

		/* Send the request to the Holland API */
		local.response = local.httpService.send().getPrefix();

		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// /////////*            Account for possible errors          *////////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		// Check status code, first of all
		if ( badResponseStatus( local.response ) ) {
			// If we receive a bad status code from the API, we return an error
			return {
				"success"  : false,
				"errors"   : [ "error: API returned status code #local.response.statusCode#" ],
				"metaData" : local.response,
				"tracking" : {}
			}
		}

		local.responseXML                 = xmlParse( local.response.fileContent );
		local.statusXML                   = xmlSearch( local.responseXML, "/TrackDetailResponse/STATUS/CODE" );
		local.responseStruct[ "success" ] = true;
		local.responseStruct[ "errors" ]  = [];
		// Holland indicates the success of retrieving tracking information with that STATUS XML node of the response they return. 1 means an error and anything else is OK.
		if ( local.statusXML[ 1 ].XmlText == 1 ) {
			local.responseStruct[ "success" ] = false;
			local.responseStruct[ "errors" ].append(
				xmlSearch( local.response.fileContent, "/TrackDetailResponse/STATUS/MESSAGE" )[ 1 ].xmlText
			);
		}

		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		/* Choose a format with which to return the API's response to the user */
		if ( arguments.format == "standard" ) {
			// Return the response as-is
			return local.response;
		} else if ( arguments.format == "structure" ) {
			// Create a struct full of information from the response
			local.responseStruct[ "metaData" ] = local.response;
			local.responseStruct[ "tracking" ] = formatter.convertXMLtoStruct( local.responseXML );
			return local.responseStruct;
		} else if ( arguments.format == "xml" ) {
			// Convert the response to an XML object, including the metadata in a struct
			local.responseStruct[ "tracking" ] = local.responseXML;
			local.responseStruct[ "metaData" ] = local.response;
			return local.responseStruct;
		} else if ( arguments.format == "json" ) {
			// Convert the XML filecontent of the response to JSON
			local.responseJSON                 = formatter.convertXMLtoJSON( local.responseXML );
			local.responseStruct[ "tracking" ] = local.responseJSON;
			local.responseStruct[ "metaData" ] = local.response;
			return local.responseStruct;
		} else {
			return { "error" : "Unknown response format specified" };
		}
	}


	/**
	 * Given a YRC tracking number, makes a request to their API to return tracking
	 * information.
	 *
	 * Currently using the public webservice. The non-public and public API tracking guides which appear on the
	 * YRC website appear the same, so we're just sticking with the public one.
	 *
	 * @shipment The tracking number of the shipment
	 * @format   The format with which to return the API response
	 *
	 * @return The tracking information of the shipment
	 */
	public struct function fetchYRC( required string shipment, string format = "standard" ){
		local.httpService = new HTTPShim();

		/* Set attributes using implicit setters */
		local.httpService.setMethod( "post" );
		local.httpService.setCharset( "utf-8" );
		local.httpService.setUrl( "http://my.yrc.com/myyrc-api/national/servlet?CONTROLLER=com.rdwy.ec.rextracking.http.controller.ProcessPublicTrackingController" );

		/* Set headers to further specify the API request */
		local.httpService.addParam(
			type  = "formfield",
			name  = "PRONumber",
			value = arguments.shipment
		);
		local.httpService.addParam( type = "formfield", name = "xml", value = "Y" );

		/* Send the request to the YRC API */
		local.response = local.httpService.send().getPrefix();

		// Check status code, first of all
		if ( badResponseStatus( local.response ) ) {
			// If we receive a bad status code from the API, we return an error
			return {
				"success"  : false,
				"errors"   : [ "error: API returned status code #local.response.statusCode#" ],
				"metaData" : local.response,
				"tracking" : {}
			}
		}

		/* Choose a format with which to return the API's response to the user */
		if ( arguments.format == "standard" ) {
			return local.response;
		} else {
			// If we aren't returning to the user with a standard format, then we ought to do some html parsing to get the correct information
			// out of the raw HTML that the API sends us back

			// Use the jSoup java library for our HTML parsing
			local.jSoupClass = createObject( "java", "org.jsoup.Jsoup" );

			// Create a document object out of the API's response
			local.doc = createObject( "java", "org.jsoup.nodes.Document" ).init( "" );
			local.doc.html( local.response.fileContent );
			local.doc = local.doc.selectFirst( "##pageContent" );
			// Check to see if we've successfully obtained the page content

			local.doc = local.doc.selectFirst( "##printArea" );
			// Check to see if we've successfully obtained the table with the tracking information


			// Scrape all of the records from the tracking information table
			local.doc = local.doc
				.selectFirst( "table" )
				.selectFirst( "tbody" )
				.selectFirst( "table" )
				.selectFirst( "tbody" );
			local.shipmentsHTML = local.doc.select( "tr" );

			// Loop through all of the shipment records in the tracking response, adding their data as structs to an array
			local.shipmentArray = [];
			for ( local.shipment in local.shipmentsHTML ) {
				local.struct       = {};
				local.shipmentData = local.shipment.select( "td" );
				if ( isDefined( "local.shipmentData[1]" ) ) {
					local.struct[ "TrackingNumber" ] = local.shipmentData[ 1 ].text();
				}
				if ( isDefined( "local.shipmentData[2]" ) ) {
					local.struct[ "Status" ] = local.shipmentData[ 2 ].text();
				}
				if ( isDefined( "local.shipmentData[3]" ) ) {
					local.struct[ "PickupDate" ] = local.shipmentData[ 3 ].text();
				}
				if ( isDefined( "local.shipmentData[4]" ) ) {
					local.struct[ "EstimatedDeilveryDate" ] = local.shipmentData[ 4 ].text();
				}
				if ( isDefined( "local.shipmentData[5]" ) ) {
					local.struct[ "ShipFrom" ] = local.shipmentData[ 5 ].text();
				}
				if ( isDefined( "local.shipmentData[6]" ) ) {
					local.struct[ "ShipTo" ] = local.shipmentData[ 6 ].text();
				}
				local.shipmentArray.append( local.struct );
			}

			// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			// /////////*            Account for possible errors          *////////////////////////////////////////////////////////////////////////////////////////////////////
			// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

			local.responseStruct[ "success" ] = true;
			local.responseStruct[ "errors" ]  = [];
			// Check to see if we returned an error key-value pair
			for ( local.i = 1; local.i <= local.shipmentArray.len(); local.i++ ) {
				if ( local.shipmentArray[ i ][ "Status" ] == "The number you requested was not found" ) {
					local.responseStruct[ "errors" ].append( "The number you requested was not found" );
					local.responseStruct[ "success" ] = false;
				}
			}

			// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

			/* Now that we have captured the data, we can return it to the user in the format that they request */
			if ( arguments.format == "structure" ) {
				// We return a structure containing the api response data and an array of shipment items and their data in substructures
				local.responseStruct[ "metaData" ] = local.response;
				local.responseStruct[ "tracking" ] = local.shipmentArray;
				return local.responseStruct;
			} else if ( arguments.format == "json" ) {
				// We return a structure containing the api response data and a JSON formatted string of shipment items and their data
				local.responseStruct[ "metaData" ] = local.response;
				local.responseStruct[ "tracking" ] = serializeJSON( local.shipmentArray );
				return local.responseStruct;
			} else if ( arguments.format == "xml" ) {
				// Return a structure containing the api response data and an XML coldfusion object of the shipment items and their data
				local.responseStruct[ "metaData" ] = local.response;
				local.responseStruct[ "tracking" ] = formatter.convertJSONtoXML(
					serializeJSON( local.shipmentArray )
				);
				return local.responseStruct;
			} else {
				return { "error" : "Unknown response format specified" };
			}
		}
	}


	/**
	 * Retrieve tracking information from aftership (Tazmanian freight) //This is untested. We ought to check it out once we find some Taz freight numbers.
	 *
	 * @service 
	 * @shipment
	 * @format  
	 */
	private struct function fetchAftership( required string shipment, string format = "standard" ){
		local.httpService = new HTTPShim();

		/* Set attributes using implicit setters */
		local.httpService.setMethod( "get" );
		local.httpService.setUrl( "https://api.aftership.com/v4/trackings/tazmanian-freight/#shipment#" );

		/* Set headers to further specify the API request */
		local.httpService.addParam(
			type  = "header",
			name  = "aftership-api-key",
			value = variables.settings.aftershipAPIKey
		);

		/* Send the request to the API */
		local.response = local.httpService.send().getPrefix();

		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// /////////*            Account for possible errors          *////////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		// Check status code, first of all
		if ( badResponseStatus( local.response ) ) {
			// If we receive a bad status code from the API, we return an error
			return {
				"success"  : false,
				"errors"   : [ "error: API returned status code #local.response.statusCode#" ],
				"metaData" : local.response,
				"tracking" : {}
			}
		}
		// TODO

		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		/* Format the Api response based on the requested format by the user */
		if ( arguments.format == "standard" ) {
			return local.response;
		} else if ( arguments.format == "structure" ) {
			local.responseStruct[ "metadata" ] = local.response;
			local.responseStruct[ "tracking" ] = deserializeJSON( local.response.filecontent );
			return local.responseStruct;
		} else if ( arguments.format == "json" ) {
			local.responseStruct[ "metadata" ] = local.response;
			local.responseStruct[ "tracking" ] = local.response.filecontent;
			return local.responseStruct;
		} else if ( arguments.format == "xml" ) {
			local.responseStruct[ "metadata" ] = local.response;
			local.responseStruct[ "tracking" ] = formatter.JSONtoXML( local.response.filecontent );
			return local.responseStruct;
		} else {
			return {
				"error" : "The service you requested to fetch shipping information from was not found or is unsupported"
			};
		}
	}


	/**
	 * TODO
	 * Given an XPO Logistics tracking number, makes a request to their API to return
	 * tracking information.
	 *
	 * https://ltl-solutions.xpo.com/help-center/api/
	 * https://xpodotcom.azureedge.net/xpo/files/s8/Shipment_Tracking_API_Implementation_Guide.pdf
	 *
	 * !!!!!!N.B. The bearer token expires 12 hours after creation, and the refresh token expires 24 hours after creation.
	 * We must detect expired tokens before we use them, and obtain new ones
	 * all within this function to not create any more layers of complexity.
	 *
	 * TODO Need to get token refreshing working correctly
	 *
	 * @shipment The tracking number of the shipment
	 * @format   The format with which to return the API response
	 *
	 * @return The tracking information of the shipment
	 */
	public struct function fetchXPOLogistics( required string shipment, string format = "standard" ){
		local.httpService = new HTTPShim();

		/* Set attributes using implicit setters */
		local.httpService.setMethod( "GET" );
		local.httpService.setUrl( "https://api.ltl.xpo.com/tracking/1.0/shipments/shipment-status-details?referenceNumbers=#arguments.shipment#" );

		// set a bad bearer and refresh token to see what response we get
		// this.XPOLogisticsTokenStruct["XPOLogisticsBearerToken"] = "9b3d2998-cf7b-3c6a-b258-a6655cc13633";
		// this.XPOLogisticsTokenStruct["XPOLogisticsRefreshToken"] = "458f8b39-5c5e-3a7a-897c-debfe3b79349fw";

		// Check to see if we need to get a bearer token to make some calls with XPO Logistics
		if (
			!this.XPOLogisticsTokenStruct.keyExists( "XPOLogisticsBearerToken" ) || !this.XPOLogisticsTokenStruct.keyExists( "XPOLogisticsRefreshToken" )
		) {
			// If the bearer/refresh token doesn't exist, we acquire one here
			// Send a request to generate a new bearer token and refresh token with an access token
			// This is usually done on the first call to the API, where no information regarding XPO logistics exists on the server
			local.tokenService = new HTTPShim();
			local.tokenService.setMethod( "POST" );
			local.tokenService.setUrl( "https://api.ltl.xpo.com/token" );
			local.tokenService.addParam(
				type  = "header",
				name  = "Authorization",
				value = variables.settings.XPOLogisticsAccessToken
			);
			local.requestBody = "grant_type=password&username=#variables.settings.XPOLogisticsUserId#&password=#variables.settings.XPOLogisticsPassword#";
			local.tokenService.addParam(
				type  = "body",
				name  = "body",
				value = local.requestBody
			);
			local.tokenResponse                                        = local.tokenService.send().getPrefix();
			// Get the response from the bearer token creation request, storing the bearer and refresh tokens
			local.responseContent                                      = deserializeJSON( local.tokenResponse[ "filecontent" ] );
			if( responseContent.keyExists( "error" ) && len( local.responseContent[ "error" ] ) > 0 ) {
				return {
					"success" : false,
					"errors"  : [
						"error": responseContent.error & " " & (responseContent.error_description ?: "")
					],
					"metaData" : {},
					"tracking" : {}
				};
			}
			this.XPOLogisticsTokenStruct[ "XPOLogisticsBearerToken" ]  = local.responseContent[ "access_token" ];
			this.XPOLogisticsTokenStruct[ "XPOLogisticsRefreshToken" ] = local.responseContent[ "refresh_token" ];
		}

		// Try to send a request and see if we get an expired token error.
		while ( true )
			// We loop here so we can try to send a request until we get no errors from potentially expired tokens
		{
			local.httpService.addParam(
				type  = "header",
				name  = "Authorization",
				value = "Bearer " & this.XPOLogisticsTokenStruct[ "XPOLogisticsBearerToken" ]
			);

			/* Send the request to the XPO Logistics API */
			local.response = local.httpService.send().getPrefix();
			// writeDump(local.response);

			// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			// /////////*            Account for possible errors          *////////////////////////////////////////////////////////////////////////////////////////////////////
			// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

			// Check status code, first of all
			if ( badResponseStatus( local.response ) ) {
				// Check to see if no information was found on the supplied tracking number
				if ( local.response.fileContent.find( "No data found for the Shipment Reference Number/s" ) ) {
					return {
						"success" : false,
						"errors"  : [
							"error: #deserializeJSON( local.response.fileContent )[ "error" ][ "message" ]#"
						],
						"metaData" : local.response,
						"tracking" : {}
					};
					break;
				}
				// Check to see if we sent invalid credentials
				if ( local.response.fileContent.find( "Persisted access token data not found" ) ) {
					// This error will be triggered when we send a bad access token. We try to use the refresh token to get a new bearer token.
					// Send a request to generate a new bearer token and refresh token with a refresh token
					local.refreshTokenService = new HTTPShim();
					local.refreshTokenService.setMethod( "POST" );
					local.refreshTokenService.setUrl( "https://api.ltl.xpo.com/token" );
					local.refreshTokenService.addParam(
						type  = "header",
						name  = "Authorization",
						value = variables.settings.XPOLogisticsAccessToken
					);
					local.requestBody = "grant_type=refresh_token&refresh_token=#this.XPOLogisticsTokenStruct[ "XPOLogisticsRefreshToken" ]#";
					local.refreshTokenService.addParam(
						type  = "body",
						name  = "body",
						value = local.requestBody
					);
					local.refreshTokenResponse                                 = local.refreshTokenService.send().getPrefix();
					// Get the response from the bearer token refresh request, storing the bearer and refresh tokens
					local.responseContent                                      = deserializeJSON( local.tokenResponse[ "filecontent" ] );
					this.XPOLogisticsTokenStruct[ "XPOLogisticsBearerToken" ]  = local.responseContent[ "access_token" ];
					this.XPOLogisticsTokenStruct[ "XPOLogisticsRefreshToken" ] = local.responseContent[
						"refresh_token"
					];
					// Get ready to send another request
					local.httpService.clearParams();
				} else {
					// If we receive another bad status code from the API, we return an error
					return {
						"success"  : false,
						"errors"   : [ "error: API returned status code #local.response.statusCode#" ],
						"metaData" : local.response,
						"tracking" : {}
					};
					break;
				}
			} else {
				break;
			}
		}

		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		/* Format the Api response based on the requested format by the user */
		if ( arguments.format == "standard" ) {
			return local.response;
		} else if ( arguments.format == "structure" ) {
			local.responseStruct[ "metadata" ] = local.response;
			local.responseStruct[ "tracking" ] = deserializeJSON( local.response.filecontent );
			return local.responseStruct;
		} else if ( arguments.format == "json" ) {
			local.responseStruct[ "metadata" ] = local.response;
			local.responseStruct[ "tracking" ] = local.response.filecontent;
			return local.responseStruct;
		} else if ( arguments.format == "xml" ) {
			local.responseStruct[ "metadata" ] = local.response;
			local.responseStruct[ "tracking" ] = formatter.convertJSONtoXML( local.response.filecontent );
			return local.responseStruct;
		} else {
			return {
				"error" : "The format you requested to return shipping information in was not found or is unsupported for XPO Logistics in DOG"
			};
		}
	}


	/**
	 * Given an uber freight tracking number, makes a request to the API to return
	 * tracking information.
	 *
	 * @shipment The tracking number of the shipment
	 * @format   The format with which to return the API response.
	 */
	public struct function fetchUberFreight( required string shipment, string format = "standard" ){
		// TODO

		return {};
	}


	/**
	 * The dog fetches the shipping information for a shipment and a service
	 * specified within its arguments. It returns the shipping information in the
	 * specified format as well!
	 *
	 * @shipment The tracking number/id of the shipment to find information about
	 * @service  The shipping service to reference regarding the tracking number
	 * @format   The format with which to return the API response. Currently no options here yet, but more will be added!
	 *
	 * @return The API request result
	 */
	public struct function fetch(
		required string service,
		required string shipment,
		string format = "standard"
	){
		// ////////////////////////////////////////////////////////////////////////////////////////////
		// ///////////////////////////////*           FedEx           *////////////////////////////////
		// ////////////////////////////////////////////////////////////////////////////////////////////
		var fedexTypes = "fedex ground,fedex,fedex freight ltl,fedex express,fedex smartpost,fedex custom critical";
		if ( listFindNoCase( fedexTypes, arguments.service ) ) {
			return fetchFedEx( arguments.shipment, arguments.format );
		}

		// /////////////////////////////////////////////////////////////////////////////////////////////
		// //////////////////////////////*            UPS            *//////////////////////////////////
		// /////////////////////////////////////////////////////////////////////////////////////////////
		else if (
			arguments.service == "ups" || arguments.service == "ups ground" || arguments.service == "tforce" || arguments.service == "tforce freight"
		) {
			return fetchUPS( arguments.shipment, arguments.format );
		}

		// /////////////////////////////////////////////////////////////////////////////////////////////
		// /////////////////////////////*       Dayton Freight       *//////////////////////////////////
		// /////////////////////////////////////////////////////////////////////////////////////////////
		else if (
			arguments.service == "dayton freight" || arguments.service == "dayton" || arguments.service == "dayton freight lines"
		) {
			return fetchDaytonFreight( arguments.shipment, arguments.format );
		}

		// /////////////////////////////////////////////////////////////////////////////////////////////
		// /////////////////////////////*        R+L Carriers        *//////////////////////////////////
		// /////////////////////////////////////////////////////////////////////////////////////////////
		else if (
			arguments.service == "rlc" || arguments.service == "r+l carriers" || arguments.service == "rl carriers" || arguments.service == "rl"
		) {
			// return fetchRLC(arguments.shipment, arguments.format);
			return {
				"success" : false,
				"errors"  : [
					"This API client is currently under construction and unable to be used. Sorry about that!"
				],
				"metaData" : {},
				"tracking" : {}
			};
		}

		// /////////////////////////////////////////////////////////////////////////////////////////////
		// /////////////////////////////*       Holland Freight      *//////////////////////////////////
		// /////////////////////////////////////////////////////////////////////////////////////////////
		else if (
			arguments.service == "holland ltl" || arguments.service == "holland freight" || arguments.service == "holland"
		) {
			return fetchHolland( arguments.shipment, arguments.format );
		}

		// /////////////////////////////////////////////////////////////////////////////////////////////
		// ////////////////////////////*          YRC Freight        *//////////////////////////////////
		// /////////////////////////////////////////////////////////////////////////////////////////////
		else if ( arguments.service == "yrc" || arguments.service == "yrc freight" || arguments.service == "yrc ltl" ) {
			return fetchYRC( arguments.shipment, arguments.format );
		}

		// /////////////////////////////////////////////////////////////////////////////////////////////
		// ///////////////////////////////*      Aftership       *//////////////////////////////////////
		// /////////////////////////////////////////////////////////////////////////////////////////////
		else if ( arguments.service == "tazmanian freight" ) {
			// return fetchAftership(arguments.shipment, arguments.format);
			return {
				"success" : false,
				"errors"  : [
					"This API client is currently under construction and unable to be used. Sorry about that!"
				],
				"metaData" : {},
				"tracking" : {}
			};
		}

		// /////////////////////////////////////////////////////////////////////////////////////////////
		// /////////////////////////////*       XPO Logistics       *///////////////////////////////////
		// /////////////////////////////////////////////////////////////////////////////////////////////
		else if ( arguments.service == "xpo logistics" || arguments.service == "xpo" ) {
			return fetchXPOLogistics( arguments.shipment, arguments.format );
			// return { "success" : false,
			//          "errors" : ["This API client is currently under construction and unable to be used. Sorry about that!"],
			//          "metaData" : {},
			//          "tracking" : {}
			//         };
		}

		// /////////////////////////////////////////////////////////////////////////////////////////////


		// The service parameter requested is not supported within DOG
		else {
			return {
				"success" : false,
				"errors"  : [
					"The service you requested ""#arguments.service#"" is not supported within DOG. Please refer to ReadMe for supported shipping services."
				],
				"metaData" : {},
				"tracking" : {}
			};
		}
	}

}
