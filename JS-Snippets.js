/********************************************************************************************************************
# A node.js module that creates an angular.js module and inserts it into a browser session to replace a module in 
# the angular app under test. It uses protractor to send the JS to the browser.
********************************************************************************************************************/
var sfClientMock = {
  sfClientModule: function() {
    angular
      .module('SFClientModule', [])
      .factory('SFClient', ['$q', function ($q) {
        var sfClient = {};

        sfClient.mockVolumes = [/*mock data goes here*/];

        sfClient.getVolumeViewModels = function() {
          var self = this;
          return $q(function(resolve, reject) {
            resolve(self.mockVolumes);
          });
        };

        sfClient.deleteVolume = function(volume) {
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

        return sfClient;
    }]);
  }
};


/********************************************************************
# D3 arc class with an optional Angular directive and React Component
/*******************************************************************/
var Arc = function(options) {
  this.inner = options.inner;
  this.outer = options.outer;
  this.start = options.start;
  this.end = options.end;
  this.transition = options.transition;
  this.name = options.name;
  this.container = options.container;
};

/*
 * http://tauday.com/tau-manifesto
 * https://www.youtube.com/watch?v=jG7vhMMXagQ
 */

Arc.arcLength = function(percent) {
  return percent * 2 * Math.PI;
};

Arc.prototype.svg = function() {
  return d3.select('#' + this.container).select('#' + this.name);
};

Arc.prototype.update = function(percent) {
  this
    .svg()
    .transition()
    .duration(this.transition)
    .ease('cubic')
    .call(this.tween.bind(this), Arc.arcLength(percent));
};

/*
  Call a tween on graph data
  Return a function that sets a new end angle in relation to
  percent of the transition completed. Then return the calculated
  intermediate arc.
*/

Arc.prototype.tween = function(transition, newAngle) {
  var self = this;
  transition.attrTween('d', function(d) {
    return function(t) {
      d.endAngle = d3.interpolate(d.endAngle, newAngle)(t);
      return self.obj(d);
    };
  });
};

Arc.prototype.render = function() {
  this.obj = d3
             .svg
             .arc()
             .innerRadius(this.inner)
             .outerRadius(this.outer)
             .startAngle(Arc.arcLength(this.start));

  d3
    .select('#' + this.container)
    .select('g')
    .append('path')
    .attr('id', this.name)
    .datum({endAngle: Arc.arcLength(this.end)})
    .attr('d', this.obj);
};

module.exports = Arc;


/***********************************
# React component for making d3 arcs
***********************************/
var Arc = require('cs-arc');
var React = require('react');

var ReactConnector = React.createClass({
  displayName: 'CSArc',
  propTypes: {
    inner:      React.PropTypes.number, // inner radius
    outer:      React.PropTypes.number, // outer radius
    start:      React.PropTypes.number, // starting angle
    end:        React.PropTypes.number, // ending angle
    width:      React.PropTypes.number, // width of the svg
    transition: React.PropTypes.number, // time in milliseconds
    container:  React.PropTypes.string, // container id
    name:       React.PropTypes.string  // arc id
  },
  updateArc: function(percent) {
    this.state.arc.update(percent);
  },
  componentDidMount: function() {
    this.state.arc.render();
    
    d3
      .select('#' + this.state.arc.container)
      .attr('width', this.props.width)
      .attr('height', this.props.width)
      .select('g')
      .attr('transform',  'translate(' + (this.props.width/2) + ',' + (this.props.width/2) + ')');
  },
  componentDidUpdate: function() {
    this.state.arc.update(this.state.arc.end);
  },
  getInitialState: function() {
    return {
      arc: new Arc({
        inner:      this.props.inner,
        outer:      this.props.outer,
        start:      this.props.start,
        end:        this.props.end,
        transition: this.props.transition,
        container:  this.props.container,
        name:       this.props.name
      })
    };
  },
  render: function() {
    return (
      <svg id={this.state.arc.container}>
        <g></g>
      </svg>
    );
  }
});

module.exports = ReactConnector;
