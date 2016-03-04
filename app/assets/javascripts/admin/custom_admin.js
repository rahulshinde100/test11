$(document).ready(function(){
  $("#category_serach").click(function(){
    $('#table-filter').toggle("slow");
  });
  // Data import js 'admin/product/index' JS added here
  $("#new_product_link").click(function(){
      $('#table-filter').css('display','none');
      $('.import-data').css('display','none');
      $('.list-product').css('display','none');
      $('.export-file').css('display','none');
      $('#new_product_wrapper').toggle("slow");
      });

    $('#import-data').click(function(){
      $('#table-filter').css('display','none');
      $('.import-data').toggle("slow");
      $('#new_product_wrapper').css('display','none');
      $('.list-product').css('display','none');
      $('.export-file').css('display','none');
       });

    $('#action_name').on('change', function() {
      var action_name = this.value;
      if(action_name == "Update Marketplace Details"){
        loadMarketPlacesOnProductImport();
        $("#product_bulk_import").css('display','block');
        $("#sub").val("Upload Details");
        $("#sample_download").attr("href", "/sample-files/update_market_place_details.xls");
        $("#sample_download").attr("download", "Sample update market place details.xls");
        $("#sample_download i").html("Download Update Marketplace Details sample .xls file");

        $("#seller_id").change(function() {
             loadMarketPlacesOnProductImport();
         });
      }else if(action_name == "Import Products"){
        $("#sub").val("Upload Products");
        $("#sample_download").attr("href", "/sample-files/sample_products_import.xls");
        $("#sample_download").attr("download", "Sample products import.xls");
        $("#sample_download i").html("Download Import Products sample .xls file");
        $("#product_bulk_import").css('display','none');
      }else if(action_name == "Import Variants"){
        $("#sub").val("Upload Variants");
        $("#sample_download").attr("href", "/sample-files/sample_variants_import.xls");
        $("#sample_download").attr("download", "Sample variants import.xls");
        $("#sample_download i").html("Download Import Variants sample .xls file");
        $("#product_bulk_import").css('display','none');
      }else if(action_name == "Quantity Inflation"){
      	loadMarketPlacesOnProductImport();
        $("#sub").val("Inflate Quantity");
        $("#sample_download").attr("href", "/sample-files/sample_quantity_inflation_import.xls");
        $("#sample_download").attr("download", "Sample quantity inflation import.xls");
        $("#sample_download i").html("Download Import Quantity Inflation sample .xls file");
        $("#product_bulk_import").css('display','none');
        $("#seller_id").change(function() {
             loadMarketPlacesOnProductImport();
         });
         $("#product_bulk_import").css('display','block');        
      }else {
        $("#sub").val("Upload Images");
        $("#sample_download").attr("href", "/sample-files/image_upload.zip");
        $("#sample_download").attr("download", "Sample images import.zip");
        $("#sample_download i").html("Download Import Images sample .zip file");
        $("#product_bulk_import").css('display','none');
      }
    });

     $('#list-product').click(function(){
      $('#table-filter').css('display','none');
      $('.list-product').toggle("slow");
      $('.export-file').css('display','none');
      $('.import-data').css('display','none');
      $("#seller_id_list").change(function() {
            loadMarketPlacesOnProductListing();
        });
        loadMarketPlacesOnProductListing();
       });

    $('#export-file').click(function(){
      $('#table-filter').css('display','none');
      $('.export-file').toggle("slow");
      $('.import-data').css('display','none');
      $('.list-product').css('display','none');
      $("#seller_id_export").change(function() {
            loadMarketPlacesOnProductExport();
        });
        loadMarketPlacesOnProductExport();
      });

    $('#xls').val('');
    $(".icon-excel").click(function(){
        $('#xls').val('xls');
    });
    $("#file").change(function(){
      filename = $(this).val();
      $("#file_path").attr("value", filename);
    });

    $("#attachment").change(function(){
      filename = $(this).val();
      new_name = truncate(filename,2);
      console.log(new_name);
      $(this).attr('val', new_name);
    });

    $("#all").change(function(){
      if($(this).is(':checked')){
        $("#listing_products input:checkbox").map(function(){$(this).attr('checked', true);}).get();
      }else{
        $("#listing_products input:checkbox").map(function(){$(this).attr('checked', false);}).get();
      }
      // update_products();
    });
    $("#listing_products input:checkbox").change(function(){

      $('#add-warehouse').css('display','block');

      var pr_id = $(this).attr('id').match(/\d+/);
      if(pr_id){
        if($(this).is(':checked')){
          $("#sale_price_"+pr_id[0]).focus();
        }else{
          $("#sale_price_"+pr_id[0]).val($("#price_"+pr_id[0]).val());
        }
      }
    });

    $("#add-warehouse").click(function(){
      update_products();
    });
    function update_products(){
      var products = {};
      var return_flag = true;
      $("#listing_products input:checkbox").each(function(index){
          var pr_id = $(this).attr('id').match(/\d+/);
          if(pr_id){
              var product = products[index] = [];
              if($(this).is(':checked')){
                if($("#sale_price_"+pr_id[0]).val()==''){
                  $("#sale_price_"+pr_id[0]).focus();
                  alert("Please Fill Special Price");
                  return_flag = false;
                  return false;
                }else{
                  product.push(pr_id[0]);
                  product.push($(this).prop('checked'));
                  product.push($("#sale_price_"+pr_id[0]).val());
                }
              }else{
                product.push(pr_id[0]);
                product.push($(this).prop('checked'));
                product.push($("#sale_price_"+pr_id[0]).val());
              }
          }
      });
      if(return_flag){
        var url = "<%= spree_current_user.has_spree_role?('admin') ? add_warehouse_sale_admin_sellers_path : add_warehouse_sale_admin_seller_path(spree_current_user.seller.id)%>";
        $.ajax({
          type: "POST",
          url: url,
          data: { products: products}
          }).done(function() {
            location.reload();
        });
      }else{
        return false;
      }
    }
  // product/index js completed

  $('.dropdown').css('display','none');
	$('.custom_title').hover(
	  function(){
	  	$('#powerTip').addClass('remove n');
	  }
  );

  $('#search_product').click(function(){
    $('.upload-file').css('display','none');
    $('.export-file').css('display','none');
    $('.list-product').css('display','none');
    $('.import-data').css('display', 'none');
    $('#table-filter').toggle("slow");
  });

  $('#search_kit').click(function(){
    $('.upload-file').css('display','none');
    $('.export-file').css('display','none');
    $('#table-filter').toggle("slow");
  });

  $('#search_orders').click(function(){
    $('#table-filter').toggle("slow");
  });

  if(/store_address/i.test(window.location.pathname))
    $('#store').css('background-color','#169AAD');

  if(/bank_details/i.test(window.location.pathname)){
    $('#abank').css('background-color','#169AAD');
    $('#ebank').css('background-color','#169AAD');
  }

  if(/seller_categories/i.test(window.location.pathname))
    $('#category').css('background-color','#169AAD');

  if(/seller_users/i.test(window.location.pathname))
    $('#user').css('background-color','#169AAD');

  if(/newsletter/i.test(window.location.pathname))
    $('#news_list').addClass('selected');

  if(/brands/i.test(window.location.pathname)){
     var config_t=$('a[href="/admin/general_settings/edit"]');
     config_t.closest('li.tab-with-icon').addClass('selected');
   }

   if(/stock_locations/i.test(window.location.pathname)){
     var config_t=$('a[href="/admin/sellers"]');
     config_t.closest('li.tab-with-icon').addClass('selected');
     var config_tab = $('a[href="/admin/general_settings/edit"]');
     config_tab.closest('li.tab-with-icon').removeClass('selected');
   }

  // if(/stock_product/i.test(window.location)){
  //   var product_tab = $('a[href="/admin/products"]');
  //   product_tab.closest('li.tab-with-icon').addClass('selected');
  //   var config_tab = $('a[href="/admin/general_settings/edit"]');
  //   config_tab.closest('li.tab-with-icon').removeClass('selected');
  // }

  if(/products/i.test(window.location.pathname))
    $('.page-title').closest('div').addClass('custom_table_cell');

  if(/kits/i.test(window.location.pathname))
    $('.page-title').closest('div').addClass('custom_table_cell');

  if( window.location.pathname == '/admin/reports/sales_total' || window.location.pathname == '/admin/reports' || window.location.pathname == '/admin/reports/'){
    $('a[href="/admin/reports/sales_total"]').closest('li').addClass('selected');
  }
  else if(/goods_and_services_tax/i.test(window.location.pathname)){
    $('a[href="/admin/reports/goods_and_services_tax"]').closest('li').addClass('selected');
  }
  else if(/seller_wise_sale_total/i.test(window.location.pathname)){
    $('a[href="/admin/reports/seller_wise_sale_total"]').closest('li').addClass('selected');
  }
  else if(/error_logs/i.test(window.location.pathname)){
    $('a[href="/admin/error_logs"]').closest('li').addClass('selected');
    $('a[href="/admin/reports"]').closest('li.tab-with-icon').addClass('selected');
  }
    if( window.location.pathname == '/admin/products/create_marketplace_list'){
        $('a[href="/admin/products"]').closest('li').removeClass('selected');
        $('a[href="/admin/products/create_marketplace_list"]').closest('li').addClass('selected');
    }else if( window.location.pathname == '/admin/products/update_marketplace_list'){
        $('a[href="/admin/products"]').closest('li').removeClass('selected');
        $('a[href="/admin/products/update_marketplace_list"]').closest('li').addClass('selected');
    }else if( window.location.pathname == '/admin/variants/get_new_variants'){
        $('a[href="/admin/products"]').closest('li').removeClass('selected');
        $('a[href="/admin/variants/get_new_variants"]').closest('li').addClass('selected');
    }else if( window.location.pathname == '/admin/variants/get_updated_variants'){
        $('a[href="/admin/products"]').closest('li').removeClass('selected');
        $('a[href="/admin/variants/get_updated_variants"]').closest('li').addClass('selected');
    }else if( window.location.pathname == '/admin/products'){
        location.queryString = {};
        var inActive = false;
        location.search.substr(1).split("&").forEach(function (pair) {
            if (pair === "") {
//                $('a[href="/admin/products"]').closest('li').addClass('selected');
            }
            else{
                var parts = pair.split("=");
                if (parts[0]=='in_active'){
                    inActive = true
                    $('a[href="/admin/products"]').closest('li').removeClass('selected');
                    $('a[href="/admin/products?in_active=true"]').closest('li').addClass('selected');
                }
            }
            if (inActive == false){
                $('a[href="/admin/products"]').closest('li').addClass('selected');
            }

        });
//        if(window.location.search == '?in_active=true'){
//            $('a[href="/admin/products"]').closest('li').removeClass('selected');
//            $('a[href="/admin/products?in_active=true"]').closest('li').addClass('selected');
//        }
    }

  $("#label_shape").select2();
  $("#label_color").select2();
  $("#label_seller_id").select2();

  $('#store_description').addClass('custom_text_area');
  $('#store_welcome_description').addClass('custom_text_area');
});

$(function() {
  $('#news_letter_list, .open').mouseover(function() {
    var x = $('#top-navigation-bar').width();
    var width = $(this).outerWidth();
    $("#sub_news_letter_list").css({

    });
    $('#sub_news_letter_list').hide();
  }).mouseout(function(){
  	$('#sub_news_letter_list').show();
  });

  $('#a-cms-list, .open').mouseover(function() {
    var x = $('#top-navigation-bar').width();
    var width = $(this).outerWidth();
    $("#sub-cms-list").css({

    });
    $('#sub-cms-list').hide();
  }).mouseout(function(){
  	$('#sub-cms-list').show();
  });
});

// Function to truncate long file name
function truncate(n, len) {
  console.log(n);
  console.log(len);
      var ext = n.substring(n.lastIndexOf(".") + 1, n.length).toLowerCase();
      var filename = n.replace('.'+ext,'');
      console.log(filename);
      if(filename.length <= len) {
          return n;
      }
      filename = filename.substr(0, len) + (n.length > len ? '...' : '');
      return filename + '.' + ext;
  };

function change_sign_val(id) {
  // according to click event change sign
  if($("#"+id).children(".add-stock-qty").css("display") == "block" ){
    $("#"+id).children(".add-stock-qty").hide();
    $("#"+id).children(".subtract-stock-qty").show();
    $("#input-"+id).val('-');
    $('.'+id).val(0 - $("#quantity-"+id).val());
  }
  else{
    $("#"+id).children(".add-stock-qty").show();
    $("#"+id).children(".subtract-stock-qty").hide();
    $("#input-"+id).val('+');
    $('.'+id).val(0 - $('#quantity-'+id).val());
  }
}

function check_sign(id){
  // Check sign in hidden field on textbox change
  var signid = id.substring(9);
  if($("#input-"+signid).val() == '-')
    $('.'+signid).val(0 - $("#"+id).val());
  else
    $('.'+signid).val($("#"+id).val());
}

function validateEmail(id){
  var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
  var contactemail = $('#' + id).val();
  if(!re.test(contactemail)){
    alert('Please enter valid Contact Email ID');
    setTimeout(function(){
      $('#' + id).focus();
    });
  }
}

function generateApiSecretKey(ID)
{
  if(confirm('Do really want to generate api secret key?'))
  {
    $.ajax({
      url: "/admin/seller_market_places/load_form_generate_api_secret_kay?id="+ID,
      context: document.body
      }).done(function(data) {
      	$("#generate_api_key_popup").html(data);
        showPopup("generate_api_key_popup");
    });
  }
}

function checkApiKey(ID)
{
  var flag = true;
  var name = $("#secret_key_user_id").val();
  var password = $("#secret_key_password").val();

  if(ID.length == 0)
  {
  	flag = false;
  	alert("Please add market place api key");
  }

  if(name.length == 0)
  {
  	flag = false;
  }

  if(password.length == 0)
  {
  	flag = false;
  }

  if(flag)
  {
  	closePopup("generate_api_key_popup");
  }

  return ID.length==0 ? false : true;
}

