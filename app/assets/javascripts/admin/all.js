// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs

//= require admin/spree_backend
//= require jquery.fancybox.pack
//= require /typeahead.jquery.min.js
//= require admin/spree_fancy
//= require admin/spree_simple_cms
//= require dataTables/jquery.dataTables
//= require dataTables/jquery.dataTables.bootstrap
//= require admin/spree_editor
//= require_tree .

$(document).ready(function(){
  $('.datatable').dataTable({
      "sDom": "<'row-fluid'<'span6'l><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>",
      // "sDom": 'T<"clear">lfrtip<"clear spacer">T',
      // "sDom": '<"H"TCfr>t<"F"ip>',
      "sPaginationType": "full_numbers"
      // "bStateSave": true,
      // "bJQueryUI": true,
      // "sPaginationType": "full_numbers",
      // "bProcessing": true,
      // "bServerSide": true,
      // "sAjaxSource": $('.datatable').data('source'),
      // "bScrollInfinite": true,
      // "bScrollCollapse": true,
      // "iDisplayLength": 100,
      // "sScrollY": "500px",
      // "sScrollX": "100%",
      // "oTableTools": {
      //     "aButtons": [
      //         "copy",
      //         "csv",
      //         "xls",
      //         {
      //     "sExtends":    "copy_to_div",
      //     "sButtonText": "Copy to div",
      //     "sDiv":        "copy",
      //   },
      //         {
      //             "sExtends": "pdf",
      //             "sPdfOrientation": "landscape",
      //             "sPdfMessage": "Your custom message would go here."
      //         },
      //         "print"
      //     ]
      // }
  });    

  $(".dataTables_length select").change(function(){
    var per_page = $(".dataTables_length select").val();
    if ($('.datatable tr').length <= per_page) {
      $('.dataTables_paginate').hide();
    }else{
      $('.dataTables_paginate').show();
    }

  });

	$(".phone").keyup(function(event) {
    var phone = $(this).val();
    if(event.which == 61 || event.which == 173 || event.which == 57 || event.which == 48 || event.which == 32 || $.isNumeric(phone))
      ;
    else
    {
      var changed = phone.replace(/[^0-9-+()\s]/gi, '').replace(/[_\s]/g, '')
      $(this).val(changed.substring(0,changed.lenght));
    }
	}); 

    $('.fancybox').fancybox({
        padding : 0,
        openEffect  : 'elastic'
    });
    if(/seller/i.test(location.pathname))
      $(".seller-tab").parent().addClass("selected")

   
  function validateEmail(sEmail) {
    var filter = /^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/;
    if (filter.test(sEmail)) {
      return true;
    }
    else {
      return false;
    }
  }
  $('.email').change(function(event) {
    var sEmail = $(this).val();
    if (!validateEmail(sEmail)) {
      $(this).val("");
      $(this).focus();   
      alert("Please enter valid email");
    }
  });
});


$(document).ready(function() {
  $("#product_seller_id").change(function(){
    $("#search_seller_id").val($(this).val());
    $.ajax({
        url: "/admin/labels.json?seller_id="+$(this).val(),
        quietMillis: 200,
        datatype: 'json',
        success: function (data) {
          data = JSON.stringify(data);
          $("#product_label_ids").val("");
          $("#s2id_product_label_ids ul.select2-choices li.select2-search-choice").remove();
          $("#seller_labels").text(data);
        }
      });
    });

  
  if ($("#product_label_ids").length > 0) {
    $("#product_label_ids").select2({
      
      placeholder: "Select",
      multiple: true,
      initSelection: function(element, callback) {        
        return $.getJSON("/admin/labels.json" + "?search=" + (element.val()) +"&seller_id=" + $("#search_seller_id").val(), null, function(data) {
          return callback(data);
        })
      },
      ajax: {
        url: "/admin/labels.json?seller_id="+$("#search_seller_id").val(),
        quietMillis: 200,
        datatype: 'json',
        data: function(term, page) {
          return {
            q: term
          }
        },
        results: function (data, page) {
        data = $("#seller_labels").html();
        if(data != ""){
            data = $.parseJSON(data);
        }else{
            data = [];
        }
          return { results: data }
        }
      },
      formatResult: function(label) {
        return label.title + " (" + label.color + ")"
      },
      formatSelection: function(label) {
        return label.title + " (" + label.color + ")"
      }
    })
  }
  
  });

