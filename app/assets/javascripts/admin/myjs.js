$(document).ready(function(){
   $("#static_chart").hide();
    $("#manually_chart").hide();
    $("#static_excel").hide();
    $("#manually_excel").hide();

	$("#static_chart_report").click(function () { 
		$("#static_chart").toggle(1000);	
		$("#manually_chart").hide();
    	$("#static_excel").hide();
    	$("#manually_excel").hide();	
	});

	$("#manually_chart_report").click(function () { 
		$("#manually_chart").toggle(1000);
		$("#static_chart").hide();
	    $("#static_excel").hide();
	    $("#manually_excel").hide();		
	});

	$("#static_excel_report").click(function () { 
		$("#static_excel").toggle(1000);	
		$("#static_chart").hide();
	    $("#manually_chart").hide();
	    $("#manually_excel").hide();	
	});

	$("#manually_excel_report").click(function () { 
		$("#manually_excel").toggle(1000);	
		$("#static_chart").hide();
	    $("#manually_chart").hide();
	    $("#static_excel").hide();
	});

	
});