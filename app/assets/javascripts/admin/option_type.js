function showMappedoption()
{
    $.ajax({
        url: "/admin/option_types_market_places/map_option_type",
        context: document.body
    }).done(function(data) {
            $("#mapping_categories").html(data);
            showPopup("mapping_categories");
            //preMappedCategories(ID);
        });
}
function mappedNewOptionType()
{
    var MARKETPLACE = $("#option_types_market_place_id").val();
    var OPTIONTYPEID = $("#option_type_id").val();
    var OPTIONNAME = $("#name").val();
    if( $("#option_type_id").val()){
        if(OPTIONNAME == null)
            alert("Please enter market place option name");
        else
        {
            $.ajax({
                url: "/admin/option_types_market_places/add_option_type?option_type_id="+OPTIONTYPEID+"&market_place_id="+MARKETPLACE+
                    "&name="+OPTIONNAME,
                context: document.body
            }).done(function(data) {
                    alert('Option Type mapped successfully');
                    closePopup('mapping_categories');
                });
        }
    }
    else{
        alert("Option Type you entered is not available");
    }
}

function showMappedoptionvalue(typeId)
{
    console.log(typeId);
    $.ajax({
        url: "/admin/option_values_market_places/map_option_value?type_id="+typeId,
        context: document.body
    }).done(function(data) {
            $("#mapping_categories").html(data);
            showPopup("mapping_categories");
            //preMappedCategories(ID);
        });
}
function mappedNewOptionValue()
{
    var MARKETPLACE = $("#option_values_market_place_id").val();
    var OPTIONTYPEID = $("#type_id").val();
    var OPTIONVALUEID = $("#option_value_id").val();
    var OPTIONNAME = $("#name").val();
    if($("#option_value_id").val()){
        if(OPTIONNAME == null)
            alert("Please enter market place option name");
        else
        {
            $.ajax({
                url: "/admin/option_values_market_places/add_option_value?option_type_id="+OPTIONTYPEID+"&market_place_id="+MARKETPLACE+"&option_value_id="+OPTIONVALUEID+
                    "&name="+OPTIONNAME,
                context: document.body
            }).done(function(data) {
                    alert('Option Value mapped successfully');
                    closePopup('mapping_categories');
                });
        }
    }
    else{
        alert("Option Value is not available for this type.");
    }

}