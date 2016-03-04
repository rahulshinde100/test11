function showMappedCategories(ID)
{
   $.ajax({
      url: "/admin/taxons_market_places/mapped_categories?id="+ID,
      context: document.body
    }).done(function(data) {
       $("#mapping_categories").html(data);
       showPopup("mapping_categories");
       preMappedCategories(ID);
    });
}
//
function preMappedCategories(ID)
{
   var MARKETPLACE = $("#category_market_place_id").val();
   $.ajax({
      url: "/admin/taxons_market_places/pre_mapped_categories?taxon_id="+ID+"&market_place_id="+MARKETPLACE,
      context: document.body
    }).done(function(data) {
       $("#pre_mapped_categories").html(data);
    });
    openCloseMapCategoryForm("close", "mapped_new_category");
}

function showPopup(ID)
{
   $("#"+ID).show();
   $(".black_overlay").show();
   //document.body.style.overflow = "hidden";
}

function closePopup(ID)
{
   $("#"+ID).hide();
   $(".black_overlay").hide();
   //document.body.style.overflow = "visible";
}

function mappedNewCategories(TAXON)
{
  var MARKETPLACE = $("#category_market_place_id").val();
 // var CATEGORIESID = $("#category_code").val();
  var CATEGORYNAME = $("#category_name").val();
  alert(CATEGORYNAME);
  // $('#category_code option:selected').each(function(index, value) {
  //    CATEGORIESNAME = CATEGORIESNAME + $(value).text()+',';
  // });
  if(CATEGORYNAME == null)
    alert("Please select market place category");
  else
  {
    $.ajax({
      url: "/admin/taxons_market_places/add_categories?taxon_id="+TAXON+"&market_place_id="+MARKETPLACE+
      "&market_place_category_name="+encodeURIComponent(CATEGORYNAME),
      context: document.body
      }).done(function(data) {
      	alert('Category mapped successfully');
        preMappedCategories(TAXON);
        openCloseMapCategoryForm('close', 'mapped_new_category');
        $("#category_code option:selected").prop("selected", false);
        $('#map_new').show();
    });
  }
}

function unmappedCategory(MARKETPLACECATEGORY, TAXON)
{
  if(confirm('Do you want to unmapped this category?'))
  {
    $.ajax({
      url: "/admin/taxons_market_places/unmapped_category?id="+MARKETPLACECATEGORY,
      context: document.body
      }).done(function(data) {
      	alert('Categories unmapped successfully');
        preMappedCategories(TAXON);
    });
  }
}

function getAllCategoriesMarketPlace(MARKETPLACE, APIKEY)
{
  var flag = false;
  var selectCategory = "";
  selectCategory = $('#category_code').text();
  flag = true;
  $("#mp_categories").show();
  $("#category_code").show();
	$.ajax({
	  url: "/admin/taxons_market_places/get_all_market_place_categories?api_key="+APIKEY+"&market_place="+MARKETPLACE,
	  context: document.body
	  }).done(function(data) {
	    $("#mp_categories").html(data);
	});
  return flag;
}

function openCloseMapCategoryForm(status, ID)
{
   if(status == "open")
   {
   	 var MARKETPLACE = $("#category_market_place_id option:selected").text();
   	 var APIKEYHASH = $("#market_place_api_keys").val().split(",");
   	 var APINAMEHASH = $("#market_place_name").val().split(",");
   	 var index = null;
   	 for(i=0; i<APINAMEHASH.length; i++)
   	 {
   	 	if(APINAMEHASH[i] == MARKETPLACE)
   	 	  index = i;
   	 }
   	 var APIKEY = APIKEYHASH[index];
   	 if(getAllCategoriesMarketPlace(MARKETPLACE, APIKEY))
   	 {
   	   $("#"+ID).show();
   	   $('#map_new').hide();
   	 }
   	 else
   	 {
   	   $("#map_new").show();
   	   alert('API call failed to load categories');
   	 }
   }
   else
   {
   	  $("#"+ID).hide();
   	  $("#map_new").show();
   }

}
