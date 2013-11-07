
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
    
    @count = 0
    
    @last_time = 0
    @time_overshoot = 0
  
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
    if @timeout != null
      now_time = Date.now()
      diff = now_time - @last_time
      @time_overshoot = @overshoot + diff
      
      # If overshot, update to bring the overshoot time down
      while @time_overshoot > @ms_per_frame
        @obj_to_update.update()
        @count = @count + 1
        @time_overshoot - @ms_per_frame
      
      @obj_to_update.update()
      @obj_to_update.render()
      @count = @count + 1
      document.getElementById("dyn").innerHTML = "<p>Ticks = "+@count+"</p><p>Num markers = "+@obj_to_update.markers.size()+"</p>"
      
      callback = @update.bind @
      @timeout = setTimeout callback, @ms_per_frame
      @last_time = Date.now()

      
  start_loop: (obj_to_update) ->
    # Stop, in the event a loop already running
    this.stop()
    
    @obj_to_update = obj_to_update
    callback = @update.bind @
    @timeout = setTimeout callback, @ms_per_frame
    @last_time = Date.now()
    @time_overshoot = 0
    
    

# This class holds all the things needed in the map:  the map itself, data used
# for displaying on the map, and the loop that updates the map and the database
# check
class @LiveMapBox
  constructor: ->
    @markers = new LinkedList
    @map = null
    @live_loop = new LiveLoop(15)
    @databaseCheckInterval = null
    @last_query_time = null
    @store = null
  
  store_select: (store) ->
    @store = store

    marker_node = @markers.head
    while marker_node isnt null
      # If a store filter is selected, set markers failing this filter to be not visible
      if store != "" and store != marker_node.obj.store.toString()
        marker_node.obj.googleMarker.setVisible(false)
      else
        marker_node.obj.googleMarker.setVisible(true)
      marker_node = marker_node.next
    
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

  
  add_marker: (lat, lng, radius, store, color) ->
    if @map != null
      marker = new Marker(lat, lng, radius, store, color, @map)
      if @store != "" and @store != null and @store != store.toString()
        marker.googleMarker.setVisible(false)
      @markers.add(marker)
    
  update: ->
    #console.log(@markers.size()) # Check that we are really removing markers
    marker_node = @markers.head
    while marker_node isnt null
      if marker_node.obj.update() == true
        # Set the map to NULL and remove from our LinkedList to ensure this
        # finished marker will be garbage collected
        marker_node.obj.googleMarker.setMap(null)
        @markers.remove(marker_node)
      marker_node = marker_node.next
  
  render: ->
    marker_node = @markers.head
    while marker_node isnt null
      marker_node.obj.render()
      marker_node = marker_node.next
  
  database_get_new: ->

    $.ajax "/live_map/database_get_new",
      type: "POST"
      data:
        last_query: @last_query_time
      #success: ->
      #  alert
      error: ->
        # This AJAX call... we should have validation of user to be able to call
        alert("Error calling /live_map/database_get_new")
  
  refresh: (query_time, json) ->
    @last_query_time = query_time
    @process_new_json(json)
    
  process_new_json: (json) ->
    for marker in json
      callback = @add_marker.bind(@, marker.lat, marker.lng, marker.radius, marker.store, marker.color)
      setTimeout callback, marker.delay*1000
    
  start_loop: ->
    @live_loop.start_loop(this)

class @Marker
  @initFillOpacity = 0.40
  @initStrokeOpacity = 0.85
  @lifetime_ticks_default = 30
  
  constructor: (lat, lng, radius, store, color, map) ->
    @ticks = 0
    @lifetime = Marker.lifetime_ticks_default
    @active = true
    @radius = radius
    @store = store
    @color = color
    @googleMarker = new google.maps.Marker(
      position: new google.maps.LatLng(lat, lng)
      map: map
      icon:
        path: google.maps.SymbolPath.CIRCLE
        strokeWeight: 2
        strokeColor: @color
        strokeOpacity: Marker.initStrokeOpacity
        fillColor: @color
        fillOpacity: Marker.initFillOpacity
        scale: @radius
    )
    
  update: ->
    @ticks = @ticks + 1
    if @ticks >= @lifetime
      @active = false
      return true
    else
      return false
  
  render: ->
    if @active == true
      # Note, it looks nicer when the lighter fill color completely fades out first,
      # before the circle outline does
      @googleMarker.setIcon(
        path: google.maps.SymbolPath.CIRCLE
        strokeWeight: 2
        strokeColor: @color
        strokeOpacity: Marker.initStrokeOpacity * (@lifetime - @ticks) /@lifetime
        fillColor: @color
        fillOpacity: Marker.initFillOpacity * Math.max(@lifetime - 1.4*@ticks, 0) / @lifetime
        scale: @radius
      )

#
# Start the actual map loading
# Create the box that stores everything we need to run this map
#
window.box = new @LiveMapBox
window.box.loadMap("map-canvas")

$('#store_list').change( ->
  window.box.store_select($('#store_list').val())
)


