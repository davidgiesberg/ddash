require "json"
require "net/http"
require "uri"

Tilt.register Tilt::ERBTemplate, 'html.erb'
graph_defaults={
  :width => 800,
  :background_color => "white",
  :foreground_color => "black"
}
get '/' do
  @graph = GraphiteGraph.new(:none, graph_defaults)
  @graph.from "-1day"
  @graph.field :temps, :data => "temp.*",
      :alias_by_node => 1

  @graph3h = GraphiteGraph.new(:none, graph_defaults)
  @graph3h.from "-3h"
  @graph3h.field :temps, :data => "temp.*",
      :alias_by_node => 1

  erb :index
end

def retrieve_last_value(graphite_graph)
  uri = URI.parse("http://raspberrypi/render?#{graphite_graph.url(:json)}")

  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)

  response = http.request(request)

  if response.code == "200"
    result = JSON.parse(response.body)
    last_value = result.first["datapoints"].last.first
  end

  last_value
end

def render_svg_graph(graphite_graph)
  uri = URI.parse("http://raspberrypi/render?#{graphite_graph.url(:svg)}")

  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)

  response = http.request(request)

  if response.code == "200"
    svg_graph = response.body
  end

  svg_graph
end
