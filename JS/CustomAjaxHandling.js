/*********************************************************************************
# This adds the jQuery ajax error to handler to any page that needs it.
# If an ajax request returns unauthorized the user is returned to the sign-in page
*********************************************************************************/
var AjaxErrorHandler = (function() {
  function register() {
​
    $( document ).ajaxError(function( event, jqxhr, settings, thrownError ) {
      if(jqxhr.status == 401 ) {
        window.location = '/sign-in';
      }
    });
  }
​
  return {
    register: register
  };
})();