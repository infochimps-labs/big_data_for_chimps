
//
// Assemble the geographic projection
//

var width  = 960,
    height = 500;
var projection = d3.geo.albers()
    .translate([width / 2, height / 2])
    .scale(1080);
var path = d3.geo.path().projection(projection);

//
// Voronoi calculators. One is in projection coordinates
// one is in lng/lat coordinates
//
var voronoi = d3.geom.voronoi()
    .x(function(pts) { return pts.x; })
    .y(function(pts) { return pts.y; })
    .clipExtent([[0, 0], [width, height]]);

// Bounding box of the US: -126, 24.5, -66.5, 50.
var voronoi_geo = d3.geom.voronoi()
    .x(function(pts) { return pts.lng; })
    .y(function(pts) { return pts.lat; })
    .clipExtent([[-126, 24], [-66, 50]])
  ;

// Attach the map element
var svg = d3.select("body").append("svg")
    .attr("width", width)
    .attr("height", height);

var infobox = d3.select("body").append("div").attr("id", "parkinfo").attr("class", "jsondump");

// Start fetching all the data
queue()
    .defer(d3.json, "us.json")
    .defer(d3.tsv,  "ballparks.tsv")
    .await(ready);

function ready(error, us, ballparks) {

  //
  // Draw the US Land background and the state borders
  //
  svg.append("path")
      .datum(topojson.feature(us, us.objects.land))
      .attr("class", "states")
      .attr("d", path)
  ;
  svg.append("path")
      .datum(topojson.mesh(us, us.objects.states, function(a, b) { return a !== b; }))
      .attr("class", "state-borders")
      .attr("d", path)
  ;

  //
  // Calculate voronoi cells of ballparks
  //

  ballparks.forEach(function(pts) {
    pts[0] = +pts.lng;
    pts[1] = +pts.lat;
    var position = projection(pts);
    pts.x = position[0];
    pts.y = position[1];
  });
  ballparks = ballparks.sort(function(a, b) { return (a.park_id > b.park_id ? 1 : -1 ); });

  voronoi(ballparks)
      .forEach(function(cell) { cell.point.cell = cell; });

  var ballpark = svg.append("g")
      .attr("class", "ballparks")
    .selectAll("g")
       .data(ballparks)
    .enter().append("g")
      .attr("class", "ballpark");

  ballpark.append("path")
      .attr("class", "ballpark-cell")
      .attr("d", function(pts) { return pts.cell.length ? "M" + pts.cell.join("L") + "Z" : null; })
      .on("click.us", function(pt,idx){
        infobox.text(JSON.stringify(pt));
        console.log(idx, pt);
      })
      .on("mouseover.us", function(pt,idx){ d3.select(this).style("fill", "#ecc");  })
      .on("mouseout.us",  function(pt,idx){ d3.select(this).style("fill", "");  })
    .append("title").text(function(pt){ return pt.park_id + ": " + pt.park_name; })
  ;

  ballpark.append("circle")
      .attr("transform", function(pt) { return "translate(" + pt.x + "," + pt.y + ")"; })
      // .attr("r",         function(pt) { return 3 + Math.log(pt.n_games); })
      .attr("r", 5)
      ;

  //
  // Create a voronoi in raw lng,lat coordinates and dump it to a div
  //

  var geojson_parks = { id: 'parklocns', type: "FeatureCollection", bbox: [[-126, 24], [-66, 50]], features: [] };
  var geojson_cells = { id: 'parkcells', type: "FeatureCollection", bbox: [[-126, 24], [-66, 50]], features: [] };

  voronoi_geo(ballparks)
      .forEach(function(cell) {
        var pt = cell.point;
        var props  = {
          park_id: pt.park_id, park_name: pt.park_name,
          beg_date: pt.beg_date, end_date: pt.end_date,
          is_active: pt.is_active, n_games: pt.n_games,
          lng: pt.lng, lat: pt.lat,
          city: pt.city, state_id: pt.state_id, country_id: pt.country_id
        };

        // stash the coord-oriented cell
        pt.geov = cell;

        // Close the polygon
        var cell_ring = cell.slice();
        cell_ring.push(cell[0]);

        geojson_cells.features.push({
          id:         pt.park_id + "_cell",
          type:       "Feature",
          properties: props,
          geometry:   { type: "Polygon", coordinates: [cell_ring] }
        });

        geojson_parks.features.push({
          id:         pt.park_id,
          type:       "Feature",
          properties: props,
          geometry:   { type: "Point", coordinates: [pt.lng, pt.lat] }
        });
      });

  var dumpy = d3.select("body").append("div")
    .attr("class", "jsondump")
    .text(JSON.stringify(geojson_cells));

}
