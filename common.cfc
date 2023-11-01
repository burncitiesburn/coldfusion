component {
    
	public commonUDF function init() {
		return this;
	}

	public string function GCD(string x, string y){
		do {
			remainder = x % y;
			x=y;
			y = remainder;
		} while(y != 0);
		
		return x;
	} 

	public string function aspectRatio(string width, string height){
		var a = width/GCD(width,height);
		var b = height/GCD(width,height);

		return "#a#:#b#";
	}
	
	public string function serializeQueryToJson(query q, string columns){

		var dataset = [];

		for(i=1;i LTE q.recordCount;i=i+1) {
			var record = {};
			

			for(k=1;k LTE listlen(columns);k++) {
				record[LCase(ListGetAt(columns, k))] = q[ListGetAt(columns, k)][i];	
			}
			ArrayAppend(dataset,record);
		}			
		
		return serializeJson(dataset);
	}
	
	public string function ago(string date){
		var odbc_date = createODBCDateTime(date);
		var dateString = "";
		if(dateDiff("h",now(),odbc_date) eq 0){
			upDate = DateDiff("n", now(), odbc_date) * -1;
			dateString = dateString & upDate & " minute";
			if(DateDiff("n", now(), odbc_date) lt -1){
				dateString = dateString & "s";
			}
		} else if (DateDiff("d", now(), odbc_date) eq 0 ){
			upDate = DateDiff("h", now(), odbc_date) * -1;
			dateString = dateString & upDate & " hour";
			if(DateDiff("h", now(), odbc_date) lt -1){
				dateString = dateString & "s";
			}
		} else {
			upDate = DateDiff("d", now(), odbc_date) * -1;
			dateString = dateString & upDate & " day";
			if(DateDiff("d", now(), odbc_date) lt -1){
				dateString = dateString & "s";
			}
		}
		dateString = dateString & " ago";
		
		return dateString;
	}

	public any function xmlValidateExternal(any list_dir, any export_dir){ // pass directoryListQueryObject of schema and xml to be validated
		validationResult = "";
		outfile = "";
		xmlFile = "";
		validation_status = "";
		arrValidation = arrayNew(1);

		for (files in list_dir){
			try{
				filename = files.name;
				outfile = "";
				errfile = "";
				filePath = export_dir & filename;
				xmlFile = fileOpen(filePath, "read");
				for(var i =0; i < 10; i++){
					line = fileReadLine(xmlFile);
					schema1 = ReFindNoCase("[xsi|sdf]:(noNamespace)?SchemaLocation=""([^""]{0,999}\.xsd[^""]{0,999})""", line, 1, true);
					if(schema1.len[1] gt 1){
						schemaFile = mid(line,schema1.pos[3], schema1.len[3]);
						replace(schemaFile,"[xsi|sdf]:(noNamespace)?SchemaLocation=", "" , "ALL");
						break;
					}
				}
				cfexecute(
					name="#request.config["system.ExecutablesDirectory"]#\libxml2-2.7.8.win32\bin\xmllint.exe" ,
					timeout=10,
					arguments="--schema #schemaFile# --noout #export_dir##filename#",
					Variable="outfile",
					errorVariable="errfile"
					);
				if(outfile contains "#export_dir##filename# validates" or errfile contains "#export_dir##filename# validates"){
					validation_status = "success";
					validationResult = filename;
				}else{
					validation_status = "failure";
					validationResult = filename;
				}
			}	catch (any e){
					validation_status = "failure";
					validationResult = e.message & "<br/>" & e.detail;
			}
			stValidation = structNew();
			stValidation["validation_status"] = validation_status;
			stValidation["validationResult"] = validationResult;
			stValidation["filename"] = filename;
			arrayAppend(arrValidation, stValidation);
		}
		
		return arrValidation;
	}

	public any function xmlValidate(any list_dir, any export_dir){
		arrValidation = arrayNew(1);
		for (files in list_dir){
			try{
				filename = files.name;
				outfile = "";
				errfile = "";
				filePath = export_dir & filename;
				result = structNew();
				xmlFile = FileRead(filePath);
					schema1 = ReFindNoCase("[xsi|sdf]:(noNamespace)?SchemaLocation=""([^""]{0,999}\.xsd[^""]{0,999})""", xmlFile, 1, true);
					if(schema1.pos[1]){
						schemaFile = mid(xmlfile,schema1.pos[3], schema1.len[3]);
						schemaArr = listToArray(schemaFile,"#chr(9)##chr(10)##chr(13)##chr(32)#");
						for(i = 1; i LTE arrayLen(schemaArr);i++){
							if(schemaArr[i] contains ".xsd"){
								if (fileExists(export_dir & trim(schemaArr[i]))){
									result = xmlValidate(filePath, export_dir & trim(schemaArr[i]));
								}else if (fileExists(export_dir & trim(ListLast(schemaArr[i],"/")))){
									result = xmlValidate(filePath,export_dir & trim(ListLast(schemaArr[i],"/")));
								}else if (fileExists(schemaArr[i]) OR left(schemaArr[i],4) eq "http"){
									result = xmlValidate(filePath,schemaArr[i]);
								}
							}
						}
					}else{
						result = xmlValidate(filePath);
					}
				
				if(result.status eq "YES"){
					validation_status = "success";
					validationResult = filename;
				}else{
					validation_status = "failure";
					validationResult = result;
				}
				
			}catch(any e){
				validation_status = "failure";
				validationResult = e.message & "<br/>" & e.detail;
			}
			stValidation["validation_status"] = validation_status;
			stValidation["validationResult"] = validationResult;
			stValidation["filename"] = filename;
			arrayAppend(arrValidation, stValidation);
		}


 		return arrValidation;
	}

	public any function xmlValidateViaXmlParse(any list_dir, any export_dir){
		arrValidation = arrayNew(1);
		cfloop (query="list_dir"){
			stValidation = structNew();
			filename = list_dir.name;
			outfile = "";
			errfile = "";
			filePath = export_dir & filename;
			try{
				result = structNew();
				xmlFile = FileRead(filePath);
				schema1 = ReFindNoCase("[xsi|sdf]:(noNamespace)?SchemaLocation=""([^""]{0,999}\.xsd[^""]{0,999})""", xmlFile, 1, true);
				if(schema1.pos[1]){
					schemaFile = mid(xmlfile,schema1.pos[3], schema1.len[3]);
					schemaArr = listToArray(schemaFile,"#chr(9)##chr(10)##chr(13)##chr(32)#");
					for(i = 1; i LTE arrayLen(schemaArr);i++){
						if(schemaArr[i] contains ".xsd"){
							if (fileExists(export_dir & trim(schemaArr[i]))){
								result = xmlParse(filePath,"no", export_dir & trim(schemaArr[i]));
							}else if (fileExists(export_dir & trim(ListLast(schemaArr[i],"/")))){
								result =  xmlParse(filePath, "no", export_dir & trim(ListLast(schemaArr[i],"/")));
							}else if (fileExists(schemaArr[i]) OR left(schemaArr[i],4) eq "http"){
								result =  xmlParse(filePath, "no",schemaArr[i]);
							}else{
									throw(message="this");
							}
						}
					}
				}else{
					result = xmlParse(filePath);
				}
				validation_status = "success";
				validationResult = validation_status;			
				
			}catch(any e){
				validation_status = "failure";
				validationResult = e.message & " : " & e.detail;
			}

			stValidation["validation_status"] = validation_status;
			stValidation["validationResult"] = validationResult;
			stValidation["filename"] = filename;
			arrayAppend(arrValidation, stValidation);
		}


 		return arrValidation;
	}

	function compareLists(any list1, any list2){
		fList = createObject("java", "java.util.ArrayList").init(listToArray(list1));
		sList = createObject("java", "java.util.ArrayList").init(listToArray(list2));

		dList = createObject("java", "java.util.HashSet").init(fList);
		dList.removeAll(sList);

		return arraytoList(dList.toArray());
	}

	function CreateGUID() {
		return insert("-", CreateUUID(), 23);
	}
	
	//Polyfill for QueryGetRow as it works differently between CF11 and CF2016
	public function GetQueryRow(query, rowNumber) {
		var i = 0;
		var rowData = {};
		
		var cols = getColumnList(query);

		for (i = 1; i lte ArrayLen(cols); i = i + 1) {
			rowData[cols[i]] = query[cols[i]][rowNumber];
		}
		return rowData;
	}

	function QueryToCsv(query){
		var csv = "";
		var cols = "";
		var headers = "";
		var i = 1;
		var j = 1;

		if(arrayLen(arguments) gte 2) headers = arguments[2];
		if(arrayLen(arguments) gte 3) cols = arguments[3];
		if(cols is "") cols = ArrayToList(getColumnList(query));
		if(headers IS "") headers = getColumnList(query);
		
		

		for(i=1; i lte arrayLen(headers); i=i+1){
			csv = csv & """" & headers[i] & """,";
		}

		csv = csv & chr(13) & chr(10);

		for(i=1; i lte query.recordCount; i=i+1){
			for(j=1; j lte arrayLen(cols); j=j+1){
				csv = csv & """" & replace(query[cols[j]][i],"""","""""","All") & """,";
			}
			csv = csv & chr(13) & chr(10);
		}
		return csv;
	}

	function getHexForColourName(colourName){
		var stColours = {"aliceblue":"##f0f8ff","antiquewhite":"##faebd7","aqua":"##00ffff","aquamarine":"##7fffd4","azure":"##f0ffff","beige":"##f5f5dc","bisque":"##ffe4c4","black":"##000000","blanchedalmond":"##ffebcd","blue":"##0000ff","blueviolet":"##8a2be2","brown":"##a52a2a","burlywood":"##deb887","cadetblue":"##5f9ea0","chartreuse":"##7fff00","chocolate":"##d2691e","coral":"##ff7f50","cornflowerblue":"##6495ed","cornsilk":"##fff8dc","crimson":"##dc143c","cyan":"##00ffff","darkblue":"##00008b","darkcyan":"##008b8b","darkgoldenrod":"##b8860b","darkgray":"##a9a9a9","darkgreen":"##006400","darkkhaki":"##bdb76b","darkmagenta":"##8b008b","darkolivegreen":"##556b2f","darkorange":"##ff8c00","darkorchid":"##9932cc","darkred":"##8b0000","darksalmon":"##e9967a","darkseagreen":"##8fbc8f","darkslateblue":"##483d8b","darkslategray":"##2f4f4f","darkturquoise":"##00ced1","darkviolet":"##9400d3","deeppink":"##ff1493","deepskyblue":"##00bfff","dimgray":"##696969","dodgerblue":"##1e90ff","firebrick":"##b22222","floralwhite":"##fffaf0","forestgreen":"##228b22","fuchsia":"##ff00ff","gainsboro":"##dcdcdc","ghostwhite":"##f8f8ff","gold":"##ffd700","goldenrod":"##daa520","gray":"##808080","green":"##008000","greenyellow":"##adff2f","honeydew":"##f0fff0","hotpink":"##ff69b4","indianred":"##cd5c5c","indigo":"##4b0082","ivory":"##fffff0","khaki":"##f0e68c","lavender":"##e6e6fa","lavenderblush":"##fff0f5","lawngreen":"##7cfc00","lemonchiffon":"##fffacd","lightblue":"##add8e6","lightcoral":"##f08080","lightcyan":"##e0ffff","lightgoldenrodyellow":"##fafad2","lightgrey":"##d3d3d3","lightgreen":"##90ee90","lightpink":"##ffb6c1","lightsalmon":"##ffa07a","lightseagreen":"##20b2aa","lightskyblue":"##87cefa","lightslategray":"##778899","lightsteelblue":"##b0c4de","lightyellow":"##ffffe0","lime":"##00ff00","limegreen":"##32cd32","linen":"##faf0e6","magenta":"##ff00ff","maroon":"##800000","mediumaquamarine":"##66cdaa","mediumblue":"##0000cd","mediumorchid":"##ba55d3","mediumpurple":"##9370d8","mediumseagreen":"##3cb371","mediumslateblue":"##7b68ee","mediumspringgreen":"##00fa9a","mediumturquoise":"##48d1cc","mediumvioletred":"##c71585","midnightblue":"##191970","mintcream":"##f5fffa","mistyrose":"##ffe4e1","moccasin":"##ffe4b5","navajowhite":"##ffdead","navy":"##000080","oldlace":"##fdf5e6","olive":"##808000","olivedrab":"##6b8e23","orange":"##ffa500","orangered":"##ff4500","orchid":"##da70d6","palegoldenrod":"##eee8aa","palegreen":"##98fb98","paleturquoise":"##afeeee","palevioletred":"##d87093","papayawhip":"##ffefd5","peachpuff":"##ffdab9","peru":"##cd853f","pink":"##ffc0cb","plum":"##dda0dd","powderblue":"##b0e0e6","purple":"##800080","rebeccapurple":"##663399","red":"##ff0000","rosybrown":"##bc8f8f","royalblue":"##4169e1","saddlebrown":"##8b4513","salmon":"##fa8072","sandybrown":"##f4a460","seagreen":"##2e8b57","seashell":"##fff5ee","sienna":"##a0522d","silver":"##c0c0c0","skyblue":"##87ceeb","slateblue":"##6a5acd","slategray":"##708090","snow":"##fffafa","springgreen":"##00ff7f","steelblue":"##4682b4","tan":"##d2b48c","teal":"##008080","thistle":"##d8bfd8","tomato":"##ff6347","turquoise":"##40e0d0","violet":"##ee82ee","wheat":"##f5deb3","white":"##ffffff","whitesmoke":"##f5f5f5","yellow":"##ffff00","yellowgreen":"##9acd32"};
		return stColours[colourName];
	}

	function determineBrowserFromUserAgent(user_agent){
		var browser = "";
		var operating_system = "";
		if (findNoCase("Firefox/",arguments.user_agent) and findNoCase("Seamonkey/",arguments.user_agent) eq 0){
			browser = "Firefox";
		}
		if (findNoCase("Seamonkey/",arguments.user_agent)){
			browser = "Seamonkey";
		}
		if (findNocase("Chrome/",arguments.user_agent) and findNocase("Chromium/",arguments.user_agent) eq 0 and findNoCase("Edg/",arguments.user_agent) eq 0){
			browser = "Chrome";
		}
		if (findNoCase("Edg/",arguments.user_agent)){
			browser = "Edge";
		}
		if (findNocase("Chromium/",arguments.user_agent)){
			browser = "Chromium";
		}
		if (findNocase("Safari/",arguments.user_agent) and findNocase("Chrome/",arguments.user_agent) eq 0 and findNocase("Chromium/",user_agent) eq 0 and findNoCase("Edg/",arguments.user_agent) eq 0){
			browser = "Safari";
		}
		if (findNocase("OPR/",arguments.user_agent)){
			browser = "Opera";
		}
		if (findNoCase("Windows NT",arguments.user_agent)){
			operating_system = "Windows";
		}else if (findNoCase("Macintosh",arguments.user_agent)){
			operating_system = "macOS";
		}else{
			operating_system = "other";
		}
		if (browser == "" or operating_system == ""){
			browser = listLast(trim(arguments.user_agent)," ");
			operating_system = "";
		}
		return browser & " (" & operating_system & ")";
	}
	function getCurrentTimeRoundedToNearestMinute(numeric minute){
		return createDateTime(year(now()),month(now()),day(now()),hour(now()),int(minute(now()) / arguments.minute)*arguments.minute,0);
	}
	
	function getColumnList(query){
		var callback =  function(item){ return item.name; };
		var cols = ArrayMap(GetMetadata(query), callback);
		return cols;
	}

	function createExtendedSearchString(searchString){
		var searchString_extended = arguments.searchString;
		if(listLen(searchString_extended," -") >= 2){
			if(listLen(searchString_extended," -") >= 3){
				searchString_extended = listAppend(searchString_extended,
											listGetAt(searchString_extended,listLen(searchString_extended," -")-1," -")
											& listGetAt(searchString_extended,listLen(searchString_extended," -")," -")
										," ");
			}
		
			searchString_extended = listAppend(searchString_extended,listFirst(searchString_extended," -")
							& listGetAt(searchString_extended,2," -")," ");
		}
		return searchString_extended;
	}
}	
