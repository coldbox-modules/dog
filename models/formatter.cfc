/**
 * Handy, dandy object that eats XML and gives you back
 * the XML in the form of a ColdFusion struct. 
 *
 * Why? Because deserializeXML doesn't work in Lucee!
 */
component
{


    property name="XMLConverter"    inject="XMLConverter@coldbox"; 


    //Default constructor
    formatter function init()
    {
        return this;
    }


    /**
     * A recursive step within the convert function.
     * Iterates through all of the xml children of the current xml
     * element, performing a recursive call lof each one of them. 
     * 
     * Recursive function structure
     *      base case:
     *          If this current xml element has no children, just return its text content
     *      work step:
     *          Iterate through each xml child node of the current node, making recursive calls of this function on each one of them.
     *          Make the results of these recursive calls the value to a key which will be returned.
     *      recursive step:
     *          This function calls itself whenever it needs to find the values of keys as described above in the work step.
     * 
     * 
     *     !!! 
     *     IN the future, we need this xml conversion to be able to return the text contained in nodes that are also parents. Currently,
     *     we only return the text of child nodes
     *     !!!
     *
     * @xml an xml element
     * 
     * @return a struct created from an XML file
     */
    any function recursiveCallXMLtoStruct(required xml)
    {
        if(arguments.xml.XmlChildren.len() == 0)
        {
            return arguments.xml.XmlText;
        }
        else 
        {
            local.nestedStruct = {}; //The struct to make the value of the current frame's key
            for(local.child in arguments.xml.XmlChildren)
            {
                local.xmlChildData = [];
                //The first index of the data array is the xml text
                local.xmlChildData.append(local.child.XmlText);
                //The second index of the data array are the descendant child nodes, if there are any
                if(local.child.XmlChildren.len() > 0)
                {
                    local.xmlChildData.append(recursiveCallXMLtoStruct(local.child));
                }
                local.nestedStruct[local.child.xmlName] = local.xmlChildData;
            }
            return local.nestedStruct;
        }
    }


    /**
     * Converts xml to a ColdFusion struct
     * 
     * Each xml tag will be represented with an array, where the first index is the xmlText of the node,
     * and the xmlChildren of the node are stored in the second index.
     * 
     * @xml
     * 
     * @return
     */
    struct function convertXMLtoStruct(required xml)
    {
        /* First, we check to see what has been passed into the function */
        if(isXMLDoc(arguments.xml))
        {
            //If we are passed an XML document, then we just take the first element at the root
            arguments.xml = arguments.xml.XmlRoot;
        }
        else if(!isXMLElem(arguments.xml))
        {
            //If we are passed anything other than an XML element, we throw an error
            throw(message = "Error: Supplied argument for converting XML to struct was invalid. You must pass in either an XML document object or XML element object.", type = "Invalid argument error");
        }

        local.struct = recursiveCallXMLtoStruct(arguments.xml);

        return local.struct;
    }


    /**
     * Converts xml to json
     * 
     * @xml
     * 
     * @return
     */
    string function convertXMLtoJSON(required xml)
    {
        /* The format of the struct is equivalent to that of JSON, so first we will convert the XML into a struct */
        local.struct = convertXMLtoStruct(arguments.xml);

        /* Use the built-in function serializeJSON to convert the struct we made into a JSON string object */
        local.json = serializeJson(local.struct);

        return local.json;
    }


    /**
     * Converts a JSON formatted string to a ColdFusion XML document
     * 
     * @json
     * 
     * @return
     */
    any function convertJSONtoXML(required string json)
    {
        /* First, we check to see if the argument string is in valid JSON format */
        if(!isJSON(arguments.json))
        {
            throw(message = "Error: Supplied argument for converting JSON to XML was invalid. You must pass in a string in valid JSON formatting.", type = "Invalid argument error");
        }

        /* Put our JSON data into a ColdFusion structure so that Coldbox's XMLConverter can process it */
        local.struct = deserializeJson(arguments.json);

        /* Convert the JSON data structure into XML using Coldbox's built in XMLconverter */
                    
        local.xml = XMLConverter.toXML(local.struct)
        local.xmlDoc = XMLParse(local.xml);

        return local.xmlDoc;
    }
}