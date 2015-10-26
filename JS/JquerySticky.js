/**********************************************************************************
# Forces headers to stick to the top of the page and scrolls content underneath it.
**********************************************************************************/
var StickyHeader = (function() {
  function register(selector) {
    var el = $(selector),
        scrollAmount;

    $(document).on('scroll', function(event) {
      scrollAmount = $(document).scrollTop();
      scrollAmount > 276 ? el.addClass('-sticky') : el.removeClass('-sticky');
    });
  };

  return {
    register: register
  };
})();