/**
 * A model used to communicate with shipping service APIs and retrieve information from them in the format
 * of your choice.
 * 
 * The following is the list of Dog's supported APIS:
 * - FedEx
 * - UPS
 * - Dayton Freight
 * - R+L Carriers
 * - Holland Freight
 * - YRC Freight
 * - Aftership
 */
component
{

    //Other models used
    property name="formatter"             inject="formatter@dog";

    //Fedex Information
    property name="fedexAPIKey"             inject="coldbox:setting:fedexApiKey@dog";
    property name="fedexPassword"           inject="coldbox:setting:fedexPassword@dog";
    property name="fedexAccountNumber"      inject="coldbox:setting:fedexAccountNumber@dog";
    property name="fedexMeterNumber"        inject="coldbox:setting:fedexMeterNumber@dog";

    //UPS Information
    property name="upsApiKey"               inject="coldbox:setting:upsApiKey@dog";
    property name="upsUsername"             inject="coldbox:setting:upsUsername@dog";
    property name="upsPassword"             inject="coldbox:setting:upsPassword@dog";

    //Dayton Freight information
    property name="daytonFreightBasicAuth"  inject="coldbox:setting:daytonFreightBasicAuth@dog";

    //RLC information

    //Holland information

    //YRC information


    //Aftership Information (Tazmanian Freight)
    property name="aftershipApiKey"       inject="coldbox:setting:aftershipApiKey@dog";        


    //Default constructor
    deliveryObservationGadget function init()
    {
        return this;
    }


    /**
     * Given a FedEx tracking number, returns the information of the shipment in the desired format.
     *
     * @shipment The tracking number of a shipment
     * 
     * @return The shipment information
     */
    any function fetchFedEx(required string shipment, string format = "standard")
    {
        local.httpService = new http();

        /* Set attributes using implicit setters */
        local.httpService.setMethod("post");
        local.httpService.setCharset("utf-8");
        local.httpService.setUrl("https://ws.fedex.com:443/web-services/track"); //Endpoint for FedEx API (port 433 must be opened for bi-directional communication on the firewall)

        /* Create SOAP format API request */
        local.fileContent = 
        "
        <soapenv:Envelope xmlns:soapenv=""http://schemas.xmlsoap.org/soap/envelope/"" xmlns=""http://fedex.com/ws/track/v20"">
            <soapenv:Header/>
            <soapenv:Body>
                <TrackRequest>
                    <WebAuthenticationDetail>
                        <ParentCredential>
                            <Key>#variables.fedexAPIKey#</Key>
                            <Password>#variables.fedexPassword#</Password>
                        </ParentCredential>
                        <UserCredential>
                            <Key>#variables.fedexAPIKey#</Key>
                            <Password>#variables.fedexPassword#</Password>
                        </UserCredential>
                    </WebAuthenticationDetail>
                    <ClientDetail>
                        <AccountNumber>#variables.fedexAccountNumber#</AccountNumber>
                        <MeterNumber>#variables.fedexMeterNumber#</MeterNumber>
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
                        <CarrierCode>FDXE</CarrierCode>
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
        httpService.addParam(type="body", name="API_XML_Request", value=local.fileContent);

        /* Send the request to the FedEx API */
        local.response = local.httpService.send().getPrefix();

        /* Account for possible errors */
        if(local.response.status_code == 503)
        {
            return {"error" : "FedEx Servers returned status code 503: Service Unavailable", "content" : local.response.filecontent};
        }

        /* Choose a format with which to return the API's response to the user */
        if(arguments.format == "standard")
        {
            //Return the response as-is
            return local.response;
        }
        else if(arguments.format == "structure")
        {
            //Convert to XML first so we can convert to JSON from XML
            local.responseXML = xmlParse(local.response.fileContent);
            //Create a struct full of information from the response
            local.responseStruct["metaData"] = local.response;
            local.responseStruct["trackResponse"] = formatter.convertXMLtoStruct(local.responseXML);
            return local.responseStruct;
        }
        else if(arguments.format == "xml")
        {
            //Convert the response to an XML object, including the metadata in a struct
            local.responseXML = xmlParse(local.response.fileContent);
            local.responseStruct["xml"] = local.responseXML;
            local.responseStruct["metaData"] = local.response;
            return local.responseStruct;
        }
        else if(arguments.format == "json")
        {
            //Convert the XML filecontent of the response to JSON
            local.responseXML = xmlParse(local.response.fileContent);
            local.responseJSON = formatter.convertXMLtoJSON(local.responseXML);
            local.responseStruct["trackResponse"] = local.responseJSON;
            local.responseStruct["metaData"] = local.response;
            return local.responseStruct;
        }
        else
        {
            return {"error" : "Unknown response format specified"}
        }
    }


    /**
     * Given a UPS tracking number, returns the information of the shipment in the desired format.
     * 
     * @shipment The tracking number of the shipment
     * 
     * @return The shipment information
     */
    any function fetchUPS(required string shipment, string format = "standard")
    {
        local.httpService = new http();

        /* Set attributes using implicit setters */
        local.httpService.setMethod("get");
        local.httpService.setCharset("utf-8");
        local.httpService.setUrl("https://onlinetools.ups.com/track/v1/details/#arguments.shipment#"); //Currently using test values

        /* Add header elements to authorize and specify the API request */
        local.httpService.addParam(type="header", name="transId", value="12345");
        local.httpService.addParam(type="header", name="transcationSrc", value="TestTrack");
        local.httpService.addParam(type="header", name="Username", value=variables.upsUsername);
        local.httpService.addParam(type="header", name="Password", value=variables.upsPassword);
        local.httpService.addParam(type="header", name="AccessLicenseNumber", value=variables.upsApiKey);
        local.httpService.addParam(type="header", name="Content-Type", value="application/json");
        local.httpService.addParam(type="header", name="Accept", value="application/json");

        /* Send the request to the UPS API */
        local.response = local.httpService.send().getPrefix();

        /* Choose a format with which to return the API's response to the user */
        if(arguments.format == "standard")
        {
            //No edits made to the standard response
            return local.response;
        }
        else if(arguments.format == "structure")
        {
            //Return a struct and metadata within a struct
            local.fileContent = local.response.fileContent;
            local.responseMetaData = local.response;
            local.responseStruct = deserializeJson(local.fileContent);
            local.responseStruct["metaData"] = local.responseMetaData;
            return local.responseStruct;
        }
        else if(arguments.format == "json")
        {
            //Return a JSON formatted string and the metadata in a struct
            local.responseMetaData = local.response;
            local.responseStruct["trackResponse"] = local.response.fileContent;
            local.responseStruct["metaData"] = local.responseMetaData;
            return local.responseStruct;
        }
        else if(arguments.format == "xml")
        {
            //Return an xml document object and the metadata in a struct
            local.responseMetaData = local.response;
            local.responseStruct["trackResponse"] = formatter.convertJSONtoXML(local.response.fileContent);
            local.responseStruct["metaData"] = local.responseMetaData;
            return local.responseStruct;
        }
        else
        {
            return {"error" : "Unknown response format specified"};
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
    any function fetchDaytonFreight(required string shipment, string format = "standard")
    {
        local.httpService = new http();

        /* Set attributes using implicit setters */
        local.httpService.setMethod("get");
        local.httpService.setCharset("utf-8");
        local.httpService.setUrl("https://api.daytonfreight.com/api/Tracking/ByNumber?number=#shipment#&type=Pro");

        /* Add credentials to the API request */
        local.httpService.addParam(type="header", name="Authorization", value="#variables.daytonFreightBasicAuth#");

        /* Send the request to the Dayton Freight API */
        local.response = local.httpService.send().getPrefix();

        /* Format the Api response based on the requested format by the user */
        if(arguments.format == "standard")
        {
            return local.response;
        }
        else if(arguments.format == "structure")
        {
            local.responseStruct["metadata"] = local.response;
            local.responseStruct["trackResponse"] = deserializeJson(local.response.filecontent);
            return local.responseStruct;
        }   
        else if(arguments.format == "json")
        {
            local.responseStruct["metadata"] = local.response;
            local.responseStruct["trackResponse"] = local.response.filecontent;
            return local.responseStruct;
        }   
        else if(arguments.format == "xml")
        {
            local.responseStruct["metadata"] = local.response;
            local.responseStruct["trackResponse"] = formatter.JSONtoXML(local.response.filecontent);
            return local.responseStruct;
        }  
        else
        {
            return {"error" : "The service you requested to fetch shipping information from was not found or is unsupported"};
        }
    }


    /**
     * Given a tracking number from R+L carriers, makes a request to their API
     * to return tracking information.
     * 
     * Waiting back to hear from vickie on this one
     * 
     */
    any function fetchRLC(required string shipment, string format = "standard")
    {

    }

    /**
     * Given a Holland freight tracking number, makes a request to their API 
     * to return tracking information.
     * 
     * !!!Currently using the public webservice. Waiting until the API key request for holland is approved!!!
     * 
     * @shipment The tracking number of the shipment
     * @format The format with which to return the API response
     * @return The tracking information of the shipment
     */
    any function fetchHolland(required string shipment, string format = "standard")
    {
        local.httpService = new http();

        /* Set attributes using implicit setters */
        local.httpService.setMethod("get");
        local.httpService.setCharset("utf-8");
        local.httpService.setUrl("https://api.hollandregional.com/api/TrackShipments/doTrackDetail?searchBy=PRO&number=#arguments.shipment#");

        /* Send the request to the Holland API */
        local.response = local.httpService.send().getPrefix();

        /* Choose a format with which to return the API's response to the user */
        if(arguments.format == "standard")
        {
            //Return the response as-is
            return local.response;
        }
        else if(arguments.format == "structure")
        {
            //Convert to XML first so we can convert to JSON from XML
            local.responseXML = xmlParse(local.response.fileContent);
            //Create a struct full of information from the response
            local.responseStruct["metaData"] = local.response;
            local.responseStruct["trackResponse"] = formatter.convertXMLtoStruct(local.responseXML);
            return local.responseStruct;
        }
        else if(arguments.format == "xml")
        {
            //Convert the response to an XML object, including the metadata in a struct
            local.responseXML = xmlParse(local.response.fileContent);
            local.responseStruct["xml"] = local.responseXML;
            local.responseStruct["metaData"] = local.response;
            return local.responseStruct;
        }
        else if(arguments.format == "json")
        {
            //Convert the XML filecontent of the response to JSON
            local.responseXML = xmlParse(local.response.fileContent);
            local.responseJSON = formatter.convertXMLtoJSON(local.responseXML);
            local.responseStruct["trackResponse"] = local.responseJSON;
            local.responseStruct["metaData"] = local.response;
            return local.responseStruct;
        }
        else
        {
            return {"error" : "Unknown response format specified"};
        }
    }


    /**
     * Given a YRC tracking number, makes a request to their API to return tracking
     * information.
     * 
     * !!!Currently using the public webservice. Waiting until the API key request for YRC is approved.
     * 
     * @shipment The tracking number of the shipment
     * @format The format with which to return the API response
     * @return The tracking information of the shipment
     */
    any function fetchYRC(required string shipment, string format = "standard")
    {
        local.httpService = new http();

        /* Set attributes using implicit setters */
        local.httpService.setMethod("post");
        local.httpService.setCharset("utf-8");
        local.httpService.setUrl("http://my.yrc.com/myyrc-api/national/servlet?CONTROLLER=com.rdwy.ec.rextracking.http.controller.ProcessPublicTrackingController");

        /* Set headers to further specify the API request */
        local.httpService.addParam(type="formfield", name="PRONumber", value=arguments.shipment);
        local.httpService.addParam(type="formfield", name="xml", value="Y");

        /* Send the request to the YRC API */
        local.response = local.httpService.send().getPrefix();

        /* Choose a format with which to return the API's response to the user */
        if(arguments.format == "standard")
        {
            return local.response;
        }
        else
        {
            //If we aren't returning to the user with a standard format, then we ought to do some html parsing to get the correct information
            //out of the raw HTML that the API sends us back

            //Use the jSoup java library for our HTML parsing
            local.jSoupClass = createObject( "java", "org.jsoup.Jsoup" );

            //Create a document object out of the API's response
            local.doc = createObject("java", "org.jsoup.nodes.Document").init("");
            local.doc.html(local.response.fileContent);
            local.doc = local.doc.selectFirst("##pageContent");
            //Check to see if we've successfully obtained the page content

            local.doc = local.doc.selectFirst("##printArea");
            //Check to see if we've successfully obtained the table with the tracking information


            //Scrape all of the records from the tracking information table
            local.doc = local.doc.selectFirst("table")
                                .selectFirst("tbody")
                                .selectFirst("table")
                                .selectFirst("tbody");
            local.shipmentsHTML = local.doc.select("tr");

            //Loop through all of the shipment records in the tracking response, adding their data as structs to an array
            local.shipmentArray = [];
            for(local.shipment in local.shipmentsHTML)
            {
                local.struct = {};
                local.shipmentData                      = local.shipment.select("td");
                local.struct["TrackingNumber"]               = local.shipmentData[1].text();
                local.struct["Status"]                  = local.shipmentData[2].text();
                local.struct["PickupDate"]              = local.shipmentData[3].text();
                local.struct["EstimatedDeilveryDate"]   = local.shipmentData[4].text();
                local.struct["ShipFrom"]                = local.shipmentData[5].text();
                local.struct["ShipTo"]                  = local.shipmentData[6].text();
                local.shipmentArray.append(local.struct);
            }

            /* Now that we have captured the data, we can return it to the user in the format that they request */
            if(arguments.format == "structure")
            {
                //We return a structure containing the api response data and an array of shipment items and their data in substructures
                local.responseStruct["metaData"] = local.response;
                local.responseStruct["trackResponse"] = local.shipmentArray;
                return local.responseStruct;
            }
            else if(arguments.format == "json")
            {
                //We return a structure containing the api response data and a JSON formatted string of shipment items and their data
                local.responseStruct["metaData"] = local.response;
                local.responseStruct["trackResponse"] = serializeJSON(local.shipmentArray);
                return local.responseStruct;
            }
            else if(arguments.format == "xml")
            {
                //Return a structure containing the api response data and an XML coldfusion object of the shipment items and their data
                local.responseStruct["metaData"] = local.response;
                local.responseStruct["trackResponse"] = formatter.convertJSONtoXML(serializeJSON(local.shipmentArray));
                return local.responseStruct;
            }
            else
            {
                return {"error" : "Unknown response format specified"};
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
    any function fetchAftership(required string shipment, string format = "standard")
    {
        local.httpService = new http();

        /* Set attributes using implicit setters */
        local.httpService.setMethod("get");
        local.httpService.setUrl("https://api.aftership.com/v4/trackings/tazmanian-freight/#shipment#");

        /* Set headers to further specify the API request */
        local.httpService.addParam(type="header", name="aftership-api-key", value=variables.aftershipAPIKey);

        /* Send the request to the YRC API */
        local.response = local.httpService.send().getPrefix();


        /* Format the Api response based on the requested format by the user */
        if(arguments.format == "standard")
        {
            return local.response;
        }
        else if(arguments.format == "structure")
        {
            local.responseStruct["metadata"] = local.response;
            local.responseStruct["trackResponse"] = deserializeJson(local.response.filecontent);
            return local.responseStruct;
        }   
        else if(arguments.format == "json")
        {
            local.responseStruct["metadata"] = local.response;
            local.responseStruct["trackResponse"] = local.response.filecontent;
            return local.responseStruct;
        }   
        else if(arguments.format == "xml")
        {
            local.responseStruct["metadata"] = local.response;
            local.responseStruct["trackResponse"] = formatter.JSONtoXML(local.response.filecontent);
            return local.responseStruct;
        }  
        else
        {
            return {"error" : "The service you requested to fetch shipping information from was not found or is unsupported"};
        }
    }


    /**
     * The dog fetches the shipping information for a shipment and a service
     * specified within its arguments. It returns the shipping information in the 
     * specified format as well!
     * 
     * @shipment The tracking number/id of the shipment to find information about
     * @service The shipping service to reference regarding the tracking number
     * @format The format with which to return the API response. Currently no options here yet, but more will be added!
     * 
     * @return The API request result
     */
    any function fetch(required string service, required string shipment, string format = "standard")
    {
        if(arguments.service == "fedex")
        {
            return fetchFedEx(arguments.shipment, arguments.format);
        }
        else if(arguments.service == "ups")
        {
            return fetchUPS(arguments.shipment, arguments.format);
        }
        else if(arguments.service == "dayton freight" || arguments.service == "dayton")
        {
            return fetchDaytonFreight(arguments.shipment, arguments.format);
        }
        else if(arguments.service == "rlc" || arguments.service == "r+l carriers" || arguments.service == "rl carriers" || arguments.service == "rl")
        {
            return fetchRLC(arguments.shipment, arguments.format);
        }
        else if(arguments.service == "holland" || arguments.service =="holland freight")
        {
            return fetchHolland(arguments.shipment, arguments.format)
        }
        else if(arguments.service == "yrc" || arguments.service == "yrc freight")
        {
            return fetchYRC(arguments.shipment, arguments.format);
        }
        else //The user enters a service that is not found or supported by dog
        {
            return {"error" : "The service you requested to fetch shipping information from was not found or is unsupported"};
        }
    }
}