class @LinkedList
  constructor: ->
    @head = null
    @tail = null
  
  add: (obj) ->
    new_node = new Node(obj, @tail, null)
    if (@tail == null and @head == null)
      @tail = new_node
      @head = new_node
    else
      @tail.next = new_node
      @tail = new_node
    return new_node
  
  remove: (node) ->
    cur_node = @head
    while (cur_node isnt null)
      if (node == cur_node)
        # Found, now remove
        if(node == @head and node == @tail)
          @head = null
          @tail = null
        else if(node == @head)
          @head = cur_node.next
          if(@head.next isnt null)
            @head.next.prev = @head
        else if(node == @tail)
          @tail = cur_node.prev
          if(@tail.prev isnt null)
            @tail.prev.next = @tail
        else
          cur_node.prev.next = cur_node.next
          cur_node.next.prev = cur_node.prev
        return cur_node
      
      cur_node = cur_node.next
    return null
  
  size: ->
    count = 0
    cur_node = @head
    while(cur_node isnt null)
      count = count + 1
      cur_node = cur_node.next
    return count

class @Node
  constructor: (obj, prev, next) ->
    @obj = obj
    @prev = prev
    @next = next
  
  has_next: ->
    return (@next == null) ? false : true
  
  has_prev: ->
    return (@prev == null) ? false : true

# list = new @LinkedList
# a = list.add("A")
# node = list.add("B")
# c = list.add("C")
# 
# console.log(node.obj is "B")
# console.log(node.prev.obj is "A")
# console.log(node.next.obj is "C")
# 
# console.log(list.remove(node).obj is "B")
# 
# console.log(list.head.obj is "A")
# console.log(list.tail.obj is "C")
# cur_node = list.head
# while(cur_node isnt null)
#   console.log(cur_node.obj)
#   cur_node = cur_node.next
# 
# console.log(list.remove(a).obj is "A")
# 
# console.log(list.head.obj is "C")
# console.log(list.tail.obj is "C")
# cur_node = list.head
# while(cur_node isnt null)
#   console.log(cur_node.obj)
#   cur_node = cur_node.next
# 
# console.log(list.remove(c).obj is "C")
# 
# console.log(list.head.obj)
# console.log(list.tail.obj)
# cur_node = list.head
# while(cur_node isnt null)
#   console.log(cur_node.obj)
#   cur_node = cur_node.next

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
    @markers = new LinkedList
    @map = null
    @live_loop = new LiveLoop(24)
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

  
  add_marker: (lat, lng, radius) ->
    if @map != null
      @markers.add(new Marker(lat, lng, radius, @map))
    
  update: ->
    # Check that we are really removing markers
    #console.log(@markers.size())
    marker = @markers.head
    while marker isnt null
      if marker.obj.update() == true
        @markers.remove(marker)
      marker = marker.next
  
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
    for marker in json
      callback = @add_marker.bind(@, marker.lat, marker.lng, marker.radius)
      setTimeout callback, marker.delay*1000
    
  start_loop: ->
    @live_loop.start_loop(this)

class @Marker
  @initFillOpacity = 0.35
  @fillOpacityDecr = 0.005
  @initStrokeOpacity = 0.8
  @strokeOpacityDecr = 0.01
  
  constructor: (lat, lng, radius, map) ->
    @active = true
    @googleMarker = new google.maps.Marker(
      position: new google.maps.LatLng(lat, lng)
      map: map
      icon:
        path: google.maps.SymbolPath.CIRCLE
        strokeColor: '#FF0000'
        strokeOpacity: Marker.initStrokeOpacity
        strokeWeight: 2
        fillColor: '#FF0000'
        fillOpacity: Marker.initFillOpacity
        scale: 20
    )
  
  update: ->
    if @active == true
      @googleMarker.setIcon(
        path: google.maps.SymbolPath.CIRCLE
        strokeColor: '#FF0000'
        strokeOpacity: Math.max(@googleMarker.icon.strokeOpacity - Marker.strokeOpacityDecr, 0)
        strokeWeight: 2
        fillColor: '#FF0000'
        fillOpacity: Math.max(@googleMarker.icon.fillOpacity - Marker.fillOpacityDecr, 0)
        scale: 20
      )
      
      if @googleMarker.icon.fillOpacity == 0 and @googleMarker.icon.strokeOpacity == 0
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



