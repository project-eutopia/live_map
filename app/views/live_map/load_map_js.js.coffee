# This class simply handles calling an update function at a certain frames-per-second
# rate.  The class passed into the start_loop() function must have an update() function
class @LiveLoop
  
  constructor: (fps) ->
    @fps = fps
    @ms_per_frame = 1000 / fps
    
    @obj_to_update = null
    @interval = null
  
  is_running: ->
    if @interval != null
      return true
    else
      return false
  
  stop: ->
    if @interval != null
      clearInterval(@interval)
      @liveMapBox = null
      @interval = null

  update: ->
    if @interval != null
      @obj_to_update.update()
      
  start_loop: (obj_to_update) ->
    # Stop, in the event a loop already running
    this.stop()
    
    @obj_to_update = obj_to_update
    callback = @update.bind @
    @interval = setInterval callback, @ms_per_frame
    
    

# This class holds all the things needed in the map:  the map itself, data used
# for displaying on the map, and the loop that updates the map and the database
# check
class @LiveMapBox
  constructor: ->
    @circles = []
    @map = null
    @live_loop = new LiveLoop(30)
    @databaseCheckInterval = null
    @last_query_time = null
    
  loadMap: (divId) ->

    mapOptions =
      zoom: 2
      center: new google.maps.LatLng(20, 0)
      mapTypeId: google.maps.MapTypeId.ROADMAP

    # Build the map
    @map = new google.maps.Map(document.getElementById(divId), mapOptions)
    
    # Get the first query of the database to get data to display
    @database_get_new()
    
    # Start the drawing loop that refreshes the map itself
    @start_loop()
 
    # Create a loop to call the database periodically to get new data to display
    callback = @database_get_new.bind @
    @databaseCheckInterval = setInterval(callback, 1000*<%= @db_check_delay %>)

  
  add_circle: (lat, lng, radius) ->
    if @map != null
      @circles.push new Circle(lat, lng, radius, @map)
    
  update: ->
    for circle in @circles
      circle.update()
      #if circle.update() == true
        # remove
  
  database_get_new: ->

    $.ajax "/live_map/database_get_new",
      type: "POST"
      data:
        last_query: @last_query_time
    
      #success: ->
      #  alert
      #error: ->
      #  alert
  
  refresh: (query_time, json) ->
    @last_query_time = query_time
    @process_new_json(json)
    
  process_new_json: (json) ->
    for circle in json
      callback = @add_circle.bind(@, circle.lat, circle.lng, circle.radius)
      setTimeout callback, circle.delay*1000
    
  start_loop: ->
    @live_loop.start_loop(this)

class @Circle
  @initFillOpacity = 0.35
  @fillOpacityDecr = 0.005
  @initStrokeOpacity = 0.8
  @strokeOpacityDecr = 0.01
  
  constructor: (lat, lng, radius, map) ->
    @active = true
    @googleCircle = new google.maps.Circle(
      strokeColor: '#FF0000'
      strokeOpacity: Circle.initStrokeOpacity
      strokeWeight: 2
      fillColor: '#FF0000'
      fillOpacity: Circle.initFillOpacity
      map: map
      center: new google.maps.LatLng(lat, lng)
      radius: radius
    )
  
  update: ->
    if @active == true
      @googleCircle.setOptions(
        strokeOpacity: Math.max(@googleCircle.strokeOpacity - Circle.strokeOpacityDecr, 0)
        fillOpacity: Math.max(@googleCircle.fillOpacity - Circle.fillOpacityDecr, 0)
      )
      
      if @googleCircle.fillOpacity == 0 and @googleCircle.strokeOpacity == 0
        @active = false
        return true
      else
        return false

#
# Start the actual map loading
# Create the box that stores everything we need to run this map
#
@box = new @LiveMapBox
@box.loadMap("map-canvas")
