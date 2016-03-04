$(document).ready(function(){
    if($.browser.safari){
        $("form").submit(function() {
                $("form input[required='required']").each(function(i, obj){
                if($(obj).val() == ""){
                    var dom_id = $(obj).attr("id");

                    if ($(obj).parent().hasClass("withError") == false){
                        $(obj).parent().addClass("withError");
                    }else{
                        $(obj).parent().removeClass("withError");
                    }

                    if($(obj).parent().hasClass("field_with_errors") == false){
                        $(obj).wrap("<span class='field_with_errors'></span>");
                    }


                    if($(obj).parent().next().hasClass("formError")){
                        $(obj).parent().next("span.formError").html("");
                        $(obj).parent().next("span.formError").html("Please fill out this field");
                    }else{
                       $(obj).parent().after("<span class='formError'>Please fill out this field</span>");
                    }

                }else{
                    $(obj).parent().removeClass("withError");
                    $(obj).parent().removeClass("field_with_errors");
                    if($(obj).parent().next().hasClass("formError")){
                        $(obj).parent().next("span.formError").remove();
                    }
                }
            });
        });
    }
});