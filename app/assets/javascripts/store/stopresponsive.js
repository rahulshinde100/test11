$(window).scroll(function(){
    $('#styled-white-strip').css("left" , -$(window).scrollLeft() ).css("width", $(document).width());
});

$(window).load(function(){
    $('#styled-white-strip').css("left" , -$(window).scrollLeft()).css("width", $(document).width());
});
