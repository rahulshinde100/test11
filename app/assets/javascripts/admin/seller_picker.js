$.fn.sellerAutocomplete = function () {
    'use strict';
    this.select2({
        minimumInputLength: 1,
        multiple: true,
        initSelection: function (element, callback) {
            $.get(Spree.routes.seller_search, {
                ids: element.val()
            }, function (data) {
                callback(data.sellers);
            });
        },
        ajax: {
            url: Spree.routes.seller_search,
            datatype: 'json',
            data: function (term) {
                return {
                    q: {
                        name_cont: term
                    }
                };
            },
            results: function (data) {
                    var sellers = data.sellers ? data.sellers : [];
                return {
                    results: sellers
                };
            }
        },
        formatResult: function (seller) {
            return seller.name;
        },
        formatSelection: function (seller) {
            return seller.name;
        }
    });
};

$(document).ready(function () {
    $('.seller_picker').sellerAutocomplete();
});