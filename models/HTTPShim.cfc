/**
 * Shim for sending HTTP requests so code can still work on ACF 2025
 */
component  {
	
	variables.attributes = {};
	variables.httpParams = [];
	variables.prefix = {};


	function init( attributes = {} ){
		variables.attributes = attributes;
		return this;
	}

	function send() {
		cfhttp( attributeCollection = variables.attributes, result="local.result" ) {
			for( var param in variables.httpParams ) {
				cfhttpparam(
					attributeCollection = param
				);
			}
		}
		// Adobe has some dumb StructBean class which can't be assigned to so we have to make a proper struct out of it
		for( var key in local.result ) {
			variables.prefix[key] = local.result[key];
		}
		if( variables.prefix.statusCode contains "Connection Failure" ) {
			variables.prefix[ 'status_code' ] = 0;
			variables.prefix[ 'status_text' ] = 'Connection Failure';
		} else {
			// ACF and Lucee both have "statusCode", which contains "200 OK" or similar.
			// Lucee only has "status_coded" which is just 200 and "status_text" which is "OK".
			variables.prefix[ 'status_code' ] = variables.prefix.statusCode.listFirst( ' ' );
			variables.prefix[ 'status_text' ] = variables.prefix.statusCode.listRest( ' ' );
		}
		return this;
	}

	function addParam( required string type, string name, required any value ) {
		var param = {
			type = arguments.type,
			value = arguments.value
		};
		if( arguments.keyExists( "name" ) ) {
			param.name = arguments.name;
		} else if( !"body,xml".listFindNoCase( arguments.type ) ) {
			throw( message = "HTTP Param type [#arguments.type#] requires a name.  Only XML and Body are exempt." );
		}
		arrayAppend( variables.httpParams, param );
		return this;
	}

	Struct function getPrefix() {
		return variables.prefix; 
	}

	/**
	 * ON missing method.  If method starts with setXXX then set attribute.XXX to first argument
	 * @param methodName The name of the method called
	 * @param arguments The arguments passed to the method
	 */
	public function onMissingMethod( required string missingMethodName, required any missingMethodArguments ){
		if ( left( missingMethodName, 3 ) == "set" && len( missingMethodName ) > 3 ) { 
			if( arrayLen( missingMethodArguments ) != 1 ) {
				throw( message = "Method #missingMethodName# expects 1 argument, but got #missingMethodArguments.len()#." );
			}
			var attrName = missingMethodName.replace( 'set', '', 'one' );
			variables.attributes[attrName] = missingMethodArguments[1];
		} else {
			throw( message = "Method #missingMethodName# does not exist." );
		}
	}

}