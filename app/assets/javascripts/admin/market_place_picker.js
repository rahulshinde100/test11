$.fn.marketplaceAutocomplete = function () {
    'use strict';

    this.select2({
        minimumInputLength: 1,
        multiple: true,
        initSelection: function (element, callback) {
            $.get(Spree.routes.market_place_search, {
                ids: element.val()
            }, function (data) {
                callback(data.market_places);
            });
        },
        ajax: {
            url: Spree.routes.market_place_search,
            datatype: 'json',
            data: function (term) {
                return {
                    q: {
                        name_cont: term
                    }
                };
            },
            results: function (data) {
                var market_places = data.market_places ? data.market_places : [];
                console.log(market_places);
                return {
                    results: market_places
                };
            }
        },
        formatResult: function (market_place) {
            return market_place.name;
        },
        formatSelection: function (market_place) {
            return market_place.name;
        }
    });
};

$(document).ready(function () {
    $('.market_place_picker').marketplaceAutocomplete();
});