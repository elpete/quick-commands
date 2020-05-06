/**
 * Create an Quick entity.  Table name, attributes, and relationships can also be defined.
 */
component {

	property name="fileSystemUtil" inject="FileSystem";
	property name="str" inject="@str";

	variables.pluralsMap = {
		"hasOne": 1,
		"hasMany": 2,
		"belongsTo": 1,
		"belongsToMany": 2,
		"hasManyThrough": 2,
		"hasOneThrough": 1,
		"belongsToThrough": 1,
		"polymorphicBelongsTo": 1,
		"polymorphicHasMany": 2
	};

	function init() {
		variables.lineSeparator = createObject( "java", "java.lang.System" ).lineSeparator();
		variables.tab = chr( 9 );
	}

	/**
	 * @name           The name of the entity to create.
	 * @table          The name of the table to create.  If none is provided, it omits the table to use Quick's convention.
	 * @key            The name of the primary key attribute for the entity.  If none is provided, it omits the `_key` to use Quick's convention.
	 * @attributes     A comma-separated list of attributes to create.  Columns can be specified after a colon. (`id:postId`).
	 * @relationships  A comma-separated list of relationships to create.  Relationships take the form of `hasMany:Post`.
	 *                 An optional method name can be provided as a third colon-separated parameter: (`hasMany:Post:publishedPosts`).
	 *                 If the method name is omitted, it uses the pluralized form of the entity name.  The related entity
	 *                 name can be a WireBox mapping.  If one is detected, this command will ignore anything including
	 *                 and after an `@` namespace.
	 * @directory      The directory to create the entity in.  Defaults to `models/entities/`.
	 * @fileName       The name of the file to create.  Defaults to the name of the entity.
	 * @overwrite      Flag to automatically overwrite the file, if needed.  Otherwise it will prompt to overwrite a file.
	 * @open           Flag to automatically open the file that is created.
	 */
	function run(
		required string name,
		string table = "",
		string key = "",
		string attributes = "",
		string relationships = "",
		string directory = "models/entities/",
		string fileName = arguments.name,
		boolean overwrite = false,
		boolean open = false
	) {
		arguments.attributes = explodeAttributes( arguments.attributes );
		arguments.relationships = explodeRelationships( arguments.relationships );

		var fileContents = generateEntityFile(
			arguments.table,
			arguments.key,
			arguments.attributes,
			arguments.relationships
		);

		var directoryPath = fileSystemUtil.resolvePath( arguments.directory );
		if ( !directoryExists( directoryPath ) ) {
			directoryCreate( directoryPath );
		}
		var filePath = directoryPath & arguments.fileName & ".cfc"
		if ( !arguments.overwrite && fileExists( filePath ) ) {
			if ( !confirm( "#arguments.fileName#.cfc already exists.  Do you want to overwrite it? [y/n]" ) ) {
				return;
			}
		}
		fileWrite( filePath, fileContents );

		if ( arguments.open ) {
			openPath( filePath );
		}

		print.line().green( arguments.name ).white( " entity created at " ).yellowLine( filePath );
	}

	private array function explodeAttributes( string attributes = "" ) {
		return arguments.attributes.listToArray()
			.map( ( attributeString ) => {
				var attr = { "name": listFirst( arguments.attributeString, ":" ) };
				if ( listIndexExists( arguments.attributeString, 2, ":" ) ) {
					attr[ "column" ] = listGetAt( arguments.attributeString, 2, ":" );
				}
				return attr;
			} );
	}

	private array function explodeRelationships( string relationships = "" ) {
		return arguments.relationships.listToArray()
			.map( ( relationshipString ) => {
				var relationshipParameters = arguments.relationshipString.listToArray( ":" );

				if ( relationshipParameters.len() < 2 ) {
					error(
						"A relationship needs to follow the signature `type:entityName:methodName?`",
						"Parsing: #arguments.relationshipString#.  Full list: #relationships#"
					);
				}

				var type = relationshipParameters[ 1 ];
				var entityName = relationshipParameters[ 2 ];
				var methodName = relationshipParameters[ 3 ] ?:
					str.camel( str.plural( listFirst( relationshipParameters[ 2 ], "@" ), variables.pluralsMap[ type ] ) )

				return {
					"type": type,
					"entityName": entityName,
					"methodName": methodName
				};
			} );
	}

	private string function generateEntityFile(
		string table = "",
		string key = "",
		array attributes = [],
		array relationships = []
	) {
		var buffer = createObject( "java", "java.lang.StringBuffer" ).init();

		writeComponentOpen( buffer, arguments.table );
		writeAttributes( buffer, arguments.attributes );
		writeKey( buffer, arguments.key );
		writeRelationships( buffer, arguments.relationships );
		writeComponentClose( buffer );

		return buffer.toString();
	}

	private void function writeComponentOpen( required any buffer, string table = "" ) {
		arguments.buffer.append( 'component ' );
		if ( arguments.table != "" ) {
			arguments.buffer.append( 'table="#arguments.table#" ' );
		}
		arguments.buffer.append( 'extends="quick.models.BaseEntity" accessors="true" {#variables.lineSeparator##variables.lineSeparator#' );
	}

	private void function writeAttributes( required any buffer, array attributes = [] ) {
		arguments.attributes.each( function( attr ) {
			buffer.append( '#variables.tab#property name="#arguments.attr.name#"' );
			if ( arguments.attr.keyExists( "column" ) ) {
				buffer.append( ' column="#arguments.attr.column#"' );
			}
			buffer.append( ';#variables.lineSeparator#' );
		} );
	}

	private void function writeKey( required any buffer, string key = "" ) {
		if ( arguments.key != "" ) {
			arguments.buffer.append( '#variables.lineSeparator##variables.tab#variables._key = "#arguments.key#";#variables.lineSeparator#' );
		}
	}

	private void function writeRelationships( required any buffer, array relationships = [] ) {
		arguments.relationships.each( function( relationship ) {
			buffer.append( '#variables.lineSeparator##variables.tab#function #arguments.relationship.methodName#() {#variables.lineSeparator#' );
			buffer.append( '#variables.tab##variables.tab#return #relationship.type#( "#relationship.entityName#" );#variables.lineSeparator#' );
			buffer.append( '#variables.tab#}#variables.lineSeparator#' );
		} );
	}

	private void function writeComponentClose( required any buffer ) {
		arguments.buffer.append( variables.lineSeparator & "}" & variables.lineSeparator );
	}

}
