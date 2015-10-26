/********************************************************************************************************************
# A node.js module that creates an angular.js module and inserts it into a browser session to replace a module in 
# the angular app under test. It uses protractor to send the JS to the browser.
********************************************************************************************************************/
var csClientMock = {
  csClientModule: function() {
    angular
      .module('CSClientModule', [])
      .factory('CSClient', ['$q', function ($q) {
        var csClient = {};

        csClient.mockVolumes = [/*mock data goes here*/];

        csClient.getVolumeViewModels = function() {
          var self = this;
          return $q(function(resolve, reject) {
            resolve(self.mockVolumes);
          });
        };

        csClient.deleteVolume = function(volume) {
          for (var i = 0; i < this.mockVolumes.length; i++) {
            if (this.mockVolumes[i].volumeID === volume.volumeID) {
              this.mockVolumes.splice(i, 1);
              return $q(function(resolve, reject) {
                resolve({});
              });
            }
          }
          return $q(function(resolve, reject) {
            reject({error: "not found"});
          });
        };

        return csClient;
    }]);
  }
};
