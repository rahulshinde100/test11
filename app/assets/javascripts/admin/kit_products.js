// Use: To show the products
function showProducts(ID, SELLERID)
{
   $.ajax({
      url: "/admin/kit_products/load_variants?kit_id="+ID+"&seller_id="+SELLERID,
      context: document.body
    }).done(function(data) {
       $("#add_products_to_kit").html(data);
       showPopup("add_products_to_kit");
    });
}

// Use: To add the variants into kit
function addVariants(KIT)
{
  var VARIANT = $("#product_variant_id").val();
  var QTY = $("#qty_id").val();
  if(VARIANT == null || VARIANT == "")
  {
    alert("Please select product");
  }
  else if(QTY == "" || QTY == null || QTY <= 0 )
  {
    alert("Quantity should be a number greater than zero");
  }
  else
  {
    $.ajax({
      url: "/admin/kit_products/add_variants?kit_id="+KIT+"&variant_id="+VARIANT+"&quantity="+QTY,
      context: document.body
      }).done(function(data) {
        if(data != "Oops..This much quantity of products are not available")
         {
            $("#index").html(data);
            closePopup('add_products_to_kit');
            alert('Product added successfully');
         }
        else
         {
             alert(data);
         }
    });
  }
}

// Use: To load the market places for kit
function loadMarketPlacesForKit(KITID)
 {
        var SELLERID = $("#kit_seller_id").val();
        $.ajax({
          url: "/admin/kits/load_market_places_for_kit?seller_id="+SELLERID+"&kit_id="+KITID,
          context: document.body
        }).done(function(data) {
       $("#kit_market_place").html(data);
       });
 }

 // Use: Bulk Kit Import for loading market places
function loadMarketPlacesOnKitImport()
 {
        var SELLERID = $("#seller_id_kit_import").val();
       $.ajax({
          url: "/admin/kits/load_market_places_for_bulk_kit_upload?seller_id="+SELLERID,
          context: document.body
        }).done(function(data) {
       $("#product_bulk_import").html(data);
       });
 }
