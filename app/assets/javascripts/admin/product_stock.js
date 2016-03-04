// Load market palce variants according to product and seller
function marketPlaceVariants(PRODUCTID, SELLERID)
{
   var MARKETPLACEID = $("#stock_market_place_id").val();
   $.ajax({
      url: "/admin/products/market_place_variants?product_id="+PRODUCTID+"&seller_id="+SELLERID+"&market_place_id="+MARKETPLACEID,
      context: document.body
    }).done(function(data) {
       $("#product_variants").html(data);
    });
}

// Show the import form
function show_import_form(ID)
{
  if($(ID).val() == "stock_import")
  {
     $('#import_stock_file').show();
     $('#export_stock_file').hide();
  }
  else
  {
     $('#import_stock_file').hide();
     $('#export_stock_file').show();
  }
}

// This to show percentage table for the multiple market places
function show_percentage_table(ID)
{
  if($(ID).val() == "percentage_quantity"){
    $("#seller_market_place_stock_config_details_field").fadeIn();
  }
  else{
    $("#seller_market_place_stock_config_details_field").fadeOut();
  }
}

// This check for percentage setting check
function percentage_check(ID)
{
  var per = parseInt($(ID).val());
  var per_total = 0;
  if($.isNumeric(per) && per >= 0){
  	$("#percentage_collection input[type='number']").each(function () {
      per_total = per_total + parseInt($(this).val());
    });
    if(per_total > 100){
      alert("Total percentage can not be more than 100");
      $(ID).val(0);
    }
  }
  else{
  	alert("Percentage must be a positive number");
  	$(ID).val(0);
  }
}

//Check valid setting applied
function settingCheckValidation()
{
  var per_total = 0;
  var flag = true;
  var r = confirm("Change of stock setting may result into auto allocation of stock, Do you really want to continue?");
  if (r == true) {
    $("#percentage_collection input[type='number']").each(function () {
	  per_total = per_total + parseInt($(this).val());
	});
	if(per_total > 100){
	  alert("Total percentage can not be more than 100");
	  flag = false;
	}
  }
  else
  {
  	flag = false;
  }
  return flag;
}

//Toggling Stock setting form
function showHideStockSettingForm(action)
{
  if(action=="open")
  {
  	$(".black_overlay").fadeIn();
  	$("#stock_setting_form").fadeIn();
  }
  else
  {
  	$(".black_overlay").fadeOut();
  	$("#stock_setting_form").fadeOut();
  }
}

//Load stock setting product form
function loadStockSettingProductFrom(ID)
{
  $.ajax({
    url: "/admin/stock_transfers/stock_setting_load_product?id="+ID,
    context: document.body
  }).done(function(data) {
    $("#stock_setting_product_form").html(data);
    showHideStockSettingForm('open');
    show_percentage_table($("#product_stock_config_type_field input[type='radio']:checked"));
  });
}

function syncWithFba(ID){

    if (confirm('This may result into auto allocation of stock, Do you really want to continue?')) {
        $.ajax({
            url: "/admin/stock_transfers/sync_with_fba?id="+ID,
            context: document.body
        }).done(function(data) {
            alert(data);
            location.reload();
        });
    }
}
//Toggling the description window for the each market places
function toggleDescriptionForm(ID)
{
  var num = ID.split("_");
  $(".description-body").each(function( index ){
    $(this).hide();	
  });
  $(".toggle-plus").each(function( index ){
    $(this).text("+");	
  });
  if($("#toggle_"+num[1]).text() == "+"){
    $("#toggle_"+num[1]).text("-");
    $("#"+ID).toggle(600);
  }
  else{
    $("#toggle_"+num[1]).text("+");
  }
}
