$(function() {
	$("#description-tabs-all").organicTabs({
		"speed": 200
	});
        
     $("#store-map").organicTabs({
		"speed": 200
	});
     $("#my-account-tabs").organicTabs({
		"speed": 200
	});   
    
    $('#search-bar #keywords').change(function(){
        $("#ui-id-1").show();
    });
    
     $('.open-search').mouseover(function(){      
       $("#search-bar").find('form').show();
    });
    
    $('#ui-id-1 li a').click(function(){ alert('hui');
       //if($("#search-bar #keywords").val() != "")
       $("#search-bar form").submit();
    });
    
    $('#first-product-list , #second-product-list').mouseenter(function(){
        $(this).children('.product-text').fadeIn(100);
    }).mouseleave(function(){
        $(this).children('.product-text').fadeOut(100);
    });
    
    $('.category-images').bxSlider({
        mode: 'fade',
        captions: false,
        auto: true,
        controls: false,
        speed: 1000,
        pager: false,
        randomStart: true
    });
    
    
    
    /* 
     * 
     * 
     * Main navigation bar hover effect 
     *
     */
    


            $('.page-wrapper #main-nav-bar li a').each(function(){
                 var this_id = this.id; 
                                    var this_id_arr = this_id.split("-");
                                    var this_id_num = this_id_arr[2]; 
                                    $('.page-wrapper #sub-cat-'+this_id_num +', .page-wrapper #main-nav-bar li #main-cat-'+this_id_num+', .page-wrapper #main-nav-bar li #main-cat-bar-'+this_id_num).mouseover(function(){
                                        
                                         if( $('#sub-cat-'+this_id_num+' li').length){
                                            $('#sub-cat-'+this_id_num+'').addClass('show-sub-cat');
                                            $(".sub-category-block#sub-cat-"+this_id_num).show();
                                         }
                                         else{
                                           //  $(this).css("padding-bottom", "7px");
                                         }
                                       
                                        $('.sub-category-block').css("left", $('.page-wrapper #main-nav-bar li #main-cat-'+this_id_num).position().left + 1);
                                        
                                        
                                        
                                        
                                        $('.page-wrapper #main-nav-bar li #main-cat-'+this_id_num).addClass('active');
                                       // $('.page-wrapper #main-nav-bar li #main-cat-'+this_id_num).next().css("opacity", 1);
                                        
                                    }).mouseout(function(){
                                        $('#sub-cat-'+this_id_num+'').removeClass('show-sub-cat');
                                        $(".sub-category-block#sub-cat-"+this_id_num).hide();
                                        $('.page-wrapper #main-nav-bar li #main-cat-'+this_id_num).removeClass('active');
                                        //if(!$('.page-wrapper #main-nav-bar li #main-cat-'+this_id_num).parent().hasClass("main-mainu-select"))
                                        //$('.page-wrapper #main-nav-bar li #main-cat-'+this_id_num).next().css("opacity", 0);
                                   

               }) ;
            });
            
            
            $('#my-account-icon ,   #pop-up-account-box, #nav-bar .horizontal-line-bar ').mouseover(function(){
               
                $('#pop-up-account-box').show();
            }).mouseout(function(){
                $('#pop-up-account-box').hide();
               
            });
            
            /*$(".main-cat-class").mouseover(function(){
                var this_id =  this.id;
                 var this_id_arr = this_id.split("-");
                 var this_id_num = this_id_arr[2]; 
                               if(this_id_num > 6 && this_id_num < 12)
                                   {
                                        var x = $(this).offset().left;
                                        var width = $(this).width();
                                        $(this).parent().find("div.sub-category-block").css({
                                            left: (x - 749 + width) + "px"
                                        });
                                   }
                                   else if(this_id_num == 12) {
                                        var x = $(this).offset().left;
                                        var width = $(this).width();
                                        $(this).parent().find("div.sub-category-block").css({
                                            left: (x - 748 + width) + "px"
                                        });
                                   }
            })*/
    
   
    
    /**
     * 
     */
    
    var taxon_index = 0;
    var org_height_row1 = 0;
    var org_height_row2 = 0;
    var org_height_row3 = 0;
    
    var max_height_1 = 0;
    var taxon_id = new Array();
    $('nav#taxonomies .taxons-list-responsive .main-taxon-list').each(function(){
         taxon_id[taxon_index] = $(this).height();
         taxon_index = taxon_index + 1;
    });
    
    for (i=0;i<taxon_id.length;i++)
    {
             
             if(i < 4 )
                 {
                        if(org_height_row1 < taxon_id[i]){
                            org_height_row1 = taxon_id[i];
                            var taxon_css_index = 0;
                             $('nav#taxonomies .taxons-list-responsive .main-taxon-list').each(function(){
                                   if (taxon_css_index < 4)
                                       {
                                           $(this).css("height" , org_height_row1);
                                           
                                       }
                                       taxon_css_index = taxon_css_index + 1;

                               });

                        }
                 }
    }
   for (i=3;i<taxon_id.length;i++)
    {
            if( i < 8 ){    
                        if(org_height_row2 < taxon_id[i]){
                            org_height_row2 = taxon_id[i];
                           
                            var taxon_css_index = 0;
                             $('nav#taxonomies .taxons-list-responsive .main-taxon-list').each(function(){
                                 
                                    if (taxon_css_index > 3 && taxon_css_index < 8)
                                       {  
                                           $(this).css("height" , org_height_row2);
                                           
                                       } 
                                       taxon_css_index = taxon_css_index + 1;

                               });

                        }
   }
    }
   
    /*for (i=9;i<taxon_id.length;i++)
    {
      
            if(i < 16 ){
                        if(org_height_row3 < taxon_id[i]){
                            org_height_row3 = taxon_id[i];
                            var taxon_css_index = 0;
                             $('nav#taxonomies .taxons-list-responsive .main-taxon-list').each(function(){                      
                                    if (taxon_css_index > 8 && taxon_css_index < 16)
                                       {
                                           $(this).css("height" , org_height_row3);
                                          
                                       } 
                                        taxon_css_index = taxon_css_index + 1;
                               });

                        }
            }
        
    }*/
    
    
                                    //$('.review-box').tinyscrollbar();
    

                                 
                                    $('#main_nav_bar_container .open-menu').click(function () {
                                        if($('#static-header').css("position") === "fixed")    
                                        {
                                           if( $(window).width() > 478 )
                                                $('#static-header').css("left" , "50%");
                                            else
                                                $('#static-header').css("left" , "80%");    
                                        }   
                                        
                                        
                                    });
    
    
    
    
                                    /* Navigator Code */
                                     if (navigator.userAgent.indexOf('Chrome') != -1 && navigator.userAgent.indexOf('Windows') != -1) {
                                            $('#main_nav_bar_container nav #main-nav-bar li a').css('padding-right',  '13.0px');
                                     }
                                     if (navigator.userAgent.indexOf('Firefox') != -1 && navigator.userAgent.indexOf('Windows') != -1) {
                                            $('#main_nav_bar_container nav #main-nav-bar li a').css('padding-right',  '13.5px');
                                            $('.sale-tab a').css('margin-left',  '-1px');
                                     }
                                     if (navigator.userAgent.indexOf('Firefox') != -1 && navigator.userAgent.indexOf('Mac') != -1) {
                                            $('.sale-tab a').css('margin-left',  '-1px');
                                     }
                                     if (navigator.userAgent.indexOf('Firefox') != -1 && navigator.userAgent.indexOf('Mac') != -1) {
                                            $('#main_nav_bar_container nav #main-nav-bar li a').css('padding-right',  '13.4px');
                                     }
                                     if (navigator.userAgent.indexOf('Safari') != -1 && navigator.userAgent.indexOf('Mac') != -1) {
                                            $('.sub-category-block').css('left',  '1px');
                                            $('#main-search-box input[type="text"]').css('height',  '24px');
                                     }
                                     if (navigator.userAgent.indexOf('IE') != -1 && navigator.userAgent.indexOf('Windows') != -1) {
                                           $('#main_nav_bar_container nav #main-nav-bar li a').css('padding-right',  '13.4px');
                                           $('.edit_user #user_country_id').css("width", "258px");  
                                     }
                                        
                                        
                                        
                                        
                                                      
                             $('#keywords, #autocomplete-ajax').keyup(function(){ 
                               
                                   
                                     
                                   
                                     
                                    if(this.id === "autocomplete-ajax"){
                                    $('#keywords').val($(this).val());
                                    }
                                    else{
                                    $('#autocomplete-ajax').val($(this).val());    
                                    }
                                    
                                            //.success(function(json){})
                                    
                                    
                               
                           }) ;       
                           
                         $('#about-us-seller').click(function(){                           
                             if($('.seller-info-text').css('visibility') === "hidden"  ) 
                                 $('.seller-info-text').css("visibility","visible").css('position', 'static');   
                             else
                                 $('.seller-info-text').css("visibility","hidden").css('position', 'absolute');   
                            });                                               
});


$(window).scroll(function() {
   /*if($('body #mobile-navigation:target').css("width") > "0%")
   {
       //$('#static-header').css("left" , "50%");
       
   }
   else{
       $('#static-header').css("left" , "0%");
   }*/
    
   
       if($('#static-header').css("position")=== "fixed" && $('body #mobile-navigation:target').css("width") > "0%" ){
            if( $(window).width() > 478 )
            $('#static-header').css("left" , "50%");
            else
            $('#static-header').css("left" , "80%");    
       }
       else{
             
            $('#static-header').css("left" , "0");
       }
   
    
});


$(window).load(function () {
    
    
     if($('#static-header').css("position")=== "fixed" && $('body #mobile-navigation:target').css("width") > "0%" ){
           $('#static-header').css("left" , "50%");
       }
       else{
            $('#static-header').css("left" , "0");
       }
    
    $('#ui-id-1').mouseout(function(){ 
        $("#ui-id-1").show().delay(3000).fadeOut(1);
        $("#search-bar form").show().delay(3000).fadeOut(1);
        $("#search-bar").find('a').removeClass('search-submit');
       
    });
    
    $("#ui-id-1").addClass("open-search");
    
    $('.open-search').mouseover(function(){
       $("#search-bar").find('form').fadeIn('300');
    });
    
    $('#ui-id-1 li a').click(function(){ alert('hui');
       //if($("#search-bar #keywords").val() != "")
       $("#search-bar form").submit();
    });
    
    
   
   
    
    
    //$('#styled-white-strip').scrollToFixed();
   
    
    if( window.location.pathname != '/checkout/payment/' && window.location.pathname != '/checkout/payment' && window.location.pathname != '/checkout/update/payment'){
      $('#checkout-summary').scrollToFixed({marginTop: 24, zIndex : -100});
   }
    
    
    
    
    $('#main-search-box form').submit(function(event){
        
       if($('#autocomplete-ajax').val() === "")
           {   
               
               
               event.preventDefault();
               return  false;
           }
           else
               {
                    //$('#homepage-slider').slideUp(300);                                    
                    //$('#slider-prev, #slider-next').hide();
                     if($('body').hasClass('home-page-slider-body'))
                    {
                         var focusElement = $("#homepage-slider");                     
                         ScrollToTop(focusElement, function() { focusElement.focus(); } , -292); 
                    }
                    else if($('#home-products').hasClass('seller-home-products')){
                         var focusElement = $("#wrapper-seller");                     
                         ScrollToTop(focusElement, function() { focusElement.focus(); } , 70); 

                    }
                    else{
                         var focusElement = $("#wrapper");                     
                         ScrollToTop(focusElement, function() { focusElement.focus(); } , 130);
                         $('#breadcrumbs').hide();   
                    }
               }
                $("#home-products").html("<div class='loading search-loading'><img src='/assets/fancybox_loading@2x.gif'/></div>")  
                $(".loading").addClass("show_loading");
    });

     $('#search-bar-new a').click(function(event){
       
       if($('#keywords').val() === "")
           {   
               
               
               event.preventDefault();
               return  false;
           }
           else
               {
                  if($("#retailer").val()==''){
                    //$('#homepage-slider').slideUp(300);                                    
                    //$('#slider-prev, #slider-next').hide();
                     if($('body').hasClass('home-page-slider-body'))
                    {
                         var focusElement = $("#homepage-slider");                     
                         ScrollToTop(focusElement, function() { focusElement.focus(); } , -292); 
                    }
                    else if($('#home-products').hasClass('seller-home-products')){
                         var focusElement = $("#wrapper-seller");                     
                         ScrollToTop(focusElement, function() { focusElement.focus(); } , 70); 

                    }
                    else{
                         var focusElement = $("#wrapper");                     
                         ScrollToTop(focusElement, function() { focusElement.focus(); } , 130); 
                         $('#breadcrumbs').hide();
                    }
                    $('#search-bar-new form').submit();
                    $("#home-products").html("<div class='loading search-loading'><img src='/assets/fancybox_loading@2x.gif'/></div>")  
                    $(".loading").addClass("show_loading");
               }else{
                    $('#search-bar-new form').submit();
                     $("#seller_products").html("<div class='loading search-loading'><img src='/assets/fancybox_loading@2x.gif'/></div>")  
                    $(".loading").addClass("show_loading");
                  }
                }
    });    
    
    
    $("#autocomplete-ajax").keypress(function(event) {
        if (event.which == 13) {
             if($(this).val() === "")
           {   
               
               
               event.preventDefault();
               return  false;
           }
           else
               {
                     if($('body').hasClass('home-page-slider-body'))
                        {
                             var focusElement = $("#homepage-slider");                     
                             ScrollToTop(focusElement, function() { focusElement.focus(); } , -292); 
                        }
                        else if($('#home-products').hasClass('seller-home-products')){
                             var focusElement = $("#wrapper-seller");                     
                             ScrollToTop(focusElement, function() { focusElement.focus(); } , 70); 

                        }
                        else{
                             var focusElement = $("#wrapper");                     
                             ScrollToTop(focusElement, function() { focusElement.focus(); } , 130); 
                             $('#breadcrumbs').hide();   
                        }
                    //$('#homepage-slider').slideUp(300);                                    
                    //$('#slider-prev, #slider-next').hide();
                    $('#main-search-box form').submit();
                    $("#home-products").html("<div class='loading search-loading'><img src='/assets/fancybox_loading@2x.gif'/></div>")  
                    $(".loading").addClass("show_loading");
               }
        }
    });
    
    
     $("#keywords").keypress(function(event) {
        if (event.which == 13) {
             if($(this).val() === "")
           {   
               
               
               event.preventDefault();
               return  false;
           }
           else
               {  if($("#retailer").val()==''){
                    if($('body').hasClass('home-page-slider-body'))
                        {
                             var focusElement = $("#homepage-slider");                     
                             ScrollToTop(focusElement, function() { focusElement.focus(); } , -292); 
                        }
                        else if($('#home-products').hasClass('seller-home-products')){
                             var focusElement = $("#wrapper-seller");                     
                             ScrollToTop(focusElement, function() { focusElement.focus(); } , 70); 

                        }
                        else{
                             var focusElement = $("#wrapper");                     
                             ScrollToTop(focusElement, function() { focusElement.focus(); } , 130); 
                             $('#breadcrumbs').hide();
                        }
                    //$('#homepage-slider').slideUp(300);                                    
                    //$('#slider-prev, #slider-next').hide();
                    $('#search-bar-new form').submit();
                     $("#home-products").html("<div class='loading search-loading'><img src='/assets/fancybox_loading@2x.gif'/></div>")  
                    $(".loading").addClass("show_loading");
                  }else{
                    $('#search-bar-new form').submit();
                     $("#seller_products").html("<div class='loading search-loading'><img src='/assets/fancybox_loading@2x.gif'/></div>")  
                    $(".loading").addClass("show_loading");
                  }
               }
        }
    });
    
    
    
    
    

        
    
    /*var summaries = $('#sidebar');
        
           // var summary = $(summaries[i]);
           // var next = summaries[i + 1];

            summaries.scrollToFixed({
                marginTop: 116,
                zIndex : 100,              
                limit: $('#footer').offset().top
            });*/
      
      
     $('#sort-navigator').click(function(){
         
         if($('#sort-navigator').hasClass("sort-open"))
             {
                $('#sorting-box').hide();
                $('#sort-navigator').removeClass("sort-open");      
             }
         else{
                $('#sorting-box').show();
                $('#sort-navigator').addClass("sort-open"); 
               
         }    
     });
    
    
    
    
});

function add_to_wishlist(var_id){
    $.ajax({
        type: 'POST',
        url: "/wished_products/wished_product/"+ var_id,
        success: function(r){
            if(r == "login"){
                login("wished_product",var_id);
                //$('#product-notify').remove();
            }else if(r == "already_register"){
                $.fancybox("<div style='float: left; width: 250px;' class='product-lightbox'><div data-hook='description' itemprop='description'>This product already there in your wishlist.<a href='#' class='button' onclick='$(\".fancybox-close\").click();return false;' style='float: right; height: 20px; font-size: 14px; margin-top: 12px;'>Ok</a></div>");
            }else{
                $.fancybox("<div style='float: left; width: 250px;' class='product-lightbox'><div data-hook='description' itemprop='description'>Thank you for your interest in this product.<a href='#' onclick='$(\".fancybox-close\").click();return false;' class='button' style='float: right; height: 20px; font-size: 14px; margin-top: 12px;'>Ok</a></div>");
            }
        },
        errors: function(r){$("#flash_messages").html("Product Not added")}
    });
    return false;
  };

function product_notify(var_id){
    $.ajax({
        type: 'POST',
        url: "/product_notifications/notify_me/"+ var_id,
        success: function(r){
            if(r == "login"){
                login("notify_me",var_id);
                //$('#product-notify').remove();
            }else if(r == "already_register"){
                $.fancybox("<div style='text-align:center;' class='product-lightbox'><div data-hook='description' itemprop='description'>You already registered your interest in this product.<br/> We will keep you posted on its availability.<div><a href='#' class='button' onclick='$(\".fancybox-close\").click();return false;' style='height: 20px; font-size: 14px; margin-top: 12px;'>Ok</a></div></div>");
            }else{
                $.fancybox("<div style='text-align:center;' class='product-lightbox'><div data-hook='description' itemprop='description'>Thank you for your interest in this product. <br/> We will keep you posted on its availability.<div><a href='#' onclick='$(\".fancybox-close\").click();return false;' class='button' style=' height: 20px; font-size: 14px; margin-top: 12px;'>Ok</a></div></div>");
            }
        },
        errors: function(r){$("#flash_messages").html("Product Not Notified")}
    });
    return false;
  };

  function login(type, var_id) {
    // $.fancybox({'content': $("#login").html()});
    $.ajax({
        type: 'GET',
        url: "/login?login_type="+type+"&var_id="+var_id,
        // data: ({authenticity_token: jQuery('meta[name="csrf-token"]').attr('content')}),
        success: function(r){ 
            $.fancybox({'content': r});
        }
    });
  };
