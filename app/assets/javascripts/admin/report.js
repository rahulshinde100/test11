// To load various form for report generation
function loadReportForm(ID)
{
  var type = $(ID).val();	
	$.ajax({
	  method: "POST",
	  url: "reports/load_form?type="+type
	})
	  .done(function( data ) {
	    $("#report_form").html(data);
	    $("#report_type").val(type);
	    handle_date_picker_fields();
	  });
}
