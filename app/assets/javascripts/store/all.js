// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs

//= require store/spree_frontend
//= require store/jquery-ui
//= require_tree .
//= require store/spree_fancy
//= require jquery.rating
//= require store/spree_wishlist
//= require store/spree_simple_cms
//= require jquery.fancybox.pack
//= require store/spree_contact_us

$(document).ready(function(){
  
	$(".datepicker").datepicker();
  $(".contact").keyup(function(event) {
    var phone = $(this).val();
    if(event.which == 61 || event.which == 173 || event.which == 57 || event.which == 48 || event.which == 32 || $.isNumeric(phone))
      ;
    else
    {
      var changed = phone.replace(/[^0-9-+()\s]/gi, '').replace(/[_\s]/g, '')
      $(this).val(changed.substring(0,changed.lenght));
    }
 
  });


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