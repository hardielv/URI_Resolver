<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
                    "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <title></title>
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3/jquery.min.js"></script>

  <!--   <link rel="stylesheet" href="../style.css" type="text/css" />  -->

    <script type="text/javascript">

        var serviceUrl = "";

        function clearURIMapDetails() {
            $('input').each(function(){
                $(this).val("");
            });        	
        }
        
        function clearForm() {
        	clearURIMapDetails();
            $('#identifiers').empty();
            document.getElementById("listVersionOf").options.length = 0;
        	document.getElementById("listVersionID").options.length = 0;
        	document.getElementById("listVersionID").style.visibility='visible';
        }
        
        function clearAll() {
        	clearURIMapDetails();
            $('#identifiers').empty();
            document.getElementById("listResourceType").options[0].selected = true;
            document.getElementById("listVersionOf").options.length = 0;
        	document.getElementById("listVersionID").options.length = 0;
        	document.getElementById("listVersionID").style.visibility='visible';
        }
        
        // Called when "Resource Type" list is changed
        function loadVersionOf() {
        	if(document.getElementById("listResourceType").selectedIndex == 0) {
        		clearForm();
        	}
        	else{
            	var type = $('#listResourceType').val();
            	var restURL = serviceUrl + "all/" + type;
	            $.ajax({
	                type: "GET",
	                url: restURL,
	                dataType: 'json',
	                contentType: "application/json",
	                error: function(XMLHttpRequest, textStatus, errorThrown){
	                	if( XMLHttpRequest.status == '404'){
	                        alert("404 Error collecting data.");
	                    }
	                	else{
	                		alert('There was an ' + errorThrown +
                                    ' error due to a ' + textStatus + 
                                    ' condition: ' + XMLHttpRequest.status);
	                	}
	                },
	                success: function(data) {
	                	clearForm();
	                	var select = document.getElementById("listVersionOf");
	                	
	                	select.options[0] = new Option("Select Identifier", "SELECT");
	                    for(i in data.resourceNames){
	                    	select.options[select.options.length] = new Option(data.resourceNames[i], data.resourceNames[i]);
	                    }
	                }
	            });
        	}
        }
        
        // Called when "Version Of" list is changed
        function loadVersionIds() {
        	var type = $('#listResourceType').val();
        	clearURIMapDetails();
        	if(type == "CODE_SYSTEM") {
	            $.ajax({
	                type: "GET",
	                url: serviceUrl + "all/" + $('#listResourceType').val() + "/" + $('#listVersionOf').val(),
	                dataType: 'json',
	                contentType: "application/json",
	                error: function(XMLHttpRequest, textStatus, errorThrown){
	                    if( XMLHttpRequest.status == '404'){
	                        alert("Error collecting data.");
	                    }
	                	else{
	                		alert('There was an ' + errorThrown +
                                    ' error due to a ' + textStatus + 
                                    ' condition: ' + XMLHttpRequest.status);
	                	}

	                },
	                success: function(data) {
	                	var select = document.getElementById("listVersionID");
	                	select.options.length=0;
	                	document.getElementById("listVersionID").style.visibility='visible';
	                	select.options[0] = new Option("Select Version", "SELECT");
	                    for(i in data.versionIds){
	                    	select.options[select.options.length] = new Option(data.versionIds[i], data.versionIds[i]);
	                    }
	                }
	            });
        	}
        	else{
            	var select = document.getElementById("listVersionID");
            	select.options.length=0;
            	document.getElementById("listVersionID").style.visibility='hidden';
        		loadVersionIdentifiers();
        	}
        }
        
        function loadVersionIdentifiers(){
            $.ajax({
                type: "GET",
                url: serviceUrl + "versions/" + $('#listResourceType').val() + "/" + 
                    $('#listVersionOf').val(),
                dataType: 'json',
                contentType: "application/json",
                error: function(XMLHttpRequest, textStatus, errorThrown){
                    if( XMLHttpRequest.status == '404'){
                        alert("No URI Map with identifier " + $('#listVersionID').val() + " was found.");
                    }
                	else{
                		alert('There was an ' + errorThrown +
                                ' error due to a ' + textStatus + 
                                ' condition: ' + XMLHttpRequest.status);
                	}
                },
                success: function(data) {
                    setIds(data);
                }
            });
        }

        // Called when "Version ID" list is changed
        function loadIdentifiers(){
        	var type = $('#listResourceType').val();
        	var id = escape($('#listVersionOf').val());
        	var vID = escape($('#listVersionID').val());
        	var restURL = serviceUrl + "version/" + type + "/" + id + "/" + vID;
        	
            $.ajax({
                type: "GET",
                url: restURL,
                dataType: 'json',
                contentType: "application/json",
                error: function(XMLHttpRequest, textStatus, errorThrown){
                    if( XMLHttpRequest.status == '404'){
                        alert("No URI Map with identifier " + vID + " was found.");
                    }
                	else{
                		alert('There was an ' + errorThrown +
                                ' error due to a ' + textStatus + 
                                ' condition: ' + XMLHttpRequest.status);
                	}
                },
                success: function(data) {
                    setIds(data);
                }
            });
        }

        function setIds(data) {
            $.ajax({
                type: "GET",
                url: serviceUrl + "versions/" + data.resourceType + "/" + data.resourceName,
                dataType: 'json',
                contentType: "application/json",
                success: function(data) {
                    $('#inputUriMapResourceType').val(data.resourceType);
                    $('#inputUriMapVersionName').val(data.resourceName);
                    $('#inputUriMapVersionUri').val(data.resourceURI);
                    $('#inputUriMapVersionOf').val(data.versionOf);

                    
                    $('#identifiers').empty();
                    for(i in data.identifiers){
                        addIdentifier(data.identifiers[i]);
                    }
                }
            });
        }

        function addIdentifier(textValue) {

            // create the new element via clone(), and manipulate it's ID using newNum value
            var newElem = $('#divToClone').find('.clonedInput').clone();
            newElem.find(".identifierInput").val(textValue);


            // insert the new element after the last "duplicatable" input field
            $('#identifiers').append(newElem);

            newElem.find('.btnDel').click(function() {
                newElem.remove();
            });
        }
        
        $(document).ready(function() {
	
            $('#btnAddIdentifier').click(function() {
                addIdentifier();

                return false;
            });
 
            $('#btnClearAll').click(function() {
            	clearAll();
                return false;
            });

            $('#btnSave').click(function() {
                var json = {
                    resourceType : $('#inputUriMapResourceType').val(),
                    resourceName : $('#inputUriMapVersionName').val(),
                    resourceURI : $('#inputUriMapVersionUri').val(),
                    versionOf : $('#inputUriMapVersionOf').val(),
                    identifiers : []
                };

                $('.identifierInput').each(function(){
                    var val = $(this).val();
                    if(val && val != ''){
                        json.identifiers.push($(this).val());
                    }
                });

                $.ajax({
                    type: "PUT",
                    url: serviceUrl + "versions/" + json.resourceType + "/" + json.resourceName,
                   // dataType: 'json',
                    contentType: "application/json",
                    data: JSON.stringify(json),
                    success: function(data) {
                        alert("Saved");
                    },
                    error: function(jqXHR, textStatus, errorThrown) {
                        alert("ERROR: " + jqXHR.responseText);
                    }
                });

                return false;
            }); 
            
        });
    </script>
</head>
 
<body>
 
<form id="myForm" class="registration">
    <fieldset style="float:none !important">
        <legend>Load a Version Map</legend>
        <label>Resource Type: </label>
                        <select name="listResourceType" id="listResourceType" onchange="return loadVersionOf();" >
                        	<option value="SELECT_OPTION">Select Resource Type</option>
                            <option value="CODE_SYSTEM">CODE_SYSTEM</option>
                            <option value="CODE_SYSTEM_VERSION">CODE_SYSTEM_VERSION</option>
                            <option value="VALUE_SET">VALUE_SET</option>
                        </select>
        <br/>
        <label>Version Of: </label>
        				<select name="listVersionOf" id="listVersionOf"  onchange="return loadVersionIds();">
        				</select>
        <br/>
        <label>Version ID: </label>
        			 	<select name="listVersionID" id="listVersionID" onchange="return loadIdentifiers();">
        			 	</select>
        <br/>
        <br/>
    </fieldset>

    <fieldset>
        <legend>URI Map Details</legend>
    <label>Version Name: </label><input type="text" name="inputUriMapVersionName" id="inputUriMapVersionName" />
    <br/>
    <label>Version URI: </label><input type="text" name="inputUriMapVersionUri" id="inputUriMapVersionUri" />
    <br/>
    <label>Resource Type: </label>
                    <select name="inputUriMapResourceType" id="inputUriMapResourceType" >
                      <option value="CODE_SYSTEM_VERSION">CODE_SYSTEM_VERSION</option>
                      <option value="MAP_VERSION">MAP_VERSION</option>
                    </select>
    <br/>
    <label>Version Of: </label><input type="text" name="inputUriMapVersionOf" id="inputUriMapVersionOf" />

		</fieldset>

    <br/>
    <fieldset style="float:none !important">
        <div id="identifiers" ></div>
        <button id="btnAddIdentifier" class="button" value="Add Identifier">Add Identifier</button>
    </fieldset>
     
            
    <fieldset> 
        <button id="btnSave" class="button" value="save">Save</button>
        <button id="btnClearAll" class="button" value="clear">Clear All</button>
    </fieldset>
   
</form>
 
    <div id="divToClone" style='visibility:hidden'>
         <div class="clonedInput">
            <label>Identifier: </label>
            <input type="text" class="identifierInput"/>
            <button value="Remove Identifier" class="btnDel button">Remove Identifier</button>
        </div>
    </div>

</body>
</html>