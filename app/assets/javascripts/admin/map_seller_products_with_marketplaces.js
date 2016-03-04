// Use: To load the market places for product
function loadMarketPlaces(PRODUCTID)
 {
        var SELLERID = $("#product_seller_id").val();
       $.ajax({
          url: "/admin/sellers_market_places_products/load_market_places?seller_id="+SELLERID+"&product_id="+PRODUCTID,
          context: document.body
        }).done(function(data) {

          if($('#loadMarketPlaces').length!==0)
          {
              $("#loadMarketPlaces").html(data);
          }
          else
          {
             $("#product_seller_id_field").append(data);
          }
       });
 }

// Use: To load the premapped market places for product
function preMappedMarketPlaces(PRODUCTID)
{
        var SELLERID = $("#product_seller_id").val();
       $.ajax({
          url: "/admin/sellers_market_places_products/pre_mapped_market_places?seller_id="+SELLERID+"&product_id="+PRODUCTID,
          context: document.body
        }).done(function(data) {

          if($('#preMappedMarketPlaces').length!==0)
          {
              $("#preMappedMarketPlaces").html(data);
          }
          else
          {
             $("#product_package_content_field").append(data);
          }
       });
}

// Use: Unmap market place from product
function unmappedMarketPlace(SELLERID, MARKETPLACEID, PRODUCTID)
{
  if(confirm('Do you want to unmapped this market place?'))
  {
    $.ajax({
      url: "/admin/sellers_market_places_products/unmapped_market_place?seller_id="+SELLERID+"&market_place_id="+MARKETPLACEID+"&product_id="+PRODUCTID,
      context: document.body
      }).done(function(data) {
        alert('Market Place unmapped successfully');
        loadMarketPlaces(PRODUCTID);
        preMappedMarketPlaces(PRODUCTID);
    });
  }
}

// Use: Bulk Product Import for loading market places
function loadMarketPlacesOnProductImport()
 {
        var SELLERID = $("#seller_id").val();
       $.ajax({
          url: "/admin/sellers_market_places_products/load_market_places_on_product_import?seller_id="+SELLERID,
          context: document.body
        }).done(function(data) {
       $("#product_bulk_import").html(data);
       });
 }

 // Use: Bulk Product Listing for loading market places
function loadMarketPlacesOnProductListing()
 {
        var SELLERID = $("#seller_id_list").val();
       $.ajax({
          url: "/admin/sellers_market_places_products/load_market_places_on_product_listing?seller_id="+SELLERID,
          context: document.body
        }).done(function(data) {
       $("#product_bulk_list").html(data);
       });
 }

 // Use: Bulk Product Export for loading market places
function loadMarketPlacesOnProductExport()
 {
   var SELLERID = $("#seller_id_export").val();
   $.ajax({
      url: "/admin/sellers_market_places_products/load_market_places_on_product_export?seller_id="+SELLERID,
      context: document.body
    }).done(function(data) {
   $("#product_bulk_export").html(data);
   });
 }
 
 function checkMarketPlace(ID)
 {
   if($("#product_image_market_place_id").val() == null)
   {
   	  $(ID).prop('checked', false);
   	  alert('Please select market place first');
   }
 }

 // Use: To show the sellers products
 function showSellerProducts()
 {
   var SELLERID = $("#seller_id_list").val();
  if(SELLERID == null)
    alert("Please select seller");
  else
  {
   $.ajax({
      url: "/admin/sellers_market_places_products/show_seller_products?seller_id="+SELLERID,
      context: document.body
    });
  }
 }

 // Use: To select skus from all checkboxes
 function selectSKUs()
 {
      var selectedSKUList = "";
      $('#listing_products input[type=checkbox]').each(function () {
         if(this.checked)
           {selectedSKUList += (selectedSKUList.length > 0 ? "," : "") + $(this).val();}
      });
      if(selectedSKUList.length > 0)
      {
         $("#product_skus").val(selectedSKUList);
         closePopup('seller_products');
      }
      else
      {
         alert('Please select atleast one SKU');
      }
 }

 // Use: To toggle all select and unselect checkboxes
 function selectUnselectAllSkus(ID)
 {
      if($(ID).is(':checked'))
      {
        $('#listing_products input[type=checkbox]').each(function () {
             $(this).prop('checked', true);
          });
      }
      else
      {
         $('#listing_products input[type=checkbox]').each(function () {
               $(this).prop('checked', false);
           });
      }
 }

 // Use: To check all selected checkboxes
 function checkAllSelected(ID)
 {
      var flag = true;
      $('#listing_products input[type=checkbox]').each(function () {
         if(!this.checked)
         {
            flag = false;
         }
         if(flag)
         {
            $("#select_all").prop('checked', true);
         }
         else
         {
            $("#select_all").prop('checked', false);
         }
      });
 }
