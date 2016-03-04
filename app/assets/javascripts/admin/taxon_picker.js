$.fn.taxonAutocomplete = function () {
    'use strict';
    this.select2({
        minimumInputLength: 1,
        multiple: true,
        initSelection: function (element, callback) {
            $.get(Spree.routes.taxons_search, {
                ids: element.val()
            }, function (data) {
                callback(data.taxons);
            });
        },
        ajax: {
            url: Spree.routes.taxons_search,
            datatype: 'json',
            data: function (term) {
                return {
                    q: {
                        name_cont: term
                    }
                };
            },
            results: function (data) {
                var taxons = data.taxons ? data.taxons : [];
                return {
                    results: taxons
                };
            }
        },
        formatResult: function (taxon) {
            return taxon.pretty_name;
        },
        formatSelection: function (taxon) {
            return taxon.pretty_name;
        }
    });
};

$(document).ready(function () {
    $('.taxon_picker').taxonAutocomplete();
});