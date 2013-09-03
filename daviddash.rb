require "json"
require "net/http"
require "uri"

GRAPHITE_RENDER_URL="http://raspberrypi/render?"

set :partial_template_engine, :erb
enable :partial_underscores

Tilt.register Tilt::ERBTemplate, 'html.erb'

graph_defaults={
  :width => 800,
  :background_color => "white",
  :foreground_color => "black"
}

get '/' do
  @inside = GraphiteGraph.new(:none, graph_defaults)
  @inside.from "-1day"
  @inside.field :temps, :data => "averageSeries(temp.*)",
      :alias => "Inside"

  @inside3h = GraphiteGraph.new(:none, graph_defaults)
  @inside3h.from "-3h"
  @inside3h.field :temps, :data => "averageSeries(temp.*)",
      :alias => "Inside"

  @outside = GraphiteGraph.new(:none, graph_defaults)
  @outside.from "-1day"
  @outside.field :temps, :data => "lcra.Bull_Creek_at_Loop_360__Austin",
      :alias => "Bull Creek @ 360"

  @outside3h = GraphiteGraph.new(:none, graph_defaults)
  @outside3h.from "-3h"
  @outside3h.field :temps, :data => "lcra.Bull_Creek_at_Loop_360__Austin",
      :alias => "Bull Creek @ 360"

  erb :index
end

def last_value(graphite_graph)
  retrieve_nth_values(graphite_graph, [-1]).first
end

def trend(graphite_graph)
  last_two_values = retrieve_nth_values(graphite_graph, [-2, -1])
  now = last_two_values[1]
  earlier = last_two_values[0]
  diff = now - earlier

  case
  when diff > 0
    "Going up"
  when diff < 0
    "Going down"
  else
    "Steady"
  end
end

def render_graph(graphite_graph)
  partial(:svg_graph, :locals => {:graphite_graph => graphite_graph})
end

private

def retrieve_nth_values(graphite_graph, indexes)
  uri = URI.parse("#{GRAPHITE_RENDER_URL}#{graphite_graph.url(:json)}")

  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)

  response = http.request(request)

  retrieved_values=[]
  if response.code == "200"
    result = JSON.parse(response.body)
    temps=result.first["datapoints"].map{|temp_time| temp_time[0]}
    retrieved_values = indexes.map{|i| temps.compact[i]}
  end

  retrieved_values
end