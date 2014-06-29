//
// Assemble the geographic projection
//

var land_feat, boundary_feat, places,
    projection,
    voronoi,
    path,
    svg,
    bg_g,
    tiles_g,
    places_g;


d3.select(window).on("resize", throttle);

var zoom      = d3.behavior.zoom()
    .scaleExtent([1, 14])
    .on("zoom", move)
     ;

var p = 80
    ;

var width = document.getElementById('map').offsetWidth;
var height = width / 2;


var path      = d3.geo.path().projection(projection);
var graticule = d3.geo.graticule();
var tooltip   = d3.select("#map").append("div").attr("class", "tooltip hidden");
var infobox   = d3.select("#placeinfo");

function qkey(tile){ return tile.key.join(", "); }

setup(width,height);

// Start fetching all the data
queue()
    .defer(d3.json, "world.json")
    .defer(d3.tsv,  "cities.tsv")
    .await(ready);


// ===========================================================================
//
// Basic Structure
//
function setup(width,height){
  projection = d3.geo.mercator()
    .translate([(width/2), (height/2)])
    .scale(0.24 * width  / Math.PI)
    ;

  // projection = d3.geo.equirectangular()
  //     .scale(250)
  //     .translate([width / 2, height / 2])
  //     .precision(.1);

  path = d3.geo.path().projection(projection);
  
  // Voronoi calculator
  voronoi = d3.geom.voronoi()
        .x(function(pts) { return pts.x; })
        .y(function(pts) { return pts.y; })
        .clipExtent([[0, 0], [width, height]]);
  
  // Attach the map element
  svg = d3.select("#map").append("svg")
      .attr("width", width)
      .attr("height", height)
      .call(zoom)
//      .on("click", click)
      .append("g");
  
  bg_g = svg.append("g")
      .attr("class",  "bg_g");
  
  places_g = svg.append("g")
      .attr("class", "places");

  tiles_g = svg.append("g")
      .attr("class",  "tiles");
}

function ready(error, atlas_topo, places_topo) {
  land_feat     = topojson.feature(atlas_topo, atlas_topo.objects.land);
  boundary_feat = topojson.mesh(atlas_topo,    atlas_topo.objects.countries, function(a, b) { return a !== b; });
  places        = places_topo;
  
  draw(land_feat, boundary_feat, places);
}

function redraw() {
  width = document.getElementById('map').offsetWidth;
  height = width / 2;
  d3.select('svg').remove();
  setup(width,height);
  draw(land_feat, boundary_feat, places);
}

function move() {
  var tr = d3.event.translate;
  var sc = d3.event.scale; 
  var ht = height/4;

  // put bounds on the translation
  tr[0] = Math.min(
    (width/height)  * (sc - 1), 
    Math.max( width * (1 - sc), tr[0] )
  );
  tr[1] = Math.min(
    ht * (sc - 1) + ht * sc, 
    Math.max(height  * (1 - sc) - ht * sc, tr[1])
  );

  // console.log(z, projection.scale(), sc, tr);
  
  zoom.translate(tr);
  
  bg_g.attr(    "transform", "translate(" + tr + ")scale(" + sc + ")");
  places_g.attr("transform", "translate(" + tr + ")scale(" + sc + ")");
  tiles_g.attr( "transform", "translate(" + tr + ")scale(" + sc + ")");
  places_g.selectAll("circle").attr("r", 5 / sc);
  
  //adjust the country hover stroke width based on zoom level
  d3.selectAll(".land-borders").style("stroke-width", 1.5 / sc);
  d3.selectAll(".place-cell"  ).style("stroke-width", 2.0 / sc);
  d3.selectAll(".tile"        ).style("stroke-width", 3.0 / sc);
  d3.selectAll(".equator"     ).style("stroke-width", 2.0 / sc);

  draw_tiles(sc);

}

function draw(land_feat, boundary_feat, places) {
  
  //
  // Calculate voronoi cells of places
  //

  places.forEach(function(pts) {
    pts[0] = +pts.lng;
    pts[1] = +pts.lat;
    var position = projection(pts);
    pts.x = position[0];
    pts.y = position[1];
  });
  
  voronoi(places)
      .forEach(function(cell) { cell.point.cell = cell; });
 
  //
  // Draw the Atlas Land background and the borders

  // Viewport device
  bg_g.append("path")
    .datum({type: "Sphere"})
    .attr("class", "outline")
    .attr("d", path);
  
  // // Grid lines
  // bg_g.append("path")
  //   .datum(graticule)
  //   .attr("class", "graticule")
  //   .attr("d", path);
  
  bg_g.append("path")
      .datum(land_feat)
      .attr("class", "land")
      .attr("d", path)
  ;
  bg_g.append("path")
      .datum(boundary_feat)
      .attr("class", "land-borders")
      .attr("d", path)
  ;

  bg_g.append("path")
   .datum({type: "LineString", coordinates: [[-180, 0], [-90, 0], [0, 0], [90, 0], [180, 0]]})
   .attr("class", "equator")
   .attr("d", path);

  var place = places_g
    .selectAll("g")
       .data(places)
    .enter().append("g")
      .attr("class", "place");


  var circles = place.append("circle")
      .attr("transform", function(pt) { return "translate(" + pt.x + "," + pt.y + ")"; })
      // .attr("r",         function(pt) { return 3 + Math.log(pt.n_games); })
      .attr("r", 5)
      ;
    
  place.append("path")
      .attr("class", "place-cell")
    .attr("d", function(pts) { if (! pts.cell) { console.log(pts); }; return (pts.cell && pts.cell.length) ? "M" + pts.cell.join("L") + "Z" : null; })
      .on("click.cell", click_handler)
      .on("mouseover.cell", function(pt,idx){ d3.select(this).style("fill", "#ecc");  })
      .on("mouseout.cell",  function(pt,idx){ d3.select(this).style("fill", "");  })
    .append("title").text(function(pt){ return pt.city + " " + pt.country_id; })
  ;
}

function draw_tiles(sc) {
  var z = (Math.log(sc) / Math.LN2 | 0) + 4,
      tiles = d3.quadTiles(projection, z);
  var tile = tiles_g.selectAll(".tile")
        .data(tiles, qkey);

  tile.enter().append("path")
      .attr("class", "tile outline")
      .on("click.cell", click_handler)
      .attr("d", path)
    .append("title").text(qkey)
  ;
  tile.exit().remove();

  // //offsets for tooltips
  // var offsetL = 40; // document.getElementById('map').offsetLeft+20;
  // var offsetT = 10; // document.getElementById('map').offsetTop+10;
  
  // .on("mousemove", function(tile,idx) {
  //   var mouse = d3.mouse(svg.node()).map( function(dd) { return parseInt(dd); } );
  //   var me = d3.select(this);
  //   console.log(mouse, this, me, this.offsetLeft);
  //   tooltip.classed("hidden", false)
  //     .attr("style", "left:"+(mouse[0]+offsetL)+"px;top:"+(mouse[1]+offsetT)+"px")
  //     .html(qkey(tile));
  // })
  // .on("mouseout",  function(d,i) {
  //   tooltip.classed("hidden", true);
  // })
  
  // var text = tiles_g.selectAll("text").data(tiles, qkey);
  // text.enter().append("text")
  //     .attr("text-anchor", "middle")
  //     .text(qkey);
  // text.exit().remove();
  // text.attr("transform", function(pt) {
  //   pt_c = projection(pt.centroid)
  //   // return "translate(" + (pt_c[0]+tr[0]) + "," + (pt_c[1] + tr[1]) + ")";
  //   return "translate(" + pt_c + ")";
  // });
  //  text.style("font-size", (10/sc)+"px");
}  

function click_handler(pt,idx) {
  var latlon = projection.invert(d3.mouse(this));
  infobox.text(
    "click: " + latlon + "\n\nobject:\n" + 
      JSON.stringify(pt)
  );
  console.log(idx, latlon, pt);
}

var throttleTimer;
function throttle() {
  window.clearTimeout(throttleTimer);
    throttleTimer = window.setTimeout(function() {
      redraw();
    }, 200);
}
