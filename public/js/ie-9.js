$(function() {
  var emailpattern = "^\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,3}$"; 

   $('#existing-customer form').submit(function(){
       var spree_login_email = $('#existing-customer #spree_user_email').val();
       var spree_user_password = $('#existing-customer #spree_user_password').val();
       if(spree_login_email == "")
       {
           alert("Email can not be empty");
           
       }
       else if (spree_user_password == "")
           {
               alert("Password can not be empty");
           }
   }) ;
   
   $('#new-customer form').submit(function(){
       var spree_user_firstname = $('#new-customer #spree_user_firstname').val();
       var spree_user_email = $('#new-customer #spree_user_email').val();
       var spree_user_password = $('#new-customer #spree_user_password').val();
       var spree_user_password_confirmation = $('#new-customer #spree_user_password_confirmation').val();
       
       if(spree_user_firstname == "")
           {
                alert("First name can not be empty");
           }
       else if(spree_user_email == "")
           {alert(spree_user_email);
                //alert("Email can not be empty");
           }
       else if( spree_user_password == "")    
           {
                alert("Password can not be empty");
           }
       else if ( spree_user_password_confirmation == "")    
           {
                alert("Confirm password can not be empty");
           }
       else if (spree_user_password != spree_user_password_confirmation)    
            {
                alert("Password and confirm password did not match");
                return false;
           }
       
       
   });
   
   
   
   $('#keywords').val("Search thousands of products");
   $('#autocomplete-ajax').val("Search thousands of products");
   
   $('#autocomplete-ajax, #keywords').focusin(function(){
       if($(this).val() == "Search thousands of products")
       $(this).val('');
   }).focusout(function(){
        if($(this).val() == "")
        $(this).val('Search thousands of products');
   });
   
   
   //$('#pickup-at-store-button').removeAttr()
   
   $('#pickup-at-store-button').click(function(){ 
      if($(this).hasClass('not-pick-at-store'))
        return false;
      //reset address box
      if($("#is_pick_at_store").val() == 'false')
        {
            alert("Please select map location");
            return false;
          }  
      else
        $("#cart-form form").submit();
        // load_map();
    });
    
    
    
    $(window).scroll(function () { 
    if( $(document).scrollTop() > 80 ){
         if($('#search-bar-new').css('opacity') == 0){
            $('#main-search-box').hide();
             
        }
    }
    else{
         if($('#search-bar-new').css('opacity') == 1){
              
            $('#search-bar-new').hide();
            
         }
    
    }
    });
   
   
 
});