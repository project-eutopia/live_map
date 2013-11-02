#console.log("<%= @query_time %>")
#console.log(<%= raw @circle_data.to_json() %>)

# Update the map data with the data received from the database
@box.refresh("<%= @query_time %>", <%= raw @circle_data.to_json() %>)
