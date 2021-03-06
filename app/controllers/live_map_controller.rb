class LiveMapController < ApplicationController
  
  @@database_query_delay_seconds = 5

  # Main page that includes the live map
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  # Javascript for loading the map; called after page loads
  def load_map_js
    @db_check_delay = @@database_query_delay_seconds
    
    respond_to do |format|
      format.js
    end
  end
  
  # Checks the database and puts data into JSON to be drawn by on the map
  def database_get_new
    # Time of previous query is: params[:last_query]
    # Store time of this query
    @query_time = Time.now()
    
    purchases = get_purchases(params[:last_query], @query_time)
    store_colors = ['#FF2222', '#DDDD00', '#00BB22', '#000099', '#6644DD']

    @circle_data = purchases.collect do |purchase|
      {lng: purchase.lng,
       lat: purchase.lat,
       radius: purchase.radius,
       store: purchase.store,
       color: store_colors[purchase.store],
       id: purchase.id,
       delay: purchase.delay}
    end
    
    respond_to do |format|
      format.js
    end
  end

  # Temporary class for generating test data for map drawing
  class Purchase
            
    attr_accessor :lat, :lng, :delay, :store, :radius, :id
    
    def initialize(lat, lng, delay, store, radius)
      @lat = lat
      @lng = lng
      @delay = delay
      @store = store # 0, 1, 2, 3, 4
      @radius = radius
      @id = 0
    end
  end

  # Temp function for test data
  def get_purchases(from_time, to_time)
    n = rand(50)+20
    purchases = Array.new(n)
    
    n.times do |i|
      purchases[i] = Purchase.new(rand(160)-80, rand(360)-180, 1.0*rand(100)/100 * @@database_query_delay_seconds, rand(5), rand(40)+5)
    end
    
    return purchases
  end
end

