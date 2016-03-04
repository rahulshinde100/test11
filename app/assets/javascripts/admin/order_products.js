// Use: To show the products for order
function searchProducts(ID)
{
   $.ajax({
      url: "/admin/orders/load_products_skus?order_id="+ID,
      context: document.body
    }).done(function(data) {
       $("#add_products_to_order").html(data);
       showPopup("add_products_to_order");
    });
}

// Use: To find out variant / line item details
function findVariantForOrder(ID, ITEMID)
{
   $.ajax({
      url: "/admin/orders/load_existing_variant_sku?order_id="+ID+"&line_item_id="+ITEMID,
      context: document.body
    }).done(function(data) {
       $("#add_products_to_order").html(data);
       showPopup("add_products_to_order");
    });
}

// Use: To update the products into order
function updateProducts(ORDERID, ITEMID)
{
  var QTY = $("#qty_id").val();
  if(QTY == "" || QTY == null || QTY <= 0 )
  {
    alert("Quantity should be a number greater than zero");
  }
  else
  {
    $.ajax({
      url: "/admin/orders/update_product_qty?order_id="+ORDERID+"&line_item_id="+ITEMID+"&quantity="+QTY,
      context: document.body
      }).done(function(data) {
        alert('Product Qty updated successfully !');
        closePopup('add_products_to_order');
        $("#order-form-wrapper").html(data);
    });
  }
}
