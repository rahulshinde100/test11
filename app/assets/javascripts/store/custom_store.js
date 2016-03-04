function custom_height(order_detail_page) {  
  if($(order_detail_page).css("display") === "none") {
    $('td.order-detail-tab').hide();    
    $(order_detail_page).show();
    $('.order-small-tab').hide();
    $('.list-wrap').animate({height:'100%',width:'100%'});           
    $("html, body").animate({ scrollTop: $(order_detail_page).offset().top - 170  }, "slow");
    return false;
  }
  else{
    $(order_detail_page).hide();
    $('.list-wrap').animate({height:'100%',width:'100%'}); 
  }      
} 

$(document).ready(function(){ 
  // hide #back-top first
  $("#back-top").hide();
  
  // fade in #back-top
  $(function () {
    $(window).scroll(function () {
      if ($(this).scrollTop() > 100) {
        $('#back-top').fadeIn();
      } else {
        $('#back-top').fadeOut();
      }
    });

    // scroll body to 0px on click
    $('#back-top a').click(function () {
      $('body,html').animate({
        scrollTop: 0
      }, 800);
      return false;
    });
  });

  $("#user_dateofbirth").datepicker({
    dateFormat: 'dd-mm-yy',
    maxDate: '-16y'
  });      

  if(document.getElementById("categories-all-div") !== null){   
    $('#categories-all-div').css( "min-height", $('#categories-all').position().top + $('#categories-all').height() - 21);  
  }
    
  if(document.getElementById("stores-all-div") !== null){
    $('#stores-all-div').css("top", $('#lhs-stores').position().top + 15); 
    $('#stores-all-div').css("min-height", $('#stores-all').height() + ($('#stores-all').position().top - $('#lhs-stores').position().top - 41)); 
  }

  if(document.getElementById("brands-all-div") !== null){
    $('#brands-all-div').css("top", $('#lhs-brands').position().top + 15); 
    $('#brands-all-div').css("min-height", $('#sidebar').height() - $('#lhs-brands').position().top - 74 );     
  }
  
  $('#categories-all, #categories-all-div').mouseover(function(){        
    $('#categories-all-div').addClass('show-sub-cat');
    $('#categories-all, .lhs-categories').addClass('active background');   
  }).mouseout(function(){
    $('#categories-all, .lhs-categories').removeClass('active background');
  }) ;

  $('.lhs-menu, #categories-all-div ').mouseout(function(){    
    if(!$('#categories-all-div').hasClass('show-sub-cat')) {
      $('#categories-all, .lhs-categories').removeClass('active background');
    }
    $('#categories-all-div').removeClass('show-sub-cat');
  });

  $('.lhs-categories').mouseover(function(){
    $('.lhs-categories').each(function(){
      if($(this).hasClass('active background')){
        $('#categories-all-div').addClass('show-sub-cat'); 
      }  
    });    
  });

  $('#stores-all, #stores-all-div').mouseover(function(){        
    $('#stores-all-div').addClass('show-sub-cat');
    $('#stores-all, .lhs-stores').addClass('active background');
  }).mouseout(function(){
    $('#stores-all, .lhs-stores').removeClass('active background');
  }) ;

  $('.lhs-menu, #stores-all-div ').mouseout(function(){    
    if(!$('#stores-all-div').hasClass('show-sub-cat')) 
      $('#stores-all, .lhs-stores').removeClass('active background');
    $('#stores-all-div').removeClass('show-sub-cat');
  });

  $('.lhs-stores').mouseover(function(){
    $('.lhs-stores').each(function(){
      if($(this).hasClass('active background'))
        $('#stores-all-div').addClass('show-sub-cat');       
    });    
  });

  $('#brands-all, #brands-all-div').mouseover(function(){        
    $('#brands-all-div').addClass('show-sub-cat');
    $('#brands-all, .lhs-brands').addClass('active background');
  }).mouseout(function(){
    $('#brands-all, .lhs-brands').removeClass('active background');
  }) ;

  $('.lhs-menu, #brands-all-div ').mouseout(function(){    
    if(!$('#brands-all-div').hasClass('show-sub-cat')) 
      $('#brands-all, .lhs-brands').removeClass('active background');
    $('#brands-all-div').removeClass('show-sub-cat');
  });

  $('.lhs-brands').mouseover(function(){
    $('.lhs-brands').each(function(){
      if($(this).hasClass('active background'))
        $('#brands-all-div').addClass('show-sub-cat');       
    });    
  });

});