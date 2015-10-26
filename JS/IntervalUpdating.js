/*****************************************************************************************************************************
# Any page that has the hardware status partial will load with the current information, when this javascript component is also 
# on page it refreshes every 5 seconds. Can be used in conjunction with the CustomAjaxHandling.js example.
/****************************************************************************************************************************/
var StatusUpdater = (function() {
  function register() {
    setInterval(function() {
      $.post('/facility/status.json', function(result) {
        $('#last-status').html(result['last_status']);
        $('#hardware-status').html(result["hardware_status"]);
        $('#phone-summary').html(result["phone_activity"]);
        $('#hardware-summary').html(result["hardware_summary"]);
        $('#connectivity').html(result["connectivity"]);
      });
    }, 5000);
  }
​
  return {
    register: register
  };
})();