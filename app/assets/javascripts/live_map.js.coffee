# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


# Load the map once the window is done loading by calling controller
window.onload = ->
  $.ajax "/live_map/load_map_js",
    type: "POST"
  
